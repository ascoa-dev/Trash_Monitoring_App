import 'package:flutter/material.dart';

/// How an achievement's live value behaves.
enum AchievementKind {
  /// Value follows the user's current data (weight, items, cleanups, days...).
  /// The level is recomputed each time, so deleting a cleanup can lower it.
  cumulative,

  /// Value can drop (current week streak). Unlocked levels stay, but the live
  /// progress bar resets when the streak breaks and must be rebuilt.
  streak,
}

/// Static definition of one achievement (title, thresholds, presentation).
class AchievementDef {
  final String id;
  final String title;

  /// Short human description of what earns it, e.g. "trash collected".
  final String metric;

  /// Unit shown next to numbers ("kg", "items", ""); empty for bare counts.
  final String unit;

  final IconData icon;
  final Color color;
  final AchievementKind kind;

  /// Ordered thresholds; index i unlocks Level (i+1).
  final List<num> thresholds;

  const AchievementDef({
    required this.id,
    required this.title,
    required this.metric,
    required this.unit,
    required this.icon,
    required this.color,
    required this.kind,
    required this.thresholds,
  });

  int get maxLevel => thresholds.length;

  /// Levels passed for a given live value (0..maxLevel).
  int levelFor(num value) {
    int level = 0;
    for (final t in thresholds) {
      if (value >= t) {
        level++;
      } else {
        break;
      }
    }
    return level;
  }

  /// Level to persist given the live [value] and the [stored] level.
  /// Cumulative levels track current data exactly (deleting a cleanup can lower
  /// them); streak levels never regress once unlocked.
  int resolveLevel(num value, int stored) {
    final computed = levelFor(value);
    return kind == AchievementKind.streak && stored > computed
        ? stored
        : computed;
  }
}

/// Per-user computed stats used to evaluate every achievement.
class AchievementStats {
  final double totalWeight;
  final int totalItems;
  final int cleanups;
  final int hotspots;
  final int volunteers;
  final int environments;
  final int locations;
  final int activeDays;

  /// Consecutive weeks with a cleanup or hotspot report (see [WeekStreak]).
  final int currentStreak;

  /// Whether this week already has activity (the streak is safe until next
  /// Monday) or still needs some to continue.
  final bool activeThisWeek;

  const AchievementStats({
    required this.totalWeight,
    required this.totalItems,
    required this.cleanups,
    required this.hotspots,
    required this.volunteers,
    required this.environments,
    required this.locations,
    required this.activeDays,
    required this.currentStreak,
    this.activeThisWeek = false,
  });

  static const empty = AchievementStats(
    totalWeight: 0,
    totalItems: 0,
    cleanups: 0,
    hotspots: 0,
    volunteers: 0,
    environments: 0,
    locations: 0,
    activeDays: 0,
    currentStreak: 0,
  );

  /// Maps an achievement id to its live value.
  num valueFor(String id) {
    switch (id) {
      case 'weight_warrior':
        return totalWeight;
      case 'item_hunter':
        return totalItems;
      case 'cleanup_champion':
        return cleanups;
      case 'hotspot_scout':
        return hotspots;
      case 'dedicated_days':
        return activeDays;
      case 'streak_master':
        return currentStreak;
      case 'mobilizer':
        return volunteers;
      case 'explorer':
        return environments;
      case 'cartographer':
        return locations;
      default:
        return 0;
    }
  }
}

/// Weekly streak maths. Weeks start Monday 00:00 local time.
class WeekStreak {
  WeekStreak._();

  /// Monday of the week containing [d] (date only, so DST can't shift it).
  static DateTime weekStart(DateTime d) =>
      DateTime(d.year, d.month, d.day - (d.weekday - 1));

  /// Consecutive active weeks ending this week, or last week: a streak stays
  /// alive through the current week and breaks only once a whole week passes
  /// with no activity. [activeWeeks] holds [weekStart] values.
  static int current(Set<DateTime> activeWeeks, DateTime now) {
    var cursor = weekStart(now);
    if (!activeWeeks.contains(cursor)) {
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 7);
      if (!activeWeeks.contains(cursor)) return 0;
    }
    var streak = 0;
    while (activeWeeks.contains(cursor)) {
      streak++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 7);
    }
    return streak;
  }
}

