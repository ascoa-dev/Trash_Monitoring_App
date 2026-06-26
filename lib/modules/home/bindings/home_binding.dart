import 'package:ascoa_app/modules/stats/controllers/stats_controller.dart';
import 'package:get/get.dart';
import 'package:ascoa_app/modules/home/controller/posts_controller.dart';
import 'package:ascoa_app/modules/news/controller/news_posts_controller.dart';
import 'package:ascoa_app/modules/main/controllers/main_nav_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Selected bottom-nav tab — shared so any screen can switch tabs.
    Get.lazyPut<MainNavController>(() => MainNavController(), fenix: true);

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
