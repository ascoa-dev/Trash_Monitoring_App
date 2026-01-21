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
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color grey = Color(
    0xFF9F9F9F,
  ); // pure white (use for icons/text on colored backgrounds)
  static const Color white70 = Colors.white70; // Flutter-provided 70% white

  // Profile-specific colors
  static const Color profileAvatarBackground = Color(0xFFFCF1AA);
  static const Color profileAvatarAccent = Color(0xFFFBB825);

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
  static const Color textDark65 = Color(0xA618333D); // ~65% alpha dark text
  // Button opacity variants (kept as explicit hex values chosen by design)
  static const Color buttonGreen70 = Color(
    0xB3228B22,
  ); // 70% alpha variant (design choice)
  static const Color buttonGreen40 = Color(
    0x66228B22,
  ); // 40% alpha variant (design choice)

  // Legacy / alternate text names
  static const Color textPrimary = textDark; // legacy alias
  static const Color textBlack = textDark;
  static const Color black = Color(0xFF000000); // legacy alias
  static const Color textBlack70 = Color(
    0xB3000000,
  ); // legacy muted black (design-provided hex)
  static const Color black87 = Color(0xDD000000); // legacy alias
  static const Color black54 = Color(0x8A000000); // 54% black for muted text
  static const Color blackWithOpacity15 = Color(
    0x26000000,
  ); // 15% black for subtle shadows

  // Divider Colors
  static const Color divider = Color(
    0xFF357187,
  ); // Light gray divider (subtle line color)

  // Social Login Colors
  static const Color google = Color(0xFF4285F4); // Google brand blue
  static const Color facebook = Color(0xFF4267B2); // Facebook brand blue
  static const Color buttonText = Color(
    0xFF3A383F,
  ); // Default button text color

  // Misc / one-off accents
  static const Color emailVerification = Color(
    0xFF448AFF,
  ); // matches Colors.blueAccent

  // Skeleton / placeholder greys used for loading states
  static const Color skeletonBase = Color(0xFFB4D17B);
  static const Color skeletonHighlight = Color(0xFF789E71);
  static const Color skeletonShade = Color(0xFFD0D0D0);

  // Card background alias (used by dashboard/home cards)
  static const Color cardBackground = loaderTrack;

  // Utility colors used in multiple widgets
  static const Color transparent = Color(0x00000000); // fully transparent
  // Shadow color matching Flutter's Colors.black26
  static const Color shadow = Color(0x42000000);
  static const Color shadowLight = Color(0x26000000);
  static const Color shadowMedium = Color(0x4D000000);

  // Error Colors
  static const Color error = Color(0xFFFBB825); // Error / validation red
  static const Color pendingUploads = Color(0xFFF1BB4A); // light red bg
  // Snackbar / Feedback Colors
  static const Color success = Color(
    0xFF4CAF50,
  ); // Success green (Material green)
  static const Color errorRed = Color(0xFFF44336); // Error red (Material red)
  static const Color info = Color(0xFF2196F3); // Info blue (Material blue)
  static const Color warning = Color(
    0xFFFF9800,
  ); // Warning orange (Material orange)

  // Date picker colors
  static const Color datePickerPrimary = Color(
    0xFF18333D,
  ); // Dark teal text/icon color
  static const Color datePickerPrimaryDisabled30 = Color(
    0x4D18333D,
  ); // 30% opacity disabled state
  static const Color datePickerPrimaryDisabled38 = Color(
    0x6118333D,
  ); // 38% opacity disabled state
  static const Color datePickerSelected = Color(
    0xFF419310,
  ); // Green selection color

  // Additional opacity variants for common uses
  static const Color blackWithOpacity10 = Color(
    0x1A000000,
  ); // 10% black for subtle shadows
  static const Color blackWithOpacity20 = Color(0x33000000); // 20% black
  static const Color textHintWithOpacity20 = Color(
    0x337E8389,
  ); // textHint with 20% opacity for borders

  // Dialog background used by AppDialog (kept as design-provided hex)
  static const Color dialogBackground = Color(0xFFC7E0B0);

  static const Color navBarSelectedBackground = Color(0xFFC7E0B0);
  static const Color profileCardBackground = navBarSelectedBackground;

  // Circular loader colors
  static const Color loaderTrack = Color(0xFFB4D17B); // light green track
  static const Color loaderActive = Color(0xFF658638); // dark green active arc
  static const Color newsCardPlaceholder = Color(0xFFEFEFEF);

  // Additional greys matching Flutter's material grey shades used across widgets
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);

  // Cleanup / small component helpers
  static const Color cleanupCounterBg = Color(0xFFDCE9CB);
  static const Color cleanupCounterIcon = Color(0xFF5E7D3A);

  // Stats Screen Colors
  static const Color statsChartFreshwater = Color(
    0xFF51D2BB,
  ); // Light teal for freshwater environment
  static const Color statsChartSaltwater = Color(
    0xFF116985,
  ); // Dark teal for saltwater environment
  static const Color statsChartLand = Color(
    0xFFC7F296,
  ); // Light green for land/inland environment
  static const Color statsFilterTeal = Color(
    0xFF357187,
  ); // Filter slider and checkbox teal
  static const Color statsFilterGreen = Color(
    0xFFC7E0B0,
  ); // Filter slider green accent
  static const Color statsActivityCardBg = Color(
    0xFFB4D17B,
  ); // Activity card background green
  static const Color datePickerDotDark = Color(0xFF4A4459);

  // Disabled button state colors (from design spec)
  static const Color buttonDisabledBackground = Color(0xFFF5F5F5);
  static const Color buttonDisabledText = Color(0xFF9E9E9E);

  //Snack bar Colors
  //Success
  static const Color snackBarSuccessBackground = Color(0xFFECFDF5);
  static const Color snackBarSuccessBorder = Color(0xFFD1FAE5);
  static const Color snackBarSuccessAccent = Color(0xFF10B981);
  static const Color snackBarSuccessTitleColor = Color(0xFF065F46);
  static const Color snackBarSuccessMessageColor = Color(0xFF047857);

  //error
  static const Color snackBarErrorBackground = Color(0xFFFFF1F2);
  static const Color snackBarErrorBorder = Color(0xFFFFE4E6);
  static const Color snackBarErrorAccent = Color(0xFFF43F5E);
  static const Color snackBarErrorTitleColor = Color(0xFF9F1239);
  static const Color snackBarErrorMessageColor = Color(0xFFBE123C);

  //warning
  static const Color snackBarWarningBackground = Color(0xFFFFFBEB);
  static const Color snackBarWarningBorder = Color(0xFFFEF3C7);
  static const Color snackBarWarningAccent = Color(0xFFF59E0B);
  static const Color snackBarWarningTitleColor = Color(0xFF92400E);
  static const Color snackBarWarningMessageColor = Color(0xFFB45309);

  //info
  static const Color snackBarInfoBackground = Color(0xFFF0F9FF);
  static const Color snackBarInfoBorder = Color(0xFFE0F2FE);
  static const Color snackBarInfoAccent = Color(0xFF0EA5E9);
  static const Color snackBarInfoTitleColor = Color(0xFF075985);
  static const Color snackBarInfoMessageColor = Color(0xFF0369A1);
  // Prevent instantiation
  AppColors._();
}
