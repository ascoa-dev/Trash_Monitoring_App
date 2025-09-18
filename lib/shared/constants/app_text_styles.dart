import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Font Families
  static const String inter = 'Inter';
  static const String roboto = 'Roboto';
  static const String rubik = 'Rubik';

  // Heading Styles
  static const TextStyle heading1 = TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w800,
    fontSize: 57,
    color: AppColors.textDark, // Primary heading color (dark slate)
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w600,
    fontSize: 32,
    color: AppColors.textDark, // Primary heading color (dark slate)
    letterSpacing: 0.1,
  );

  // Label Styles
  static const TextStyle label = TextStyle(
    fontFamily: rubik,
    fontSize: 16,
    color: AppColors.textAccent, // Label / input label color
  );

  // Body Styles
  static const TextStyle body = TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w400,
    fontSize: 14, // Updated to match Figma
    color: AppColors.textDark, // Primary body text color
  );

  static const TextStyle bodySecondary = TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: AppColors.textDark, // Secondary body text color
    letterSpacing: 0.1,
  );

  // Button Styles
  static const TextStyle buttonLink = TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w800, // Updated to match Figma
    fontSize: 14,
    color: AppColors.textDark,
    decoration: TextDecoration.underline,
    decorationThickness: 1.0,
    decorationColor: AppColors.textDark,
    letterSpacing: 0.4,
  );

  // Divider Text
  static const TextStyle dividerText = TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w500,
    fontSize: 16,
    color: AppColors.textAccent, // Divider text color (e.g., "OR")
  );

  // Terms Text Styles
  static const TextStyle termsBase = TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: AppColors.textDark, // Terms and legal text color
    height: 1.6, // 160% line height
  );

  static const TextStyle termsLink = TextStyle(
    fontWeight: FontWeight.w800,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.textDark,
  );

  // Error Text
  static const TextStyle errorText = TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    color: AppColors.error, // Error color for inline validation messages
  );

  // Primary Button Text
  static const TextStyle buttonPrimaryText = TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w900,
    fontSize: 16,
    color: AppColors.pureWhite,
    letterSpacing: 0.2,
  );

  // Social Button Text
  static const TextStyle buttonSocialText = TextStyle(
    fontFamily: rubik,
    fontWeight: FontWeight.w700,
    fontSize: 16,
    color: AppColors.buttonText,
  );

  // Input hint text style
  static const TextStyle inputHint = TextStyle(
    fontFamily: rubik,
    fontSize: 16,
    color: AppColors.textHint,
  );

  // Prevent instantiation
  AppTextStyles._();
}
