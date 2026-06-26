import 'package:we_monitor/app/controllers/haptic_controller.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:get/get.dart';

/// Custom Date Picker Widget with Material 3 Design
///
/// Usage Examples:
///
/// 1. With start and end dates:
/// ```dart
/// CustomDatePicker.show(
///   context,
///   startDate: DateTime(2024, 1, 1),
///   endDate: DateTime(2024, 12, 31),
///   initialDate: DateTime.now(),
/// );
/// ```
///
/// 2. With only start date (no past dates):
/// ```dart
/// CustomDatePicker.show(
///   context,
///   startDate: DateTime.now(),
/// );
/// ```
///
/// 3. With only end date (no future dates):
/// ```dart
/// CustomDatePicker.show(
///   context,
///   endDate: DateTime.now(),
/// );
/// ```
class CustomDatePicker extends StatelessWidget {
  final DateTime? initialDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime>? onDateSelected;

  const CustomDatePicker({
    super.key,
    this.initialDate,
    this.startDate,
    this.endDate,
    this.onDateSelected,
  });

  /// Show the date picker as an overlay
  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return showDialog<DateTime>(
      context: context,
      barrierColor: AppColors.black54,
      builder:
          (context) => _DatePickerOverlay(
            initialDate: initialDate ?? DateTime.now(),
            startDate: startDate,
            endDate: endDate,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // No need to build UI; you can just return an empty container
    return const SizedBox.shrink();
  }
}

class _DatePickerOverlay extends StatelessWidget {
  final DateTime initialDate;
  final DateTime? startDate;
  final DateTime? endDate;

  const _DatePickerOverlay({
    required this.initialDate,
    this.startDate,
    this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: SizeUtils.w(
          context,
          AppDimensions.datePickerHorizontalPadding,
        ),
      ),
      child: _DatePickerContent(
        initialDate: initialDate,
        startDate: startDate,
        endDate: endDate,
        onDateSelected: (date) => Navigator.of(context).pop(date),
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _DatePickerContent extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime>? onDateSelected;
  final VoidCallback? onCancel;

  const _DatePickerContent({
    required this.initialDate,
    this.startDate,
    this.endDate,
    this.onDateSelected,
    this.onCancel,
  });

  @override
  State<_DatePickerContent> createState() => _DatePickerContentState();
}

class _DatePickerContentState extends State<_DatePickerContent> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  static const Color _textColor = AppColors.datePickerPrimary;

  final haptics = Get.find<HapticController>();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  // ✅ Date enable check
  bool _isDateEnabled(DateTime date) {
    final onlyDate = DateTime(date.year, date.month, date.day);
    return (widget.startDate == null ||
            !onlyDate.isBefore(widget.startDate!)) &&
        (widget.endDate == null || !onlyDate.isAfter(widget.endDate!));
  }

  // ✅ Navigation boundaries including year logic
  bool get _canGoToPreviousMonth {
    if (widget.startDate == null) return true;
    final lastOfPrev = DateTime(_currentMonth.year, _currentMonth.month, 0);
    return !lastOfPrev.isBefore(widget.startDate!);
  }

  bool get _canGoToNextMonth {
    if (widget.endDate == null) return true;
    final firstOfNext = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      1,
    );
    return !firstOfNext.isAfter(widget.endDate!);
  }

  void _previousMonth() {
    if (_canGoToPreviousMonth) {
      haptics.light();
      setState(() {
        _currentMonth = DateTime(
          _currentMonth.year,
          _currentMonth.month - 1,
          1,
        );
      });
    }
  }

  void _nextMonth() {
    if (_canGoToNextMonth) {
      haptics.light();
      setState(() {
        _currentMonth = DateTime(
          _currentMonth.year,
          _currentMonth.month + 1,
          1,
        );
      });
    }
  }

  // ✅ Year boundary logic
  bool get _canGoToPreviousYear {
    if (widget.startDate == null) return true;
    final lastOfPrevYear = DateTime(_currentMonth.year - 1, 12, 31);
    return !lastOfPrevYear.isBefore(widget.startDate!);
  }

