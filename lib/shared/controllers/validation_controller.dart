import 'package:get/get.dart';
import 'package:ascoa_app/shared/utils/validators.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/controllers/cities_controller.dart';

class ValidationController extends GetxController {
  var emailError = Rx<String?>(null);
  var passwordError = Rx<String?>(null);
  var firstNameError = Rx<String?>(null);
  var lastNameError = Rx<String?>(null);
  var phoneNumberError = Rx<String?>(null);
  var cityError = Rx<String?>(null);

  // Password rule states
  final hasMinLength = false.obs; // >= 8
  final hasUppercase = false.obs;
  final hasLowercase = false.obs;
  final hasNumber = false.obs;
  final hasSpecial = false.obs;
  final passwordText = ''.obs; // current password text
  final showPasswordChecklist = false.obs; // controls UI visibility

  final nameRegex = RegExp(r"^[a-zA-Z ,.'-]+$");
  final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');

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

  void validateFirstName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      firstNameError.value = '${AppStrings.firstNameError} is required';
    } else if (!nameRegex.hasMatch(trimmed)) {
      firstNameError.value = 'Invalid ${AppStrings.firstNameError}';
    } else {
      firstNameError.value = null; // valid
    }
  }

  void validateLastName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      lastNameError.value = '${AppStrings.lastNameError} is required';
    } else if (!nameRegex.hasMatch(trimmed)) {
      lastNameError.value = 'Invalid ${AppStrings.lastNameError}';
    } else {
      lastNameError.value = null; // valid
    }
  }

  void validateCity(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      cityError.value = '${AppStrings.cityError} is required';
    } else if (!nameRegex.hasMatch(trimmed)) {
      // reuse nameRegex for city
      cityError.value = 'Invalid ${AppStrings.cityError}';
    } else {
      // Check if custom cities are allowed
      try {
        final citiesController = Get.find<CitiesController>();
        if (!citiesController.allowCustomCities) {
          // If custom cities not allowed, validate against the list
          if (!citiesController.isCityValid(trimmed)) {
            final isFrench = Get.locale?.languageCode == 'fr';
            cityError.value = isFrench 
                ? AppStrings.citySelectorPleaseSelectFrench
                : AppStrings.citySelectorPleaseSelect;
            return;
          }
        }
      } catch (e) {
        // CitiesController not found, skip validation
      }
      cityError.value = null; // valid
    }
  }

  void validatePhoneNumber(String dialCode, String number) {
    final trimmedNumber = number.trim();

    // Check required
    final requiredResult = Validators.validateRequired(
      trimmedNumber,
      AppStrings.phoneNumberError,
    );
    if (requiredResult != null) {
      phoneNumberError.value = requiredResult;
      return;
    }

    // Combine dial code and number
    final combined = '$dialCode$trimmedNumber'.replaceAll(' ', '');
    if (!phoneRegex.hasMatch(combined)) {
      phoneNumberError.value = 'Invalid ${AppStrings.phoneNumberError}';
    } else {
      phoneNumberError.value = null; // valid
    }
  }

  void validatePhoneNumberFull(String value) {
    final trimmed = value.trim();
    final requiredResult = Validators.validateRequired(
      trimmed,
      AppStrings.phoneNumberLabel,
    );
    if (requiredResult != null) {
      phoneNumberError.value = requiredResult;
      return;
    }

    final normalized = trimmed.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final candidate = normalized.startsWith('+') ? normalized : '+$normalized';

    if (!phoneRegex.hasMatch(candidate)) {
      phoneNumberError.value = AppStrings.validationPhoneInvalid;
    } else {
      phoneNumberError.value = null;
    }
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
    clearProfileValidation();
    passwordText.value = '';
    hasMinLength.value = false;
    hasUppercase.value = false;
    hasLowercase.value = false;
    hasNumber.value = false;
    hasSpecial.value = false;
    showPasswordChecklist.value = false;
  }

  // Reset only password-related validation state (do not touch email/terms)
  void clearPasswordValidation() {
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

  bool get isProfileFormValid {
    return firstNameError.value == null &&
        lastNameError.value == null &&
        phoneNumberError.value == null &&
        cityError.value == null;
  }

  void clearProfileValidation() {
    firstNameError.value = null;
    lastNameError.value = null;
    phoneNumberError.value = null;
    cityError.value = null;
  }
}
