import 'package:we_monitor/modules/stats/controllers/stats_controller.dart';
import 'package:get/get.dart';
import 'package:we_monitor/modules/home/controller/posts_controller.dart';
import 'package:we_monitor/modules/news/controller/news_posts_controller.dart';
import 'package:we_monitor/modules/main/controllers/main_nav_controller.dart';
import 'package:we_monitor/modules/achievements/achievements_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Selected bottom-nav tab — shared so any screen can switch tabs.
    Get.lazyPut<MainNavController>(() => MainNavController(), fenix: true);

    // Achievements: created on home load so its onInit evaluation renders any
    // celebrations the user hasn't seen yet (e.g. unlocks earned while the app
    // was closed, or backfilled for pre-existing users by the admin script).
    if (!Get.isRegistered<AchievementsController>()) {
      Get.put(AchievementsController(), permanent: true);
    }

    // Use lazyPut for efficient loading - controller only created when needed
    // fenix: true keeps it in memory during tab switches but allows cleanup
    Get.lazyPut<HomePostsController>(
      () => HomePostsController(),
      tag: 'home_posts',
      fenix: true,
    );

    // News tab feed — created lazily on first News-tab open.
    Get.lazyPut<NewsPostsController>(
      () => NewsPostsController(),
      tag: 'news_posts',
      fenix: true,
    );

    Get.lazyPut<StatsController>(
      () => StatsController(),
      tag: 'stats_controller',
      fenix: true,
    );
  }
}
