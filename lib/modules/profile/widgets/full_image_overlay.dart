import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A full-screen overlay that displays an image with a dismissible backdrop.
///
/// Tap anywhere outside the image to dismiss the overlay.
/// Used for viewing profile avatars in full resolution.
class FullImageOverlay extends StatelessWidget {
  final String imageUrl;
  final String? placeholderAsset;

  const FullImageOverlay({
    super.key,
    required this.imageUrl,
    this.placeholderAsset,
  });

  /// Shows the overlay as a modal dialog
  static Future<void> show(
    BuildContext context, {
    required String imageUrl,
    String? placeholderAsset,
  }) {
    return showDialog(
      context: context,
      barrierColor: AppColors.black87,
      barrierDismissible: true,
      builder:
          (context) => FullImageOverlay(
            imageUrl: imageUrl,
            placeholderAsset: placeholderAsset,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: AppColors.transparent,
        child: Stack(
          children: [
            // Dismissible background
            Positioned.fill(child: Container(color: AppColors.transparent)),
            // Centered image
            Center(
              child: GestureDetector(
                onTap: () {}, // Prevents tap from propagating to parent
                child: Hero(
                  tag: 'avatar_$imageUrl',
                  child: InteractiveViewer(
                    minScale: AppDimensions.fullImageOverlayMinScale,
                    maxScale: AppDimensions.fullImageOverlayMaxScale,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        SizeUtils.r(
                          context,
                          AppDimensions.avatarPreviewOverlayRadius,
                        ),
                      ),
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth:
                              MediaQuery.of(context).size.width *
                              AppDimensions.fullImageOverlayMaxViewportFactor,
                          maxHeight:
                              MediaQuery.of(context).size.height *
                              AppDimensions.fullImageOverlayMaxViewportFactor,
                        ),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
                          placeholder:
                              (context, url) => Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                          errorWidget: (context, url, error) {
                            if (placeholderAsset != null) {
                              return Image.asset(
                                placeholderAsset!,
                                fit: BoxFit.contain,
                              );
                            }
                            return Icon(
                              Icons.error_outline,
                              color: AppColors.primary,
                              size: SizeUtils.r(
                                context,
                                AppDimensions.fullImageOverlayErrorIconSize,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
