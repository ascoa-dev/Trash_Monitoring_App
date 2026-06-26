import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:we_monitor/app/controllers/pending_cleanups_controller.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/widgets/primary_button.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:we_monitor/shared/constants/app_typography.dart';

class PendingCleanupsScreen extends GetView<PendingCleanupsController> {
  const PendingCleanupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isFrench = Get.locale?.languageCode == 'fr';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          isFrench
              ? AppStrings.pendingCleanupsTitleFrench
              : AppStrings.pendingCleanupsTitle,
          style: AppTextStyles.heading2(
            context,
          ).copyWith(color: AppColors.black87),
        ),
        leading: BackButton(
          color: AppColors.black87,
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.pendingCleanups.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(
                SizeUtils.w(context, AppDimensions.pendingCleanupsEmptyPadding),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_done_outlined,
                    size: SizeUtils.w(
                      context,
                      AppDimensions.pendingCleanupsEmptyIconSize,
                    ),
                    color: AppColors.textHint.withValues(alpha: 0.5),
                  ),
                  SizedBox(
                    height: SizeUtils.h(
                      context,
                      AppDimensions.pendingCleanupsEmptyIconSpacing,
                    ),
                  ),
                  Text(
                    isFrench
                        ? AppStrings.pendingCleanupsNoneFrench
                        : AppStrings.pendingCleanupsNone,
                    style: AppTextStyles.heading2(context),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: SizeUtils.h(
                      context,
                      AppDimensions.pendingCleanupsEmptyTextSpacing,
                    ),
                  ),
                  Text(
                    isFrench
                        ? AppStrings.pendingCleanupsAllUploadedFrench
                        : AppStrings.pendingCleanupsAllUploaded,
                    style: AppTextStyles.body(context),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(
                  SizeUtils.w(
                    context,
                    AppDimensions.pendingCleanupsListPadding,
                  ),
                ),
                itemCount: controller.pendingCleanups.length,
                itemBuilder: (context, index) {
                  final cleanup = controller.pendingCleanups[index];
                  final isUploading =
                      controller.uploadingId.value == cleanup.localId;

                  return Card(
                    color: AppColors.background,
                    margin: EdgeInsets.only(
                      bottom: SizeUtils.h(
                        context,
                        AppDimensions.pendingCleanupsCardMargin,
                      ),
                    ),
                    elevation: (SizeUtils.h(
                      context,
                      AppDimensions.pendingCleanupsCardElevation,
                    )),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        SizeUtils.r(
                          context,
                          AppDimensions.pendingCleanupsCardBorderRadius,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(
                        SizeUtils.w(
                          context,
                          AppDimensions.pendingCleanupsCardPadding,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.group,
                                color: AppColors.black87,
                                size: SizeUtils.w(
                                  context,
                                  AppDimensions.pendingCleanupsIconSize,
                                ),
                              ),
                              SizedBox(
                                width: SizeUtils.w(
                                  context,
                                  AppDimensions.pendingCleanupsIconSpacing,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  cleanup.groupName,
                                  style: AppTextStyles.heading2(
                                    context,
                                  ).copyWith(
                                    fontSize: SizeUtils.h(
                                      context,
                                      AppTypography.heading2FontSize,
                                    ),
                                  ),
                                ),
                              ),
                              if (cleanup.isUploading)
                                SizedBox(
                                  width: SizeUtils.w(
                                    context,
                                    AppDimensions.pendingCleanupsProgressSize,
                                  ),
                                  height: SizeUtils.w(
                                    context,
                                    AppDimensions.pendingCleanupsProgressSize,
                                  ),
                                  child: CircularProgressIndicator(
                                    strokeWidth: (SizeUtils.w(
                                      context,
                                      AppDimensions
                                          .pendingCleanupsProgressStrokeWidth,
                                    )),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(
                            height: SizeUtils.h(
                              context,
                              AppDimensions.pendingCleanupsInfoSpacing,
                            ),
                          ),
                          _buildInfoRow(
                            context,
                            Icons.calendar_today,
                            cleanup.date,
                          ),
                          SizedBox(
                            height: SizeUtils.h(
                              context,
                              AppDimensions.pendingCleanupsInfoRowSpacing,
                            ),
                          ),
                          _buildInfoRow(
                            context,
                            Icons.location_on,
                            cleanup.location,
                          ),
                          SizedBox(
                            height: SizeUtils.h(
                              context,
                              AppDimensions.pendingCleanupsInfoRowSpacing,
                            ),
                          ),
                          _buildInfoRow(
                            context,
                            Icons.people,
                            '${cleanup.peopleCount} ${isFrench ? AppStrings.pendingCleanupsPeopleFrench : AppStrings.pendingCleanupsPeople}',
                          ),
                          SizedBox(
                            height: SizeUtils.h(
                              context,
                              AppDimensions.pendingCleanupsInfoRowSpacing,
                            ),
                          ),
                          _buildInfoRow(
                            context,
                            Icons.delete_outline,
                            '${cleanup.trashItems.values.fold(0, (sum, count) => sum + count)} ${isFrench ? AppStrings.pendingCleanupsItemsFrench : AppStrings.pendingCleanupsItems}',
                          ),
                          if (cleanup.localPhotoPaths != null &&
                              cleanup.localPhotoPaths!.isNotEmpty) ...[
                            SizedBox(
                              height: SizeUtils.h(
                                context,
                                AppDimensions.pendingCleanupsInfoRowSpacing,
                              ),
                            ),
                            _buildInfoRow(
                              context,
                              Icons.photo_library,
                              '${cleanup.localPhotoPaths!.length} ${isFrench ? AppStrings.pendingCleanupsPhotos : AppStrings.pendingCleanupsPhotos}',
                            ),
                          ],
                          SizedBox(
                            height: SizeUtils.h(
                              context,
                              AppDimensions.pendingCleanupsInfoRowSpacing,
                            ),
                          ),
                          Text(
                            isFrench
                                ? '${AppStrings.pendingCleanupsSavedFrench}: ${cleanup.savedAt.day}/${cleanup.savedAt.month}/${cleanup.savedAt.year} ${cleanup.savedAt.hour}:${cleanup.savedAt.minute.toString().padLeft(2, '0')}'
                                : '${AppStrings.pendingCleanupsSaved}: ${cleanup.savedAt.day}/${cleanup.savedAt.month}/${cleanup.savedAt.year} ${cleanup.savedAt.hour}:${cleanup.savedAt.minute.toString().padLeft(2, '0')}',
                            style: AppTextStyles.bodySecondary(
                              context,
                            ).copyWith(
                              color: AppColors.black87,
                              fontSize: SizeUtils.h(
                                context,
                                AppDimensions.pendingCleanupsFontSize,
                              ),
                            ),
                          ),
                          if (cleanup.uploadError != null) ...[
                            SizedBox(
                              height: SizeUtils.h(
                                context,
                                AppDimensions.pendingCleanupsInfoRowSpacing,
                              ),
                            ),
                            Text(
                              '${isFrench ? AppStrings.errorTitleFrench : AppStrings.errorTitle}: ${cleanup.uploadError}',
                              style: AppTextStyles.bodySecondary(
                                context,
                              ).copyWith(
                                color: AppColors.errorRed,
                                fontSize: SizeUtils.h(
                                  context,
                                  AppDimensions.pendingCleanupsFontSize,
                                ),
                              ),
                            ),
                          ],
                          SizedBox(
                            height: SizeUtils.h(
                              context,
                              AppDimensions.pendingCleanupsInfoSpacing,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed:
                                      isUploading
                                          ? null
                                          : () => _showDeleteConfirmation(
                                            context,
                                            cleanup,
                                            isFrench,
                                          ),
                                  icon: const Icon(Icons.delete_outline),
                                  label: Text(
                                    isFrench
                                        ? AppStrings.pendingCleanupsDeleteFrench
                                        : AppStrings.pendingCleanupsDelete,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.errorRed,
                                    side: const BorderSide(
                                      color: AppColors.errorRed,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: SizeUtils.w(
                                  context,
                                  AppDimensions.pendingCleanupsButtonSpacing,
                                ),
                              ),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      isUploading
                                          ? null
                                          : () =>
                                              controller.uploadCleanup(cleanup),
                                  icon: const Icon(Icons.cloud_upload),
                                  label: Text(
                                    isFrench
                                        ? AppStrings.pendingCleanupsUploadFrench
                                        : AppStrings.pendingCleanupsUpload,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.buttonGreen,
                                    foregroundColor: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.all(
                SizeUtils.w(
                  context,
                  AppDimensions.pendingCleanupsFooterPadding,
                ),
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.05),
                    blurRadius: SizeUtils.r(
                      context,
                      AppDimensions.pendingCleanupsFooterShadowBlur,
                    ),
                    offset: Offset(
                      0,
                      SizeUtils.h(
                        context,
                        AppDimensions.pendingCleanupsFooterShadowOffsetY,
                      ),
                    ),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label:
                        isFrench
                            ? '${AppStrings.pendingCleanupsUploadAllFrench} (${controller.pendingCleanups.length})'
                            : '${AppStrings.pendingCleanupsUploadAll} (${controller.pendingCleanups.length})',
                    onPressed: () {
                      if (controller.uploadingId.value.isEmpty) {
                        _showUploadAllConfirmation(context, isFrench);
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: SizeUtils.w(context, AppDimensions.pendingCleanupsInfoIconSize),
          color: AppColors.black87,
        ),
        SizedBox(
          width: SizeUtils.w(context, AppDimensions.pendingCleanupsIconSpacing),
        ),
        Expanded(child: Text(text, style: AppTextStyles.body(context))),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, cleanup, bool isFrench) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              isFrench
                  ? AppStrings.pendingCleanupsDeleteTitleFrench
                  : AppStrings.pendingCleanupsDeleteTitle,
            ),
            content: Text(
              isFrench
                  ? AppStrings.pendingCleanupsDeleteMessageFrench
                  : AppStrings.pendingCleanupsDeleteMessage,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  isFrench
                      ? AppStrings.avatarPickerCancelFrench
                      : AppStrings.pendingCleanupsCancel,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  controller.deleteCleanup(cleanup);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.errorRed,
                ),
                child: Text(
                  isFrench
                      ? AppStrings.pendingCleanupsDeleteFrench
                      : AppStrings.pendingCleanupsDelete,
                ),
              ),
            ],
          ),
    );
  }

  void _showUploadAllConfirmation(BuildContext context, bool isFrench) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              isFrench
                  ? AppStrings.pendingCleanupsUploadAllFrench
                  : AppStrings.pendingCleanupsUploadAllTitle,
            ),
            content: Text(
              isFrench
                  ? AppStrings.pendingCleanupsUploadAllMessageFrench
                  : AppStrings.pendingCleanupsUploadAllMessage,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  isFrench
                      ? AppStrings.avatarPickerCancelFrench
                      : AppStrings.pendingCleanupsCancel,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  controller.uploadAll();
                },
                child: Text(
                  isFrench
                      ? AppStrings.pendingCleanupsUploadFrench
                      : AppStrings.pendingCleanupsUpload,
                ),
              ),
            ],
          ),
    );
  }
}
