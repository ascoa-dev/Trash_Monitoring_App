import 'package:flutter/material.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';

class NewsSkeletonCard extends StatefulWidget {
  const NewsSkeletonCard({super.key});

  @override
  State<NewsSkeletonCard> createState() => _NewsSkeletonCardState();
}

class _NewsSkeletonCardState extends State<NewsSkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: AppDimensions.shimmerDurationMs),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double radius = SizeUtils.r(context, AppDimensions.newsCardRadius);
    final double cardWidth = SizeUtils.w(context, AppDimensions.newsCardWidth);
    final double imageHeight = SizeUtils.h(
      context,
      AppDimensions.newsCardImageHeight,
      useContentHeight: false,
    );

    return SizedBox(
      width: cardWidth,
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.skeletonBase,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image skeleton
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(radius),
                    topRight: Radius.circular(radius),
                  ),
                  child: Container(
                    height: imageHeight,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.skeletonBase,
                          AppColors.skeletonHighlight.withAlpha(
                            ((AppDimensions.shimmerBaseAlpha +
                                        (_shimmerController.value *
                                            AppDimensions.shimmerRangeAlpha)) *
                                    255)
                                .toInt(),
                          ),
                          AppColors.skeletonBase,
                        ],
                        stops: [
                          AppDimensions.zero,
                          _shimmerController.value,
                          AppDimensions.one,
                        ],
                      ),
                    ),
                  ),
                ),
                // Text skeleton
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeUtils.w(
                      context,
                      AppDimensions.newsCardHorizontalPadding,
                    ),
                    vertical: SizeUtils.h(
                      context,
                      AppDimensions.newsCardVerticalPadding,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: cardWidth * 0.8,
                        height: SizeUtils.h(
                          context,
                          AppDimensions.smallSpacing,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.skeletonShade,
                          borderRadius: BorderRadius.circular(
                            SizeUtils.r(context, AppDimensions.smallRadius),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: SizeUtils.h(
                          context,
                          AppDimensions.smallSpacing,
                        ),
                      ),
                      Container(
                        width: cardWidth * 0.5,
                        height: SizeUtils.h(
                          context,
                          AppDimensions.smallSpacing,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.skeletonShade,
                          borderRadius: BorderRadius.circular(
                            SizeUtils.r(context, AppDimensions.smallRadius),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
