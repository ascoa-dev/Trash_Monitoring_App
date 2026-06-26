import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/app/controllers/haptic_controller.dart';

/// Combined Date and Environment filter widget matching Figma design
/// Features TWO SEPARATE date pickers stacked vertically (From on top, To on bottom)
class StatsFilterWidget extends StatefulWidget {
  final List<DateTime> availableDates;
  final DateTime? fromDate;
  final DateTime? toDate;
  final Function(DateTime) onFromDateChanged;
  final Function(DateTime) onToDateChanged;
  final Set<String> selectedEnvironments;
  final Function(String) onEnvironmentToggle;

  const StatsFilterWidget({
    super.key,
    required this.availableDates,
    required this.fromDate,
    required this.toDate,
    required this.onFromDateChanged,
    required this.onToDateChanged,
    required this.selectedEnvironments,
    required this.onEnvironmentToggle,
  });

  @override
  State<StatsFilterWidget> createState() => _StatsFilterWidgetState();
}

class _StatsFilterWidgetState extends State<StatsFilterWidget> {
  String? _errorMessage;

  // Colors from shared constants
  static const Color _tealColor = AppColors.statsFilterTeal;
  static const Color _greenColor = AppColors.statsFilterGreen;

  int get _fromIndex {
    if (widget.availableDates.isEmpty || widget.fromDate == null) return 0;
    final index = widget.availableDates.indexWhere(
      (date) =>
          date.year == widget.fromDate!.year &&
          date.month == widget.fromDate!.month &&
          date.day == widget.fromDate!.day,
    );
    return index >= 0 ? index : 0;
  }

  int get _toIndex {
    if (widget.availableDates.isEmpty || widget.toDate == null) {
      return widget.availableDates.length - 1;
    }
    final index = widget.availableDates.indexWhere(
      (date) =>
          date.year == widget.toDate!.year &&
          date.month == widget.toDate!.month &&
          date.day == widget.toDate!.day,
    );
    return index >= 0 ? index : widget.availableDates.length - 1;
  }

