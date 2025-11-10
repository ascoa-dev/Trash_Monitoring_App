import 'package:ascoa_app/modules/start_cleanup/views/basic_infomation_section.dart';
import 'package:ascoa_app/modules/start_cleanup/views/trash_collected.dart';
import 'package:ascoa_app/modules/start_cleanup/controllers/cleanup_form_controller.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_images.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/utils/size_utils.dart';
import 'package:ascoa_app/shared/widgets/primary_button.dart';
import 'package:ascoa_app/shared/widgets/app_dialog.dart';
import 'package:ascoa_app/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class NewCleanUpScreen extends StatelessWidget {
  const NewCleanUpScreen({super.key});

  Future<void> _handleSaveCleanup(BuildContext context) async {
    final controller = Get.find<CleanupFormController>();

    // Re-validate all sections
    final isBasicInfoValid = controller.validateSection('basicInfo');
    final isTrashValid = controller.validateSection('trashCollected');

    // Manage section states based on validation
    if (!isBasicInfoValid || !isTrashValid) {
      // Close valid sections, expand invalid ones
      if (!isBasicInfoValid) {
        controller.setExpandedSection('basicInfo');
      } else if (!isTrashValid) {
        controller.setExpandedSection('trashCollected');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.pleaseFixFormErrors),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Close all sections if validation passed
    controller.setExpandedSection(null);

    // Get current user
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.mustBeLoggedIn),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Show loading indicator
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: SizeUtils.w(context, AppDimensions.smallLoaderSize),
                height: SizeUtils.h(context, AppDimensions.smallLoaderSize),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.pureWhite,
                  ),
                ),
              ),
              SizedBox(
                width: SizeUtils.w(context, AppDimensions.snackBarGapSmall),
              ),
              Text(AppStrings.submittingCleanup),
            ],
          ),
          backgroundColor: AppColors.info,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 30),
        ),
      );
    }

    // Submit cleanup
    final cleanupId = await controller.submitCleanup(currentUser.uid);

    // Hide loading indicator
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    if (cleanupId != null) {
      // Success - show AppDialog and navigate home when user confirms
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            return AppDialog(
              title: AppStrings.cleanUpSavedDialogTitle,
              decoratedHero: false,
              imageAsset: AppImages.cleanConfirm,
              imageWidth: SizeUtils.w(ctx, AppDimensions.dialogImageWidth),
              imageHeight: SizeUtils.h(ctx, AppDimensions.dialogImageHeight),
              body: AppStrings.cleanUpSavedDialogSubtitle,
              primaryActionLabel: AppStrings.cleanUpSavedDialogButton,
              onPrimaryAction: () {
                Navigator.of(ctx).pop();
                // Navigate to home and clear stack
                Get.offAllNamed(AppRoutes.home);
              },
            );
          },
        );
      }
    } else {
      // Error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.cleanupSubmitFailed),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const ScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section (scrolls with page)
            _buildHeaderSection(context),

            // Expandable Sections (grows/shrinks dynamically)
            _buildExpandableSections(context),
            SizedBox(
              height: SizeUtils.h(
                context,
                AppDimensions.cleanupSectionGapLarge,
              ),
            ),
            // Footer Section (scrolls with page, always at bottom)
            _buildFooterSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Stack(
      children: [
        // Top Decorative Image - height: 287px from CSS
        Image.asset(
          AppImages.cleanupTop,
          fit: BoxFit.cover,
          width: double.infinity,
          height: SizeUtils.h(context, AppDimensions.cleanupTopImageHeight),
        ),

        // Content overlapping the image
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Back Button - positioned at top from design
            Padding(
              padding: EdgeInsets.only(
                left: SizeUtils.w(context, AppDimensions.cleanupHeaderBackLeft),
                top:
                    mediaQuery.padding.top +
                    SizeUtils.h(
                      context,
                      AppDimensions.cleanupHeaderBackTopInset,
                    ),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back,
                    color: AppColors.buttonPrimary,
                    size: SizeUtils.r(context, AppDimensions.iconBackSize),
                  ),
                ),
              ),
            ),

            SizedBox(
              height: SizeUtils.h(context, AppDimensions.cleanupSpacing20),
            ),

            // Title - positioned at top: 131px from CSS
            Text(
              AppStrings.newCleanUp,
              style: AppTextStyles.cleanUpSectionTitle(context),
              textAlign: TextAlign.center,
            ),

            SizedBox(
              height: SizeUtils.h(context, AppDimensions.cleanupSpacing4),
            ),

            // Clean Image - positioned at top: 167px from CSS
            Center(
              child: Image.asset(
                AppImages.cleanup,
                height: SizeUtils.h(
                  context,
                  AppDimensions.cleanupCleanImageHeight,
                ),
                fit: BoxFit.cover,
              ),
            ),

            SizedBox(
              height: SizeUtils.h(context, AppDimensions.cleanupSpacing12),
            ),

            // Subtitle - positioned at top: 271px from CSS
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SizeUtils.w(
                  context,
                  AppDimensions.cleanupSubtitleHorizontalPadding,
                ),
              ),
              child: Text(
                AppStrings.fillInformation,
                textAlign: TextAlign.center,
                style: AppTextStyles.cleanUpSectionSubtitle(context),
              ),
            ),

            SizedBox(
              height: SizeUtils.h(context, AppDimensions.cleanupSpacing24),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandableSections(BuildContext context) {
    final controller = Get.find<CleanupFormController>();

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeUtils.w(
          context,
          AppDimensions.cleanupSectionsHorizontalPadding,
        ),
      ),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return Column(
            children: [
              CleanUpSection(
                title: AppStrings.basicInformation,
                controller: controller,
              ),
              SizedBox(
                height: SizeUtils.h(context, AppDimensions.cleanupSpacing20),
              ),
              CleanUpSection(
                title: AppStrings.trashCollected,
                controller: controller,
              ),
              SizedBox(
                height: SizeUtils.h(context, AppDimensions.cleanupSpacing16),
              ),
              CleanUpSection(
                title: AppStrings.photosVideosOptional,
                controller: controller,
              ),
              SizedBox(
                height: SizeUtils.h(context, AppDimensions.cleanupSpacing24),
              ), // Space before footer
            ],
          );
        },
      ),
    );
  }

  Widget _buildFooterSection(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Bottom decorative image - positioned to start overlapping with buttons
        Positioned(
          left: AppDimensions.zero,
          right: AppDimensions.zero,
          top: AppDimensions.zero, // Overlap amount - adjust based on design
          child: IgnorePointer(
            child: Image.asset(
              AppImages.cleanupBottom,
              fit: BoxFit.cover,
              width: double.infinity,
              alignment: Alignment.topCenter,
            ),
          ),
        ),

        // Buttons overlapping the bottom image
        Padding(
          padding: EdgeInsets.only(
            left: SizeUtils.w(
              context,
              AppDimensions.cleanupFooterHorizontalPadding,
            ),
            right: SizeUtils.w(
              context,
              AppDimensions.cleanupFooterHorizontalPadding,
            ),
            top: AppDimensions.zero,
            bottom:
                mediaQuery.padding.bottom +
                SizeUtils.h(context, AppDimensions.cleanupFooterBottomExtra),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Save Button - positioned at top per design
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  onPressed: () => _handleSaveCleanup(context),
                  label: AppStrings.saveCleanUp,
                  labelStyle: AppTextStyles.saveCleanUpText(context),
                ),
              ),

              SizedBox(
                height: SizeUtils.h(context, AppDimensions.cleanupSpacing12),
              ),

              // Cancel Button - positioned at top per design
              SizedBox(
                width: double.infinity,
                height: SizeUtils.h(
                  context,
                  AppDimensions.cleanupCancelButtonHeight,
                ),
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.buttonPrimary,
                      width:
                          AppDimensions.inputBorderWidth == 0
                              ? 1
                              : AppDimensions.inputBorderWidth,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        SizeUtils.r(
                          context,
                          AppDimensions.cleanupCancelButtonRadius,
                        ),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: SizeUtils.h(
                        context,
                        AppDimensions.cleanupCancelButtonVerticalPadding,
                      ),
                      horizontal: SizeUtils.w(
                        context,
                        AppDimensions.cleanupCancelButtonHorizontalPadding,
                      ),
                    ),
                  ),
                  child: Text(
                    AppStrings.cancelCleanUp,
                    style: AppTextStyles.saveCleanUpText(
                      context,
                    ).copyWith(color: AppColors.textDark),
                  ),
                ),
              ),

              // Additional spacing to show more of the bottom image
              SizedBox(
                height: SizeUtils.h(
                  context,
                  AppDimensions.cleanupFooterExtraSpacing,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CleanUpSection extends StatefulWidget {
  final String title;
  final CleanupFormController controller;

  const CleanUpSection({
    super.key,
    required this.title,
    required this.controller,
  });

  @override
  State<CleanUpSection> createState() => _CleanUpSectionState();
}

class _CleanUpSectionState extends State<CleanUpSection> {
  bool get _isExpanded => widget.controller.expandedSection == widget.title;

  void _handleExpansionTap() {
    final currentlyExpanded = _isExpanded;

    if (currentlyExpanded) {
      // Trying to collapse - validate first
      final isValid = widget.controller.validateSection(widget.title);
      if (!isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.fixErrorsBeforeClosing),
            backgroundColor: AppColors.errorRed,
            duration: Duration(seconds: 3),
          ),
        );
        return; // Don't allow collapse
      }
      // Validation passed, allow collapse
      widget.controller.setExpandedSection(null);
    } else {
      // Trying to expand - validate currently open section first
      if (widget.controller.expandedSection != null) {
        // Use non-mutating check to avoid re-setting errors immediately
        final isValid = widget.controller.checkSectionValidity(
          widget.controller.expandedSection!,
        );
        if (!isValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.fixErrorsBeforeProceeding),
              backgroundColor: AppColors.errorRed,
              duration: Duration(seconds: 3),
            ),
          );
          return; // Don't allow expansion
        }
      }
      // Validation passed or no section open, allow expansion
      widget.controller.setExpandedSection(widget.title);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return Container(
          width: SizeUtils.w(context, AppDimensions.cleanupSectionWidth),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              SizeUtils.r(context, AppDimensions.cleanupSectionRadius),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium,
                offset: Offset(
                  AppDimensions.cleanupSectionShadowOffsetX,
                  AppDimensions.cleanupSectionShadowOffsetY,
                ),
                blurRadius: AppDimensions.cleanupSectionShadowBlur,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              SizeUtils.r(context, AppDimensions.cleanupSectionRadius),
            ),
            child: ExpansionTile(
              key: ValueKey('${widget.title}_$_isExpanded'),
              initiallyExpanded: _isExpanded,
              enabled: false, // Disable default tap behavior
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  SizeUtils.r(context, AppDimensions.cleanupSectionRadius),
                ),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  SizeUtils.r(context, AppDimensions.cleanupSectionRadius),
                ),
              ),
              collapsedBackgroundColor: AppColors.skeletonBase,
              backgroundColor: AppColors.accent,
              title: GestureDetector(
                onTap: _handleExpansionTap,
                behavior: HitTestBehavior.opaque,
                child: Text(
                  widget.title,
                  style:
                      _isExpanded
                          ? AppTextStyles.cleanUpOptionsExpanded(context)
                          : AppTextStyles.cleanUpOptionsCollapsed(context),
                ),
              ),
              trailing: GestureDetector(
                onTap: _handleExpansionTap,
                child: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                ),
              ),
              children: [
                if (widget.title == AppStrings.basicInformation)
                  BasicInformationSection(controller: widget.controller)
                else if (widget.title == AppStrings.trashCollected)
                  TrashCollectedSection(controller: widget.controller)
                else if (widget.title == AppStrings.photosVideosOptional)
                  Padding(
                    padding: EdgeInsets.all(
                      SizeUtils.h(context, AppDimensions.cleanupContentPadding),
                    ),
                    child: Text(
                      AppStrings.photosVideosPlaceholder,
                      style: AppTextStyles.bodySecondary(
                        context,
                      ).copyWith(color: AppColors.black54),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
