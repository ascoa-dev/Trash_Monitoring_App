import 'dart:io';
import 'package:we_monitor/app/controllers/haptic_controller.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:we_monitor/modules/start_cleanup/controllers/media_upload_controller.dart';
import 'package:we_monitor/modules/start_cleanup/controllers/cleanup_form_controller.dart';
import 'package:we_monitor/shared/controllers/connectivity_controller.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:we_monitor/shared/widgets/circular_upload_progress.dart';

class PhotosSection extends StatefulWidget {
  final CleanupFormController formController;

  const PhotosSection({super.key, required this.formController});

  @override
  State<PhotosSection> createState() => _PhotosSectionState();
}

class _PhotosSectionState extends State<PhotosSection> {
  final ImagePicker _picker = ImagePicker();

  MediaUploadController get controller =>
      widget.formController.mediaUploadController;

  Future<void> _pickImages() async {
    try {
      // Check if we can add more photos
      if (!controller.canAddMore) {
        Get.find<HapticController>().light();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Maximum ${MediaUploadConfig.maxPhotos} photos allowed',
              ),
              backgroundColor: AppColors.errorRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Calculate how many more photos can be added
      final remainingSlots =
          MediaUploadConfig.maxPhotos - controller.photoCount;

      // Pick multiple images with limit (note: limit may not work on all platforms)
      final pickedFiles = await _picker.pickMultiImage(
        imageQuality: 100, // We'll compress later
        limit: remainingSlots,
      );

      if (pickedFiles.isEmpty) return;
      Get.find<HapticController>().selectionClick();

      // Take only the number of photos we can add (fallback for platforms that don't respect limit)
      final filesToAdd = pickedFiles.take(remainingSlots).toList();

      // Convert to File objects and add to controller
      final files = filesToAdd.map((xFile) => File(xFile.path)).toList();
      await controller.addPhotos(files);

      // Check connectivity before attempting upload
      final connectivityController = Get.find<ConnectivityController>();
      final isOnline = connectivityController.isOnline.value;

      if (isOnline) {
        Get.find<HapticController>().selectionClick();
        // Get the cleanup doc ID and start uploading immediately
        final cleanupDocId = widget.formController.cleanupDocId;

        // Upload all pending photos
        for (final file in files) {
          final photo = controller.photos.firstWhere(
            (p) => p.file.path == file.path,
          );
          controller.compressAndUpload(photo.id, cleanupDocId);
        }
      }

      // Show feedback
      if (mounted) {
        String message;
        Color backgroundColor;

        if (filesToAdd.length < pickedFiles.length) {
          message =
              'Only ${filesToAdd.length} photo${filesToAdd.length > 1 ? 's' : ''} added (limit: ${MediaUploadConfig.maxPhotos})';
          backgroundColor = AppColors.warning;
        } else if (!isOnline) {
          Get.find<HapticController>().light();
          message =
              '${files.length} photo${files.length > 1 ? 's' : ''} added. Will upload when online.';
          backgroundColor = AppColors.info;
        } else {
          message =
              '${files.length} photo${files.length > 1 ? 's' : ''} uploading...';
          backgroundColor = AppColors.info;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      Get.find<HapticController>().light();
      debugPrint('[PhotosSection] Error picking images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to pick images. Please try again.'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        SizeUtils.w(context, AppDimensions.cleanupContentPadding),
      ),
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Upload button
          SizedBox(
            width: double.infinity,
            height: SizeUtils.h(context, AppDimensions.buttonHeight),
            child: ElevatedButton(
              onPressed:
                  controller.canAddMore
                      ? () {
                        Get.find<HapticController>().medium();
                        _pickImages();
                      }
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonGreen,
                disabledBackgroundColor: AppColors.grey400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    SizeUtils.r(context, AppDimensions.borderRadius),
                  ),
                ),
              ),
              child: Text(
                AppStrings.uploadImagesButton,
                style: AppTextStyles.buttonPrimaryText(
                  context,
                ).copyWith(color: AppColors.pureWhite),
              ),
            ),
          ),

          SizedBox(
            height: SizeUtils.h(context, AppDimensions.cleanupSpacing16),
          ),

          // Preview label
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              if (!controller.hasPhotos) {
                return const SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.previewLabel,
                    style: AppTextStyles.body(context),
                  ),
                  SizedBox(
                    height: SizeUtils.h(
                      context,
                      AppDimensions.cleanupSpacing12,
                    ),
                  ),
                  _buildPhotoGrid(),
                ],
              );
            },
          ),

          // Done/Complete Button - Photos are optional so always enable
          SizedBox(
            height: SizeUtils.h(context, AppDimensions.cleanupSpacing24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Photos are optional. You can continue without uploading photos.',
                textAlign: TextAlign.start,
                style: AppTextStyles.trashCollectionSubtitle(context),
              ),
              SizedBox(
                height: SizeUtils.h(context, AppDimensions.cleanupSpacing4),
              ),
              SizedBox(
                width: double.infinity,
                height: SizeUtils.h(context, AppDimensions.buttonHeight),
                child: ElevatedButton(
                  onPressed: () {
                    Get.find<HapticController>().medium();
                    _handleComplete();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        SizeUtils.r(context, AppDimensions.borderRadius),
                      ),
                    ),
                  ),
                  child: Text(
                    AppStrings.continueButton,
                    style: AppTextStyles.saveCleanUpText(
                      context,
                    ).copyWith(color: AppColors.pureWhite),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: SizeUtils.h(context, AppDimensions.cleanupSpacing12),
          ),
        ],
      ),
    );
  }

  void _handleComplete() {
    // Photos are optional - no validation needed
    // Mark section as completed
    widget.formController.markSectionCompleted(AppStrings.photosVideosOptional);

    // Collapse this section (no more sections to navigate to)
    widget.formController.setExpandedSection(null);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All sections completed! You can now save your cleanup.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final photos = controller.photos;

        if (photos.isEmpty) {
          return const SizedBox.shrink();
        }

        // Determine grid layout based on photo count
        final crossAxisCount = _getGridCrossAxisCount(photos.length);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
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
          itemBuilder: (context, index) {
            final photo = photos[index];
            return _buildPhotoCard(photo);
          },
        );
      },
    );
  }

  int _getGridCrossAxisCount(int photoCount) {
    // 1 photo: 1 column
    // 2 photos: 2 columns
    // 3 photos: 3 columns
    // 4 photos: 2 columns (2x2)
    // 5 photos: 2 columns for first 4, then 1 for last
    if (photoCount <= 3) return photoCount;
    return 2;
  }

  Widget _buildPhotoCard(PhotoUpload photo) {
    return Stack(
      children: [
        // Photo preview
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              SizeUtils.r(
                context,
                AppDimensions.borderRadius *
                    AppDimensions.photosBorderRadiusMultiplier,
              ),
            ),
            color: AppColors.grey300,
            image: DecorationImage(
              image: FileImage(photo.file),
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Progress overlay (shown during compression/upload)
        if (photo.status == PhotoUploadStatus.compressing ||
            photo.status == PhotoUploadStatus.uploading)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                SizeUtils.r(
                  context,
                  AppDimensions.borderRadius *
                      AppDimensions.photosBorderRadiusMultiplier,
                ),
              ),
              color: AppColors.black54.withAlpha(
                (AppDimensions.photosOverlayOpacity * 255).round(),
              ),
            ),
            child: Center(
              child: CircularUploadProgress(
                size: SizeUtils.r(context, AppDimensions.circularLoaderSize),
                progress: photo.progress,
                activeColor: AppColors.loaderActive,
                trackColor: AppColors.loaderTrack,
                strokeWidth: SizeUtils.r(
                  context,
                  AppDimensions.circularLoaderStrokeWidth,
                ),
                gap: SizeUtils.r(context, AppDimensions.circularLoaderGap),
              ),
            ),
          ),

        // Error overlay
        if (photo.status == PhotoUploadStatus.error)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                SizeUtils.r(
                  context,
                  AppDimensions.borderRadius *
                      AppDimensions.photosBorderRadiusMultiplier,
                ),
              ),
              color: AppColors.errorRed.withAlpha(
                (AppDimensions.photosOverlayOpacity * 255).round(),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.error_outline,
                color: AppColors.pureWhite,
                size: SizeUtils.r(
                  context,
                  AppDimensions.socialIconSize *
                      AppDimensions.photosErrorIconSizeMultiplier,
                ),
              ),
            ),
          ),

        // Action button (cancel during upload, discard after upload)
        Positioned(
          top: SizeUtils.h(context, AppDimensions.photosActionButtonOffset),
          right: SizeUtils.w(context, AppDimensions.photosActionButtonOffset),
          child: _buildActionButton(photo),
        ),
      ],
    );
  }

  Widget _buildActionButton(PhotoUpload photo) {
    IconData icon;
    Color backgroundColor;
    VoidCallback? onPressed;

    if (photo.status == PhotoUploadStatus.compressing ||
        photo.status == PhotoUploadStatus.uploading) {
      // Cancel button during upload
      icon = Icons.close;
      backgroundColor = AppColors.errorRed;
      onPressed = () {
        Get.find<HapticController>().light();
        controller.removePhoto(photo.id);
      };
    } else if (photo.status == PhotoUploadStatus.completed ||
        photo.status == PhotoUploadStatus.pending ||
        photo.status == PhotoUploadStatus.error) {
      // Discard button after upload or if pending/error
      icon = Icons.delete_outline;
      backgroundColor = AppColors.errorRed;
      onPressed = () {
        Get.find<HapticController>().light();
        controller.removePhoto(photo.id);
      };
    } else {
      // Cancelled - no button
      return const SizedBox.shrink();
    }

    return Container(
      width: SizeUtils.r(context, AppDimensions.photosActionButtonSize),
      height: SizeUtils.r(context, AppDimensions.photosActionButtonSize),
      decoration: BoxDecoration(
        color: backgroundColor,
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
        iconSize: SizeUtils.r(
          context,
          AppDimensions.photosActionButtonIconSize,
        ),
        icon: Icon(icon, color: AppColors.pureWhite),
        onPressed: onPressed,
      ),
    );
  }
}
