import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFFFFFFFF); // White background
  static const Color accent = Color(0xFFA4C639); // Green accent color
  static const Color buttonPrimary = Color(0xFF228B22); // Green button color
  static const Color white = Colors.white;
  static const Color white70 = Colors.white70;

  // Text Colors
  static const Color textPrimary = Color(0xFF000000); // Black text for titles
  static const Color textSecondary = Color(0xFF333333); // Dark gray for labels
  static const Color textHint = Color(0xFF9F9F9F); // Light gray for hints
  static const Color textWhite = Color(0xFFFFFFFF); // White text
  static const Color textWhite70 = Color(
    0xB3FFFFFF,
  ); // White text with 70% opacity
  static const Color textBlack = Color(0xFF000000); // Black text (fully opaque)
  static const Color textBlack70 = Color(
    0xB3000000,
  ); // Black text with 70% opacity

  // Divider Colors
  static const Color divider = Color(
    0xFFE0E0E0,
  ); // Light gray divider for white background

  // Social Login Colors
  static const Color google = Color(0xFF4285F4);
  static const Color facebook = Color(0xFF4267B2);
  static const Color buttonText = Color(0xFF3A383F);

  // Error Colors
  static const Color error = Color(0xFFFF0000); // Red color for error messages

  // Prevent instantiation
  AppColors._();
}