  void _handleFromChange(int newIndex) {
    Get.find<HapticController>().selectionClick();
    if (newIndex > _toIndex) {
      setState(() {
        _errorMessage = AppStrings.statsErrorFromDate;
      });
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) setState(() => _errorMessage = null);
      });
      widget.onFromDateChanged(widget.availableDates[_toIndex]);
    } else {
      Get.find<HapticController>().light();
      setState(() {
        _errorMessage = AppStrings.statsErrorFromDate;
      });
      widget.onFromDateChanged(widget.availableDates[newIndex]);
    }
  }

  void _handleToChange(int newIndex) {
    Get.find<HapticController>().selectionClick();
    if (newIndex < _fromIndex) {
      setState(() {
        _errorMessage = AppStrings.statsErrorToDate;
      });
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) setState(() => _errorMessage = null);
      });
      widget.onToDateChanged(widget.availableDates[_fromIndex]);
    } else {
      Get.find<HapticController>().light();
      setState(() => _errorMessage = null);
      widget.onToDateChanged(widget.availableDates[newIndex]);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.availableDates.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalDates = widget.availableDates.length;
    final fromIndex = _fromIndex;
    final toIndex = _toIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Section Header
        Text(
          AppStrings.statsFilterDate,
          style: AppTextStyles.statsFilterLabel(context),
        ),
        SizedBox(
          height: SizeUtils.h(context, AppDimensions.statsPagePaddingVertical),
        ),

        // Date labels row (From date on left, To date on right)
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              _formatDate(widget.availableDates[fromIndex]),
              style: AppTextStyles.statsFilterDate(context),
            ),
          ],
        ),

        // FROM Date Picker (on top) - teal on left, green on right
        _DatePickerSlider(
          selectedIndex: fromIndex,
          totalDates: totalDates,
          leftColor: _tealColor,
          rightColor: _greenColor,
          handleColor: _tealColor,
          onChanged: _handleFromChange,
          type: "From",
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              _formatDate(widget.availableDates[toIndex]),
              style: AppTextStyles.statsFilterDate(context),
            ),
          ],
        ),
        // TO Date Picker (on bottom) - green on left, teal on right (reversed)
        _DatePickerSlider(
          selectedIndex: toIndex,
          totalDates: totalDates,
          leftColor: _greenColor,
          rightColor: _tealColor,
          handleColor: _tealColor,
          onChanged: _handleToChange,
          type: "To",
        ),

        // Error message
        if (_errorMessage != null)
          Padding(
            padding: EdgeInsets.only(
              top: SizeUtils.h(
                context,
                AppDimensions.statsFilterErrorTopPadding,
              ),
            ),
            child: Text(
              _errorMessage!,
              style: AppTextStyles.statsError(context),
            ),
          ),

        SizedBox(
          height: SizeUtils.h(context, AppDimensions.statsFilterSectionSpacing),
        ),
        // Environment Section Header
        Text(
          AppStrings.statsFilterEnvironment,
          style: AppTextStyles.statsFilterLabel(context),
        ),
        SizedBox(
          height: SizeUtils.h(context, AppDimensions.statsFilterLabelSpacing),
        ),

        // Environment checkboxes row
        Row(
          children: [
            _buildCheckbox('All'),
            SizedBox(
              width: SizeUtils.w(
                context,
                AppDimensions.statsFilterCheckboxSpacing,
              ),
            ),
            _buildCheckbox('Inland'),
            SizedBox(
              width: SizeUtils.w(
                context,
                AppDimensions.statsFilterCheckboxSpacing,
              ),
            ),
            _buildCheckbox('Freshwater'),
            SizedBox(
              width: SizeUtils.w(
                context,
                AppDimensions.statsFilterCheckboxSpacing,
              ),
            ),
            _buildCheckbox('Saltwater'),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckbox(String label) {
    final isSelected = widget.selectedEnvironments.contains(label);
    return GestureDetector(
      onTap: () {
        Get.find<HapticController>().selectionClick();
        widget.onEnvironmentToggle(label);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: SizeUtils.w(context, AppDimensions.statsCheckboxSize),
            height: SizeUtils.h(context, AppDimensions.statsCheckboxSize),
            decoration: BoxDecoration(
              border: Border.all(
                color: _tealColor,
                width: SizeUtils.w(
                  context,
                  AppDimensions.statsCheckboxBorderWidth,
                ),
              ),
              borderRadius: BorderRadius.circular(
                SizeUtils.r(context, AppDimensions.statsCheckboxBorderRadius),
              ),
              color: isSelected ? _tealColor : AppColors.transparent,
            ),
            child:
                isSelected
                    ? Icon(
                      Icons.check,
                      size: SizeUtils.r(
                        context,
                        AppDimensions.statsCheckboxIconSize,
                      ),
                      color: AppColors.white,
                    )
                    : null,
          ),
          SizedBox(
            width: SizeUtils.w(
              context,
              AppDimensions.statsFilterCheckboxIconSpacing,
            ),
          ),
          Text(label, style: AppTextStyles.statsFilterDate(context)),
        ],
      ),
    );
  }
}

/// Individual date picker slider matching Figma design exactly
/// Layout: [Left colored bar with dots] [Handle with transparent padding on sides] [Right colored bar with dots]
class _DatePickerSlider extends StatelessWidget {
  final int selectedIndex;
  final int totalDates;
  final Color leftColor;
  final Color rightColor;
  final Color handleColor;
  final Function(int) onChanged;
  final String type;

