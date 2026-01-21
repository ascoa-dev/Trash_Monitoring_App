import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';

/// Enum representing different types of snackbar messages
enum SnackbarType { success, error, warning, info }

/// Model class representing a snackbar message
class SnackbarMessage {
  final String title;
  final String message;
  final SnackbarType type;
  final Duration duration;

  const SnackbarMessage({
    required this.title,
    required this.message,
    this.type = SnackbarType.info,
    this.duration = const Duration(seconds: 2),
  });

  /// Factory for error messages
  factory SnackbarMessage.error(String title, String message) {
    return SnackbarMessage(
      title: title,
      message: message,
      type: SnackbarType.error,
    );
  }

  /// Factory for success messages
  factory SnackbarMessage.success(String title, String message) {
    return SnackbarMessage(
      title: title,
      message: message,
      type: SnackbarType.success,
    );
  }

  /// Factory for warning messages
  factory SnackbarMessage.warning(String title, String message) {
    return SnackbarMessage(
      title: title,
      message: message,
      type: SnackbarType.warning,
    );
  }

  /// Factory for info messages
  factory SnackbarMessage.info(String title, String message) {
    return SnackbarMessage(
      title: title,
      message: message,
      type: SnackbarType.info,
    );
  }
}

/// Service class to display beautiful, consistent snackbars throughout the app.
///
/// Uses OverlayEntry for floating top snackbars with no layout shift.
/// Initialize with [init] passing the app's navigator key.
class SnackbarService {
  SnackbarService._();

  static GlobalKey<NavigatorState>? _navigatorKey;
  static OverlayEntry? _currentEntry;
  static GlobalKey<_TopSnackbarState>? _currentSnackbarKey;

  /// Initialize the service with a navigator key
  static void init(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Get colors based on snackbar type
  static _SnackbarColors _getColors(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return const _SnackbarColors(
          background: AppColors.snackBarSuccessBackground,
          border: AppColors.snackBarSuccessBorder,
          accent: AppColors.snackBarSuccessAccent,
          titleColor: AppColors.snackBarSuccessTitleColor,
          messageColor: AppColors.snackBarSuccessMessageColor,
        );
      case SnackbarType.error:
        return const _SnackbarColors(
          background: AppColors.snackBarErrorBackground,
          border: AppColors.snackBarErrorBorder,
          accent: AppColors.snackBarErrorAccent,
          titleColor: AppColors.snackBarErrorTitleColor,
          messageColor: AppColors.snackBarErrorMessageColor,
        );
      case SnackbarType.warning:
        return const _SnackbarColors(
          background: AppColors.snackBarWarningBackground,
          border: AppColors.snackBarWarningBorder,
          accent: AppColors.snackBarWarningAccent,
          titleColor: AppColors.snackBarWarningTitleColor,
          messageColor: AppColors.snackBarWarningMessageColor,
        );
      case SnackbarType.info:
        return const _SnackbarColors(
          background: AppColors.snackBarInfoBackground,
          border: AppColors.snackBarInfoBorder,
          accent: AppColors.snackBarInfoAccent,
          titleColor: AppColors.snackBarInfoTitleColor,
          messageColor: AppColors.snackBarInfoMessageColor,
        );
    }
  }

