import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ascoa_app/modules/home/views/home_screen.dart';
import 'package:ascoa_app/modules/home/bindings/home_binding.dart';
import 'package:ascoa_app/modules/news/views/news_screen.dart';
import 'package:ascoa_app/modules/news/controller/news_posts_controller.dart';
import 'package:ascoa_app/modules/main/controllers/main_nav_controller.dart';
import 'package:ascoa_app/modules/profile/views/profile_screen.dart';
import 'package:ascoa_app/modules/stats/views/stats_screen.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/widgets/nav_bar.dart';
import 'package:ascoa_app/app/routes/app_routes.dart';
import 'package:ascoa_app/shared/analytics/analytics_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final MainNavController _nav;
  // pages are built inside build() to avoid const evaluation / hot-reload
  // issues where some widgets might not be available at reload time.

  @override
  void initState() {
    super.initState();

    // Initialize home binding for lazy controller loading
    HomeBinding().dependencies();
    _nav = Get.find<MainNavController>();

    int initial = 0;
    final args = Get.arguments;
    if (args is Map) {
      final initialTab = args['initialTab'];
      if (initialTab is int) {
        initial = initialTab < 0 ? 0 : (initialTab > 4 ? 4 : initialTab);
      } else if (initialTab is String) {
        switch (initialTab.toLowerCase()) {
          case 'profile':
            initial = 4;
            break;
          case 'news':
            initial = 3;
            break;
          case 'stats':
            initial = 1;
            break;
          case 'home':
            initial = 0;
            break;
        }
      }
    }
    _nav.currentIndex.value = initial;
    _onTabShown(initial);
    // React to tab changes from anywhere (nav bar taps, "More News" link).
    ever<int>(_nav.currentIndex, _onTabShown);
  }

  void _onTabShown(int index) {
    _trackScreenView(index);
    // News is lazy — fetch the feed only when the tab is actually shown.
    if (index == 3) _loadNewsIfNeeded();
  }

  void _loadNewsIfNeeded() {
    Get.find<NewsPostsController>(tag: 'news_posts').loadOnce();
  }

  void _trackScreenView(int index) {
    switch (index) {
      case 0:
        Analytics.screenView(AnalyticsEvents.homeViewed);
        break;
      case 1:
        Analytics.screenView(AnalyticsEvents.statsViewed);
        break;
      case 3:
        Analytics.screenView(AnalyticsEvents.newsViewed);
        break;
      case 4:
        Analytics.screenView(AnalyticsEvents.profileViewed);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = const [
      HomeScreen(),
      StatsScreen(),
      NewsScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Obx(() {
          final int selected = _nav.currentIndex.value;
          final int navIndex = selected >= 2 ? selected - 1 : selected;
          final int safeIndex =
              (navIndex >= 0 && navIndex < pages.length) ? navIndex : 0;
          return Stack(
            children: [
              Positioned.fill(
                child: IndexedStack(index: safeIndex, children: pages),
              ),
              Positioned(
                left: AppDimensions.zero,
                right: AppDimensions.zero,
                bottom: AppDimensions.zero,
                child: CustomNavBar(
                  currentIndex: selected,
                  onTap: (index) {
                    if (index == 2) {
                      _openAddReport();
                      return;
                    }
                    _nav.goTo(index);
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  void _openAddReport() {
    Analytics.track(AnalyticsEvents.cleanupCtaClicked);
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.cleaning_services_outlined),
                title: const Text('Start New Cleanup'),
                onTap: () {
                  Get.back();
                  Get.toNamed(AppRoutes.newCleanUp);
                },
              ),
              ListTile(
                leading: const Icon(Icons.report_problem_outlined),
                title: const Text('Report Plastic Hotspot'),
                onTap: () {
                  Get.back();
                  Get.toNamed(AppRoutes.reportHotspot);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