  const _DatePickerSlider({
    required this.selectedIndex,
    required this.totalDates,
    required this.leftColor,
    required this.rightColor,
    required this.handleColor,
    required this.onChanged,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    if (totalDates <= 1) {
      // Single date - show a simple bar
      return Container(
        height: SizeUtils.h(context, AppDimensions.statsSliderHandleHeight),
        alignment: Alignment.center,
        child: Container(
          height: SizeUtils.h(context, AppDimensions.statsSliderTrackHeight),
          decoration: BoxDecoration(
            color: leftColor,
            borderRadius: BorderRadius.circular(
              SizeUtils.r(context, AppDimensions.statsSliderTrackBorderRadius),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: SizeUtils.h(context, AppDimensions.statsSliderHandleHeight),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          // Handle dimensions from shared constants
          final handleWidth = SizeUtils.w(
            context,
            AppDimensions.statsSliderHandleWidth,
          );
          final handleHeight = SizeUtils.h(
            context,
            AppDimensions.statsSliderHandleHeight,
          );
          final trackHeight = SizeUtils.h(
            context,
            AppDimensions.statsSliderTrackHeight,
          );
          final paddingWidth = SizeUtils.w(
            context,
            AppDimensions.statsSliderPaddingWidth,
          );

          // Total handle area width (padding + handle + padding)
          final totalHandleAreaWidth =
              paddingWidth + handleWidth + paddingWidth;

          // Available track width (total width minus handle area)
          final trackWidth = width - totalHandleAreaWidth;

          // Handle position based on selected index
          final handlePosition = selectedIndex / (totalDates - 1) * trackWidth;

          // Left bar width = handle position
          final leftBarWidth = handlePosition;

          // Right bar width = remaining track width after handle
          final rightBarWidth = trackWidth - handlePosition;

          return GestureDetector(
            onTapDown: (details) {
              _handleInteraction(details.localPosition.dx, width);
            },
            onHorizontalDragUpdate: (details) {
              _handleInteraction(details.localPosition.dx, width);
            },
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Left colored bar (teal for From, green for To)
                Positioned(
                  left: AppDimensions.zero,
                  child: Container(
                    width: leftBarWidth,
                    height: trackHeight,
                    decoration: BoxDecoration(
                      color: leftColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(
                          SizeUtils.r(
                            context,
                            AppDimensions.statsSliderTrackBorderRadius,
                          ),
                        ),
                        bottomLeft: Radius.circular(
                          SizeUtils.r(
                            context,
                            AppDimensions.statsSliderTrackBorderRadius,
                          ),
                        ),
                      ),
                    ),
                    child: _buildDots(
                      selectedIndex,
                      leftBarWidth,
                      type == "From"
                          ? AppColors.white
                          : AppColors.datePickerDotDark,
                      context,
                    ),
                  ),
                ),

                // Right colored bar (green for From, teal for To)
                Positioned(
                  right: 0,
                  child: Container(
                    width: rightBarWidth,
                    height: trackHeight,
                    decoration: BoxDecoration(
                      color: rightColor,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(
                          SizeUtils.r(
                            context,
                            AppDimensions.statsSliderTrackBorderRadius,
                          ),
                        ),
                        bottomRight: Radius.circular(
                          SizeUtils.r(
                            context,
                            AppDimensions.statsSliderTrackBorderRadius,
                          ),
                        ),
                      ),
                    ),
                    child: _buildDots(
                      totalDates - 1 - selectedIndex,
                      rightBarWidth,
                      type == "To"
                          ? AppColors.white
                          : AppColors.datePickerDotDark,
                      context,
                    ),
                  ),
                ),

                // Handle area with transparent padding on sides
                Positioned(
                  left: leftBarWidth,
                  child: SizedBox(
                    width: totalHandleAreaWidth,
                    height: handleHeight,
                    child: Row(
                      children: [
                        // Left transparent padding (same as background)
                        Container(
                          width: paddingWidth,
                          height: trackHeight,
                          color: AppColors.white,
                        ),
                        // Actual handle
                        Container(
                          width: handleWidth,
                          height: handleHeight,
                          decoration: BoxDecoration(
                            color: handleColor,
                            borderRadius: BorderRadius.circular(
                              SizeUtils.r(
                                context,
                                AppDimensions.statsSliderHandleBorderRadius,
                              ),
                            ),
                          ),
                        ),
                        // Right transparent padding (same as background)
                        Container(
                          width: paddingWidth,
                          height: trackHeight,
                          color: AppColors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleInteraction(double localX, double totalWidth) {
    const totalHandleAreaWidth = 16.0; // 6 + 4 + 6
    final trackWidth = totalWidth - totalHandleAreaWidth;

    // Clamp position to track bounds
    final clampedX = localX.clamp(0.0, trackWidth);
    final newIndex = (clampedX / trackWidth * (totalDates - 1)).round().clamp(
      0,
      totalDates - 1,
    );
    onChanged(newIndex);
  }

  Widget _buildDots(
    int dotCount,
    double barWidth,
    Color dotColor,
    BuildContext context,
  ) {
    if (dotCount <= 0 || barWidth < 20) return const SizedBox.shrink();

    // Calculate how many dots fit (4px dot + ~10px spacing)
    final spaceBasedLimit = (barWidth / 14).floor();
    final maxDots = spaceBasedLimit.clamp(0, dotCount);
    if (maxDots <= 0) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeUtils.r(context, AppDimensions.statsSliderDotPadding),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(maxDots, (index) {
          return Container(
            width: SizeUtils.w(context, AppDimensions.statsSliderDotSize),
            height: SizeUtils.h(context, AppDimensions.statsSliderDotSize),
            decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
          );
        }),
      ),
    );
  }
}
