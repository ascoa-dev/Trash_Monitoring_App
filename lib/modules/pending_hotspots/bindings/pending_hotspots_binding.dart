import 'package:get/get.dart';
import 'package:we_monitor/app/controllers/pending_hotspots_controller.dart';

class PendingHotspotsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PendingHotspotsController>(() => PendingHotspotsController());
  }
}
