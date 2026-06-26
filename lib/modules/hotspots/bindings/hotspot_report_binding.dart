import 'package:get/get.dart';
import 'package:we_monitor/modules/hotspots/controllers/hotspot_report_controller.dart';

class HotspotReportBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<HotspotReportController>()) {
      Get.delete<HotspotReportController>();
    }
    Get.put(HotspotReportController());
  }
}
