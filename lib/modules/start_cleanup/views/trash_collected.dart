import 'package:we_monitor/app/controllers/haptic_controller.dart';
import 'package:we_monitor/modules/start_cleanup/controllers/cleanup_form_controller.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';

class TrashCollectedSection extends StatefulWidget {
  final CleanupFormController controller;
  final bool isEditMode;

  const TrashCollectedSection({
    super.key,
    required this.controller,
    this.isEditMode = false,
  });

  @override
  State<TrashCollectedSection> createState() => _TrashCollectedSectionState();
}

class _TrashCollectedSectionState extends State<TrashCollectedSection> {
  String? _expandedCategory;

  String? get _selectedEnvironment =>
      widget.controller.selectedEnvironments.isNotEmpty
          ? widget.controller.selectedEnvironments.first
          : null;

  @override
  void initState() {
    super.initState();
  }

  void _onEnvironmentChanged(String? environment) {
    Get.find<HapticController>().selectionClick();
    widget.controller.selectedEnvironments.clear();
    if (environment != null) {
      widget.controller.selectedEnvironments.add(environment);
    }
    widget.controller.clearFieldError('environment');
  }

  void _onItemCountChanged(String itemName, int count) {
    Get.find<HapticController>().selectionClick();
    if (count > 0) {
      Get.find<HapticController>().light();
      widget.controller.trashItems[itemName] = count;
    } else {
      widget.controller.trashItems.remove(itemName);
    }
    widget.controller.clearFieldError('trashItems');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return Container(
          color: AppColors.background,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SizeUtils.w(
                context,
                AppDimensions.cleanupContentPadding,
              ),
              vertical: SizeUtils.h(context, AppDimensions.cleanupSpacing12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Environment Section
                Text(
                  AppStrings.environmentLabel,
                  style: AppTextStyles.trashCollectionLabel(context),
                ),
                SizedBox(
                  height: SizeUtils.h(context, AppDimensions.cleanupSpacing4),
                ),
                Column(
                  children: [
                    ...AppStrings.environments.map((env) {
                      final isSelected = _selectedEnvironment == env;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        visualDensity: const VisualDensity(
                          horizontal: -4.0,
                          vertical: -4.0,
                        ),
                        leading: Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: AppColors.textAccent,
                        ),
                        title: Text(
                          env,
                          style: AppTextStyles.trashCollectionEnvironment(
                            context,
                          ),
                        ),
                        onTap: () {
                          Get.find<HapticController>().selectionClick();
                          _onEnvironmentChanged(env);
                        },
                      );
                    }),
                  ],
                ),
                // Environment error message
                if (widget.controller.environmentError != null)
                  Padding(
                    padding: EdgeInsets.only(
                      top: SizeUtils.h(
                        context,
                        AppDimensions.inputErrorSpacing,
                      ),
                      left: SizeUtils.w(
                        context,
                        AppDimensions.cleanupContentPadding,
                      ),
                    ),
                    child: Text(
                      widget.controller.environmentError!,
                      style: AppTextStyles.trashErrorText(context),
                    ),
                  ),
                SizedBox(
                  height: SizeUtils.h(context, AppDimensions.cleanupSpacing16),
                ),

                // Categories Section
                Text(
                  AppStrings.categoriesLabel,
                  style: AppTextStyles.trashCollectionLabel(context),
                ),
                Text(
                  AppStrings.categoriesSubtitle,
                  style: AppTextStyles.trashCollectionSubtitle(context),
                ),
                SizedBox(
                  height: SizeUtils.h(context, AppDimensions.cleanupSpacing12),
                ),

                // Show loading indicator while template is being fetched
                if (widget.controller.isLoadingTemplate)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: SizeUtils.h(
                        context,
                        AppDimensions.cleanupSpacing20,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          SizedBox(
                            height: SizeUtils.h(
                              context,
                              AppDimensions.cleanupSmallLoaderSize,
                            ),
                            width: SizeUtils.w(
                              context,
                              AppDimensions.cleanupSmallLoaderSize,
                            ),
                            child: CircularProgressIndicator(
                              strokeWidth: SizeUtils.h(
                                context,
                                AppDimensions.smallLoaderStrokeWidth,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: SizeUtils.h(
                              context,
                              AppDimensions.cleanupSpacing12,
                            ),
                          ),
                          Text(
                            AppStrings.loadingCategories,
                            style: AppTextStyles.bodySecondary(context),
                          ),
                        ],
                      ),
                    ),
                  )
                // Show categories once loaded
                else if (widget.controller.categories.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: SizeUtils.h(
                        context,
                        AppDimensions.cleanupSpacing20,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        AppStrings.noCategoriesAvailable,
                        style: AppTextStyles.bodySecondary(context),
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      // Dropdowns for each category (from Firestore)
                      ...widget.controller.getOrderedCategories().map((entry) {
                        final categoryKey = entry.key;
                        final category = entry.value;
                        final isExpanded = _expandedCategory == categoryKey;

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: SizeUtils.h(
                              context,
                              AppDimensions.cleanupCategoryItemBottomSpacing,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              Get.find<HapticController>().light();
                              setState(() {
                                _expandedCategory =
                                    isExpanded ? null : categoryKey;
                              });
                            },
                            borderRadius: BorderRadius.circular(
                              SizeUtils.r(
                                context,
                                AppDimensions.cleanupCategoryTileRadius,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.dialogBackground,
                                borderRadius: BorderRadius.circular(
                                  SizeUtils.r(
                                    context,
                                    AppDimensions.cleanupCategoryTileRadius,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.blackWithOpacity15,
                                    offset: Offset(
                                      SizeUtils.w(
                                        context,
                                        AppDimensions
                                            .cleanupSectionShadowOffsetX,
                                      ),
                                      SizeUtils.h(
                                        context,
                                        AppDimensions
                                            .cleanupSectionShadowOffsetY,
                                      ),
                                    ),
                                    blurRadius: SizeUtils.h(
                                      context,
                                      AppDimensions.cleanupSectionShadowBlur,
                                    ),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: SizeUtils.w(
                                        context,
                                        AppDimensions
                                            .cleanupCategoryHeaderHorizontalPadding,
                                      ),
                                      vertical: SizeUtils.h(
                                        context,
                                        AppDimensions
                                            .cleanupCategoryHeaderVerticalPadding,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            category.name,
                                            style:
                                                AppTextStyles.trashCollectionDropdownCategory(
                                                  context,
                                                ),
                                          ),
                                        ),
                                        Icon(
                                          isExpanded
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
                                          color: AppColors.black87,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 👇 When expanded, show items inline
                                  if (isExpanded)
                                    Padding(
                                      padding: EdgeInsets.all(
                                        SizeUtils.h(
                                          context,
                                          AppDimensions
                                              .cleanupCategoryItemInnerVerticalPadding,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          ...category.items.keys.map((
                                            itemName,
                                          ) {
                                            final currentCount =
                                                widget
                                                    .controller
                                                    .trashItems[itemName] ??
                                                0;
                                            return Padding(
                                              padding: EdgeInsets.only(
                                                bottom: SizeUtils.h(
                                                  context,
                                                  AppDimensions
                                                      .cleanupCategoryItemBottomSpacing,
                                                ),
                                              ),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: SizeUtils.h(
                                                    context,
                                                    AppDimensions
                                                        .cleanupCategoryItemInnerVerticalPadding,
                                                  ),
                                                  horizontal: SizeUtils.w(
                                                    context,
                                                    AppDimensions
                                                        .cleanupCategoryItemHorizontalPadding,
                                                  ),
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.pureWhite,
                                                  border: Border.all(
                                                    color:
                                                        AppColors
                                                            .dialogBackground,
                                                    width: SizeUtils.h(
                                                      context,
                                                      AppDimensions
                                                          .cleanupCategoryBorderWidth,
                                                    ),
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        SizeUtils.r(
                                                          context,
                                                          AppDimensions
                                                              .cleanupCategoryItemRadius,
                                                        ),
                                                      ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        itemName,
                                                        style:
                                                            AppTextStyles.trashCollectionDropdownCategory(
                                                              context,
                                                            ).copyWith(
                                                              color:
                                                                  AppColors
                                                                      .textAccent,
                                                              letterSpacing:
                                                                  0.1,
                                                            ),
                                                        maxLines: 2,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: SizeUtils.w(
                                                        context,
                                                        AppDimensions
                                                            .smallSpacing,
                                                      ),
                                                    ),
                                                    Container(
                                                      height: SizeUtils.h(
                                                        context,
                                                        AppDimensions
                                                            .cleanupCategoryControlHeight,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                          color:
                                                              AppColors
                                                                  .dialogBackground,
                                                          width: SizeUtils.h(
                                                            context,
                                                            AppDimensions
                                                                .cleanupCategoryControlBorderWidth,
                                                          ),
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              SizeUtils.r(
                                                                context,
                                                                AppDimensions
                                                                    .cleanupCategoryControlBorderRadius,
                                                              ),
                                                            ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          // Minus button
                                                          SizedBox(
                                                            width: SizeUtils.w(
                                                              context,
                                                              AppDimensions
                                                                  .cleanupCategorySmallGap,
                                                            ),
                                                          ),
                                                          Container(
                                                            width: SizeUtils.w(
                                                              context,
                                                              AppDimensions
                                                                  .cleanupCategoryControlButtonSize,
                                                            ),
                                                            height: SizeUtils.h(
                                                              context,
                                                              AppDimensions
                                                                  .cleanupCategoryControlButtonSize,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  AppColors
                                                                      .dialogBackground,
                                                              borderRadius: BorderRadius.all(
                                                                Radius.circular(
                                                                  SizeUtils.r(
                                                                    context,
                                                                    AppDimensions
                                                                        .cleanupCategoryItemRadius,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            child: IconButton(
                                                              icon: Icon(
                                                                Icons.remove,
                                                                size: SizeUtils.r(
                                                                  context,
                                                                  AppDimensions
                                                                      .cleanupCategoryIconLargeSize,
                                                                ),
                                                              ),
                                                              color:
                                                                  AppColors
                                                                      .textAccent,
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              constraints:
                                                                  const BoxConstraints(),
                                                              onPressed:
                                                                  currentCount >
                                                                          0
                                                                      ? () => _onItemCountChanged(
                                                                        itemName,
                                                                        currentCount -
                                                                            1,
                                                                      )
                                                                      : null,
                                                            ),
                                                          ),
                                                          // Count display
                                                          Container(
                                                            width: SizeUtils.w(
                                                              context,
                                                              AppDimensions
                                                                  .cleanupCategoryControlCountWidth,
                                                            ),
                                                            height: SizeUtils.h(
                                                              context,
                                                              AppDimensions
                                                                  .cleanupCategoryControlButtonSize,
                                                            ),
                                                            alignment:
                                                                Alignment
                                                                    .center,
                                                            decoration:
                                                                const BoxDecoration(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                ),
                                                            child: Text(
                                                              '$currentCount',
                                                              style: AppTextStyles.body(
                                                                context,
                                                              ).copyWith(
                                                                fontSize: SizeUtils.h(
                                                                  context,
                                                                  AppDimensions
                                                                      .cleanupCategoryControlCountFontSize,
                                                                ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                                color:
                                                                    AppColors
                                                                        .textAccent,
                                                              ),
                                                            ),
                                                          ),
                                                          // Plus button
                                                          Container(
                                                            width: SizeUtils.w(
                                                              context,
                                                              AppDimensions
                                                                  .cleanupCategoryControlButtonSize,
                                                            ),
                                                            height: SizeUtils.h(
                                                              context,
                                                              AppDimensions
                                                                  .cleanupCategoryControlButtonSize,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  AppColors
                                                                      .dialogBackground,
                                                              borderRadius: BorderRadius.all(
                                                                Radius.circular(
                                                                  SizeUtils.r(
                                                                    context,
                                                                    AppDimensions
                                                                        .cleanupCategoryItemRadius,
                                                                  ),
                                                                ),
                                                              ),
                                                              border: Border.all(
                                                                color:
                                                                    AppColors
                                                                        .dialogBackground,
                                                                width: SizeUtils.h(
                                                                  context,
                                                                  AppDimensions
                                                                      .cleanupCategoryControlBorderWidth,
                                                                ),
                                                              ),
                                                            ),
                                                            child: IconButton(
                                                              icon: Icon(
                                                                Icons.add,
                                                                size: SizeUtils.r(
                                                                  context,
                                                                  AppDimensions
                                                                      .cleanupCategoryIconLargeSize,
                                                                ),
                                                              ),
                                                              color:
                                                                  AppColors
                                                                      .textAccent,
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              constraints:
                                                                  const BoxConstraints(),
                                                              onPressed:
                                                                  () => _onItemCountChanged(
                                                                    itemName,
                                                                    currentCount +
                                                                        1,
                                                                  ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: SizeUtils.w(
                                                              context,
                                                              AppDimensions
                                                                  .cleanupCategorySmallGap,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                if (widget.controller.trashItemsError != null)
                  Padding(
                    padding: EdgeInsets.only(
                      top: SizeUtils.h(
                        context,
                        AppDimensions.inputErrorSpacing,
                      ),
                      left: SizeUtils.w(
                        context,
                        AppDimensions.cleanupContentPadding,
                      ),
                    ),
                    child: Text(
                      widget.controller.trashItemsError!,
                      style: AppTextStyles.trashErrorText(context),
                    ),
                  ),

                // Next Button
                if (!widget.isEditMode) ...[
                  SizedBox(
                    height: SizeUtils.h(context, AppDimensions.cleanupSpacing24),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: SizeUtils.h(context, AppDimensions.buttonHeight),
                    child: ElevatedButton(
                      onPressed: () {
                        Get.find<HapticController>().medium();
                        _handleNext(context);
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
                        AppStrings.nextButton,
                        style: AppTextStyles.saveCleanUpText(
                          context,
                        ).copyWith(color: AppColors.pureWhite),
                      ),
                    ),
                  ),
                ],
                SizedBox(
                  height: SizeUtils.h(context, AppDimensions.cleanupSpacing12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleNext(BuildContext context) {
    // Validate all fields in this section
    final isValid = widget.controller.validateSection(
      AppStrings.trashCollected,
    );

    if (!isValid) {
      Get.find<HapticController>().heavy();
      // Show specific error message based on what's missing
      String errorMessage = AppStrings.pleaseFixFormErrors;
      if (widget.controller.environmentError != null) {
        errorMessage = AppStrings.pleaseSelectEnvironment;
      } else if (widget.controller.trashItemsError != null) {
        errorMessage = AppStrings.pleaseAddTrashItem;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    Get.find<HapticController>().medium();
    // Mark section as completed
    widget.controller.markSectionCompleted(AppStrings.trashCollected);

    // Move to next section (Photos)
    widget.controller.setExpandedSection(AppStrings.photosVideosOptional);
  }
}
