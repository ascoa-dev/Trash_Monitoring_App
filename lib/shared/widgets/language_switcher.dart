import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/i18n/locale_service.dart';

/// Small "EN | FR" pill used on the login / signup screens.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final isFr = LocaleService.isFrench;
    Widget chip(String label, bool selected, Locale locale) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: selected ? null : () => LocaleService.setLocale(locale),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
    return Semantics(
      label: 'shared.language'.tr,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            chip('EN', !isFr, LocaleService.en),
            chip('FR', isFr, LocaleService.fr),
          ],
        ),
      ),
    );
  }
}

/// Current language name in its own language.
String currentLanguageName() => LocaleService.isFrench ? 'Français' : 'English';

/// Simple English / Français chooser (used from the Profile screen).
Future<void> showLanguageChooser(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder:
        (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final entry in {
                'English': LocaleService.en,
                'Français': LocaleService.fr,
              }.entries)
                ListTile(
                  title: Text(entry.key),
                  trailing:
                      entry.value.languageCode == LocaleService.code
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    LocaleService.setLocale(entry.value);
                  },
                ),
            ],
          ),
        ),
  );
}