  bool get _canGoToNextYear {
    if (widget.endDate == null) return true;
    final firstOfNextYear = DateTime(_currentMonth.year + 1, 12, 31);
    return !firstOfNextYear.isAfter(widget.endDate!);
  }

  void _previousYear() {
    if (_canGoToPreviousYear) {
      setState(() {
        _currentMonth = DateTime(
          _currentMonth.year - 1,
          _currentMonth.month,
          1,
        );
      });
    }
  }

  void _nextYear() {
    if (_canGoToNextYear) {
      setState(() {
        _currentMonth = DateTime(
          _currentMonth.year + 1,
          _currentMonth.month,
          1,
        );
      });
    }
  }

  void _selectDate(DateTime date) {
    if (_isDateEnabled(date)) {
      haptics.selectionClick();
      setState(() => _selectedDate = date);
    }
  }

  void _confirmSelection() {
    haptics.medium();
    widget.onDateSelected?.call(_selectedDate);
  }

  // ✅ Gesture handling: swipe left/right to change month
  void _onHorizontalSwipe(DragEndDetails details) {
    if (details.primaryVelocity == null) return;
    if (details.primaryVelocity! < 0) {
      haptics.light();
      _nextMonth();
    } else if (details.primaryVelocity! > 0) {
      haptics.light();
      _previousMonth();
    }
  }

  void _showMonthDropdown() async {
    haptics.selectionClick();
    _removeDropdown();

    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    // Get the position of the month button
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);

