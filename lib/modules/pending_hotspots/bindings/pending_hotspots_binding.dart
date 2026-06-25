import 'package:get/get.dart';
import 'package:ascoa_app/app/controllers/pending_hotspots_controller.dart';

class PendingHotspotsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PendingHotspotsController>(() => PendingHotspotsController());
  }
}
