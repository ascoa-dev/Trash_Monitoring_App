import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:we_monitor/shared/widgets/app_dialog.dart';

/// Prompts the user when a newer version is in the store.
///
/// Reads one small doc, `config/app_version`, once per app session:
/// `{ android: {latest: '1.1.0', min: '1.0.0'}, ios: {latest, min} }`.
/// Firestore serves it from its offline cache when there's no network, so
/// the check works offline and costs a single tiny read when online.
/// Below `min` the dialog can't be dismissed; below `latest` "Later" snoozes
/// that version for [_snooze].
class UpdateService {
  UpdateService._();

  static const _snooze = Duration(days: 3);
  static const _playUrl =
      'https://play.google.com/store/apps/details?id=com.ascoa.wemonitor';
  static const _appStoreUrl =
      'https://apps.apple.com/app/we-monitor-ascoa/id6794283541';
  static bool _checked = false;

  static Future<void> checkOncePerSession() async {
    if (_checked || !(Platform.isAndroid || Platform.isIOS)) return;
    _checked = true;
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('config')
              .doc('app_version')
              .get();
      final platform = doc.data()?[Platform.isIOS ? 'ios' : 'android'];
      if (platform is! Map) return;
      final latest = platform['latest'] as String?;
      final min = platform['min'] as String?;
      final current = (await PackageInfo.fromPlatform()).version;

      final forced = min != null && compareVersions(current, min) < 0;
      final outdated = latest != null && compareVersions(current, latest) < 0;
      if (!forced && !outdated) return;
      if (!forced && await _isSnoozed(latest!)) return;
      _showDialog(forced: forced, latest: latest ?? min!);
    } catch (e) {
      debugPrint('[UpdateService] check skipped: $e');
    }
  }

  /// Numeric dotted-version compare: -1, 0 or 1. Missing parts count as 0.
  static int compareVersions(String a, String b) {
    List<int> parts(String v) =>
        v.split('+').first.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final x = parts(a), y = parts(b);
    for (var i = 0; i < x.length || i < y.length; i++) {
      final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
      if (d != 0) return d.sign;
    }
    return 0;
  }

  static Future<Box> _box() => Hive.openBox('app_settings');

  static Future<bool> _isSnoozed(String version) async {
    final until = (await _box()).get('update_snooze_$version') as int?;
    return until != null && DateTime.now().millisecondsSinceEpoch < until;
  }

  static Future<void> _snoozeVersion(String version) async {
    (await _box()).put(
      'update_snooze_$version',
      DateTime.now().add(_snooze).millisecondsSinceEpoch,
    );
  }

  static Future<void> _openStore() async {
    final uri = Uri.parse(Platform.isIOS ? _appStoreUrl : _playUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static void _showDialog({required bool forced, required String latest}) {
    Get.dialog(
      PopScope(
        canPop: !forced,
        child: AppDialog(
          title: AppStrings.updateAvailableTitle,
          body:
              forced
                  ? AppStrings.updateRequiredBody
                  : AppStrings.updateAvailableBody.replaceAll(
                    '{version}',
                    latest,
                  ),
          icon: Icons.system_update_outlined,
          primaryActionLabel: AppStrings.updateNow,
          onPrimaryAction: _openStore,
          secondaryActions:
              forced
                  ? const []
                  : [
                    AppDialogAction(
                      label: AppStrings.updateLater,
                      onPressed: () {
                        _snoozeVersion(latest);
                        Get.back();
                      },
                    ),
                  ],
        ),
      ),
      barrierDismissible: false,
    );
  }
}