  /// Show a beautiful snackbar with the app's design language
  static void show(SnackbarMessage message) {
    // Get context from navigator key
    final context = _navigatorKey?.currentContext;
    if (context == null) {
      debugPrint('SnackbarService: Navigator context not available yet');
      return;
    }

    // Animate out and remove any existing snackbar
    if (_currentEntry != null && _currentSnackbarKey != null) {
      final previousEntry = _currentEntry;
      _currentSnackbarKey?.currentState?.dismiss().then((_) {
        try {
          previousEntry?.remove();
        } catch (e) {
          debugPrint('SnackbarService: Error removing previous entry: $e');
        }
      });
    }

    try {
      // Get the overlay from navigator context
      final overlay = Navigator.of(context).overlay;
      if (overlay == null) {
        debugPrint('SnackbarService: Overlay not available');
        return;
      }

      // Create a new key for this snackbar
      final snackbarKey = GlobalKey<_TopSnackbarState>();
      _currentSnackbarKey = snackbarKey;

      // Create the overlay entry with animation
      final entry = OverlayEntry(
        builder: (context) => _TopSnackbar(key: snackbarKey, message: message),
      );

      overlay.insert(entry);
      _currentEntry = entry;

      // Auto-dismiss after duration with animation
      Future.delayed(message.duration, () async {
        try {
          await snackbarKey.currentState?.dismiss();
          entry.remove();
          if (_currentEntry == entry) {
            _currentEntry = null;
            _currentSnackbarKey = null;
          }
        } catch (e) {
          debugPrint('SnackbarService: Error removing entry: $e');
        }
      });
    } catch (e) {
      debugPrint('SnackbarService: Error showing snackbar: $e');
    }
  }

  /// Show a snackbar with explicit title and message (convenience method)
  static void showMessage({
    required String title,
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    show(
      SnackbarMessage(
        title: title,
        message: message,
        type: type,
        duration: duration,
      ),
    );
  }

  /// Show a success snackbar
  static void success(String title, String message) {
    show(SnackbarMessage.success(title, message));
  }

  /// Show an error snackbar
  static void error(String title, String message) {
    show(SnackbarMessage.error(title, message));
  }

  /// Show a warning snackbar
  static void warning(String title, String message) {
    show(SnackbarMessage.warning(title, message));
  }

  /// Show an info snackbar
  static void info(String title, String message) {
    show(SnackbarMessage.info(title, message));
  }
}

/// Internal class to hold snackbar colors
class _SnackbarColors {
  final Color background;
  final Color accent;
  final Color titleColor;
  final Color messageColor;
  final Color border;

  const _SnackbarColors({
    required this.background,
    required this.accent,
    required this.titleColor,
    required this.messageColor,
    this.border = Colors.transparent,
  });
}

/// Animated top snackbar widget
class _TopSnackbar extends StatefulWidget {
  final SnackbarMessage message;

  const _TopSnackbar({super.key, required this.message});

  @override
  State<_TopSnackbar> createState() => _TopSnackbarState();
}

class _TopSnackbarState extends State<_TopSnackbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  /// Animate out and call onDismissed when complete
  Future<void> dismiss() async {
    await _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final colors = SnackbarService._getColors(widget.message.type);

    return Positioned(
      top: media.padding.top + AppDimensions.snackBarPositionTop,
      left: AppDimensions.snackBarPositionHorizontal,
      right: AppDimensions.snackBarPositionHorizontal,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(
              AppDimensions.snackBarPadding,
            ), // Reduced padding
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(
                AppDimensions.snackBarBorderRadius,
              ), // Radius 12px
              border: Border.all(
                color: colors.border, // Specific border color
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  offset: const Offset(0, 4),
                  blurRadius: AppDimensions.snackBarBoxShadowBlur,
                  spreadRadius: -1,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(0, 2),
                  blurRadius: AppDimensions.snackBarBoxShadowBlur,
                  spreadRadius: -1,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Accent Bar (Fixed height/width now)
                Container(
                  width: AppDimensions.snackBarContainerWidth,
                  height: AppDimensions.snackBarContainerHeight,
                  margin: const EdgeInsets.only(
                    top: AppDimensions.snackBarEdgeInsetTop,
                  ), // Visual alignment
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.snackBarContainerBorderRadius,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.snackBarSpacing),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.message.title,
                        style: AppTextStyles.snackBarTitle(
                          context,
                        ).copyWith(color: colors.titleColor),
                      ),
                      const SizedBox(height: AppDimensions.snackBarTextSpacing),
                      Text(
                        widget.message.message,
                        style: AppTextStyles.snacBarBody(
                          context,
                        ).copyWith(color: colors.messageColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
