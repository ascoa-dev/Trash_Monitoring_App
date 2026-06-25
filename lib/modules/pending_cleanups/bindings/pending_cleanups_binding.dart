import 'package:get/get.dart';
import 'package:ascoa_app/app/controllers/pending_cleanups_controller.dart';

class PendingCleanupsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PendingCleanupsController>(() => PendingCleanupsController());
  }
}
