import 'package:get/get.dart';
import 'package:ascoa_app/shared/utils/validators.dart';

class ValidationController extends GetxController {
  var emailError = Rx<String?>(null);
  var passwordError = Rx<String?>(null);

  // Password rule states
  final hasMinLength = false.obs; // >= 8
  final hasUppercase = false.obs;
  final hasLowercase = false.obs;
  final hasNumber = false.obs;
  final hasSpecial = false.obs;
  final passwordText = ''.obs; // current password text
  final showPasswordChecklist = false.obs; // controls UI visibility

  // Reactive variable to track terms acceptance
  var isTermsAccepted = false.obs;

  // Reactive variable to track terms error
  var termsError = Rx<String?>(null);

  void validateEmail(String email) {
    emailError.value = Validators.validateEmail(email);
  }

  // Quick check without mutating state
  bool isEmailValid(String email) {
    return Validators.validateEmail(email) == null;
  }

  // Clear only email error state
  void clearEmailError() {
    emailError.value = null;
  }

  void validatePasswordRequired(String password) {
    passwordError.value = Validators.validateRequired(password, 'Password');
  }

  void validateStrongPassword(String password) {
    passwordError.value = Validators.validateStrongPassword(password);
  }

  void updatePasswordRules(String password) {
    passwordText.value = password;
    hasMinLength.value = password.length >= 8;
    hasUppercase.value = RegExp(r'[A-Z]').hasMatch(password);
    hasLowercase.value = RegExp(r'[a-z]').hasMatch(password);
    hasNumber.value = RegExp(r'[0-9]').hasMatch(password);
    hasSpecial.value = RegExp(r'[@$!%*?&]').hasMatch(password);
    // Do not auto-hide when rules are met; visibility is controlled by
    // focus/typing (kept visible even when valid per signup requirement).
  }

  bool get allPasswordRulesMet =>
      hasMinLength.value &&
      hasUppercase.value &&
      hasLowercase.value &&
      hasNumber.value &&
      hasSpecial.value;

  void handlePasswordFocus(bool focused) {
    // Show when focused regardless of rule state; hide on blur only if empty
    if (focused) {
      showPasswordChecklist.value = true;
    } else {
      if (passwordText.value.isEmpty) {
        showPasswordChecklist.value = false;
      }
    }
  }

  void clearValidation() {
    emailError.value = null;
    passwordError.value = null;
    passwordText.value = '';
    hasMinLength.value = false;
    hasUppercase.value = false;
    hasLowercase.value = false;
    hasNumber.value = false;
    hasSpecial.value = false;
    showPasswordChecklist.value = false;
  }

  bool get isFormValid {
    return emailError.value == null && passwordError.value == null;
  }
}
