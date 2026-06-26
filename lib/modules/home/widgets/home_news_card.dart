import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:we_monitor/shared/analytics/analytics_service.dart';

class HomeNewsCard extends StatelessWidget {
  const HomeNewsCard({
    super.key,
    required this.title,
    required this.link,
    required this.image,
    this.isAssetImage = true,
    this.width,
    this.squareImage = false,
  });

  final String title;
  final String link;
  final String image;
  final bool isAssetImage;

  /// Card width. Null falls back to the fixed home-carousel width; pass
  /// `double.infinity` for full-width stacked cards (news tab).
  final double? width;

  /// When true, the image area is a 1:1 box and the photo is shown in full
  /// (BoxFit.contain) over the app background — nothing cropped (news tab).
  final bool squareImage;

  static double estimatedHeight(BuildContext context) {
    final double imageHeight = SizeUtils.h(
      context,
      AppDimensions.newsCardImageHeight,
      useContentHeight: false,
    );
    final double textSectionHeight = SizeUtils.h(
      context,
      AppDimensions.newsCardTextSectionHeight,
      useContentHeight: false,
    );
    return imageHeight + textSectionHeight;
  }

  Future<void> _openLink() async {
    Analytics.track(AnalyticsEvents.newsArticleClicked, {
      AnalyticsProps.articleTitle: title,
      AnalyticsProps.articleUrl: link,
    });
    final Uri uri = Uri.parse(link);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $link');
    }
  }

  /// Image area. News tab: shorter box, full photo (contain) on a green
  /// letterbox fill. Home carousel: fixed-height cover crop (unchanged).
  Widget _buildImage(BuildContext context, double imageHeight) {
    final BoxFit fit = squareImage ? BoxFit.contain : BoxFit.cover;
    final Widget photo =
        isAssetImage
            ? Image.asset(image, fit: fit)
            : CachedNetworkImage(
              imageUrl: image,
              fit: fit,
              placeholder:
                  (c, s) => Container(color: AppColors.newsCardPlaceholder),
              errorWidget:
                  (c, s, e) => Container(
                    color: AppColors.newsCardPlaceholder,
                    child: const Icon(Icons.broken_image),
                  ),
            );

    if (squareImage) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          width: double.infinity,
          color: const Color.fromARGB(255, 231, 250, 227),
          child: photo,
        ),
      );
    }
    return SizedBox(height: imageHeight, width: double.infinity, child: photo);
  }

  @override
  Widget build(BuildContext context) {
    final double radius = SizeUtils.r(context, AppDimensions.newsCardRadius);
    final double cardWidth =
        width ?? SizeUtils.w(context, AppDimensions.newsCardWidth);
    final double imageHeight = SizeUtils.h(
      context,
      AppDimensions.newsCardImageHeight,
      useContentHeight: false,
    );

    return SizedBox(
      width: cardWidth,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: _openLink,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: _buildImage(context, imageHeight),
                ),
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
                  child: Text(
                    title,
                    style: AppTextStyles.newsBody(context).copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
