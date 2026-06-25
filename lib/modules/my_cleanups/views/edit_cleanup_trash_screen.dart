import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ascoa_app/app/models/cleanup_model.dart';
import 'package:ascoa_app/modules/start_cleanup/controllers/cleanup_form_controller.dart';
import 'package:ascoa_app/modules/start_cleanup/views/trash_collected.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/services/snackbar_service.dart';
import 'package:ascoa_app/shared/utils/size_utils.dart';

class EditCleanupTrashScreen extends StatefulWidget {
  const EditCleanupTrashScreen({super.key});

  @override
  State<EditCleanupTrashScreen> createState() => _EditCleanupTrashScreenState();
}

class _EditCleanupTrashScreenState extends State<EditCleanupTrashScreen> {
  late final CleanupModel cleanup;
  late final CleanupFormController controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    cleanup = Get.arguments as CleanupModel;
    controller = Get.find<CleanupFormController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadTrashCollectedForEdit(cleanup);
      controller.setExpandedSection(AppStrings.trashCollected);
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final success = await controller.updateCleanupTrashCollected(cleanup.id!);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      SnackbarService.success('Saved', 'Trash collected was updated');
      Get.back();
    } else {
      SnackbarService.error('Error', 'Failed to update trash collected');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'Edit Trash Collected',
          style: AppTextStyles.heading2(context),
        ),
        leading: BackButton(
          color: AppColors.black87,
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            SizeUtils.w(context, AppDimensions.screenPadding),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${cleanup.groupName} • ${cleanup.date}',
                style: AppTextStyles.bodySecondary(context),
              ),
              SizedBox(
                height: SizeUtils.h(context, AppDimensions.cleanupSpacing16),
              ),
              TrashCollectedSection(
                controller: controller,
                isEditMode: true,
              ),
              SizedBox(
                height: SizeUtils.h(context, AppDimensions.cleanupSpacing16),
              ),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonGreen,
                  disabledBackgroundColor: AppColors.grey400,
                ),
                child: Text(
                  _isSaving ? 'SAVING...' : 'SAVE CHANGES',
                  style: AppTextStyles.saveCleanUpText(
                    context,
                  ).copyWith(color: AppColors.pureWhite),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
