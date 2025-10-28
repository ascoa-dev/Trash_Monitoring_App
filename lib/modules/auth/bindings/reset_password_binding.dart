import 'package:get/get.dart';
import 'package:ascoa_app/modules/auth/controllers/reset_password_controller.dart';

class ResetPasswordBinding extends Bindings {
  @override
  void dependencies() {
    String oobCode = '';
    final args = Get.arguments;

    if (args is Map) {
      final dynamic value = args['oobCode'];
      if (value is String) {
        oobCode = value;
      }
    } else if (args is String) {
      oobCode = args;
    }

    if (Get.isRegistered<ResetPasswordController>()) {
      Get.delete<ResetPasswordController>();
    }

    Get.put<ResetPasswordController>(ResetPasswordController(oobCode: oobCode));
  }
}
