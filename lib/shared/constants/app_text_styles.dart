import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import '../utils/size_utils.dart';

class AppTextStyles {
  // Font Families
  static const String inter = 'Inter';
  static const String roboto = 'Roboto';
  static const String rubik = 'Rubik';

  // Heading Styles
  static TextStyle heading1(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w800,
    fontSize: SizeUtils.h(context, 57),
    color: AppColors.textDark, // Primary heading color (dark slate)
  );

  static TextStyle heading2(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w600,
    fontSize: SizeUtils.h(context, 32),
    color: AppColors.textDark, // Primary heading color (dark slate)
    letterSpacing: AppTypography.letterSpacingSmall,
  );

  static TextStyle profileHeading(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w700,
    fontSize: SizeUtils.h(context, 28),
    color: AppColors.textDark,
    letterSpacing: AppTypography.letterSpacingSmall,
  );

  static TextStyle profileName(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w700,
    fontSize: SizeUtils.h(context, 22),
    color: AppColors.textDark,
    letterSpacing: AppTypography.letterSpacingSmall,
  );

  static TextStyle profileCaption(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w800,
    fontSize: SizeUtils.h(context, 13),
    color: AppColors.textDark,
    letterSpacing: AppTypography.letterSpacingSmall,
  );

  static TextStyle profileActionTitle(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w400,
    fontSize: SizeUtils.h(context, 16),
    color: AppColors.textDark,
    letterSpacing: AppTypography.letterSpacingSmall,
  );

  static TextStyle profileActionSubtitle(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w400,
    fontSize: SizeUtils.h(context, 12),
    color: AppColors.textDark65,
    letterSpacing: AppTypography.letterSpacingSmall,
  );

  static TextStyle profileSignOutText(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w500,
    fontSize: SizeUtils.h(context, 16),
    color: AppColors.textWhite,
    letterSpacing: AppTypography.letterSpacingSmall,
  );

  // Label Styles
  static TextStyle label(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontSize: SizeUtils.h(context, 16),
    color: AppColors.textAccent, // Label / input label color
  );

  // Body Styles
  static TextStyle body(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w400,
    fontSize: SizeUtils.h(context, 14), // Updated to match Figma
    color: AppColors.textDark, // Primary body text color
  );

  static TextStyle bodySecondary(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w400,
    fontSize: SizeUtils.h(context, 14),
    color: AppColors.textDark, // Secondary body text color
    letterSpacing: AppTypography.letterSpacingSmall,
  );

  // Button Styles
  static TextStyle buttonLink(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w800, // Updated to match Figma
    fontSize: SizeUtils.h(context, 14),
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
    fontSize: SizeUtils.h(context, 16),
    color: AppColors.textDark, // Divider text color (e.g., "OR")
  );

  // Terms Text Styles
  static TextStyle termsBase(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w400,
    fontSize: SizeUtils.h(context, 14),
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
    fontSize: SizeUtils.h(context, 12),
    color: AppColors.error, // Error color for inline validation messages
  );

  // Primary Button Text
  static TextStyle buttonPrimaryText(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w900,
    fontSize: SizeUtils.h(context, 16),
    color: AppColors.pureWhite,
    letterSpacing: AppTypography.letterSpacingButtonPrimary,
  );

  // Social Button Text
  static TextStyle buttonSocialText(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w700,
    fontSize: SizeUtils.h(context, 16),
    color: AppColors.buttonText,
  );

  // Input hint text style
  static TextStyle inputHint(BuildContext context) => TextStyle(
    fontFamily: rubik,
    fontSize: SizeUtils.h(context, 16),
    color: AppColors.textHint,
  );

  // Prevent instantiation
  AppTextStyles._();
}