/// A definition combined with the user's current progress, for the UI.
class AchievementProgress {
  final AchievementDef def;

  /// Currently unlocked level (persisted; streak levels never regress).
  final int unlockedLevel;

  /// Current live value of the metric.
  final num value;

  const AchievementProgress({
    required this.def,
    required this.unlockedLevel,
    required this.value,
  });

  bool get isMaxed => unlockedLevel >= def.maxLevel;

  /// Threshold of the next level, or null when maxed.
  num? get nextThreshold => isMaxed ? null : def.thresholds[unlockedLevel];

  /// 0..1 progress toward the next level (1.0 when maxed). Measured from 0 so
  /// the bar matches the "6.1 / 25 kg" label shown under it.
  double get fraction {
    if (isMaxed) return 1;
    final target = nextThreshold!;
    if (target <= 0) return 0;
    return (value / target).clamp(0, 1).toDouble();
  }
}

/// The catalogue. Order here is the display order on the screen.
class Achievements {
  Achievements._();

  static const List<AchievementDef> all = [
    AchievementDef(
      id: 'weight_warrior',
      title: 'Weight Warrior',
      metric: 'trash collected',
      unit: 'kg',
      icon: Icons.fitness_center_rounded,
      color: Color(0xFF357187),
      kind: AchievementKind.cumulative,
      thresholds: [5, 25, 50, 100, 250, 500],
    ),
    AchievementDef(
      id: 'item_hunter',
      title: 'Item Hunter',
      metric: 'items removed',
      unit: '',
      icon: Icons.delete_sweep_rounded,
      color: Color(0xFF1E88A8),
      kind: AchievementKind.cumulative,
      thresholds: [50, 250, 500, 1000, 5000],
    ),
    AchievementDef(
      id: 'cleanup_champion',
      title: 'Cleanup Champion',
      metric: 'cleanups logged',
      unit: '',
      icon: Icons.recycling_rounded,
      color: Color(0xFF419310),
      kind: AchievementKind.cumulative,
      thresholds: [1, 5, 10, 25, 50, 100, 200, 500],
    ),
    AchievementDef(
      id: 'hotspot_scout',
      title: 'Hotspot Scout',
      metric: 'hotspots reported',
      unit: '',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFD3691E),
      kind: AchievementKind.cumulative,
      thresholds: [1, 5, 10, 25, 50, 100, 250],
    ),
    AchievementDef(
      id: 'dedicated_days',
      title: 'Dedicated',
      metric: 'active days',
      unit: '',
      icon: Icons.calendar_month_rounded,
      color: Color(0xFF6A4FA8),
      kind: AchievementKind.cumulative,
      thresholds: [1, 5, 15, 30, 60, 120, 240],
    ),
    AchievementDef(
      id: 'streak_master',
      title: 'Streak Master',
      metric: 'week streak',
      unit: '',
      icon: Icons.bolt_rounded,
      color: Color(0xFFFBB825),
      kind: AchievementKind.streak,
      // Weeks in a row with a cleanup or hotspot report.
      thresholds: [2, 4, 8, 12, 26, 52],
    ),
    AchievementDef(
      id: 'mobilizer',
      title: 'Mobilizer',
      metric: 'volunteers rallied',
      unit: '',
      icon: Icons.groups_rounded,
      color: Color(0xFFBE123C),
      kind: AchievementKind.cumulative,
      thresholds: [10, 50, 100, 500, 1000],
    ),
    AchievementDef(
      id: 'explorer',
      title: 'Explorer',
      metric: 'environments covered',
      unit: '',
      icon: Icons.travel_explore_rounded,
      color: Color(0xFF0F766E),
      kind: AchievementKind.cumulative,
      thresholds: [1, 2, 3],
    ),
    AchievementDef(
      id: 'cartographer',
      title: 'Cartographer',
      metric: 'distinct locations',
      unit: '',
      icon: Icons.map_rounded,
      color: Color(0xFF9A6324),
      kind: AchievementKind.cumulative,
      thresholds: [3, 10, 25, 50, 100, 200],
    ),
  ];

  static AchievementDef byId(String id) => all.firstWhere((a) => a.id == id);
}
