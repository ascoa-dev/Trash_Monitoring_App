import 'package:ascoa_app/shared/controllers/validation_controller.dart';
/// Helper utilities for wiring auth forms (login/signup) to the ValidationController.
class AuthFormUtils {
  /// Validate basic login fields (email + required password) and return whether the form is valid.
  static bool validateLogin(ValidationController validationController, String email, String password) {
    validationController.validateEmail(email);
    validationController.validatePasswordRequired(password);
    return validationController.isFormValid;
  }

  /// Validate signup password using stronger rules and update the password checklist state.
  static void handleSignupPasswordChange(ValidationController validationController, String password) {
    validationController.updatePasswordRules(password);
    validationController.validateStrongPassword(password);
    if (!validationController.allPasswordRulesMet) {
      validationController.showPasswordChecklist.value = true;
    }
  }
}
