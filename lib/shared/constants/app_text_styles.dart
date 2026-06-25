import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'package:ascoa_app/shared/utils/size_utils.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';

class AppTextStyles {
  // Font Families
  static const String inter = 'Inter';
  static const String roboto = 'Roboto';
  static const String rubik = 'Rubik';

  // Heading Styles
  static TextStyle heading1(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w800,
    fontSize: SizeUtils.h(context, AppTypography.heading1FontSize),
    color: AppColors.textDark, // Primary heading color (dark slate)
  );

  static TextStyle heading2(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w600,
    fontSize: SizeUtils.h(context, AppTypography.heading2FontSize),
    color: AppColors.textDark, // Primary heading color (dark slate)
    letterSpacing: AppTypography.letterSpacingSmall,
  );

  static TextStyle profileHeading(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w700,
    fontSize: SizeUtils.h(context, AppTypography.profileHeadingFontSize),
    color: AppColors.textDark,
    letterSpacing: AppTypography.letterSpacingSmall,
  );

  static TextStyle profileName(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w700,
    fontSize: SizeUtils.h(context, AppTypography.profileNameFontSize),
    color: AppColors.textDark,
    letterSpacing: AppTypography.letterSpacingSmall,
  );

  static TextStyle profileCaption(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w800,
    fontSize: SizeUtils.h(context, AppTypography.profileCaptionFontSize),
    color: AppColors.textDark,
    letterSpacing: AppTypography.letterSpacingSmall,
  );

  static TextStyle profileActionTitle(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w400,
    fontSize: SizeUtils.h(context, AppTypography.profileActionTitleFontSize),
    color: AppColors.textDark,
    letterSpacing: AppTypography.letterSpacingSmall,
  );

  static TextStyle profileActionSubtitle(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w400,
    fontSize: SizeUtils.h(context, AppTypography.profileActionSubtitleFontSize),
    color: AppColors.textDark65,
    letterSpacing: AppTypography.letterSpacingSmall,
  );

  static TextStyle profileSignOutText(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w400,
    fontSize: SizeUtils.h(context, AppTypography.profileSignOutFontSize),
    color: AppColors.textWhite,
    letterSpacing: AppTypography.letterSpacingSmall,
  );

  // Label Styles
  static TextStyle label(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontSize: SizeUtils.h(context, AppTypography.labelFontSize),
    color: AppColors.textAccent, // Label / input label color
  );

  // Body Styles
  static TextStyle body(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w400,
    fontSize: SizeUtils.h(
      context,
      AppTypography.bodyFontSize,
    ), // Updated to match Figma
    color: AppColors.textDark, // Primary body text color
  );

  static TextStyle bodySecondary(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w400,
    fontSize: SizeUtils.h(context, AppTypography.bodyFontSize),
    color: AppColors.textDark, // Secondary body text color
    letterSpacing: AppTypography.letterSpacingSmall,
  );

  // Button Styles
  static TextStyle buttonLink(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w800, // Updated to match Figma
    fontSize: SizeUtils.h(context, AppTypography.buttonLinkFontSize),
    color: AppColors.textDark,
    decoration: TextDecoration.underline,
    decorationThickness: 1.0,
    decorationColor: AppColors.textDark,
    letterSpacing: AppTypography.letterSpacingButton,
  );

  // Divider Text
  static TextStyle dividerText(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w500,
    fontSize: SizeUtils.h(context, AppTypography.dividerTextFontSize),
    color: AppColors.textDark, // Divider text color (e.g., "OR")
  );

  // Terms Text Styles
  static TextStyle termsBase(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w400,
    fontSize: SizeUtils.h(context, AppTypography.termsBaseFontSize),
    color: AppColors.textDark, // Terms and legal text color
    height: AppTypography.lineHeightLong, // 160% line height
  );

  static const TextStyle termsLink = TextStyle(
    fontWeight: FontWeight.w800,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.textDark,
  );

  // Error Text
  static TextStyle errorText(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w400,
    fontSize: SizeUtils.h(context, AppTypography.errorTextFontSize),
    color: AppColors.error, // Error color for inline validation messages
  );

  static TextStyle trashErrorText(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w400,
    fontSize: SizeUtils.h(context, AppTypography.trashErrorTextFontSize),
    color: AppColors.errorRed, // Error color for inline validation messages
  );

  // Primary Button Text
  static TextStyle buttonPrimaryText(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w900,
    fontSize: SizeUtils.h(context, AppTypography.buttonPrimaryFontSize),
    color: AppColors.pureWhite,
    letterSpacing: AppTypography.letterSpacingButtonPrimary,
  );