    final selectedMonth = await showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx +
            AppDimensions
                .datePickerMenuOffsetX1, // approximate button x position
        offset.dy + AppDimensions.datePickerMenuOffsetY1, // closer to button
        offset.dx + AppDimensions.datePickerMenuOffsetX2,
        offset.dy + AppDimensions.datePickerMenuOffsetY2,
      ),
      constraints: BoxConstraints(
        maxHeight: SizeUtils.h(
          context,
          AppDimensions.datePickerMenuMaxHeight,
        ), // ~5 items
      ),
      color: AppColors.background,
      items: List.generate(12, (i) {
        final monthDate = DateTime(_currentMonth.year, i + 1, 1);
        final isEnabled = _isDateEnabled(monthDate);
        return PopupMenuItem<int>(
          value: i + 1,
          enabled: isEnabled,
          child: Text(
            months[i],
            style: AppTextStyles.datePickerMenuItem(context).copyWith(
              color:
                  isEnabled
                      ? _textColor
                      : AppColors.datePickerPrimaryDisabled38,
            ),
          ),
        );
      }),
      elevation: 4,
    );

    if (selectedMonth != null && mounted) {
      setState(() {
        _currentMonth = DateTime(_currentMonth.year, selectedMonth, 1);
      });
    }
  }

  void _showYearDropdown() async {
    haptics.selectionClick();
    _removeDropdown();

    final currentYear = _currentMonth.year;
    final startYear = widget.startDate?.year ?? currentYear - 50;
    final endYear = widget.endDate?.year ?? currentYear + 50;

    // Get the position of the year button
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);

    final selectedYear = await showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx +
            AppDimensions
                .datePickerMenuOffsetYearX1, // approximate button x position
        offset.dy + AppDimensions.datePickerMenuOffsetY1, // closer to button
        offset.dx + AppDimensions.datePickerMenuOffsetYearRight,
        offset.dy + AppDimensions.datePickerMenuOffsetY2,
      ),
      constraints: BoxConstraints(
        maxHeight: SizeUtils.h(
          context,
          AppDimensions.datePickerMenuMaxHeight,
        ), // ~5 items
      ),
      color: AppColors.background,
      items: List.generate(endYear - startYear + 1, (i) {
        final year = startYear + i;
        final yearDate = DateTime(year, _currentMonth.month, 1);
        final isEnabled = _isDateEnabled(yearDate);
        return PopupMenuItem<int>(
          value: year,
          enabled: isEnabled,
          child: Text(
            year.toString(),
            style: AppTextStyles.datePickerMenuItem(context).copyWith(
              fontWeight:
                  year == currentYear ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }),
      elevation: 4,
    );

    if (selectedYear != null && mounted) {
      final newMonth = DateTime(selectedYear, _currentMonth.month, 1);
      if (_isDateEnabled(newMonth)) {
        setState(() => _currentMonth = newMonth);
      }
    }
  }

  void _removeDropdown() {
    // No longer needed with showMenu approach
  }

  List<DateTime> _getDaysInMonth() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday % 7;

    final days = <DateTime>[];

    // Previous month trailing days
    for (int i = firstWeekday; i > 0; i--) {
      days.add(firstDay.subtract(Duration(days: i)));
    }

    // Current month days
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i));
    }

    // Fill remaining
    final remainingDays = (7 - (days.length % 7)) % 7;
    for (int i = 1; i <= remainingDays; i++) {
      days.add(lastDay.add(Duration(days: i)));
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    final monthName = _getMonthName(_currentMonth.month);
    final year = _currentMonth.year;
    final days = _getDaysInMonth();

    return GestureDetector(
      onHorizontalDragEnd: _onHorizontalSwipe,
      child: Container(
        width: SizeUtils.w(context, AppDimensions.datePickerWidth),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(
            SizeUtils.r(context, AppDimensions.datePickerBorderRadius),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              height: SizeUtils.h(
                context,
                AppDimensions.datePickerHeaderHeight,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: SizeUtils.w(
                  context,
                  AppDimensions.datePickerHorizontalPadding,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Month Selector
                  Row(
                    children: [
                      _IconButton(
                        icon: Icons.chevron_left,
                        onPressed:
                            _canGoToPreviousMonth ? _previousMonth : null,
                        disabled: !_canGoToPreviousMonth,
                      ),
                      _MenuButton(
                        label: monthName,
                        onPressed: _showMonthDropdown,
                      ),
                      _IconButton(
                        icon: Icons.chevron_right,
                        onPressed: _canGoToNextMonth ? _nextMonth : null,
                        disabled: !_canGoToNextMonth,
                      ),
                    ],
                  ),
                  // Year Selector
                  // ✅ Fixed Year Selector
                  Row(
                    children: [
                      _IconButton(
                        icon: Icons.chevron_left,
                        onPressed: _canGoToPreviousYear ? _previousYear : null,
                        disabled: !_canGoToPreviousYear,
                      ),
                      _MenuButton(
                        label: year.toString(),
                        onPressed: _showYearDropdown,
                      ),
                      _IconButton(
                        icon: Icons.chevron_right,
                        onPressed: _canGoToNextYear ? _nextYear : null,
                        disabled: !_canGoToNextYear,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Calendar grid (same as before)
            Padding(
              padding: EdgeInsets.fromLTRB(
                SizeUtils.w(context, AppDimensions.datePickerHorizontalPadding),
                AppDimensions.zero,
                SizeUtils.w(context, AppDimensions.datePickerHorizontalPadding),
                SizeUtils.h(context, AppDimensions.datePickerVerticalPadding),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: SizeUtils.h(
                      context,
                      AppDimensions.datePickerMenuItemHeight,
                    ),
                    child: Row(
                      children:
                          ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                              .map(
                                (day) => Expanded(
                                  child: Center(
                                    child: Text(
                                      day,
                                      style: AppTextStyles.datePickerMenuItem(
                                        context,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                  ...List.generate(
                    (days.length / 7).ceil(),
                    (weekIndex) => SizedBox(
                      height: SizeUtils.h(
                        context,
                        AppDimensions.datePickerDaySize,
                      ),
                      child: Row(
                        children: List.generate(7, (dayIndex) {
                          final index = weekIndex * 7 + dayIndex;
                          if (index >= days.length) {
                            return const Expanded(child: SizedBox());
                          }
                          final date = days[index];
                          final isCurrentMonth =
                              date.month == _currentMonth.month;
                          final isSelected =
                              date.year == _selectedDate.year &&
                              date.month == _selectedDate.month &&
                              date.day == _selectedDate.day;
                          final isEnabled = _isDateEnabled(date);
                          return Expanded(
                            child: _DayCell(
                              date: date,
                              isCurrentMonth: isCurrentMonth,
                              isSelected: isSelected,
                              isEnabled: isEnabled,
                              onTap: () => _selectDate(date),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Buttons (same)
            Container(
              height: SizeUtils.h(
                context,
                AppDimensions.datePickerButtonHeight,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: SizeUtils.w(
                  context,
                  AppDimensions.datePickerHorizontalPadding,
                ),
                vertical: SizeUtils.h(context, AppDimensions.cleanupSpacing4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _TextButton(
                    label: AppStrings.cancel,
                    onPressed: () {
                      haptics.selectionClick();
                      widget.onCancel?.call();
                    },
                  ),
                  SizedBox(
                    width: SizeUtils.w(context, AppDimensions.smallSpacing),
                  ),
                  _TextButton(
                    label: AppStrings.ok,
                    onPressed: _confirmSelection,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool disabled;

  const _IconButton({
    required this.icon,
    this.onPressed,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: SizeUtils.w(
        context,
        AppDimensions.datePickerHeaderIconContainerSize,
      ),
      height: SizeUtils.h(
        context,
        AppDimensions.datePickerHeaderIconContainerSize,
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(
            SizeUtils.r(context, AppDimensions.datePickerHeaderIconSize),
          ),
          child: Center(
            child: Icon(
              icon,
              size: SizeUtils.r(
                context,
                AppDimensions.datePickerHeaderIconSize,
              ),
              color:
                  disabled
                      ? AppColors.datePickerPrimaryDisabled30
                      : AppColors.datePickerPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _MenuButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(
          SizeUtils.r(context, AppDimensions.datePickerBorderRadius),
        ),
        child: Container(
          height: SizeUtils.h(context, AppDimensions.datePickerMenuItemHeight),
          padding: EdgeInsets.fromLTRB(
            SizeUtils.w(context, AppDimensions.smallSpacing),
            SizeUtils.h(context, AppDimensions.datePickerMenuVerticalPadding),
            SizeUtils.w(context, AppDimensions.cleanupSpacing4),
            SizeUtils.h(context, AppDimensions.datePickerMenuVerticalPadding),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: AppTextStyles.datePickerMenuItem(context)),
              SizedBox(width: SizeUtils.w(context, AppDimensions.smallSpacing)),
              Icon(
                Icons.arrow_drop_down,
                size: SizeUtils.r(
                  context,
                  AppDimensions.datePickerMenuIconSize,
                ),
                color: AppColors.datePickerPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final bool isCurrentMonth;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _DayCell({
    required this.date,
    required this.isCurrentMonth,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color:
            isSelected ? AppColors.datePickerSelected : AppColors.transparent,
        borderRadius: BorderRadius.circular(
          SizeUtils.r(context, AppDimensions.datePickerDaySize / 2),
        ),
        child: InkWell(
          onTap: isEnabled && isCurrentMonth ? onTap : null,
          borderRadius: BorderRadius.circular(
            SizeUtils.r(context, AppDimensions.datePickerDaySize / 2),
          ),
          child: Container(
            width: SizeUtils.w(context, AppDimensions.datePickerDaySize),
            height: SizeUtils.h(context, AppDimensions.datePickerDaySize),
            alignment: Alignment.center,
            child: Text(
              date.day.toString(),
              style: AppTextStyles.datePickerDay(context).copyWith(
                color:
                    isSelected
                        ? AppColors.pureWhite
                        : (isCurrentMonth && isEnabled)
                        ? AppColors.datePickerPrimary
                        : AppColors.datePickerPrimaryDisabled38,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TextButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _TextButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(
          SizeUtils.r(context, AppDimensions.datePickerBorderRadius),
        ),
        child: Container(
          height: SizeUtils.h(
            context,
            AppDimensions.datePickerTextButtonHeight,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: SizeUtils.w(
              context,
              AppDimensions.datePickerTextButtonHorizontalPadding,
            ),
            vertical: SizeUtils.h(
              context,
              AppDimensions.datePickerTextButtonVerticalPadding,
            ),
          ),
          child: Center(
            child: Text(label, style: AppTextStyles.datePickerButton(context)),
          ),
        ),
      ),
    );
  }
}
