import 'package:get/get.dart';

/// Holds the selected bottom-nav tab so any screen can switch tabs without
/// re-navigating to the home route (Get.offNamed to the current route is a
/// no-op). MainScreen reacts to [currentIndex]; callers use [goTo].
class MainNavController extends GetxController {
  final RxInt currentIndex = 0.obs;

  void goTo(int index) => currentIndex.value = index;
}
