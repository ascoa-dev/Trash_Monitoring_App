import 'package:get/get.dart';

import 'strings_core.dart';
import 'strings_auth.dart';
import 'strings_profile.dart';
import 'strings_admin.dart';
import 'strings_cleanup.dart';
import 'strings_hotspot.dart';
import 'strings_home.dart';
import 'strings_news.dart';
import 'strings_stats.dart';
import 'strings_achievements.dart';
import 'strings_shared.dart';
import 'strings_sync.dart';

/// Merges every per-area key map. Keys are namespaced: 'core.x', 'home.x'...
/// Add strings to strings_<area>.dart (En AND Fr); no change needed here.
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': {
          ...coreEn,
          ...authEn,
          ...profileEn,
          ...adminEn,
          ...cleanupEn,
          ...hotspotEn,
          ...homeEn,
          ...newsEn,
          ...statsEn,
          ...achievementsEn,
          ...sharedEn,
          ...syncEn,
        },
        'fr_FR': {
          ...coreFr,
          ...authFr,
          ...profileFr,
          ...adminFr,
          ...cleanupFr,
          ...hotspotFr,
          ...homeFr,
          ...newsFr,
          ...statsFr,
          ...achievementsFr,
          ...sharedFr,
          ...syncFr,
        },
      };
}
