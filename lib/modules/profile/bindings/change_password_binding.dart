import 'package:get/get.dart';
import 'package:ascoa_app/modules/profile/controllers/change_password_controller.dart';

class ChangePasswordBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ChangePasswordController>()) {
      Get.put<ChangePasswordController>(ChangePasswordController());
    }
  }
}
