import 'package:get/get.dart';
import 'package:ascoa_app/modules/hotspots/controllers/hotspot_report_controller.dart';

class HotspotReportBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<HotspotReportController>()) {
      Get.delete<HotspotReportController>();
    }
    Get.put(HotspotReportController());
  }
}
