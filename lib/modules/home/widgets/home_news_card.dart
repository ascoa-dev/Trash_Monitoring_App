import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/utils/size_utils.dart';
import 'package:ascoa_app/shared/analytics/analytics_service.dart';

class HomeNewsCard extends StatelessWidget {
  const HomeNewsCard({
    super.key,
    required this.title,
    required this.link,
    required this.image,
    this.isAssetImage = true,
  });

  final String title;
  final String link;
  final String image;
  final bool isAssetImage;

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
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(radius),
                    topRight: Radius.circular(radius),
                    bottomLeft: Radius.circular(radius),
                    bottomRight: Radius.circular(radius),
                  ),
                  child: SizedBox(
                    height: imageHeight,
                    width: double.infinity,
                    child:
                        isAssetImage
                            ? Image.asset(image, fit: BoxFit.cover)
                            : CachedNetworkImage(
                              imageUrl: image,
                              fit: BoxFit.cover,
                              placeholder:
                                  (c, s) => Container(
                                    color: AppColors.newsCardPlaceholder,
                                  ),
                              errorWidget:
                                  (c, s, e) => Container(
                                    color: AppColors.newsCardPlaceholder,
                                    child: const Icon(Icons.broken_image),
                                  ),
                            ),
                  ),
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
