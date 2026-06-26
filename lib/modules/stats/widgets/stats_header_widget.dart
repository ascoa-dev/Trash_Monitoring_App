import 'package:we_monitor/app/controllers/haptic_controller.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:flutter/material.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/constants/app_images.dart';
import 'package:get/get.dart';

class StatsHeaderWidget extends StatelessWidget {
  final VoidCallback onRefresh;

  const StatsHeaderWidget({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SizeUtils.h(context, AppDimensions.statsHeaderHeight),
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              AppImages.cleanupTop,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.textAccent.withValues(alpha: 0.1),
                        AppColors.accentGreen.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Content overlay - positioned at bottom of the image
          Positioned(
            left: SizeUtils.w(context, AppDimensions.zero),
            right: SizeUtils.w(context, AppDimensions.zero),
            bottom: SizeUtils.h(
              context,
              AppDimensions.statsHeaderPositionBottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reports icon and title with refresh button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      AppImages.navStats,
                      width: SizeUtils.w(
                        context,
                        AppDimensions.statsHeaderIconSize,
                      ),
                      height: SizeUtils.h(
                        context,
                        AppDimensions.statsHeaderIconSize,
                      ),
                    ),
                    SizedBox(
                      width: SizeUtils.w(
                        context,
                        AppDimensions.statsHeaderIconSpacing,
                      ),
                    ),
                    Text(
                      AppStrings.statsPageTitle,
                      style: AppTextStyles.statsTitle(context),
                    ),
                    SizedBox(
                      width: SizeUtils.w(
                        context,
                        AppDimensions.statsHeaderRefreshSpacing,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        Get.find<HapticController>().selectionClick();
                        onRefresh();
                      },
                      color: AppColors.textDark,
                      tooltip: AppStrings.statsRefreshTooltip,
                    ),
                  ],
                ),
                SizedBox(
                  height: SizeUtils.h(
                    context,
                    AppDimensions.statsHeaderRefreshSpacing,
                  ),
                ),
                Text(
                  AppStrings.statsSubtitle,
                  style: AppTextStyles.statsMapInfo(context),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
