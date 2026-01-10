import 'package:ascoa_app/app/controllers/haptic_controller.dart';
import 'package:ascoa_app/shared/utils/size_utils.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:get/get.dart';

class _StackMeta {
  final String label;
  final int value;
  final Color color;
  const _StackMeta(this.label, this.value, this.color);
}

class WasteChartWidget extends StatefulWidget {
  final Map<String, Map<String, int>> chartData;
  const WasteChartWidget({super.key, required this.chartData});

  // Define all categories to display consistently - must match trash_template.json names
  static const List<String> allCategories = [
    'Most Likely Items to Find',
    'Fishing Gear',
    'Tiny Trash (<2.5 cm)',
    'Packaging Materials',
    'Personal Hygiene',
    'Items of Local Concern',
    'Other Trash',
  ];

  @override
  State<WasteChartWidget> createState() => _WasteChartWidgetState();
}

class _WasteChartWidgetState extends State<WasteChartWidget> {
  int? _touchedStackIndex;
  int? _touchedGroupIndex;
  Offset? _tooltipPosition;
  bool _isHolding = false; // Track if user is holding down
  final Map<int, List<_StackMeta>> _stackMetaByGroup = {};

  // fl_chart exposes the touched stack index on the touched spot, but the
  // exact field name has varied between versions. Probe a few likely names
  // safely and return the first that works.
  int? _extractTouchedStackIndex(dynamic spot) {
    if (spot == null) return null;
    try {
      return spot.touchedRodStackItemIndex as int?;
    } catch (_) {}
    try {
      return spot.touchedBarStackItemIndex as int?;
    } catch (_) {}
    try {
      return spot.touchedStackItemIndex as int?;
    } catch (_) {}
    try {
      return spot.touchedStackIndex as int?;
    } catch (_) {}
    try {
      return spot.stackIndex as int?;
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: AppDimensions.statsChartAspectRatio,
      child: Padding(
        padding: EdgeInsets.all(
          SizeUtils.h(context, AppDimensions.statsChartPadding),
        ),
        child: Stack(
          children: [
            BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                maxY: _getMaxY(),
                barTouchData: BarTouchData(
                  enabled: true,
                  handleBuiltInTouches: false,
                  touchCallback: (event, response) {
                    // Check if this is a touch end event
                    if (event is FlPanEndEvent ||
                        event is FlPanCancelEvent ||
                        event is FlTapUpEvent ||
                        event is FlLongPressEnd) {
                      setState(() {
                        _isHolding = false;
                        _touchedStackIndex = null;
                        _touchedGroupIndex = null;
                        _tooltipPosition = null;
                      });
                      return;
                    }

                    final spot = response?.spot;

                    if (spot != null) {
                      final idx = _extractTouchedStackIndex(spot);
                      if (!_isHolding) {
                        Get.find<HapticController>().selectionClick();
                      }
                      setState(() {
                        _isHolding = true;
                        _touchedStackIndex = idx;
                        _touchedGroupIndex = spot.touchedBarGroupIndex;
                        _tooltipPosition = event.localPosition;
                      });
                    }
                  },

                  touchTooltipData: BarTouchTooltipData(
                    // Disable fl_chart's built-in tooltip rendering
                    getTooltipItem: (group, groupIndex, rod, rodIndex) => null,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() <
                                WasteChartWidget.allCategories.length) {
                          return Padding(
                            padding: EdgeInsets.only(
                              top: SizeUtils.h(
                                context,
                                AppDimensions.statsChartLabelTopPadding,
                              ),
                            ),
                            child: SizedBox(
                              width: SizeUtils.w(
                                context,
                                AppDimensions.statsChartLabelWidth,
                              ),
                              child: Text(
                                _abbreviateCategory(
                                  WasteChartWidget.allCategories[value.toInt()],
                                ),
                                style: AppTextStyles.statsChartLabel(context),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: SizeUtils.h(
                        context,
                        AppDimensions.statsChartBottomReservedSize,
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: _getYInterval(),
                      getTitlesWidget: (value, meta) {
                        // Only show labels at intervals
                        if (value % _getYInterval() == 0) {
                          return Text(
                            value.toInt().toString(),
                            style: AppTextStyles.statsChartLabel(context),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: SizeUtils.h(
                        context,
                        AppDimensions.statsChartLeftReservedSize,
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _getYInterval(),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.grey.withValues(alpha: 0.2),
                      strokeWidth: SizeUtils.h(
                        context,
                        AppDimensions.statsChartGridStrokeWidth,
                      ),
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: _buildBarGroups(),
              ),
            ),
            // Per-segment labels with cutoff (value >= 5)
            _buildNumbersOverlay(),
            // Legend overlay in top-right corner
            Positioned(
              top: SizeUtils.h(
                context,
                AppDimensions.statsChartLegendTopOffset,
              ),
              right: SizeUtils.w(
                context,
                AppDimensions.statsChartLegendRightOffset,
              ),
              child: IgnorePointer(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeUtils.w(
                      context,
                      AppDimensions.statsChartLegendPaddingHorizontal,
                    ),
                    vertical: SizeUtils.h(
                      context,
                      AppDimensions.statsChartLegendPaddingVertical,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(
                      SizeUtils.r(
                        context,
                        AppDimensions.statsChartLegendBorderRadius,
                      ),
                    ),
                    border: Border.all(
                      color: AppColors.grey.withValues(alpha: 0.3),
                      width: SizeUtils.h(
                        context,
                        AppDimensions.statsChartLegendBorderWidth,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LegendItem(
                        color: AppColors.statsChartFreshwater,
                        label: AppStrings.environmentFreshwater,
                      ),
                      SizedBox(
                        height: SizeUtils.h(
                          context,
                          AppDimensions.statsChartLegendItemSpacing,
                        ),
                      ),
                      _LegendItem(
                        color: AppColors.statsChartLand,
                        label: AppStrings.environmentLand,
                      ),
                      SizedBox(
                        height: SizeUtils.h(
                          context,
                          AppDimensions.statsChartLegendItemSpacing,
                        ),
                      ),
                      _LegendItem(
                        color: AppColors.statsChartSaltwater,
                        label: AppStrings.environmentSaltwater,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Custom tooltip overlay - only show while holding
            if (_isHolding &&
                _touchedStackIndex != null &&
                _touchedGroupIndex != null &&
                _tooltipPosition != null)
              _buildCustomTooltip(),
          ],
        ),
      ),
    );
  }

  // � Per-segment labels with hard cutoff (value >= 5)
  Widget _buildNumbersOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartWidth =
            constraints.maxWidth -
            SizeUtils.w(context, AppDimensions.statsChartLeftReservedSize);
        final chartHeight =
            constraints.maxHeight -
            SizeUtils.h(context, AppDimensions.statsChartBottomReservedSize) -
            SizeUtils.h(context, AppDimensions.statsChartPadding);
        final barWidth = SizeUtils.w(context, AppDimensions.statsChartBarWidth);
        final numBars = WasteChartWidget.allCategories.length;
        final spacing = chartWidth / numBars;
        final maxY = _getMaxY();

        final allSegments = <Widget>[];

        for (int index = 0; index < numBars; index++) {
          final category = WasteChartWidget.allCategories[index];
          final data = widget.chartData[category] ?? {};
          final saltwater = data['Saltwater'] ?? 0;
          final freshwater = data['Freshwater'] ?? 0;
          final land = data['Land'] ?? 0;

          double runningTotal = 0;

          void addSegmentLabel(int value, Color bgColor) {
            if (value <= 0) return;
            if (value < 5) return; // 🥈 Hard cutoff: only show if >= 5

            final segmentHeight = (value / maxY) * chartHeight;
            final segmentBottom = runningTotal;
            final segmentTop = runningTotal + segmentHeight;

            final bool showInside = segmentHeight > 20;

            final yPosition =
                showInside
                    ? SizeUtils.h(context, AppDimensions.statsChartPadding) +
                        chartHeight -
                        (segmentBottom + segmentTop) / 2
                    : SizeUtils.h(context, AppDimensions.statsChartPadding) +
                        chartHeight -
                        segmentTop -
                        SizeUtils.h(context, AppDimensions.statsChartBarsGap);
            allSegments.add(
              Positioned(
                left:
                    SizeUtils.w(
                      context,
                      AppDimensions.statsChartLeftReservedSize,
                    ) +
                    index * spacing +
                    (spacing - barWidth) / 2,
                top: yPosition - 12,
                width: barWidth,
                child: Center(
                  child: Text(
                    value.toString(),
                    style: AppTextStyles.statsChartBars(context),
                  ),
                ),
              ),
            );

            runningTotal += segmentHeight;
          }

          addSegmentLabel(saltwater, AppColors.statsChartSaltwater);
          addSegmentLabel(freshwater, AppColors.statsChartFreshwater);
          addSegmentLabel(land, AppColors.statsChartLand);
        }

        return IgnorePointer(child: Stack(children: allSegments));
      },
    );
  }

  Widget _buildCustomTooltip() {
    final groupIndex = _touchedGroupIndex!;
    final stackIndex = _touchedStackIndex!;
    final position = _tooltipPosition!;

    // Guard against invalid stack indices
    if (stackIndex < 0) return const SizedBox.shrink();

    final metas = _stackMetaByGroup[groupIndex];
    if (metas == null || stackIndex >= metas.length) {
      return const SizedBox.shrink();
    }

    final meta = metas[stackIndex];

    return Positioned(
      left: position.dx,
      top: position.dy - 60, // Position above touch point
      child: IgnorePointer(
        child: FractionalTranslation(
          translation: const Offset(-0.5, 0), // Center horizontally
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: SizeUtils.w(context, 12),
              vertical: SizeUtils.h(context, 8),
            ),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(SizeUtils.h(context, 4)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  meta.label,
                  style: AppTextStyles.statsActivityTooltip(
                    context,
                  ).copyWith(color: Colors.white),
                ),
                Text(
                  '${meta.value} items',
                  style: AppTextStyles.statsActivityTooltip(
                    context,
                  ).copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(WasteChartWidget.allCategories.length, (index) {
      final category = WasteChartWidget.allCategories[index];
      final data = widget.chartData[category] ?? {};
      final freshwater = (data['Freshwater'] ?? 0).toDouble();
      final saltwater = (data['Saltwater'] ?? 0).toDouble();
      final land = (data['Land'] ?? 0).toDouble();

      double runningTotal = 0;
      final stackItems = <BarChartRodStackItem>[];
      final metas = <_StackMeta>[];

      void addSegment(double value, String label, Color color) {
        if (value <= 0) return;
        stackItems.add(
          BarChartRodStackItem(runningTotal, runningTotal + value, color),
        );
        metas.add(_StackMeta(label, value.toInt(), color));
        runningTotal += value;
      }

      addSegment(
        saltwater,
        AppStrings.environmentSaltwater,
        AppColors.statsChartSaltwater,
      );
      addSegment(
        freshwater,
        AppStrings.environmentFreshwater,
        AppColors.statsChartFreshwater,
      );
      addSegment(land, AppStrings.environmentLand, AppColors.statsChartLand);

      _stackMetaByGroup[index] = metas;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: runningTotal,
            color: AppColors.transparent,
            width: SizeUtils.w(context, AppDimensions.statsChartBarWidth),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(
                SizeUtils.h(context, AppDimensions.statsChartBarBorderRadius),
              ),
            ),
            rodStackItems: stackItems,
          ),
        ],
      );
    });
  }

  double _getMaxY() {
    double max = 0;
    for (final category in WasteChartWidget.allCategories) {
      final data = widget.chartData[category] ?? {};
      final total =
          (data['Freshwater'] ?? 0) +
          (data['Saltwater'] ?? 0) +
          (data['Land'] ?? 0);
      if (total > max) max = total.toDouble();
    }
    // Better scaling for small values
    if (max <= 1) return 2; // For single items
    if (max <= 2) return 3;
    if (max <= 5) return 5;
    if (max <= 10) return 10;
    if (max <= 20) return 20;
    if (max <= 50) return 50;
    return ((max / 10).ceil() * 10).toDouble();
  }

  double _getYInterval() {
    final maxY = _getMaxY();
    if (maxY <= 2) return 1; // Show 0, 1, 2
    if (maxY <= 5) return 1;
    if (maxY <= 10) return 2;
    if (maxY <= 20) return 5;
    if (maxY <= 50) return 10;
    return (maxY / 5).ceilToDouble();
  }

  String _abbreviateCategory(String category) {
    // Break category names into multiple lines for better display
    switch (category) {
      case 'Most Likely Items to Find':
        return 'Most\nLikely';
      case 'Fishing Gear':
        return 'Fishing\nGear';
      case 'Tiny Trash (<2.5 cm)':
        return 'Tiny\nTrash';
      case 'Packaging Materials':
        return 'Packaging';
      case 'Personal Hygiene':
        return 'Personal\nHygiene';
      case 'Items of Local Concern':
        return 'Local\nConcern';
      case 'Other Trash':
        return 'Other\nTrash';
      default:
        return category;
    }
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: SizeUtils.w(context, AppDimensions.statsChartLegendIconSize),
          height: SizeUtils.h(context, AppDimensions.statsChartLegendIconSize),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(
              SizeUtils.r(
                context,
                AppDimensions.statsLegendItemIconBorderRadius,
              ),
            ),
          ),
        ),
        SizedBox(
          width: SizeUtils.w(context, AppDimensions.statsChartLegendSpacing),
        ),
        Text(label, style: AppTextStyles.statsChartLegend(context)),
      ],
    );
  }
}
