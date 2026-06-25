import 'package:get/get.dart';
import 'package:ascoa_app/modules/profile/controllers/edit_profile_controller.dart';

class EditProfileBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<EditProfileController>()) {
      Get.put<EditProfileController>(EditProfileController());
    }
  }
}
