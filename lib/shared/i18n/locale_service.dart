import 'dart:ui' as ui;
import 'package:flutter/widgets.dart' show Locale;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Resolves, applies and persists the app language (English / French).
class LocaleService {
  LocaleService._();

  static const en = Locale('en', 'US');
  static const fr = Locale('fr', 'FR');
  static const supported = [en, fr];
  static const _boxName = 'app_settings';
  static const _key = 'locale';

  /// Locale chosen at startup (saved choice, else device language).
  static Locale initial = en;

  /// Call once in main() after Hive.initFlutter().
  static Future<void> init() async {
    String? saved;
    try {
      final box = await Hive.openBox(_boxName);
      saved = box.get(_key) as String?;
    } catch (e) {
      debugPrint('LocaleService: could not read saved locale: $e');
    }
    final device = Get.deviceLocale ?? ui.PlatformDispatcher.instance.locale;
    initial = saved != null ? _fromCode(saved) : _fromCode(device.languageCode);
    await initializeDateFormatting('fr');
    await initializeDateFormatting('en');
    _setAuthLanguage(initial);
  }

  static Locale _fromCode(String code) =>
      code.toLowerCase().startsWith('fr') ? fr : en;

  static bool get isFrench => (Get.locale ?? initial).languageCode == 'fr';

  /// Current language code ('en' or 'fr'), for DateFormat etc.
  static String get code => isFrench ? 'fr' : 'en';

  /// Switch language, persist the choice and update Firebase Auth emails.
  static Future<void> setLocale(Locale locale) async {
    Get.updateLocale(locale);
    _setAuthLanguage(locale);
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_key, locale.languageCode);
    } catch (e) {
      debugPrint('LocaleService: could not save locale: $e');
    }
  }

  static void _setAuthLanguage(Locale l) {
    try {
      FirebaseAuth.instance.setLanguageCode(l.languageCode);
    } catch (_) {}
  }
}
