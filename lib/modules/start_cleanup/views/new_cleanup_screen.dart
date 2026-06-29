import 'package:we_monitor/app/controllers/haptic_controller.dart';
import 'package:we_monitor/modules/start_cleanup/views/basic_infomation_section.dart';
import 'package:we_monitor/modules/start_cleanup/views/trash_collected.dart';
import 'package:we_monitor/modules/start_cleanup/views/photos_section.dart';
import 'package:we_monitor/modules/start_cleanup/controllers/cleanup_form_controller.dart';
import 'package:we_monitor/shared/controllers/connectivity_controller.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_images.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:we_monitor/shared/widgets/app_dialog.dart';
import 'package:we_monitor/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:we_monitor/shared/analytics/analytics_service.dart';

class NewCleanUpScreen extends StatefulWidget {
  const NewCleanUpScreen({super.key});

  @override
  State<NewCleanUpScreen> createState() => _NewCleanUpScreenState();
}

class _NewCleanUpScreenState extends State<NewCleanUpScreen> {
  @override
  void initState() {
    super.initState();
    Analytics.screenView(AnalyticsEvents.cleanupStarted);
    // Open Basic Information section by default when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<CleanupFormController>();
      controller.setExpandedSection(AppStrings.basicInformation);
    });
    Get.find<HapticController>().light();
  }

  Future<void> _handleSaveCleanup(BuildContext context) async {
    final controller = Get.find<CleanupFormController>();

    // Check if all sections are completed
    if (!controller.canSubmit) {
      Get.find<HapticController>().heavy();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.pleaseCompleteAllSections),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Re-validate all sections one final time
    final isBasicInfoValid = controller.validateSection(
      AppStrings.basicInformation,
    );
    final isTrashValid = controller.validateSection(AppStrings.trashCollected);

    // Manage section states based on validation
    if (!isBasicInfoValid || !isTrashValid) {
      Get.find<HapticController>().heavy();
      // Close valid sections, expand invalid ones
      if (!isBasicInfoValid) {
        controller.setExpandedSection(AppStrings.basicInformation);
        controller.resetSectionCompletion(AppStrings.basicInformation);
      } else if (!isTrashValid) {
        controller.setExpandedSection(AppStrings.trashCollected);
        controller.resetSectionCompletion(AppStrings.trashCollected);
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

    // Check if photos are still uploading
    final hasUploadsInProgress =
        controller.mediaUploadController.hasUploadsInProgress;
    final uploadMessage =
        hasUploadsInProgress
            ? AppStrings.waitingForPhotoUploads
            : AppStrings.submittingCleanup;

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
              Expanded(child: Text(uploadMessage)),
            ],
          ),
          backgroundColor: AppColors.info,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(minutes: 5), // Long duration for uploads
        ),
      );
    }

    // Submit cleanup
    final cleanupId = await controller.submitCleanup(currentUser.uid);

    // Always hide loading indicator after submission completes (online or offline)
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    if (cleanupId != null) {
      Get.find<HapticController>().medium();
      // Check if it was saved offline or online
      final connectivityController = Get.find<ConnectivityController>();
      final wasOnline = connectivityController.isOnline.value;

      // Success - show AppDialog and navigate home when user confirms
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            return AppDialog(
              title:
                  wasOnline
                      ? AppStrings.cleanUpSavedDialogTitle
                      : 'Cleanup Saved Offline',
              decoratedHero: false,
              imageAsset: AppImages.cleanConfirm,
              imageWidth: SizeUtils.w(ctx, AppDimensions.dialogImageWidth),
              imageHeight: SizeUtils.h(ctx, AppDimensions.dialogImageHeight),
              body:
                  wasOnline
                      ? AppStrings.cleanUpSavedDialogSubtitle
                      : 'Your cleanup has been saved offline. It will be uploaded when you have internet connection. You can manage pending uploads from your profile.',
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const ScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Section (scrolls with page)
                    _buildHeaderSection(context),

                    // Expandable Sections (grows/shrinks dynamically)
                    _buildExpandableSections(context),

                    const Spacer(),

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
            ),
          );
        },
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
          fit: BoxFit.fill,
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
                  onPressed: () {
                    Get.find<HapticController>().selectionClick();
                    Navigator.pop(context);
                  },
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
    final controller = Get.find<CleanupFormController>();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Bottom decorative image - positioned to start overlapping with buttons
        Positioned(
          left: AppDimensions.zero,
          right: AppDimensions.zero,
          bottom: AppDimensions.zero,
          child: IgnorePointer(
            child: Image.asset(
              AppImages.cleanupBottom,
              fit: BoxFit.cover,
              width: double.infinity,
              alignment: Alignment.bottomCenter,
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
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final canSubmit = controller.canSubmit;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Save Button - disabled until all sections are completed
                  SizedBox(
                    width: double.infinity,
                    height: SizeUtils.h(context, AppDimensions.buttonHeight),
                    child: ElevatedButton(
                      onPressed:
                          canSubmit
                              ? () {
                                Get.find<HapticController>().medium();
                                _handleSaveCleanup(context);
                              }
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            canSubmit
                                ? AppColors.buttonGreen
                                : AppColors.buttonDisabledBackground,
                        disabledBackgroundColor:
                            AppColors.buttonDisabledBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            SizeUtils.r(context, AppDimensions.borderRadius),
                          ),
                        ),
                      ),
                      child: Text(
                        AppStrings.saveCleanUp,
                        style: AppTextStyles.saveCleanUpText(context).copyWith(
                          color:
                              canSubmit
                                  ? AppColors.pureWhite
                                  : AppColors.buttonDisabledText,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(
                    height: SizeUtils.h(
                      context,
                      AppDimensions.cleanupSpacing12,
                    ),
                  ),

                  // Cancel Button - positioned at top per design
                  SizedBox(
                    width: double.infinity,
                    height: SizeUtils.h(
                      context,
                      AppDimensions.cleanupCancelButtonHeight,
                    ),
                    child: OutlinedButton(
                      onPressed: () {
                        Get.find<HapticController>().selectionClick();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.buttonPrimary,
                          width:
                              SizeUtils.w(
                                        context,
                                        AppDimensions.inputBorderWidth,
                                      ) ==
                                      0
                                  ? 1
                                  : SizeUtils.w(
                                    context,
                                    AppDimensions.inputBorderWidth,
                                  ),
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
              );
            },
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

class _CleanUpSectionState extends State<CleanUpSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _chevronRotationAnimation;

  bool get _isExpanded => widget.controller.expandedSection == widget.title;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _chevronRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(_expandAnimation);

    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CleanUpSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Check if this section can be tapped (for viewing previously completed sections)
  bool get _canTapHeader {
    // Check if this section is accessible based on the flow
    switch (widget.title) {
      case AppStrings.basicInformation:
        // Basic info is always accessible (it's the first section)
        return true;
      case AppStrings.trashCollected:
        // Trash collected is only accessible if basic info is completed
        return widget.controller.basicInfoCompleted;
      case AppStrings.photosVideosOptional:
        // Photos is only accessible if trash collected is completed
        return widget.controller.trashCollectedCompleted;
      default:
        return false;
    }
  }

  void _handleHeaderTap() {
    // 1. If it's the currently expanded section, try to close it.
    if (_isExpanded) {
      Get.find<HapticController>().light();
      final isValid = widget.controller.validateSection(widget.title);
      if (isValid) {
        widget.controller.markSectionCompleted(widget.title);
        widget.controller.setExpandedSection(null);
      } else {
        // Trigger errors visually by notifying listeners
        Get.find<HapticController>().heavy();
      }
      return;
    }

    // 2. If it's a closed section:
    // First validate the currently open section if there is one.
    final currentExpanded = widget.controller.expandedSection;
    if (currentExpanded != null) {
      final isCurrentValid = widget.controller.validateSection(currentExpanded);
      if (!isCurrentValid) {
        // Current section is invalid, don't switch! Show errors on current section.
        Get.find<HapticController>().heavy();
        return;
      }
      // Current section is valid, mark it as completed
      widget.controller.markSectionCompleted(currentExpanded);
    }

    // Now check if the target section is accessible.
    if (_canTapHeader) {
      Get.find<HapticController>().light();

      // If we are moving back to a previous section, reset completion for sections after it
      widget.controller.resetSectionCompletion(widget.title);

      widget.controller.setExpandedSection(widget.title);
    } else {
      // Not accessible yet
      Get.find<HapticController>().heavy();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final isCompleted = _isSectionCompleted();

        return Container(
          width: SizeUtils.w(context, AppDimensions.cleanupSectionWidth),
          decoration: BoxDecoration(
            color: _isExpanded ? AppColors.accent : AppColors.skeletonBase,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header (Clickable full-width tap target)
                GestureDetector(
                  onTap: _handleHeaderTap,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeUtils.w(context, 16),
                      vertical: SizeUtils.h(
                        context,
                        14,
                      ), // Unexpanded state height adjustment
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            style:
                                _isExpanded
                                    ? AppTextStyles.cleanUpOptionsExpanded(
                                      context,
                                    )
                                    : AppTextStyles.cleanUpOptionsCollapsed(
                                      context,
                                    ),
                          ),
                        ),
                        // Show checkmark for completed sections
                        if (isCompleted && !_isExpanded)
                          Padding(
                            padding: EdgeInsets.only(
                              right: SizeUtils.w(context, 8),
                            ),
                            child: Icon(
                              Icons.check_circle,
                              color: AppColors.buttonGreen,
                              size: SizeUtils.r(context, 20),
                            ),
                          ),
                        RotationTransition(
                          turns: _chevronRotationAnimation,
                          child: Icon(
                            Icons.expand_more,
                            color:
                                _canTapHeader || _isExpanded
                                    ? AppColors.textDark
                                    : AppColors.grey400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Expanded Content
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.title == AppStrings.basicInformation)
                        BasicInformationSection(controller: widget.controller)
                      else if (widget.title == AppStrings.trashCollected)
                        TrashCollectedSection(controller: widget.controller)
                      else if (widget.title == AppStrings.photosVideosOptional)
                        PhotosSection(formController: widget.controller),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isSectionCompleted() {
    switch (widget.title) {
      case AppStrings.basicInformation:
        return widget.controller.basicInfoCompleted;
      case AppStrings.trashCollected:
        return widget.controller.trashCollectedCompleted;
      case AppStrings.photosVideosOptional:
        return widget.controller.photosCompleted;
      default:
        return false;
    }
  }
}
