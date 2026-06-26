import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:we_monitor/app/controllers/haptic_controller.dart';
import 'package:we_monitor/modules/home/widgets/home_news_card.dart';
import 'package:we_monitor/modules/news/controller/news_posts_controller.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_images.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/services/snackbar_service.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  Future<void> _openBlog() async {
    Get.find<HapticController>().selectionClick();
    final Uri url = Uri.parse(AppStrings.newslink);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      SnackbarService.warning(
        AppStrings.newsTitle,
        AppStrings.couldNotOpenNewsLink,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NewsPostsController>(tag: 'news_posts');
    final double padding = SizeUtils.w(context, AppDimensions.screenPadding);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: SizeUtils.h(context, AppDimensions.screenPadding)),
            // Title + a link straight to the full blog page on the website.
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.newsTitle,
                    style: AppTextStyles.dashboardHeading(context),
                  ),
                ),
                GestureDetector(
                  onTap: _openBlog,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppStrings.moreNews,
                        style: AppTextStyles.newsCaption(context),
                      ),
                      SizedBox(width: SizeUtils.w(context, 4)),
                      Icon(
                        Icons.open_in_new,
                        size: SizeUtils.r(context, 16),
                        color: AppTextStyles.newsCaption(context).color,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
              height: SizeUtils.h(
                context,
                AppDimensions.homeScreenNewsSectionSpacing,
              ),
            ),
            Expanded(
              child: Obx(() {
                final posts = controller.posts;
                final isLoading = controller.isLoading.value;
                final hasError = controller.error.value != null;

                if (isLoading && posts.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (hasError && posts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppStrings.failedToLoadNews,
                          style: AppTextStyles.newsBody(context),
                        ),
                        SizedBox(
                          height: SizeUtils.h(
                            context,
                            AppDimensions.homeScreenNewsErrorSpacing,
                          ),
                        ),
                        TextButton(
                          onPressed: controller.loadPosts,
                          child: const Text(AppStrings.retry),
                        ),
                      ],
                    ),
                  );
                }

                if (posts.isEmpty) {
                  return Center(
                    child: Text(
                      AppStrings.noNewsFound,
                      style: AppTextStyles.newsBody(context),
                    ),
                  );
                }

                // ListView.builder + CachedNetworkImage (inside HomeNewsCard)
                // build and fetch each card lazily as it scrolls into view.
                return ListView.separated(
                  padding: EdgeInsets.only(
                    bottom: SizeUtils.h(context, AppDimensions.navBarHeight) * 2,
                  ),
                  itemCount: posts.length,
                  separatorBuilder: (_, _) => SizedBox(
                    height: SizeUtils.h(
                      context,
                      AppDimensions.homeScreenNewsCardSpacing,
                    ),
                  ),
                  itemBuilder: (context, index) {
                    final item = posts[index];
                    final bool isAsset =
                        item.imageUrl == null || item.imageUrl!.isEmpty;
                    return HomeNewsCard(
                      title: item.title,
                      link: item.link,
                      image: isAsset ? AppImages.placeholder : item.imageUrl!,
                      isAssetImage: isAsset,
                      width: double.infinity,
                      squareImage: true,
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
