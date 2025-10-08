import 'package:flutter/material.dart';

class AppColors {
  // Canonical / Descriptive Colors
  // Keep these as the canonical names for each unique hex value. Do NOT
  // change the hex values here unless you intend to change the visual
  // palette app-wide.
  static const Color background = Color(
    0xFFFBFFF4,
  ); // off-white page background
  static const Color accentGreen = Color(
    0xFF658638,
  ); // accent / highlight green
  static const Color buttonGreen = Color(0xFF419310); // button primary green
  static const Color pureWhite = Color(
    0xFFFFFFFF,
  ); // pure white (use for icons/text on colored backgrounds)
  static const Color white70 = Colors.white70; // Flutter-provided 70% white

  // Legacy / backward-compatible aliases
  // Existing code may reference older names; keep these as aliases so
  // changes are non-breaking. New code should use the canonical names above.
  static const Color primary = background;
  static const Color accent = accentGreen;
  static const Color buttonPrimary = buttonGreen;
  static const Color white =
      background; // historical: matched background off-white

  // Text Colors (canonical)
  static const Color textDark = Color(
    0xFF18333D,
  ); // dark slate for primary text
  static const Color textAccent = Color(
    0xFF357187,
  ); // secondary/teal accent for labels
  static const Color textHint = Color(0xFF9F9F9F); // hint / placeholder
  static const Color textWhite = pureWhite; // white for text/icons
  static const Color textWhite70 = Color(0xB3FFFFFF); // white @ ~70% alpha
  // Button opacity variants (kept as explicit hex values chosen by design)
  static const Color buttonGreen70 = Color(
    0xB3228B22,
  ); // 70% alpha variant (design choice)
  static const Color buttonGreen40 = Color(
    0x66228B22,
  ); // 40% alpha variant (design choice)

  // Legacy / alternate text names
  static const Color textPrimary = textDark; // legacy alias
  static const Color textBlack = textDark; // legacy alias
  static const Color textBlack70 = Color(
    0xB3000000,
  ); // legacy muted black (design-provided hex)

  // Divider Colors
  static const Color divider = Color(
    0xFFE0E0E0,
  ); // Light gray divider (subtle line color)

  // Social Login Colors
  static const Color google = Color(0xFF4285F4); // Google brand blue
  static const Color facebook = Color(0xFF4267B2); // Facebook brand blue
  static const Color buttonText = Color(
    0xFF3A383F,
  ); // Default button text color

  // Error Colors
  static const Color error = Color(0xFFFBB825); // Error / validation red

  // Prevent instantiation
  AppColors._();
}
