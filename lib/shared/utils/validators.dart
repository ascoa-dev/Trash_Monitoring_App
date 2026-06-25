import 'package:ascoa_app/shared/constants/app_strings.dart';

class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.validationEmailRequired;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return AppStrings.validationEmailInvalid;
    }

    return null;
  }

  // Password validation (basic for login)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.validationPasswordRequired;
    }

    if (value.length < 6) {
      return AppStrings.validationPasswordTooShort.replaceFirst('%d', '6');
    }

    return null;
  }

  // Stronger password validation (for signup)
  static String? validateStrongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.validationPasswordRequired;
    }

    if (value.length < 8) {
      return AppStrings.validationPasswordTooShort.replaceFirst('%d', '8');
    }

    if (!RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]',
    ).hasMatch(value)) {
      return AppStrings.validationPasswordStrength;
    }

    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return AppStrings.validationConfirmPasswordRequired;
    }

    if (value != password) {
      return AppStrings.validationPasswordsMismatch;
    }

    return null;
  }

  // Generic required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return AppStrings.validationRequiredField.replaceFirst('%s', fieldName);
    }
    return null;
  }

  // Phone number validation (optional)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
      return AppStrings.validationPhoneInvalid;
    }

    return null;
  }

  // Prevent instantiation
  Validators._();
}
