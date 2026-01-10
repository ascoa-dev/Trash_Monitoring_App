import 'package:ascoa_app/app/controllers/haptic_controller.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_typography.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/utils/size_utils.dart';

final haptics = Get.find<HapticController>();

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
    haptics.selectionClick();
    final isFrench = Get.locale?.languageCode == 'fr';
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      favorite: const ['CM'],
      onSelect: (country) {
        haptics.light();
        onChanged(country);
      },
      countryListTheme: CountryListThemeData(
        bottomSheetHeight:
            MediaQuery.of(context).size.height *
            AppDimensions.bottomSheetHeightFactor,
        textStyle: AppTextStyles.body(context).copyWith(
          color: AppColors.textDark,
          fontSize: SizeUtils.h(context, AppDimensions.inputFontSize),
          letterSpacing: AppTypography.letterSpacingSmall,
        ),
        inputDecoration: InputDecoration(
          labelText:
              isFrench
                  ? AppStrings.countrySearchLabelFrench
                  : AppStrings.countrySearchLabel,
          labelStyle: AppTextStyles.bodySecondary(
            context,
          ).copyWith(color: AppColors.textAccent),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: SizeUtils.h(context, topSpacing)),
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
                  height: SizeUtils.h(context, AppDimensions.inputFieldHeight),
                  decoration: BoxDecoration(
                    color: enabled ? AppColors.background : AppColors.white70,
                    border: Border.all(
                      color: isError ? AppColors.error : AppColors.accentGreen,
                      width:
                          isError
                              ? SizeUtils.w(
                                context,
                                AppDimensions.inputBorderWidthError,
                              )
                              : SizeUtils.w(
                                context,
                                AppDimensions.inputBorderWidth,
                              ),
                    ),
                    borderRadius: BorderRadius.circular(
                      SizeUtils.r(context, AppDimensions.smallRadius),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeUtils.w(
                      context,
                      AppDimensions.inputHorizontalPadding,
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(
                        selectedCountry.flagEmoji,
                        style: TextStyle(
                          fontSize: SizeUtils.r(
                            context,
                            AppDimensions.flagEmojiSize,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: SizeUtils.w(
                          context,
                          AppDimensions.selectorSmallGap,
                        ),
                      ),
                      Text(
                        '+${selectedCountry.phoneCode}',
                        style: AppTextStyles.body(context).copyWith(
                          fontSize: SizeUtils.h(
                            context,
                            AppDimensions.inputFontSize,
                          ),
                          height:
                              SizeUtils.h(
                                context,
                                AppDimensions.inputLineHeight,
                              ) /
                              SizeUtils.h(context, AppDimensions.inputFontSize),
                          letterSpacing: AppTypography.letterSpacingSmall,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textAccent,
                        size: SizeUtils.r(
                          context,
                          AppDimensions.selectorIconSize,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left:
                    SizeUtils.w(context, AppDimensions.inputHorizontalPadding) -
                    SizeUtils.w(context, AppDimensions.chipHorizontalPadding),
                top: -SizeUtils.h(context, AppDimensions.floatingLabelOffset),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeUtils.w(
                      context,
                      AppDimensions.chipHorizontalPadding,
                    ),
                  ),
                  color: AppColors.background,
                  child: Text(
                    label,
                    style: AppTextStyles.body(context).copyWith(
                      fontSize: SizeUtils.h(
                        context,
                        AppDimensions.floatingLabelFontSize,
                      ),
                      height:
                          SizeUtils.h(context, 16) /
                          SizeUtils.h(
                            context,
                            AppDimensions.floatingLabelFontSize,
                          ),
                      color: AppColors.textAccent,
                      letterSpacing: AppTypography.letterSpacingSmall,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (supportText != null) ...[
            SizedBox(
              height: SizeUtils.h(context, AppDimensions.inputErrorSpacing),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SizeUtils.w(
                  context,
                  AppDimensions.inputHorizontalPadding,
                ),
              ),
              child: Text(
                supportText!,
                style: AppTextStyles.bodySecondary(context).copyWith(
                  fontSize: SizeUtils.h(
                    context,
                    AppDimensions.supportTextFontSize,
                  ),
                  height:
                      SizeUtils.h(context, 16) /
                      SizeUtils.h(context, AppDimensions.supportTextFontSize),
                  color: isError ? AppColors.error : AppColors.textAccent,
                  letterSpacing: AppTypography.letterSpacingSmall,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
