import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_images.dart';

class FullscreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String? placeholderAsset;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrl,
    this.placeholderAsset,
  });

  /// Shows the fullscreen viewer
  static Future<void> show(
    BuildContext context, {
    required String imageUrl,
    String? placeholderAsset,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, _, secondaryAnimation) => FullscreenImageViewer(
          imageUrl: imageUrl,
          placeholderAsset: placeholderAsset,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // The photo view
          Positioned.fill(
            child: PhotoView(
              imageProvider: CachedNetworkImageProvider(imageUrl),
              loadingBuilder: (context, event) => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.buttonGreen),
                ),
              ),
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Image.asset(
                    placeholderAsset ?? AppImages.hotspotPlaceholder,
                    fit: BoxFit.contain,
                  ),
                );
              },
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 4.0,
              initialScale: PhotoViewComputedScale.contained,
              backgroundDecoration: const BoxDecoration(color: Colors.black),
            ),
          ),
          // Close button at top-right
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: ClipOval(
              child: Material(
                color: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
