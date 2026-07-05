import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:we_monitor/app/models/achievement.dart';
import 'package:we_monitor/modules/achievements/achievement_celebration_dialog.dart';

/// A level that was just unlocked, awaiting its celebration.
class UnlockedEvent {
  final AchievementDef def;
  final int level; // 1-based
  const UnlockedEvent(this.def, this.level);
}

/// Fetches the user's activity, computes stats, evaluates achievements against
/// persisted levels, stores any new unlocks, and queues celebrations.
///
/// Persisted under `users/{uid}.achievements` as
/// `{ id: { level, seen, updatedAt } }` where:
///   - `level` = highest unlocked level (monotonic).
///   - `seen`  = highest level whose celebration was actually rendered to the
///     user. A celebration is pending whenever `level > seen`, so an unlock
///     that was earned while the app was closed (e.g. via the admin backfill)
///     still fires the next time the app runs. Only the *highest* pending level
///     is celebrated — jumping from level 1 to 3 shows one card for level 3,
///     not one per level.
class AchievementsController extends GetxController {
  final RxBool isLoading = false.obs;
  final Rx<AchievementStats> stats = AchievementStats.empty.obs;

  /// Persisted highest-unlocked level per achievement id.
  final RxMap<String, int> unlocked = <String, int>{}.obs;

  /// Persisted highest *seen* (celebrated) level per achievement id.
  final RxMap<String, int> seen = <String, int>{}.obs;

  bool _celebrating = false;
  final List<UnlockedEvent> _queue = [];

  /// Progress rows in catalogue order, for the screen.
  List<AchievementProgress> get progress => Achievements.all
      .map((def) => AchievementProgress(
            def: def,
            unlockedLevel: unlocked[def.id] ?? 0,
            value: stats.value.valueFor(def.id),
          ))
      .toList();

  int get totalUnlocked =>
      Achievements.all.fold(0, (acc, d) => acc + (unlocked[d.id] ?? 0));

  int get totalPossible =>
      Achievements.all.fold(0, (acc, d) => acc + d.maxLevel);

  @override
  void onInit() {
    super.onInit();
    evaluate();
  }

  /// Ensure the controller exists and run an evaluation that renders any
  /// pending celebrations. Call after a successful cleanup/hotspot submission
  /// and on app start.
  static Future<void> checkAfterActivity() async {
    final ctrl = Get.isRegistered<AchievementsController>()
        ? Get.find<AchievementsController>()
        : Get.put(AchievementsController(), permanent: true);
    await ctrl.evaluate();
  }

  /// Fetch → compute → evaluate → persist → render any pending celebrations.
  ///
  /// A celebration is pending for an achievement whenever its unlocked `level`
  /// exceeds its `seen` level. This always runs (app open, screen open, after
  /// activity) so an unlock earned while offline/closed is never skipped.
  Future<void> evaluate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final db = FirebaseFirestore.instance;

