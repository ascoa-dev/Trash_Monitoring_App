import 'package:we_monitor/shared/i18n/tr_params.dart';
import 'package:we_monitor/modules/start_cleanup/controllers/cleanup_section_ids.dart';
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
import 'package:we_monitor/shared/drafts/form_draft.dart';
import 'package:we_monitor/shared/services/draft_service.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:we_monitor/shared/widgets/upload_photo_grid.dart';
import 'package:we_monitor/shared/widgets/image_picker_dialog.dart';

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
                'shared.maxPhotos'.trp({'max': MediaUploadConfig.maxPhotos}),
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

      // Show source selector dialog (Camera or Gallery)
      final ImageSource? source = await Get.dialog<ImageSource?>(
        const ImagePickerDialog(),
      );
      if (source == null) return;

      List<XFile> pickedFiles = [];
      if (source == ImageSource.camera) {
        final XFile? file = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 2048,
          maxHeight: 2048,
          imageQuality: 90,
        );
        if (file != null) {
          pickedFiles = [file];
        }
      } else {
        pickedFiles = await _picker.pickMultiImage(
          maxWidth: 2048,
          maxHeight: 2048,
          imageQuality: 90,
          limit: remainingSlots,
        );
      }

      if (pickedFiles.isEmpty) return;
      Get.find<HapticController>().selectionClick();

      // Take only the number of photos we can add (fallback for platforms that don't respect limit)
      final filesToAdd = pickedFiles.take(remainingSlots).toList();

      // Copy to durable storage (picker cache can be purged) and add to controller
      final docId = widget.formController.cleanupDocId;
      final files = <File>[
        for (final xFile in filesToAdd)
          await DraftService.copyPhoto(
            FormDraft.kindCleanup,
            docId,
            xFile.path,
          ),
      ];
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
              'shared.photosAddedLimit'.trp({'n': filesToAdd.length, 'max': MediaUploadConfig.maxPhotos});
          backgroundColor = AppColors.warning;
        } else if (!isOnline) {
          Get.find<HapticController>().light();
          message =
              'shared.photosAddedOffline'.trp({'n': files.length});
          backgroundColor = AppColors.info;
        } else {
          message =
              'shared.photosUploading'.trp({'n': files.length});
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
          SnackBar(
            content: Text('cleanup.photosFailedPick'.tr),
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
                  UploadPhotoGrid(
                    media: controller,
                    docId: widget.formController.cleanupDocId,
                  ),
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
                'cleanup.photosOptionalNote'.tr,
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
    widget.formController.markSectionCompleted(CleanupSectionIds.photosVideosOptional);

    // Collapse this section (no more sections to navigate to)
    widget.formController.setExpandedSection(null);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('cleanup.allSectionsDone'.tr),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
