import 'package:get/get.dart';
import 'package:we_monitor/app/controllers/pending_cleanups_controller.dart';

class PendingCleanupsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PendingCleanupsController>(() => PendingCleanupsController());
  }
}
