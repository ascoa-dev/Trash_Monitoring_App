import 'package:flutter/widgets.dart';

/// Utilities for responsive sizing based on the emulator baseline.
///
/// Baseline captured from emulator logs:
///   width = 448, height = 997, padding.top = 53, padding.bottom = 24
/// All absolute pixel values (from Figma/emulator) can be scaled using these helpers
/// so that the emulator look is preserved and other devices match proportionally.
class SizeUtils {
  // Baseline logical pixels from the emulator used during design validation
  static const double baselineWidth = 448.0;
  static const double baselineHeight = 997.0;
  static const double baselineTopInset = 53.0;
  static const double baselineBottomInset = 24.0;

  static Size _size(BuildContext context) => MediaQuery.of(context).size;
  static EdgeInsets _padding(BuildContext context) =>
      MediaQuery.of(context).padding;

  /// Full screen width in logical pixels.
  static double screenWidth(BuildContext context) => _size(context).width;

  /// Full screen height in logical pixels (including system padding).
  static double screenHeight(BuildContext context) => _size(context).height;

  /// Safe area padding (system insets).
  static EdgeInsets viewPadding(BuildContext context) => _padding(context);

  /// Content height excluding top/bottom safe area paddings.
  static double contentHeight(BuildContext context) {
    final size = _size(context);
    final pad = _padding(context);
    return size.height - pad.top - pad.bottom;
  }

  /// Scale factor for widths relative to baseline width (448).
  static double widthScale(BuildContext context) =>
      screenWidth(context) / baselineWidth;

  /// Scale factor for heights relative to the full baseline height (997).
  static double screenHeightScale(BuildContext context) =>
      screenHeight(context) / baselineHeight;

  /// Scale factor for heights relative to baseline content height (997 - 53 - 24 = 920).
  static double contentHeightScale(BuildContext context) {
    const double baselineContentHeight =
        baselineHeight - baselineTopInset - baselineBottomInset; // 920
    return contentHeight(context) / baselineContentHeight;
  }

  /// Scale an emulator-referenced vertical size (in px) to this device.
  /// By default uses content height so elements inside SafeArea align proportionally.
  static double h(
    BuildContext context,
    double emulatorPx, {
    bool useContentHeight = true,
  }) {
    final factor =
        useContentHeight
            ? contentHeightScale(context)
            : screenHeightScale(context);
    return emulatorPx * factor;
  }

  /// Scale an emulator-referenced horizontal size (in px) to this device.
  static double w(BuildContext context, double emulatorPx) {
    return emulatorPx * widthScale(context);
  }

  /// Scale a general size (e.g., radii) using the average of width/height scales.
  static double r(BuildContext context, double emulatorPx) {
    final avg = (widthScale(context) + screenHeightScale(context)) / 2.0;
    return emulatorPx * avg;
  }
}
