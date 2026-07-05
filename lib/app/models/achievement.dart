import 'package:flutter/material.dart';

/// How an achievement's live value behaves.
enum AchievementKind {
  /// Value only grows (weight, items, cleanups, days...). Unlock is permanent
  /// and never regresses.
  cumulative,

  /// Value can drop (current day streak). Unlocked levels stay, but the live
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
  final int currentStreak;

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

/// A definition combined with the user's current progress, for the UI.
class AchievementProgress {
  final AchievementDef def;

  /// Highest level ever unlocked (persisted, monotonic).
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
  num? get nextThreshold =>
      isMaxed ? null : def.thresholds[unlockedLevel];

  /// Threshold of the level currently in progress' floor (previous unlocked).
  num get currentFloor =>
      unlockedLevel == 0 ? 0 : def.thresholds[unlockedLevel - 1];

  /// 0..1 progress toward the next level (1.0 when maxed).
  double get fraction {
    if (isMaxed) return 1;
    final floor = currentFloor;
    final target = nextThreshold!;
    final span = (target - floor);
    if (span <= 0) return 0;
    final p = (value - floor) / span;
    return p.clamp(0, 1).toDouble();
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
      metric: 'day streak',
      unit: '',
      icon: Icons.bolt_rounded,
      color: Color(0xFFFBB825),
      kind: AchievementKind.streak,
      thresholds: [3, 5, 7, 14, 30],
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