    try {
      isLoading.value = true;

      final results = await Future.wait([
        db.collection('cleanups').where('userId', isEqualTo: uid).get(),
        db.collection('plastic_hotspots').where('userId', isEqualTo: uid).get(),
        db.collection('users').doc(uid).get(),
      ]);
      final cleanupDocs = (results[0] as QuerySnapshot).docs;
      final hotspotDocs = (results[1] as QuerySnapshot).docs;
      final userSnap = results[2] as DocumentSnapshot;

      final computed = _computeStats(cleanupDocs, hotspotDocs.length);
      stats.value = computed;

      // Load persisted { level, seen } per achievement.
      final userData = userSnap.data() as Map<String, dynamic>?;
      final storedRaw =
          (userData?['achievements'] as Map<String, dynamic>?) ?? const {};
      final storedLevel = <String, int>{};
      final storedSeen = <String, int>{};
      storedRaw.forEach((id, v) {
        if (v is Map) {
          storedLevel[id] = (v['level'] is int) ? v['level'] as int : 0;
          // `seen` may be absent on data written before this system existed.
          storedSeen[id] = (v['seen'] is int) ? v['seen'] as int : 0;
        }
      });

      final newLevel = <String, int>{};
      final newSeen = <String, int>{};
      final events = <UnlockedEvent>[];
      for (final def in Achievements.all) {
        final prevSeen = storedSeen[def.id] ?? 0;
        final computedLevel = def.levelFor(computed.valueFor(def.id));
        final level = computedLevel;
        newLevel[def.id] = level;
        // If the level was downgraded below what they have seen, reduce seen level to match
        final adjustedSeen = prevSeen > level ? level : prevSeen;
        newSeen[def.id] = adjustedSeen;
        // Pending if the unlocked level is ahead of what the user has seen.
        // Celebrate only the highest pending level (no per-level spam).
        if (level > adjustedSeen) events.add(UnlockedEvent(def, level));
      }

      unlocked.value = newLevel;
      seen.value = newSeen;

      // Persist level and seen changes
      final changed = newLevel.entries.any((e) => (storedLevel[e.key] ?? 0) != e.value) ||
                      newSeen.entries.any((e) => (storedSeen[e.key] ?? 0) != e.value);
      if (changed) await _persistLevels(db, uid, newLevel, newSeen);

      if (events.isNotEmpty) {
        _queue
          ..clear()
          ..addAll(events);
        _drainQueue(db, uid);
      }
    } catch (e) {
      debugPrint('[Achievements] evaluate error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _persistLevels(
    FirebaseFirestore db,
    String uid,
    Map<String, int> levels,
    Map<String, int> seens,
  ) async {
    final payload = <String, dynamic>{};
    levels.forEach((id, level) {
      payload[id] = {
        'level': level,
        'seen': seens[id] ?? 0,
        'updatedAt': FieldValue.serverTimestamp(),
      };
    });
    await db.collection('users').doc(uid).set(
      {'achievements': payload},
      SetOptions(merge: true),
    );
  }

  /// Mark an achievement's celebration as seen once the card is dismissed, so
  /// it never re-fires. This is the "seen marker" — it only advances after the
  /// app has actually rendered the celebration.
  Future<void> _markSeen(
    FirebaseFirestore db,
    String uid,
    String id,
    int level,
  ) async {
    seen[id] = level;
    seen.refresh();
    try {
      await db.collection('users').doc(uid).set(
        {
          'achievements': {
            id: {'seen': level, 'updatedAt': FieldValue.serverTimestamp()},
          },
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('[Achievements] markSeen error: $e');
    }
  }

  void _drainQueue(FirebaseFirestore db, String uid) {
    if (_celebrating || _queue.isEmpty) return;
    _celebrating = true;
    final event = _queue.removeAt(0);
    showAchievementCelebration(event, onDismiss: () async {
      // The card was actually rendered and dismissed → record it as seen.
      await _markSeen(db, uid, event.def.id, event.level);
      _celebrating = false;
      _drainQueue(db, uid);
    });
  }

  AchievementStats _computeStats(
    List<QueryDocumentSnapshot> cleanups,
    int hotspotCount,
  ) {
    final unflaggedCleanups = cleanups.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      return data != null && data['flagged'] != true;
    }).toList();

    double totalWeight = 0;
    int totalItems = 0;
    int volunteers = 0;
    final environments = <String>{};
    final locations = <String>{};
    final days = <DateTime>{};

    for (final doc in unflaggedCleanups) {
      final data = doc.data() as Map<String, dynamic>;
      final basic = (data['basicInfo'] as Map<String, dynamic>?) ?? const {};
      final trash = (data['trashCollected'] as Map<String, dynamic>?) ?? const {};

      totalWeight += ((trash['totalWeight'] as num?) ?? 0).toDouble();
      volunteers += ((basic['peopleCount'] as num?) ?? 0).toInt();

      final env = (trash['environment'] as String?)?.trim();
      if (env != null && env.isNotEmpty) environments.add(env);
      final loc = (basic['location'] as String?)?.trim();
      if (loc != null && loc.isNotEmpty) locations.add(loc.toLowerCase());

      final categories =
          (trash['categories'] as Map<String, dynamic>?) ?? const {};
      for (final cat in categories.values) {
        if (cat is Map<String, dynamic>) {
          for (final item in cat.values) {
            if (item is Map<String, dynamic>) {
              totalItems += ((item['count'] as num?) ?? 0).toInt();
            }
          }
        }
      }

      final created = data['createdAt'];
      DateTime? d;
      if (created is Timestamp) {
        d = created.toDate();
      } else {
        d = _parseDdMmYyyy(basic['date'] as String?);
      }
      if (d != null) days.add(DateTime(d.year, d.month, d.day));
    }

    return AchievementStats(
      totalWeight: totalWeight,
      totalItems: totalItems,
      cleanups: unflaggedCleanups.length,
      hotspots: hotspotCount,
      volunteers: volunteers,
      environments: environments.length,
      locations: locations.length,
      activeDays: days.length,
      currentStreak: _currentStreak(days),
    );
  }

  /// Consecutive days ending today (or yesterday, so an in-progress streak
  /// still counts). Returns 0 once the streak is broken.
  static int _currentStreak(Set<DateTime> days) {
    if (days.isEmpty) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    DateTime cursor;
    if (days.contains(today)) {
      cursor = today;
    } else if (days.contains(yesterday)) {
      cursor = yesterday;
    } else {
      return 0;
    }

    int streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static DateTime? _parseDdMmYyyy(String? date) {
    if (date == null) return null;
    final parts = date.split('/');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }
}