  // Social Button Text
  static TextStyle buttonSocialText(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w700,
    fontSize: SizeUtils.h(context, AppTypography.buttonSocialFontSize),
    color: AppColors.buttonText,
  );

  // Input hint text style
  static TextStyle inputHint(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontSize: SizeUtils.h(context, AppTypography.inputHintFontSize),
    color: AppColors.textHint,
  );

  static TextStyle cleanUpSubtitle(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w300,
    fontStyle: FontStyle.italic,
    fontSize: SizeUtils.h(context, AppTypography.cleanUpSubtitleFontSize),
    color: AppColors.textAccent,
    letterSpacing: AppTypography.letterSpacingSmall,
  );

  static TextStyle dashboardHeading(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w500,
    fontSize: SizeUtils.h(context, AppTypography.dashboardHeadingFontSize),
    color: AppColors.textDark, // Primary heading color (dark slate)
    letterSpacing: AppTypography.letterSpacingSmall,
  );

  static TextStyle dashboardGreeting(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w500,
    fontSize: SizeUtils.h(context, 22),
    color: AppColors.background, // Primary heading color (dark slate)
    letterSpacing: AppTypography.homeTextLetterSpacing,
  );

  static TextStyle newsCaption(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w800,
    decoration: TextDecoration.underline,
    fontSize: SizeUtils.h(context, AppTypography.newsCaptionFontSize),
    color: AppColors.textDark,
    letterSpacing: AppTypography.letterSpacingSmall,
  );

  static TextStyle newsBody(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w400,
    fontSize: SizeUtils.h(context, AppTypography.newsBodyFontSize),
    color: AppColors.textDark65,
    letterSpacing: AppTypography.letterSpacingSmall,
  );

  static TextStyle blogText(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w600,
    fontSize: SizeUtils.h(context, AppTypography.blogTextFontSize),
    color: AppColors.textDark,
    letterSpacing: AppTypography.letterSpacingSmall,
  );

  static TextStyle cleanUpSectionTitle(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w700,
    fontSize: SizeUtils.h(context, AppTypography.cleanUpSectionTitleFontSize),
    color: AppColors.textDark,
    letterSpacing: AppTypography.letterSpacingSmall,
  );

  static TextStyle cleanUpSectionSubtitle(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w600,
    fontSize: SizeUtils.h(
      context,
      AppTypography.cleanUpSectionSubtitleFontSize,
    ),
    color: AppColors.textDark,
    letterSpacing: AppTypography.letterSpacingSmall,
  );

  // Date Picker specific styles
  static TextStyle datePickerMenuItem(BuildContext context) => TextStyle(
    fontFamily: roboto,
    fontWeight: FontWeight.w500,
    fontSize: SizeUtils.h(context, AppTypography.datePickerMenuItemFontSize),
    color: AppColors.datePickerPrimary,
    letterSpacing: AppTypography.letterSpacingSmall,
  );

  static TextStyle datePickerDay(BuildContext context) => TextStyle(
    fontFamily: roboto,
    fontWeight: FontWeight.w400,
    fontSize: SizeUtils.h(context, AppTypography.datePickerDayFontSize),
    color: AppColors.datePickerPrimary,
    letterSpacing: 0.5,
  );

  static TextStyle datePickerButton(BuildContext context) => TextStyle(
    fontFamily: roboto,
    fontWeight: FontWeight.w500,
    fontSize: SizeUtils.h(context, AppTypography.datePickerButtonFontSize),
    color: AppColors.buttonGreen,
  );

  static TextStyle cleanUpOptionsCollapsed(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w500,
    fontSize: SizeUtils.h(context, 16),
    color: AppColors.textDark,
    letterSpacing: AppTypography.letterSpacingSmall,
  );

  static TextStyle cleanUpOptionsExpanded(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w400,
    fontSize: SizeUtils.h(context, 16),
    color: AppColors.background,
    letterSpacing: AppTypography.letterSpacingSmall,
  );

  static TextStyle saveCleanUpText(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w800,
    fontSize: SizeUtils.h(context, 16),
    color: AppColors.pureWhite,
    letterSpacing: AppTypography.letterSpacingButtonPrimary,
  );

  static TextStyle cancelCleanUpText(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w800,
    fontSize: SizeUtils.h(context, 16),
    color: AppColors.textDark65,
    letterSpacing: AppTypography.letterSpacingButtonPrimary,
  );

