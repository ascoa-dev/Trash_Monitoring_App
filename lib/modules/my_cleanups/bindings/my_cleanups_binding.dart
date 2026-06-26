import 'package:get/get.dart';
import 'package:we_monitor/modules/my_cleanups/controllers/my_cleanups_controller.dart';

class MyCleanupsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MyCleanupsController>(() => MyCleanupsController());
  }
}
