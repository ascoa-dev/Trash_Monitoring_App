import 'package:ascoa_app/app/controllers/haptic_controller.dart';
import 'package:ascoa_app/modules/stats/controllers/stats_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ascoa_app/app/controllers/auth_controller.dart';
import 'package:ascoa_app/shared/services/snackbar_service.dart';
import 'package:ascoa_app/app/models/user.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_images.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/utils/size_utils.dart';
import 'package:ascoa_app/shared/widgets/auth_header.dart';
import 'package:ascoa_app/shared/widgets/primary_button.dart';
import 'package:ascoa_app/app/routes/app_routes.dart';
import 'package:ascoa_app/modules/home/widgets/home_news_card.dart';
import 'package:ascoa_app/modules/home/widgets/news_skeleton_card.dart';
import 'package:ascoa_app/modules/home/controller/posts_controller.dart';
import 'package:ascoa_app/modules/main/controllers/main_nav_controller.dart';
import 'package:ascoa_app/shared/services/spotlight_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ascoa_app/modules/profile/widgets/full_image_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AuthController _authController;
  late final PageController _highlightController;

  // Spotlight images loaded from the Firebase Storage `spotlight/` folder
  // (managed by admins on the website). Empty until loaded; if it stays empty
  // the highlights section is not rendered.
  List<String> _spotlightUrls = [];

  late final HomePostsController _postsController;
  late final StatsController _statsController;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
    _highlightController = PageController(
      viewportFraction: AppDimensions.homeScreenHighlightViewportFraction,
    );

    // Get controller from binding (lazily initialized)
    _postsController = Get.find<HomePostsController>(tag: 'home_posts');

    // Load posts once on init — home shows only the latest few.
    _postsController.loadPosts(perPage: 4);
    _statsController = Get.find<StatsController>(tag: 'stats_controller');

    _loadSpotlightImages();
  }

  Future<void> _loadSpotlightImages() async {
    final urls = await SpotlightService.fetchImageUrls();
    if (!mounted) return;
    setState(() => _spotlightUrls = urls);
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ===== FINE-TUNING CONTROLS =====
    // Adjust these values to match Figma exactly
    final double horizontalPadding = SizeUtils.w(
      context,
      AppDimensions.screenPadding,
    );
    // Gap between news section and blog button

    // Bottom section positioning (Figma: 137px from bottom of blog button to screen bottom)
    final double blogButtonToScreenBottom = SizeUtils.h(
      context,
      AppDimensions.homeScreenBottomGap,
      useContentHeight: false,
    ); // Space after blog button
    // ===== END FINE-TUNING CONTROLS =====

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Stack(
          children: [
            // Bottom graphic FIRST (painted behind everything)
            Positioned(
              left: AppDimensions.zero,
              right: AppDimensions.zero,
              bottom: AppDimensions.zero,
              child: _buildBottomGraphic(context),
            ),
            // Content column SECOND (painted on top)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroSection(context),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStartCleanupCard(context),
                      SizedBox(
                        height: SizeUtils.h(
                          context,
                          AppDimensions.homeScreenStatsGap,
                        ),
                      ),
                      _buildStats(context),
                      SizedBox(
                        height: SizeUtils.h(
                          context,
                          AppDimensions.homeScreenStatsGap,
                        ),
                      ),
                      // Highlights section only renders when the spotlight
                      // folder has images.
                      if (_spotlightUrls.isNotEmpty) ...[
                        _buildHighlightsSection(context),
                        SizedBox(
                          height: SizeUtils.h(
                            context,
                            AppDimensions.homeScreenCarouselGap,
                          ),
                        ),
                      ],
                      _buildNewsSection(context),
                      SizedBox(
                        height: SizeUtils.h(
                          context,
                          AppDimensions.homeScreenButtonGap,
                        ),
                      ),
                      _buildBlogCard(context),
                      SizedBox(
                        height: SizeUtils.h(context, blogButtonToScreenBottom),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final double welcomeTop = SizeUtils.h(
      context,
      AppDimensions.homeScreenWelcomeTop,
      useContentHeight: false,
    );
    final double headerTop = SizeUtils.h(
      context,
      AppDimensions.homeScreenHeaderTop,
      useContentHeight: false,
    );
    final double headerHeight = SizeUtils.h(
      context,
      AppDimensions.homeScreenHeaderHeight,
      useContentHeight: false,
    );
    final double heroHeight =
        headerTop +
        headerHeight +
        SizeUtils.h(
          context,
          AppDimensions.homeScreenSpacer,
          useContentHeight: false,
        );
    final double avatarSize = SizeUtils.r(
      context,
      AppDimensions.dashboardAvatarSize,
    );
    final double spacer = SizeUtils.w(context, AppDimensions.homeScreenSpacer);
    final double horizontalPadding = SizeUtils.w(
      context,
      AppDimensions.screenPadding,
    );

    return SizedBox(
      height: heroHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppImages.dashboardTop,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned(
            top: welcomeTop,
            left: horizontalPadding,
            right: horizontalPadding,
            child: Obx(() {
              final UserModel? user = _authController.currentUserModel.value;
              final String displayName = _displayName(user);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Welcome back, $displayName!',
                          style: AppTextStyles.dashboardGreeting(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: spacer),
                  _buildAvatar(context, avatarSize),
                ],
              );
            }),
          ),
          Positioned(
            top: headerTop,
            left: AppDimensions.zero,
            right: AppDimensions.zero,
            child: Center(child: AuthHeader(scale: _authHeaderScale(context))),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, double size) {
    return Obx(() {
      final user = _authController.currentUserModel.value;
      final thumbUrl = user?.thumbUrl;
      final avatarUrl = user?.avatarUrl;

      final previewUrl = avatarUrl ?? thumbUrl;
      final fullUrl = avatarUrl;

      return GestureDetector(
        onTap: () {
          if (fullUrl != null && fullUrl.isNotEmpty) {
            Get.find<HapticController>().selectionClick();
            final normalized = _normalizeCacheBustedUrl(fullUrl);
            FullImageOverlay.show(
              context,
              imageUrl: normalized,
              placeholderAsset: AppImages.profilePlaceholder,
            );
          }
        },
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.profileAvatarBackground,
          ),
          child: ClipOval(
            child:
                previewUrl != null && previewUrl.isNotEmpty
                    ? CachedNetworkImage(
                      imageUrl: _normalizeCacheBustedUrl(previewUrl),
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            color: AppColors.profileAvatarBackground,
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.buttonGreen,
                                ),
                              ),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Image.asset(
                            AppImages.profilePlaceholder,
                            fit: BoxFit.cover,
                          ),
                    )
                    : Image.asset(
                      AppImages.profilePlaceholder,
                      fit: BoxFit.cover,
                    ),
          ),
        ),
      );
    });
  }

  static String _normalizeCacheBustedUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final params = Map<String, String>.from(uri.queryParameters);

      final token = params['token'];
      if (token != null && token.contains('?v=')) {
        final parts = token.split('?v=');
        params['token'] = parts.first;
        if (parts.length > 1 && !params.containsKey('v')) {
          params['v'] = parts.last;
        }
      }

      if (!params.containsKey('v') && url.contains('?v=')) {
        final suffix = url.split('?v=').last;
        if (suffix.isNotEmpty && !suffix.contains('&')) {
          params['v'] = suffix;
        }
      }

      if (params.isEmpty) {
        return url;
      }

      return uri.replace(queryParameters: params).toString();
    } catch (_) {
      return url;
    }
  }

  Widget _buildStartCleanupCard(BuildContext context) {
    final double cardWidth = SizeUtils.w(
      context,
      AppDimensions.homeScreenStartCleanupCardWidth,
    );
    final double radius = SizeUtils.r(
      context,
      AppDimensions.homeScreenStartCleanupCardRadius,
    );
    final double imageSize = SizeUtils.h(
      context,
      AppDimensions.homeScreenStartCleanupImageSize,
      useContentHeight: false,
    );

    return Align(
      child: Container(
        width: cardWidth,
        padding: EdgeInsets.symmetric(
          horizontal: SizeUtils.w(
            context,
            AppDimensions.homeScreenStartCleanupCardHorizontalPadding,
          ),
          vertical: SizeUtils.h(
            context,
            AppDimensions.homeScreenStartCleanupCardVerticalPadding,
          ),
        ),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: SizeUtils.r(
                context,
                AppDimensions.homeScreenStartCleanupCardShadowBlur,
              ),
              offset: Offset(
                AppDimensions.zero,
                SizeUtils.h(
                  context,
                  AppDimensions.homeScreenStartCleanupCardShadowOffsetY,
                  useContentHeight: false,
                ),
              ),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PrimaryButton(
              label: AppStrings.startNewCleanup,
              fixedWidth: SizeUtils.w(
                context,
                AppDimensions.homeScreenStartCleanupButtonWidth,
              ),
              fixedHeight: SizeUtils.h(
                context,
                AppDimensions.homeScreenStartCleanupButtonHeight,
                useContentHeight: false,
              ),
              onPressed: () {
                Get.find<HapticController>().medium();
                Get.toNamed(AppRoutes.newCleanUp);
              },
              labelStyle: AppTextStyles.buttonPrimaryText(context).copyWith(
                fontSize: SizeUtils.h(
                  context,
                  AppDimensions.homeScreenStartCleanupButtonFontSize,
                ),
              ),
            ),
            SizedBox(
              width: SizeUtils.w(
                context,
                AppDimensions.homeScreenStartCleanupCardSpacing,
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(
                SizeUtils.r(
                  context,
                  AppDimensions.homeScreenStartCleanupCardRadius,
                ),
              ),
              child: Image.asset(
                AppImages.cleanup,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    return Obx(() {
      if (_statsController.isLoading.value &&
          _statsController.allCleanups.isEmpty) {
        return Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Please Wait...',
                style: AppTextStyles.cleanUpSubtitle(context),
                textAlign: TextAlign.center,
              ),
              Text(
                'Loading your stats',
                style: AppTextStyles.cleanUpSubtitle(context),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
      final int cleanups = _statsController.currentMonthCleanupCount;
      final String trashKg = _statsController.currentMonthTrashKg
          .toStringAsFixed(3);
      final bool isFirstWeek = _statsController.isFirstWeekOfMonth;
      String message;
      String subMessage;

      if (cleanups == 0) {
        if (isFirstWeek) {
          message = AppStrings.statMessageFirstWeek;
          subMessage = AppStrings.statSubMessageFirstWeek;
        } else {
          message = AppStrings.statMessagePostFirstWeek;
          subMessage = AppStrings.statSubMessagePostFirstWeek;
        }
      } else {
        message = '$cleanups${AppStrings.statMessageClean}';
        subMessage = '$trashKg${AppStrings.statSubMessageClean}';
      }

      return Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              message,
              style: AppTextStyles.cleanUpSubtitle(context),
              textAlign: TextAlign.center,
            ),
            Text(
              subMessage,
              style: AppTextStyles.cleanUpSubtitle(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildHighlightsSection(BuildContext context) {
    final double carouselHeight = SizeUtils.h(
      context,
      AppDimensions.homeScreenHighlightCarouselHeight,
      useContentHeight: false,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.highlights,
          style: AppTextStyles.dashboardHeading(context),
        ),
        SizedBox(
          height: SizeUtils.h(
            context,
            AppDimensions.homeScreenHighlightCarouselSpacing,
          ),
        ),
        SizedBox(
          height: carouselHeight,
          child: PageView.builder(
            controller: _highlightController,
            padEnds: false,
            physics: const ClampingScrollPhysics(),
            // PageView.builder + CachedNetworkImage load each page lazily.
            itemCount: _spotlightUrls.length,
            itemBuilder: (context, index) {
              return _HighlightCard(imageUrl: _spotlightUrls[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNewsSection(BuildContext context) {
    final double listHeight = HomeNewsCard.estimatedHeight(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.news,
                style: AppTextStyles.dashboardHeading(context),
              ),
            ),
            GestureDetector(
              onTap: () {
                Get.find<HapticController>().selectionClick();
                // Switch to the in-app News tab (shows the full feed).
                Get.find<MainNavController>().goTo(3);
              },
              child: Text(
                AppStrings.moreNews,
                style: AppTextStyles.newsCaption(context),
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
        SizedBox(
          height: listHeight,
          child: Obx(() {
            final posts = _postsController.posts;
            final isLoading = _postsController.isLoading.value;
            final hasError = _postsController.error.value != null;

            // Show skeleton when loading AND no cached posts
            if (isLoading && posts.isEmpty) {
              return ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: 3,
                  separatorBuilder:
                      (_, _) => SizedBox(
                        width: SizeUtils.w(
                          context,
                          AppDimensions.homeScreenNewsCardSpacing,
                        ),
                      ),
                  itemBuilder: (context, index) => const NewsSkeletonCard(),
                ),
              );
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
                      onPressed: () => _postsController.loadPosts(perPage: 4),
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

            return ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.zero,
                // Home shows only the latest few; full feed lives in News tab.
                itemCount: posts.length > 4 ? 4 : posts.length,
                separatorBuilder:
                    (_, _) => SizedBox(
                      width: SizeUtils.w(
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
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBlogCard(BuildContext context) {
    final double cardWidth = double.infinity;
    final double radius = SizeUtils.r(
      context,
      AppDimensions.homeScreenBlogCardRadius,
    );
    final double iconSize = SizeUtils.h(
      context,
      AppDimensions.homeScreenBlogCardIconSize,
      useContentHeight: false,
    );

    return Align(
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: () {
            Get.find<HapticController>().selectionClick();
            SnackbarService.info(
              AppStrings.comingSoon,
              AppStrings.comingSoonMessage,
            );
          },
          child: Container(
            width: cardWidth,
            height: SizeUtils.h(
              context,
              AppDimensions.homeScreenBlogCardHeight,
              useContentHeight: false,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: SizeUtils.w(
                context,
                AppDimensions.homeScreenBlogCardHorizontalPadding,
              ),
            ),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: SizeUtils.r(
                    context,
                    AppDimensions.homeScreenBlogCardShadowBlur,
                  ),
                  offset: Offset(
                    AppDimensions.zero,
                    SizeUtils.h(
                      context,
                      AppDimensions.homeScreenBlogCardShadowOffsetY,
                      useContentHeight: false,
                    ),
                  ),
                ),
              ],
            ),
            child: Row(
              children: [
                Image.asset(
                  AppImages.blog,
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                ),
                SizedBox(
                  width: SizeUtils.w(
                    context,
                    AppDimensions.homeScreenBlogCardSpacing,
                  ),
                ),
                Expanded(
                  child: Text(
                    AppStrings.blog,
                    style: AppTextStyles.blogText(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomGraphic(BuildContext context) {
    final double height = SizeUtils.h(
      context,
      AppDimensions.homeScreenBottomGraphicHeight,
      useContentHeight: false,
    );
    return IgnorePointer(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Image.asset(
          AppImages.dashboardBottom,
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
        ),
      ),
    );
  }

  double _authHeaderScale(BuildContext context) {
    // ⚠️ ADJUST THIS to change auth header size
    // Decrease the number to make header smaller, increase to make it bigger
    // Current: AppDimensions.homeScreenAuthHeaderCurrent (try AppDimensions.homeScreenAuthHeaderSmall for smaller, AppDimensions.homeScreenAuthHeaderLarge for bigger)
    final double targetWidth = SizeUtils.w(
      context,
      AppDimensions.homeScreenAuthHeaderTargetWidth,
    );
    return targetWidth / AppDimensions.authHeaderBaseWidth;
  }

  String _displayName(UserModel? user) {
    if (user == null) {
      return 'there';
    }
    final String combined = user.firstName.trim();
    if (combined.isNotEmpty) {
      return combined;
    }
    if (user.email.isNotEmpty) {
      return user.email.split('@').first;
    }
    return 'there';
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final double radius = SizeUtils.r(
      context,
      AppDimensions.homeScreenHighlightCardRadius,
    );
    final double width = SizeUtils.w(
      context,
      AppDimensions.homeScreenHighlightCardWidth,
    );
    final double height = SizeUtils.h(
      context,
      AppDimensions.homeScreenHighlightCardHeight,
      useContentHeight: false,
    );

    return Padding(
      padding: EdgeInsets.only(
        right: SizeUtils.w(
          context,
          AppDimensions.homeScreenHighlightCardSpacing,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          Get.find<HapticController>().selectionClick();
          FullImageOverlay.show(
            context,
            imageUrl: imageUrl,
            placeholderAsset: AppImages.placeholder,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: SizedBox(
            width: width,
            height: height,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder:
                  (context, url) =>
                      Image.asset(AppImages.placeholder, fit: BoxFit.cover),
              errorWidget:
                  (context, url, error) =>
                      Image.asset(AppImages.placeholder, fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }
}
