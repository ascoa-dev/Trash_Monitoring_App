import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Font Families
  static const String inter = 'Inter';
  static const String roboto = 'Roboto';

  // Heading Styles
  static const TextStyle heading1 = TextStyle(
    fontFamily: inter,
    fontWeight: FontWeight.w700,
    fontSize: 28,
    color: AppColors.textPrimary, // Black text for white background
  );

  // Label Styles
  static const TextStyle label = TextStyle(
    fontFamily: roboto,
    fontSize: 16,
    color: AppColors.textSecondary, // Dark gray for labels
  );

  // Body Styles
  static const TextStyle body = TextStyle(
    fontFamily: inter,
    fontWeight: FontWeight.w400,
    fontSize: 14, // Updated to match Figma
    color: AppColors.textBlack, // White text for "Forgot password?"
  );

  static const TextStyle bodySecondary = TextStyle(
    fontFamily: inter,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: AppColors.textBlack70, // White text with 70% opacity
  );

  // Button Styles
  static const TextStyle buttonLink = TextStyle(
    fontFamily: inter,
    fontWeight: FontWeight.w400, // Updated to match Figma
    fontSize: 14,
    color: AppColors.textBlack,
    decoration: TextDecoration.underline,
    decorationThickness: 1.0,
    decorationColor: AppColors.textBlack,
  );

  // Divider Text
  static const TextStyle dividerText = TextStyle(
    fontFamily: inter,
    fontWeight: FontWeight.w500,
    fontSize: 16,
    color: AppColors.textSecondary, // Dark text for white background
  );

  // Terms Text Styles
  static const TextStyle termsBase = TextStyle(
    fontFamily: roboto,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: AppColors.textSecondary, // Dark gray for terms text
    height: 1.6, // 160% line height
  );

  static const TextStyle termsLink = TextStyle(
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.textSecondary,
  );

  // Error Text
  static const TextStyle errorText = TextStyle(
    fontFamily: roboto,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    color: AppColors.error, // Red color for error messages
  );

  // Primary Button Text
  static const TextStyle buttonPrimaryText = TextStyle(
    fontFamily: inter,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: AppColors.white,
  );

  // Social Button Text
  static const TextStyle buttonSocialText = TextStyle(
    fontFamily: roboto,
    fontWeight: FontWeight.w700,
    fontSize: 16,
    color: AppColors.buttonText,
  );

  // Input hint text style
  static const TextStyle inputHint = TextStyle(
    fontFamily: roboto,
    fontSize: 16,
    color: AppColors.textHint,
  );

  // Prevent instantiation
  AppTextStyles._();
}
