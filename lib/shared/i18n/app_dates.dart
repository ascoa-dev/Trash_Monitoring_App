import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:we_monitor/shared/i18n/locale_service.dart';

/// Locale-aware date helpers (display only; stored date strings stay as-is).
class AppDates {
  AppDates._();

  /// "Today" / "Yesterday" / "N days ago" / dd/MM/yyyy.
  static String relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'shared.today'.tr;
    if (diff.inDays == 1) return 'shared.yesterday'.tr;
    if (diff.inDays < 7) {
      return 'shared.daysAgo'.tr.replaceAll('{n}', '${diff.inDays}');
    }
    return DateFormat('dd/MM/yyyy', LocaleService.code).format(dt);
  }

  /// e.g. "05 Jan 2025" / "05 janv. 2025".
  static String medium(DateTime dt) =>
      DateFormat('dd MMM yyyy', LocaleService.code).format(dt);
}
