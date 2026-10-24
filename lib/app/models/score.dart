import 'package:we_monitor/app/models/achievement.dart';

/// Port of ascoa_web/lib/score.ts. Keep the weights in sync with the web.
class Score {
  Score._();

  static const int cleanup = 10;
  static const double kg = 2;
  static const int volunteer = 1;
  static const int hotspot = 5;
  static const int location = 3;
  static const int achievementLevel = 5; // all-time only

  static double activityPoints(AchievementStats s) =>
      cleanup * s.cleanups +
      kg * s.totalWeight +
      volunteer * s.volunteers +
      hotspot * s.hotspots +
      location * s.locations;

  /// Sum of levels computed from live stats (streak uses the current streak,
  /// like the web).
  static int levelSum(AchievementStats s) =>
      Achievements.all.fold(0, (n, d) => n + d.levelFor(s.valueFor(d.id)));

  static int allTime(AchievementStats s) =>
      (activityPoints(s) + achievementLevel * levelSum(s)).round();

  /// [monthStats] = stats over this calendar month's cleanups/hotspots only.
  static int monthly(AchievementStats monthStats) =>
      activityPoints(monthStats).round();
}
