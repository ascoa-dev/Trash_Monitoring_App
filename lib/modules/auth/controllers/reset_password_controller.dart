import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:we_monitor/app/controllers/auth_controller.dart';
import 'package:we_monitor/modules/auth/models/reset_password_status.dart';
import 'package:we_monitor/app/routes/app_routes.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:we_monitor/shared/controllers/validation_controller.dart';
import 'package:we_monitor/shared/services/snackbar_service.dart';

class ResetPasswordController extends GetxController {
  ResetPasswordController({required this.oobCode});

  final String oobCode;

  late final AuthController _authController;
  late final ValidationController _validationController;

  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final RxnString confirmPasswordError = RxnString();
  final RxBool isSubmitting = false.obs;

  String? _lastSnackbarMessage;

  ValidationController get validationController => _validationController;

  void _showSnackbar(String message) {
    if (message.isEmpty) return;
    if (Get.isSnackbarOpen && _lastSnackbarMessage == message) {
      return;
    }

    final isFrench = Get.locale?.languageCode == 'fr';
    final title =
        isFrench ? AppStrings.errorTitleFrench : AppStrings.errorTitle;

    if (Get.isSnackbarOpen) {
      Get.back();
    }

    SnackbarService.error(title, message);
    _lastSnackbarMessage = message;
  }

  @override
  void onInit() {
    super.onInit();
    _authController = Get.find<AuthController>();
    _validationController = Get.find<ValidationController>();
    _validationController.clearPasswordValidation();

    if (oobCode.isEmpty) {
      Future.microtask(() {
        final isFrench = Get.locale?.languageCode == 'fr';
        _showSnackbar(
          isFrench
              ? AppStrings.resetPasswordInvalidLinkFrench
              : AppStrings.resetPasswordInvalidLink,
        );
        Get.offAllNamed(AppRoutes.login);
      });
    }
  }

  @override
  void onClose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    confirmPasswordError.value = null;
    _validationController.clearPasswordValidation();
    super.onClose();
  }

  void handleNewPasswordFocus(bool focused) {
    _validationController.handlePasswordFocus(focused);
  }

  void validateNewPassword(String value) {
    final trimmed = value.trim();
    _validationController.updatePasswordRules(trimmed);
    _validationController.validateStrongPassword(trimmed);
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
          _showSnackbar(message);
        }
      }
    } else {
      confirmPasswordError.value = null;
      if (previous != null) {
        _lastSnackbarMessage = null;
      }
    }
  }

  bool get hasValidationErrors {
    return confirmPasswordError.value != null ||
        _validationController.passwordError.value != null;
  }

  Future<ResetPasswordStatus> submit() async {
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    validateNewPassword(newPassword);
    validateConfirmPassword(confirmPassword);

    if (hasValidationErrors) {
      final message =
          confirmPasswordError.value ??
          _validationController.passwordError.value;
      if (message != null) {
        _showSnackbar(message);
      }
      return ResetPasswordStatus.validationError;
    }

    if (oobCode.isEmpty) {
      final isFrench = Get.locale?.languageCode == 'fr';
      _showSnackbar(
        isFrench
            ? AppStrings.resetPasswordInvalidLinkFrench
            : AppStrings.resetPasswordInvalidLink,
      );
      return ResetPasswordStatus.error;
    }

    isSubmitting.value = true;
    try {
      final status = await _authController.resetPasswordWithCode(
        oobCode: oobCode,
        newPassword: newPassword,
      );

      if (status == ResetPasswordStatus.success) {
        newPasswordController.clear();
        confirmPasswordController.clear();
        confirmPasswordError.value = null;
        _validationController.clearPasswordValidation();
        _lastSnackbarMessage = null;
      } else {
        final isFrench = Get.locale?.languageCode == 'fr';
        switch (status) {
          case ResetPasswordStatus.invalidCode:
            _showSnackbar(
              isFrench
                  ? AppStrings.resetPasswordInvalidCodeFrench
                  : AppStrings.resetPasswordInvalidCode,
            );
            break;
          case ResetPasswordStatus.expired:
            _showSnackbar(
              isFrench
                  ? AppStrings.resetPasswordExpiredFrench
                  : AppStrings.resetPasswordExpired,
            );
            break;
          case ResetPasswordStatus.error:
            _showSnackbar(
              isFrench
                  ? AppStrings.resetPasswordGenericErrorFrench
                  : AppStrings.resetPasswordGenericError,
            );
            break;
          case ResetPasswordStatus.validationError:
            _validationController.passwordError.value ??=
                AppStrings.validationPasswordStrength;
            _showSnackbar(AppStrings.validationPasswordStrength);
            break;
          case ResetPasswordStatus.success:
            break;
        }
      }

      return status;
    } finally {
      isSubmitting.value = false;
    }
  }
}
