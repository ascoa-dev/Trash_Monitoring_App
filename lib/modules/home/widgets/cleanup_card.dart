import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:we_monitor/app/models/cleanup_model.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_images.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:we_monitor/shared/widgets/user_byline.dart';

class CleanupCard extends StatelessWidget {
  const CleanupCard({
    super.key,
    required this.cleanup,
    required this.onTap,
    this.width,
  });

  final CleanupModel cleanup;
  final VoidCallback onTap;
  final double? width;

  String _formatDate() {
    final dt = cleanup.createdAt;
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
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
    final bool hasPhoto = cleanup.photoUrls?.isNotEmpty == true;

    return SizedBox(
      width: cardWidth,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
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
                  child: SizedBox(
                    height: imageHeight,
                    width: double.infinity,
                    child:
                        hasPhoto
                            ? CachedNetworkImage(
                              imageUrl: cleanup.photoUrls!.first,
                              fit: BoxFit.cover,
                              memCacheWidth: 600,
                              memCacheHeight: 400,
                              placeholder: (c, s) => _placeholder(),
                              errorWidget: (c, s, e) => _placeholder(),
                            )
                            : _placeholder(),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeUtils.w(
                      context,
                      AppDimensions.otherCardHorizontalPadding,
                    ),
                    vertical: SizeUtils.h(
                      context,
                      AppDimensions.otherCardVerticalPadding,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cleanup.groupName,
                        style: AppTextStyles.newsBody(context).copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${cleanup.peopleCount} people · ${cleanup.totalWeight.toStringAsFixed(1)} kg . ${_formatDate()}',
                        style: AppTextStyles.bodySecondary(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: SizeUtils.h(context, 3)),
                      UserByline(userId: cleanup.userId),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFEFF6E5),
      child: Center(
        child: Image.asset(
          AppImages.hotspotPlaceholder,
          fit: BoxFit.contain,
          width: 64,
          height: 64,
        ),
      ),
    );
  }
}
