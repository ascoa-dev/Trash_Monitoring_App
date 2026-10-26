import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:we_monitor/app/controllers/haptic_controller.dart';
import 'package:we_monitor/modules/start_cleanup/controllers/media_upload_controller.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/controllers/connectivity_controller.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:we_monitor/shared/widgets/circular_upload_progress.dart';

/// Two-column grid of form photos, all visible at once, each showing its
/// upload state. Photos not uploaded yet (added offline, restored from a
/// draft, failed) upload as soon as the device is online.
class UploadPhotoGrid extends StatefulWidget {
  const UploadPhotoGrid({super.key, required this.media, required this.docId});

  final MediaUploadController media;
  final String docId;

  @override
  State<UploadPhotoGrid> createState() => _UploadPhotoGridState();
}

class _UploadPhotoGridState extends State<UploadPhotoGrid> {
  late final Worker _onlineWorker;

  @override
  void initState() {
    super.initState();
    final isOnline = Get.find<ConnectivityController>().isOnline;
    _onlineWorker = ever<bool>(isOnline, (online) {
      if (online) _uploadRemaining();
    });
    if (isOnline.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _uploadRemaining());
    }
  }

  @override
  void dispose() {
    _onlineWorker.dispose();
    super.dispose();
  }

  void _uploadRemaining() {
    if (mounted) widget.media.compressAndUploadAll(widget.docId);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.media,
      builder: (context, _) {
        final photos =
            widget.media.photos
                .where((p) => p.status != PhotoUploadStatus.cancelled)
                .toList();
        if (photos.isEmpty) return const SizedBox.shrink();
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: SizeUtils.w(
              context,
              AppDimensions.cleanupSpacing12,
            ),
            mainAxisSpacing: SizeUtils.h(
              context,
              AppDimensions.cleanupSpacing12,
            ),
            childAspectRatio: AppDimensions.photosGridChildAspectRatio,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) => _buildCard(photos[index]),
        );
      },
    );
  }

  Widget _buildCard(PhotoUpload photo) {
    final radius = BorderRadius.circular(
      SizeUtils.r(
        context,
        AppDimensions.borderRadius * AppDimensions.photosBorderRadiusMultiplier,
      ),
    );
    final isOnline = Get.find<ConnectivityController>().isOnline.value;

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: radius,
          child: Image.file(photo.file, fit: BoxFit.cover, cacheWidth: 300),
        ),
        if (photo.status != PhotoUploadStatus.completed)
          GestureDetector(
            onTap:
                photo.status == PhotoUploadStatus.error
                    ? () {
                      Get.find<HapticController>().light();
                      widget.media.compressAndUpload(photo.id, widget.docId);
                    }
                    : null,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                color: (photo.status == PhotoUploadStatus.error
                        ? AppColors.errorRed
                        : AppColors.black54)
                    .withAlpha(
                      (AppDimensions.photosOverlayOpacity * 255).round(),
                    ),
              ),
              child: _buildStatus(photo, isOnline),
            ),
          ),
        Positioned(
          top: SizeUtils.h(context, AppDimensions.photosActionButtonOffset),
          right: SizeUtils.w(context, AppDimensions.photosActionButtonOffset),
          child: _buildRemoveButton(photo),
        ),
      ],
    );
  }

  Widget _buildStatus(PhotoUpload photo, bool isOnline) {
    final labelStyle = AppTextStyles.bodySecondary(
      context,
    ).copyWith(color: AppColors.pureWhite, fontWeight: FontWeight.w600);

    final Widget indicator;
    final String label;
    if (photo.status == PhotoUploadStatus.error) {
      indicator = Icon(
        Icons.refresh,
        color: AppColors.pureWhite,
        size: SizeUtils.r(context, AppDimensions.circularLoaderSize),
      );
      label = 'shared.photoTapRetry'.tr;
    } else if (photo.status == PhotoUploadStatus.pending && !isOnline) {
      indicator = Icon(
        Icons.cloud_off,
        color: AppColors.pureWhite,
        size: SizeUtils.r(context, AppDimensions.circularLoaderSize),
      );
      label = 'shared.photoWaitingNetwork'.tr;
    } else {
      indicator = CircularUploadProgress(
        size: SizeUtils.r(context, AppDimensions.circularLoaderSize),
        progress: photo.progress,
        activeColor: AppColors.loaderActive,
        trackColor: AppColors.loaderTrack,
        strokeWidth: SizeUtils.r(
          context,
          AppDimensions.circularLoaderStrokeWidth,
        ),
        gap: SizeUtils.r(context, AppDimensions.circularLoaderGap),
      );
      label = '${(photo.progress * 100).round()}%';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            indicator,
            const SizedBox(height: 6),
            Text(label, style: labelStyle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoveButton(PhotoUpload photo) {
    final uploading =
        photo.status == PhotoUploadStatus.compressing ||
        photo.status == PhotoUploadStatus.uploading;
    return Container(
      width: SizeUtils.r(context, AppDimensions.photosActionButtonSize),
      height: SizeUtils.r(context, AppDimensions.photosActionButtonSize),
      decoration: BoxDecoration(
        color: AppColors.errorRed,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: AppDimensions.photosActionButtonShadowBlur,
            offset: Offset(0, AppDimensions.photosActionButtonShadowYOffset),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: SizeUtils.r(context, AppDimensions.photosActionButtonIconSize),
        icon: Icon(
          uploading ? Icons.close : Icons.delete_outline,
          color: AppColors.pureWhite,
        ),
        onPressed: () {
          Get.find<HapticController>().light();
          widget.media.removePhoto(photo.id);
        },
      ),
    );
  }
}
