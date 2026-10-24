import 'package:flutter_test/flutter_test.dart';
import 'package:we_monitor/shared/i18n/strings_achievements.dart';
import 'package:we_monitor/shared/i18n/strings_admin.dart';
import 'package:we_monitor/shared/i18n/strings_auth.dart';
import 'package:we_monitor/shared/i18n/strings_cleanup.dart';
import 'package:we_monitor/shared/i18n/strings_core.dart';
import 'package:we_monitor/shared/i18n/strings_home.dart';
import 'package:we_monitor/shared/i18n/strings_hotspot.dart';
import 'package:we_monitor/shared/i18n/strings_news.dart';
import 'package:we_monitor/shared/i18n/strings_profile.dart';
import 'package:we_monitor/shared/i18n/strings_shared.dart';
import 'package:we_monitor/shared/i18n/strings_stats.dart';
import 'package:we_monitor/shared/i18n/strings_sync.dart';

void main() {
  final areas = <String, List<Map<String, String>>>{
    'core': [coreEn, coreFr],
    'auth': [authEn, authFr],
    'profile': [profileEn, profileFr],
    'admin': [adminEn, adminFr],
    'cleanup': [cleanupEn, cleanupFr],
    'hotspot': [hotspotEn, hotspotFr],
    'home': [homeEn, homeFr],
    'news': [newsEn, newsFr],
    'stats': [statsEn, statsFr],
    'achievements': [achievementsEn, achievementsFr],
    'shared': [sharedEn, sharedFr],
    'sync': [syncEn, syncFr],
  };
  final token = RegExp(r'\{\w+\}|%[sd]');

  areas.forEach((area, maps) {
    test('$area: every En key exists in Fr with same placeholders', () {
      final en = maps[0], fr = maps[1];
      for (final e in en.entries) {
        expect(fr.containsKey(e.key), isTrue, reason: 'missing fr: ${e.key}');
        expect(fr[e.key]!.trim(), isNotEmpty, reason: 'empty fr: ${e.key}');
        final enTokens = token.allMatches(e.value).map((m) => m[0]).toSet();
        final frTokens = token.allMatches(fr[e.key]!).map((m) => m[0]).toSet();
        expect(frTokens, enTokens, reason: 'placeholders differ: ${e.key}');
      }
      for (final k in fr.keys) {
        expect(en.containsKey(k), isTrue, reason: 'orphan fr key: $k');
        expect(k.startsWith('$area.'), isTrue, reason: 'bad prefix: $k');
      }
    });
  });
}