  static TextStyle trashCollectionLabel(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w400,
    fontSize: SizeUtils.h(context, 16),
    color: AppColors.textDark,
  );

  static TextStyle trashCollectionEnvironment(BuildContext context) =>
      TextStyle(
        fontFamily: rubik,
        fontWeight: FontWeight.w400,
        fontSize: SizeUtils.h(context, 14),
        color: AppColors.textAccent,
      );

  static TextStyle trashCollectionSubtitle(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w400,
    fontSize: SizeUtils.h(context, 13),
    color: AppColors.textAccent,
  );

  static TextStyle trashCollectionDropdownCategory(BuildContext context) =>
      TextStyle(
        fontFamily: rubik,
        fontWeight: FontWeight.w400,
        fontSize: SizeUtils.h(context, 14),
        color: AppColors.textDark,
      );

  // Stats Screen Text Styles
  static TextStyle statsTitle(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontSize: SizeUtils.h(context, AppDimensions.statsHeaderText),
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static TextStyle statsChartTitle(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontSize: SizeUtils.h(context, AppDimensions.statsChartTitleFontSize),
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static TextStyle statsActivityValue(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontSize: SizeUtils.h(context, AppDimensions.statsActivityValueFontSize),
    fontWeight: FontWeight.bold,
    color: AppColors.textAccent,
  );

  static TextStyle statsActivityLabel(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontSize: SizeUtils.h(context, AppDimensions.statsActivityLabelFontSize),
    fontWeight: FontWeight.w500,
    fontStyle: FontStyle.italic,
    color: AppColors.textAccent,
  );

  static TextStyle statsActivityUnitLabel(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontSize: SizeUtils.h(
      context,
      AppDimensions.statsActivityUnitLabelFontSize,
    ),
    fontWeight: FontWeight.w900,
    color: AppColors.textAccent,
  );

  static TextStyle statsActivityLabelSmall(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontSize: SizeUtils.h(
      context,
      AppDimensions.statsActivityLabelSmallFontSize,
    ),
    fontWeight: FontWeight.w600,
    color: AppColors.textAccent,
  );

  static TextStyle statsActivityUnit(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontSize: SizeUtils.h(context, AppDimensions.statsActivityUnitFontSize),
    fontWeight: FontWeight.w600,
    color: AppColors.textAccent,
  );

  static TextStyle statsActivityTooltip(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontSize: SizeUtils.h(context, AppDimensions.statsActivityUnitFontSize),
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
  static TextStyle statsChartLegend(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontSize: SizeUtils.h(context, AppDimensions.statsChartLegendFontSize),
    color: AppColors.textDark,
  );

  static TextStyle statsChartLabel(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontSize: SizeUtils.h(context, AppDimensions.statsChartLabelFontSize),
    color: AppColors.textDark,
  );

  static TextStyle statsFilterDate(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontSize: SizeUtils.h(context, AppDimensions.statsFilterDateFontSize),
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static TextStyle statsFilterLabel(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontSize: SizeUtils.h(context, AppDimensions.statsFilterLabelFontSize),
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static TextStyle statsError(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontSize: SizeUtils.h(context, AppDimensions.statsErrorFontSize),
    color: AppColors.errorRed,
  );

  static TextStyle statsMapInfo(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontSize: SizeUtils.h(context, AppDimensions.statsMapInfoFontSize),
    color: AppColors.textDark,
  );

  static TextStyle statsChartBars(BuildContext context) => TextStyle(
    fontFamily: rubik,
    color: AppColors.black,
    fontSize: SizeUtils.h(context, AppDimensions.statsChartBarsFontSize),
    fontWeight: FontWeight.w400,
    shadows: [
      Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 2),
    ],
  );

  static TextStyle navBarBadge(BuildContext context) => TextStyle(
    fontFamily: rubik,
    color: AppColors.black,
    fontSize: SizeUtils.h(context, AppDimensions.navBarPendingBadgeFontSize),
    fontWeight: FontWeight.bold,
    shadows: [
      Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 2),
    ],
  );

  static TextStyle snackBarTitle(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w700,
    fontSize: SizeUtils.h(context, AppTypography.snackBarTitleFontSize),
    height: 1.25,
    letterSpacing: -0.2, // Tighter tracking
  );

  static TextStyle snacBarBody(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w500,
    fontSize: SizeUtils.h(context, AppTypography.snackBarBodyFontSize),
    height: 1.5,
  );

  // Prevent instantiation
  AppTextStyles._();
}
