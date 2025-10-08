import 'package:get/get.dart';
import 'package:ascoa_app/shared/utils/validators.dart';

class ValidationController extends GetxController {
  var emailError = Rx<String?>(null);
  var passwordError = Rx<String?>(null);

  // Reactive variable to track terms acceptance
  var isTermsAccepted = false.obs;

  // Reactive variable to track terms error
  var termsError = Rx<String?>(null);

  void validateEmail(String email) {
    emailError.value = Validators.validateEmail(email);
  }

  void validatePasswordRequired(String password) {
    passwordError.value = Validators.validateRequired(password, 'Password');
  }

  void validateStrongPassword(String password) {
    passwordError.value = Validators.validateStrongPassword(password);
  }

  void clearValidation() {
    emailError.value = null;
    passwordError.value = null;
  }

  bool get isFormValid {
    return emailError.value == null && passwordError.value == null;
  }
}
