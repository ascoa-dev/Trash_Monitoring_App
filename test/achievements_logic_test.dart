import 'package:flutter_test/flutter_test.dart';
import 'package:we_monitor/app/models/achievement.dart';

// Replica of AchievementsController._currentStreak (private) so the streak
// rule is covered by a runnable check without pulling in Firebase.
int currentStreak(Set<DateTime> days) {
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

DateTime day(int daysAgo) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return today.subtract(Duration(days: daysAgo));
}

void main() {
  final weight = Achievements.byId('weight_warrior'); // [5,25,50,100,250,500]

  test('levelFor counts passed thresholds', () {
    expect(weight.levelFor(0), 0);
    expect(weight.levelFor(4.9), 0);
    expect(weight.levelFor(5), 1);
    expect(weight.levelFor(60), 3); // 5,25,50 passed
    expect(weight.levelFor(9999), weight.maxLevel);
  });

  test('progress fraction is relative to the current level band', () {
    // unlocked lvl 1 (>=5), value 15, next threshold 25, floor 5 -> 10/20 = .5
    final p = AchievementProgress(def: weight, unlockedLevel: 1, value: 15);
    expect(p.nextThreshold, 25);
    expect(p.fraction, closeTo(0.5, 1e-9));
    expect(p.isMaxed, false);
  });

  test('maxed achievement reports full progress and no next threshold', () {
    final p = AchievementProgress(
      def: weight,
      unlockedLevel: weight.maxLevel,
      value: 999,
    );
    expect(p.isMaxed, true);
    expect(p.nextThreshold, isNull);
    expect(p.fraction, 1);
  });

  test('current streak counts consecutive days up to today', () {
    expect(currentStreak({day(0), day(1), day(2)}), 3);
  });

  test('current streak still counts if last activity was yesterday', () {
    expect(currentStreak({day(1), day(2)}), 2);
  });

  test('current streak resets to 0 when the chain is broken', () {
    // gap at day 1 -> streak from today/yesterday cannot reach older days
    expect(currentStreak({day(0), day(3), day(4)}), 1);
    // last activity 3 days ago -> broken
    expect(currentStreak({day(3), day(4), day(5)}), 0);
  });

  test('stats.valueFor maps ids to metrics', () {
    const s = AchievementStats(
      totalWeight: 12.5,
      totalItems: 40,
      cleanups: 3,
      hotspots: 1,
      volunteers: 22,
      environments: 2,
      locations: 5,
      activeDays: 4,
      currentStreak: 2,
    );
    expect(s.valueFor('weight_warrior'), 12.5);
    expect(s.valueFor('streak_master'), 2);
    expect(s.valueFor('mobilizer'), 22);
  });
}
