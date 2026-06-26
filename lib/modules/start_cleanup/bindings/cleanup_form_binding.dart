import 'package:get/get.dart';
import 'package:we_monitor/modules/start_cleanup/controllers/cleanup_form_controller.dart';

/// Binding for cleanup form screen
/// Initializes and manages CleanupFormController lifecycle
class CleanupFormBinding extends Bindings {
  @override
  void dependencies() {
    // Clean up any existing instance
    if (Get.isRegistered<CleanupFormController>()) {
      Get.delete<CleanupFormController>();
    }

    // Create new controller instance
    Get.put<CleanupFormController>(CleanupFormController());

    // Fetch trash template when controller is created
    final controller = Get.find<CleanupFormController>();
    controller.fetchTrashTemplate();
  }
}
