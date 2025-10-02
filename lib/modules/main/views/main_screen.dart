import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ascoa_app/modules/home/views/home_screen.dart';
import 'package:ascoa_app/modules/news/views/news_screen.dart';
import 'package:ascoa_app/modules/profile/views/profile_screen.dart';
import 'package:ascoa_app/modules/stats/views/stats_screen.dart';
import 'package:ascoa_app/modules/add_report/views/add_report_screen.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/widgets/nav_bar.dart';

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
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(index: safeIndex, children: pages),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
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
    );
  }

  void _openAddReport() {
    Get.to(() => const AddReportScreen());
  }
}
