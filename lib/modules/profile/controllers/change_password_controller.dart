import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ascoa_app/app/controllers/auth_controller.dart';
import 'package:ascoa_app/modules/profile/models/change_password_status.dart';
import 'package:ascoa_app/shared/controllers/validation_controller.dart';
import 'package:ascoa_app/shared/utils/validators.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';

class ChangePasswordController extends GetxController {
  late final AuthController _authController;
  late final ValidationController _validationController;

  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final RxnString currentPasswordError = RxnString();
  final RxnString confirmPasswordError = RxnString();
  final RxBool isSubmitting = false.obs;
  String? _lastSnackbarMessage;

  ValidationController get validationController => _validationController;

  void _showErrorSnackbar(String message, {bool force = false}) {
    if (message.isEmpty) return;
    if (!force && Get.isSnackbarOpen && _lastSnackbarMessage == message) {
      return;
    }
    final isFrench = Get.locale?.languageCode == 'fr';
    if (Get.isSnackbarOpen) {
      if (!force && _lastSnackbarMessage == message) {
        return;
      }
      Get.back();
    }
    Get.snackbar(
      isFrench ? AppStrings.errorTitleFrench : AppStrings.errorTitle,
      message,
      snackPosition: SnackPosition.TOP,
    );
    _lastSnackbarMessage = message;
  }

  void _showValidationSnackbar() {
    final message =
        currentPasswordError.value ??
        _validationController.passwordError.value ??
        confirmPasswordError.value;
    if (message != null && message.isNotEmpty) {
      _showErrorSnackbar(message);
    }
  }

  void _showSuccessSnackbar() {
    final isFrench = Get.locale?.languageCode == 'fr';
    final title =
        isFrench
            ? AppStrings.changePasswordTitleFrench
            : AppStrings.changePasswordTitle;
    final message =
        isFrench
            ? AppStrings.changePasswordSuccessFrench
            : AppStrings.changePasswordSuccess;
    if (Get.isSnackbarOpen) {
      if (_lastSnackbarMessage == message) {
        return;
      }
      Get.back();
    }
    Get.snackbar(title, message, snackPosition: SnackPosition.TOP);
    _lastSnackbarMessage = message;
  }

  @override
  void onInit() {
    super.onInit();
    _authController = Get.find<AuthController>();
    _validationController = Get.find<ValidationController>();
    _validationController.clearPasswordValidation();
  }

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    _validationController.clearPasswordValidation();
    currentPasswordError.value = null;
    confirmPasswordError.value = null;
    super.onClose();
  }

  void validateCurrentPassword(String value) {
    final trimmed = value.trim();
    final isFrench = Get.locale?.languageCode == 'fr';
    final result = Validators.validateRequired(
      trimmed,
      isFrench
          ? AppStrings.currentPasswordLabelFrench
          : AppStrings.currentPasswordLabel,
    );
    currentPasswordError.value = result;
  }

  void validateNewPassword(String value) {
    final trimmed = value.trim();
    final currentTrimmed = currentPasswordController.text.trim();
    final isFrench = Get.locale?.languageCode == 'fr';
    final samePasswordMessage =
        isFrench
            ? AppStrings.changePasswordSameAsCurrentFrench
            : AppStrings.changePasswordSameAsCurrent;

    _validationController.updatePasswordRules(value);

    if (trimmed.isNotEmpty &&
        currentTrimmed.isNotEmpty &&
        trimmed == currentTrimmed) {
      _validationController.passwordError.value = samePasswordMessage;
    } else {
      _validationController.validateStrongPassword(trimmed);
    }

    validateConfirmPassword(
      confirmPasswordController.text,
      fromConfirmField: false,
    );
  }

  void validateConfirmPassword(String value, {bool fromConfirmField = false}) {
    final trimmed = value.trim();
    final basePassword = newPasswordController.text.trim();
    final previous = confirmPasswordError.value;
    if (trimmed.isEmpty) {
      confirmPasswordError.value = AppStrings.validationConfirmPasswordRequired;
    } else if (trimmed != basePassword) {
      confirmPasswordError.value = AppStrings.validationPasswordsMismatch;
      if (fromConfirmField && basePassword.isNotEmpty) {
        final message = confirmPasswordError.value;
        if (message != null && message != previous) {
          _showErrorSnackbar(message);
        }
      }
    } else {
      confirmPasswordError.value = null;
      if (previous != null) {
        _lastSnackbarMessage = null;
      }
    }
  }

  void handleNewPasswordFocus(bool focused) {
    _validationController.handlePasswordFocus(focused);
  }

  bool get hasValidationErrors {
    return currentPasswordError.value != null ||
        confirmPasswordError.value != null ||
        _validationController.passwordError.value != null;
  }

  Future<ChangePasswordStatus> submit() async {
    final current = currentPasswordController.text.trim();
    final newPass = newPasswordController.text.trim();
    final confirmPass = confirmPasswordController.text.trim();

    validateCurrentPassword(current);
    validateNewPassword(newPass);
    validateConfirmPassword(confirmPass);

    if (hasValidationErrors) {
      _showValidationSnackbar();
      return ChangePasswordStatus.validationError;
    }

    isSubmitting.value = true;
    try {
      final status = await _authController.changePassword(
        currentPassword: current,
        newPassword: newPass,
      );

      if (status == ChangePasswordStatus.success) {
        currentPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();
        _validationController.clearPasswordValidation();
        currentPasswordError.value = null;
        confirmPasswordError.value = null;
        _lastSnackbarMessage = null;
        _showSuccessSnackbar();
      } else if (status == ChangePasswordStatus.wrongPassword) {
        final isFrench = Get.locale?.languageCode == 'fr';
        currentPasswordError.value =
            isFrench
                ? AppStrings.changePasswordWrongCurrentFrench
                : AppStrings.changePasswordWrongCurrent;
        _showErrorSnackbar(currentPasswordError.value!, force: true);
      } else if (status == ChangePasswordStatus.error && !Get.isSnackbarOpen) {
        final isFrench = Get.locale?.languageCode == 'fr';
        _showErrorSnackbar(
          isFrench
              ? AppStrings.changePasswordGenericErrorFrench
              : AppStrings.changePasswordGenericError,
        );
      } else if (status == ChangePasswordStatus.validationError) {
        _showValidationSnackbar();
      }

      return status;
    } finally {
      isSubmitting.value = false;
    }
  }
}
