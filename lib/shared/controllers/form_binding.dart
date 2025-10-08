import 'package:get/get.dart';
import 'form_controllers.dart';
import 'validation_controller.dart';

class FormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FormControllers>(() => FormControllers());
    Get.lazyPut<ValidationController>(() => ValidationController());
  }
}
