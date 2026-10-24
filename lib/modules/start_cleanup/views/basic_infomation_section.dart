import 'package:we_monitor/app/controllers/haptic_controller.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/services/location_validator.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:we_monitor/shared/widgets/floating_label_input_field.dart';
import 'package:we_monitor/shared/widgets/custom_date_picker.dart';
import 'package:we_monitor/shared/widgets/location_picker_field.dart';
import 'package:we_monitor/modules/start_cleanup/controllers/cleanup_form_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BasicInformationSection extends StatefulWidget {
  final CleanupFormController controller;

  const BasicInformationSection({super.key, required this.controller});

  @override
  State<BasicInformationSection> createState() =>
      _BasicInformationSectionState();
}

class _BasicInformationSectionState extends State<BasicInformationSection> {
  late final TextEditingController peopleController;
  late final TextEditingController groupController;
  late final TextEditingController dateController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with values from form controller
    peopleController = TextEditingController(
      text: widget.controller.peopleCount.toString(),
    );
    groupController = TextEditingController(text: widget.controller.groupName);
    dateController = TextEditingController(text: widget.controller.date);

    // Sync changes back to form controller
    peopleController.addListener(_syncPeopleCount);
    groupController.addListener(_syncGroupName);
    dateController.addListener(_syncDate);
  }

  @override
  void dispose() {
    peopleController.dispose();
    groupController.dispose();
    dateController.dispose();
    super.dispose();
  }

  void _syncPeopleCount() {
    final count = int.tryParse(peopleController.text) ?? 0;
    widget.controller.peopleCount = count;
  }

  void _syncGroupName() {
    widget.controller.groupName = groupController.text;
  }

  void _syncDate() {
    widget.controller.date = dateController.text;
  }

  void _incrementPeople() {
    final newCount = widget.controller.peopleCount + 1;
    widget.controller.peopleCount = newCount;
    peopleController.text = newCount.toString();
    widget.controller.clearFieldError(
      'peopleCount',
    ); // also notifies (draft save)
  }

  void _decrementPeople() {
    if (widget.controller.peopleCount > 0) {
      final newCount = widget.controller.peopleCount - 1;
      widget.controller.peopleCount = newCount;
      peopleController.text = newCount.toString();
      widget.controller.clearFieldError(
        'peopleCount',
      ); // also notifies (draft save)
    }
  }

  // Using shared FloatingLabelInputField for consistent inputs

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        SizeUtils.h(context, AppDimensions.cleanupContentPadding),
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(
          SizeUtils.r(context, AppDimensions.cleanupSectionRadius),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number of People - use FloatingLabelInputField with +/- buttons
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Place the floating input in the middle, buttons on sides
                    Row(
                      children: [
                        // Decrement button
                        IconButton(
                          onPressed: () {
                            Get.find<HapticController>().selectionClick();
                            _decrementPeople();
                          },
                          icon: Icon(
                            Icons.remove,
                            size: SizeUtils.r(
                              context,
                              AppDimensions.smallIconSize,
                            ),
                          ),
                          color: AppColors.accentGreen,
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),

                        // Floating input occupies the remaining width
                        Expanded(
                          child: ListenableBuilder(
                            listenable: widget.controller,
                            builder: (context, _) {
                              return FloatingLabelInputField(
                                controller: peopleController,
                                label: AppStrings.numberOfPeopleLabel,
                                hint: '0',
                                keyboardType: TextInputType.number,
                                topSpacing: AppDimensions.zero,
                                supportText: widget.controller.peopleCountError,
                                isError:
                                    widget.controller.peopleCountError != null,
                                onChanged: (val) {
                                  final parsed = int.tryParse(val) ?? 0;
                                  widget.controller.peopleCount = parsed;
                                  widget.controller.clearFieldError(
                                    'peopleCount',
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        // Increment button
                        IconButton(
                          onPressed: () {
                            Get.find<HapticController>().selectionClick();
                            _incrementPeople();
                          },
                          icon: Icon(
                            Icons.add,
                            size: SizeUtils.r(
                              context,
                              AppDimensions.smallIconSize,
                            ),
                          ),
                          color: AppColors.accentGreen,
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),

                    SizedBox(
                      height: SizeUtils.h(
                        context,
                        AppDimensions.cleanupSpacing4,
                      ),
                    ),
                    Text(
                      AppStrings.totalParticipants,
                      style: AppTextStyles.bodySecondary(context).copyWith(
                        fontSize: SizeUtils.h(
                          context,
                          AppDimensions.smallFontSize,
                        ),
                        color: AppColors.textAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: SizeUtils.h(context, AppDimensions.cleanupSpacing12),
          ),

          // Group Name
          ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              return FloatingLabelInputField(
                controller: groupController,
                label: AppStrings.groupNameLabel,
                hint: AppStrings.enterGroupName,
                supportText: widget.controller.groupNameError,
                isError: widget.controller.groupNameError != null,
                onChanged:
                    (_) => widget.controller.clearFieldError('groupName'),
              );
            },
          ),
          SizedBox(height: SizeUtils.h(context, AppDimensions.cleanupSpacing4)),
          Text(
            AppStrings.cleanAloneHint,
            style: AppTextStyles.bodySecondary(context).copyWith(
              fontSize: SizeUtils.h(context, 12),
              color: AppColors.textHint,
            ),
          ),
          SizedBox(
            height: SizeUtils.h(context, AppDimensions.cleanupSpacing12),
          ),

          // Date - use custom date picker on tap (readOnly)
          ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              return FloatingLabelInputField(
                controller: dateController,
                label: AppStrings.dateLabel,
                hint: AppStrings.datePlaceholder,
                keyboardType: TextInputType.datetime,
                readOnly: true,
                supportText: widget.controller.dateError,
                isError: widget.controller.dateError != null,
                onTap: () async {
                  Get.find<HapticController>().selectionClick();
                  // open custom date picker on tap
                  // ignore: use_build_context_synchronously
                  final picked = await CustomDatePicker.show(
                    context,
                    initialDate: DateTime.now(),
                    startDate: DateTime(2023),
                    endDate: DateTime.now(),
                  );
                  if (!mounted) return;
                  if (picked != null) {
                    setState(
                      () =>
                          dateController.text =
                              "${picked.day}/${picked.month}/${picked.year}",
                    );
                    widget.controller.clearFieldError('date');
                  }
                },
                suffixIcon: Icon(
                  Icons.calendar_today_outlined,
                  size: SizeUtils.r(context, AppDimensions.smallIconSize),
                  color: AppColors.textHint,
                ),
              );
            },
          ),
          SizedBox(height: SizeUtils.h(context, AppDimensions.cleanupSpacing4)),
          Text(
            AppStrings.datePlaceholder,
            style: AppTextStyles.bodySecondary(context).copyWith(
              fontSize: SizeUtils.h(context, AppDimensions.smallFontSize),
              color: AppColors.textHint,
            ),
          ),
          SizedBox(
            height: SizeUtils.h(context, AppDimensions.cleanupSpacing16),
          ),

          // Location: explicit choices only (search, GPS, map picker confirm)
          ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              return LocationPickerField(
                value: widget.controller.pickedLocation,
                onChanged: widget.controller.setPickedLocation,
                onError: (error) => widget.controller.locationError = error,
                errorText: widget.controller.locationError,
              );
            },
          ),

          // Next Button
          SizedBox(
            height: SizeUtils.h(context, AppDimensions.cleanupSpacing24),
          ),
          SizedBox(
            width: double.infinity,
            height: SizeUtils.h(context, AppDimensions.buttonHeight),
            child: ElevatedButton(
              onPressed: _handleNext,
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
          SizedBox(
            height: SizeUtils.h(context, AppDimensions.cleanupSpacing12),
          ),
        ],
      ),
    );
  }

  void _handleNext() async {
    Get.find<HapticController>().medium();
    // Validate all fields in this section
    final isValid = widget.controller.validateSection(
      AppStrings.basicInformation,
    );

    if (!isValid) {
      Get.find<HapticController>().light();
      _showError(AppStrings.pleaseFixFormErrors);
      return;
    }

    // A location accepted offline (bounding box only) is re-checked against
    // Google as soon as we're online.
    final picked = widget.controller.pickedLocation!;
    if (!picked.verified) {
      final rechecked = await LocationValidator.reverify(picked);
      if (!mounted) return;
      if (rechecked == null) {
        Get.find<HapticController>().light();
        widget.controller.locationError = AppStrings.selectLocationInCameroon;
        _showError(AppStrings.selectLocationInCameroon);
        return;
      }
      widget.controller.setPickedLocation(rechecked);
    }

    Get.find<HapticController>().light();
    // Mark section as completed
    widget.controller.markSectionCompleted(AppStrings.basicInformation);

    // Move to next section (Trash Collected)
    widget.controller.setExpandedSection(AppStrings.trashCollected);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
