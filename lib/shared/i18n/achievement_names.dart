import 'package:get/get.dart';
import 'package:we_monitor/app/models/achievement.dart';

/// Translated achievement (badge) title / metric, keyed by achievement id.
/// Keys: `achievements.<id>.title` and `achievements.<id>.metric`.
class AchievementNames {
  AchievementNames._();

  static String title(AchievementDef d) {
    final k = 'achievements.${d.id}.title';
    final t = k.tr;
    return t == k ? d.title : t;
  }

  static String metric(AchievementDef d) {
    final k = 'achievements.${d.id}.metric';
    final t = k.tr;
    return t == k ? d.metric : t;
  }
}
