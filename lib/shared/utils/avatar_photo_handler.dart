import 'dart:io';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/services/avatar_uploader.dart';
import 'package:ascoa_app/shared/utils/image_utils.dart';
import 'package:ascoa_app/shared/utils/size_utils.dart';
import 'package:ascoa_app/shared/widgets/avatar_crop_screen.dart';
import 'package:ascoa_app/shared/widgets/image_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

/// Centralized handler for avatar photo editing functionality.
///
/// This class provides a reusable method for handling the complete avatar
/// photo editing flow including:
/// - Image source selection (camera/gallery)
/// - Image picking
/// - Image cropping
/// - Image compression and thumbnail creation
/// - Upload to Firebase with progress tracking
///
/// Used by both EditProfileScreen and CompleteProfileScreen to avoid
/// code duplication.
class AvatarPhotoHandler {
  final ImagePicker _imagePicker = ImagePicker();
  final AvatarUploader _avatarUploader = AvatarUploader();

  /// Handles the complete avatar photo editing flow.
  ///
  /// Parameters:
  /// - [context]: BuildContext for size calculations (optional, uses Get.context if null)
  /// - [onSuccess]: Callback invoked with the new avatar URL upon successful upload
  ///
  /// Returns: The uploaded avatar URL, or null if cancelled or failed
  ///
  /// Example:
  /// ```dart
  /// final handler = AvatarPhotoHandler();
  /// final newUrl = await handler.handleEditPhoto(
  ///   onSuccess: (url) {
  ///     setState(() {
  ///       _avatarUrl = url;
  ///     });
  ///   },
  /// );
  /// ```
  Future<String?> handleEditPhoto({
    BuildContext? context,
    void Function(String url)? onSuccess,
  }) async {
    final isFrench = Get.locale?.languageCode == 'fr';

    // Capture context-dependent values at the START before any await
    final ctx = context ?? Get.context;
    if (ctx == null) return null; // No context available

    final dialogRadius = SizeUtils.r(ctx, AppDimensions.dialogRadius);
    final dialogPadding = SizeUtils.h(
      ctx,
      AppDimensions.dialogHorizontalPadding,
    );
    final headingStyle = AppTextStyles.heading2(
      ctx,
    ).copyWith(fontSize: SizeUtils.h(ctx, 18));
    final bodyStyle = AppTextStyles.body(ctx);
    final progressHeight = SizeUtils.h(ctx, AppDimensions.screenPadding);
    final progressBottomSpacing = SizeUtils.h(ctx, AppDimensions.smallSpacing);

    try {
      // Show image source picker dialog via Get (avoids BuildContext across async gaps)
      final ImageSource? source = await Get.dialog<ImageSource?>(
        const ImagePickerDialog(),
      );

      if (source == null) return null; // User cancelled

      // Pick image from selected source
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (pickedFile == null) return null; // User cancelled

      final File imageFile = File(pickedFile.path);

      // Navigate to crop screen via Get
      final File? croppedFile = await Get.to<File?>(
        () => AvatarCropScreen(
          imageFile: imageFile,
          outputSize: AppDimensions.avatarCropOutputSize.toInt(),
        ),
      );

      if (croppedFile == null) return null; // User cancelled crop

      // Show progress dialog (using pre-captured values, no context across async gaps)
      final RxDouble uploadProgress = 0.0.obs;
      // Use PopScope to prevent dismissing during upload (Flutter 3.12+)
      Get.dialog(
        PopScope(
          canPop: false, // Prevent dismissing during upload
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(dialogRadius),
            ),
            backgroundColor: AppColors.pureWhite,
            child: Padding(
              padding: EdgeInsets.all(dialogPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isFrench
                        ? AppStrings.avatarUploadProgressFrench
                        : AppStrings.avatarUploadProgress,
                    style: headingStyle,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: progressHeight),
                  Obx(
                    () => LinearProgressIndicator(
                      value: uploadProgress.value,
                      backgroundColor: AppColors.profileAvatarBackground,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.buttonGreen,
                      ),
                    ),
                  ),
                  SizedBox(height: progressBottomSpacing),
                  Obx(
                    () => Text(
                      '${(uploadProgress.value * 100).toStringAsFixed(0)}%',
                      style: bodyStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Compress main avatar
      final File? compressedAvatar = await ImageUtils.compressToWebP(
        croppedFile,
        targetSizePx: AppDimensions.avatarCropOutputSize.toInt(),
        quality: 75,
      );

      if (compressedAvatar == null) {
        Get.back(); // Close progress dialog
        Get.snackbar(
          isFrench ? 'Erreur' : 'Error',
          isFrench
              ? AppStrings.avatarCompressionErrorFrench
              : AppStrings.avatarCompressionError,
          backgroundColor: AppColors.error,
          colorText: AppColors.pureWhite,
          snackPosition: SnackPosition.TOP,
        );
        return null;
      }

      // Create thumbnail
      final File? thumbnail = await ImageUtils.createThumbnail(
        croppedFile,
        sizePx: AppDimensions.avatarCropThumbSize.toInt(),
        quality: 70,
      );

      if (thumbnail == null) {
        Get.back(); // Close progress dialog
        Get.snackbar(
          isFrench ? 'Erreur' : 'Error',
          isFrench
              ? AppStrings.avatarCompressionErrorFrench
              : AppStrings.avatarCompressionError,
          backgroundColor: AppColors.error,
          colorText: AppColors.pureWhite,
          snackPosition: SnackPosition.TOP,
        );
        return null;
      }

      // Upload to Firebase
      final String newAvatarUrl = await _avatarUploader.uploadAvatar(
        avatarFile: compressedAvatar,
        thumbnailFile: thumbnail,
        onProgress: (progress) {
          uploadProgress.value = progress;
        },
      );

      // Clean up temp files
      await ImageUtils.cleanupTempFiles([
        imageFile,
        croppedFile,
        compressedAvatar,
        thumbnail,
      ]);

      // Close progress dialog
      Get.back();

      // Call success callback if provided
      onSuccess?.call(newAvatarUrl);

      // Show success message
      Get.snackbar(
        isFrench ? 'Succès' : 'Success',
        isFrench
            ? AppStrings.avatarUploadSuccessFrench
            : AppStrings.avatarUploadSuccess,
        backgroundColor: AppColors.buttonGreen,
        colorText: AppColors.pureWhite,
        snackPosition: SnackPosition.TOP,
      );

      return newAvatarUrl;
    } catch (e) {
      // Close progress dialog if open
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      final isFrench = Get.locale?.languageCode == 'fr';
      Get.snackbar(
        isFrench ? 'Erreur' : 'Error',
        isFrench
            ? AppStrings.avatarUploadErrorFrench
            : AppStrings.avatarUploadError,
        backgroundColor: AppColors.error,
        colorText: AppColors.pureWhite,
        snackPosition: SnackPosition.TOP,
      );

      return null;
    }
  }
}
