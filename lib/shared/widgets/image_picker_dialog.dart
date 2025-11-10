import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/utils/size_utils.dart';

/// Dialog to choose camera or gallery for avatar image selection
///
/// Returns ImageSource (camera/gallery) or null if cancelled
class ImagePickerDialog extends StatelessWidget {
  const ImagePickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isFrench = Get.locale?.languageCode == 'fr';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          SizeUtils.r(context, AppDimensions.dialogRadius),
        ),
      ),
      backgroundColor: AppColors.pureWhite,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeUtils.w(
            context,
            AppDimensions.dialogHorizontalPadding,
          ),
          vertical: SizeUtils.h(context, AppDimensions.dialogTopPadding),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isFrench
                  ? AppStrings.avatarPickerTitleFrench
                  : AppStrings.avatarPickerTitle,
              style: AppTextStyles.heading2(context).copyWith(
                fontSize: SizeUtils.h(
                  context,
                  AppDimensions.profileNameFontSize,
                ),
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeUtils.h(context, AppDimensions.screenPadding)),
            // Camera button
            SizedBox(
              width: double.infinity,
              height: SizeUtils.h(context, AppDimensions.buttonHeight),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(ImageSource.camera),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      SizeUtils.r(context, AppDimensions.borderRadius),
                    ),
                  ),
                ),
                icon: Icon(
                  Icons.camera_alt,
                  color: AppColors.pureWhite,
                  size: SizeUtils.r(context, AppDimensions.smallIconSize),
                ),
                label: Text(
                  isFrench
                      ? AppStrings.avatarPickerCameraFrench
                      : AppStrings.avatarPickerCamera,
                  style: AppTextStyles.buttonPrimaryText(
                    context,
                  ).copyWith(color: AppColors.pureWhite),
                ),
              ),
            ),
            SizedBox(height: SizeUtils.h(context, AppDimensions.smallSpacing)),
            // Gallery button
            SizedBox(
              width: double.infinity,
              height: SizeUtils.h(context, AppDimensions.buttonHeight),
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.buttonGreen,
                    width: AppDimensions.inputBorderWidth,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      SizeUtils.r(context, AppDimensions.borderRadius),
                    ),
                  ),
                ),
                icon: Icon(
                  Icons.photo_library,
                  color: AppColors.buttonGreen,
                  size: SizeUtils.r(context, AppDimensions.smallIconSize),
                ),
                label: Text(
                  isFrench
                      ? AppStrings.avatarPickerGalleryFrench
                      : AppStrings.avatarPickerGallery,
                  style: AppTextStyles.buttonPrimaryText(
                    context,
                  ).copyWith(color: AppColors.textDark),
                ),
              ),
            ),
            SizedBox(height: SizeUtils.h(context, AppDimensions.smallSpacing)),
            // Cancel button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                isFrench
                    ? AppStrings.avatarPickerCancelFrench
                    : AppStrings.avatarPickerCancel,
                style: AppTextStyles.body(
                  context,
                ).copyWith(color: AppColors.textBlack70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
