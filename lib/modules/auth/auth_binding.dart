import 'package:get/get.dart';
import 'package:ascoa_app/shared/controllers/form_controllers.dart';
import 'package:ascoa_app/shared/controllers/validation_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Inject controllers needed for auth module
    Get.lazyPut<FormControllers>(() => FormControllers());
    Get.lazyPut<ValidationController>(() => ValidationController());

    // Note: AuthController is already globally registered in main.dart
    // We don't need to inject it here since it's permanent
  }
}
