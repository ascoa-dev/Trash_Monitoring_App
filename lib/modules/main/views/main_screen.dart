import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ascoa_app/modules/home/views/home_screen.dart';
import 'package:ascoa_app/modules/home/bindings/home_binding.dart';
import 'package:ascoa_app/modules/news/views/news_screen.dart';
import 'package:ascoa_app/modules/profile/views/profile_screen.dart';
import 'package:ascoa_app/modules/stats/views/stats_screen.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/widgets/nav_bar.dart';
import 'package:ascoa_app/app/routes/app_routes.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  // pages are built inside build() to avoid const evaluation / hot-reload
  // issues where some widgets might not be available at reload time.

  @override
  void initState() {
    super.initState();

    // Initialize home binding for lazy controller loading
    HomeBinding().dependencies();

    final args = Get.arguments;
    if (args is Map) {
      final initialTab = args['initialTab'];
      if (initialTab is int) {
        final safeIndex =
            initialTab < 0 ? 0 : (initialTab > 4 ? 4 : initialTab);
        _selectedIndex = safeIndex;
      } else if (initialTab is String) {
        switch (initialTab.toLowerCase()) {
          case 'profile':
            _selectedIndex = 4;
            break;
          case 'news':
            _selectedIndex = 3;
            break;
          case 'stats':
            _selectedIndex = 1;
            break;
          case 'home':
            _selectedIndex = 0;
            break;
        }
      }
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

    final int navIndex =
        _selectedIndex >= 2 ? _selectedIndex - 1 : _selectedIndex;
    final int safeIndex =
        (navIndex >= 0 && navIndex < pages.length) ? navIndex : 0;
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: IndexedStack(index: safeIndex, children: pages),
            ),
            Positioned(
              left: AppDimensions.zero,
              right: AppDimensions.zero,
              bottom: AppDimensions.zero,
              child: CustomNavBar(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  if (index == 2) {
                    _openAddReport();
                    return;
                  }
                  setState(() => _selectedIndex = index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddReport() {
    Get.toNamed(AppRoutes.newCleanUp);
  }
}
