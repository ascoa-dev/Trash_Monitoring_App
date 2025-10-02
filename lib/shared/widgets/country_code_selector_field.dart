import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';

/// A floating-label country selector that matches the styling of
/// [FloatingLabelInputField] while leveraging the `country_picker` package
/// for a complete list of international dialing codes.
class CountryCodeSelectorField extends StatelessWidget {
  final Country selectedCountry;
  final ValueChanged<Country> onChanged;
  final String label;
  final String? supportText;
  final bool isError;
  final bool enabled;
  final double topSpacing;

  const CountryCodeSelectorField({
    super.key,
    required this.selectedCountry,
    required this.onChanged,
    required this.label,
    this.supportText,
    this.isError = false,
    this.enabled = true,
    this.topSpacing = AppDimensions.fieldVerticalSpacing,
  });

  Future<void> _openCountryPicker(BuildContext context) async {
    if (!enabled) return;
    final isFrench = Get.locale?.languageCode == 'fr';
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      favorite: const ['CM'],
      onSelect: onChanged,
      countryListTheme: CountryListThemeData(
        bottomSheetHeight: MediaQuery.of(context).size.height * 0.75,
        textStyle: AppTextStyles.body.copyWith(
          color: AppColors.textDark,
          fontSize: AppDimensions.inputFontSize,
          letterSpacing: 0.1,
        ),
        inputDecoration: InputDecoration(
          labelText:
              isFrench
                  ? AppStrings.countrySearchLabelFrench
                  : AppStrings.countrySearchLabel,
          labelStyle: AppTextStyles.bodySecondary.copyWith(
            color: AppColors.textAccent,
          ),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () => _openCountryPicker(context),
                child: Container(
                  width: double.infinity,
                  height: AppDimensions.inputFieldHeight,
                  decoration: BoxDecoration(
                    color: enabled ? AppColors.background : AppColors.white70,
                    border: Border.all(
                      color: isError ? AppColors.error : AppColors.accentGreen,
                      width:
                          isError
                              ? AppDimensions.inputBorderWidthError
                              : AppDimensions.inputBorderWidth,
                    ),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.smallRadius,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.inputHorizontalPadding,
                  ),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(
                        selectedCountry.flagEmoji,
                        style: TextStyle(fontSize: AppDimensions.flagEmojiSize),
                      ),
                      const SizedBox(width: AppDimensions.selectorSmallGap),
                      Text(
                        '+${selectedCountry.phoneCode}',
                        style: AppTextStyles.body.copyWith(
                          fontSize: AppDimensions.inputFontSize,
                          height: 22 / AppDimensions.inputFontSize,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textAccent,
                        size: AppDimensions.selectorIconSize,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left:
                    AppDimensions.inputHorizontalPadding -
                    AppDimensions.chipHorizontalPadding,
                top: -AppDimensions.floatingLabelOffset,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.chipHorizontalPadding,
                  ),
                  color: AppColors.background,
                  child: Text(
                    label,
                    style: AppTextStyles.body.copyWith(
                      fontSize: AppDimensions.floatingLabelFontSize,
                      height: 16 / AppDimensions.floatingLabelFontSize,
                      color: AppColors.textAccent,
                      letterSpacing: 0.1,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (supportText != null) ...[
            const SizedBox(height: AppDimensions.inputErrorSpacing),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.inputHorizontalPadding,
              ),
              child: Text(
                supportText!,
                style: AppTextStyles.bodySecondary.copyWith(
                  fontSize: AppDimensions.supportTextFontSize,
                  height: 16 / AppDimensions.supportTextFontSize,
                  color: isError ? AppColors.error : AppColors.textAccent,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
