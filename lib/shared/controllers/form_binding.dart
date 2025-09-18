import 'package:get/get.dart';
import 'form_controllers.dart';
import 'validation_controller.dart';

class FormBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<FormControllers>()) {
      Get.put<FormControllers>(FormControllers(), permanent: true);
    }
    if (!Get.isRegistered<ValidationController>()) {
      Get.put<ValidationController>(ValidationController(), permanent: true);
    }
  }
}
