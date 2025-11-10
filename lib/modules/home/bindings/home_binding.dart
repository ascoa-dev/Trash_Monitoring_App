import 'package:get/get.dart';
import 'package:ascoa_app/modules/home/controller/posts_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Use lazyPut for efficient loading - controller only created when needed
    // fenix: true keeps it in memory during tab switches but allows cleanup
    Get.lazyPut<HomePostsController>(
      () => HomePostsController(),
      tag: 'home_posts',
      fenix: true,
    );
  }
}
