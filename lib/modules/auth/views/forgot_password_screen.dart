// ===============================================
// FORGOT PASSWORD SCREEN AND FORGOT PASSWORD CONFIRMATION SCREEN- Created by Michel
// Branch: feature/forgot-password
// Description: Screen for password reset functionality
// Usage: Navigated from LoginScreen forgot password button
// ===============================================

// ===============================================
// FORGOT PASSWORD SCREEN AND CONFIRMATION - Login Screen Styling
// ===============================================

import 'package:ascoa_app/app/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ascoa_app/app/routes/app_routes.dart';
import 'package:ascoa_app/shared/controllers/form_controllers.dart';
import 'package:ascoa_app/shared/controllers/validation_controller.dart';
import 'package:ascoa_app/shared/widgets/floating_label_input_field.dart';
import 'package:ascoa_app/shared/widgets/primary_button.dart';
import 'package:ascoa_app/shared/widgets/app_dialog.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Controllers
  late final AuthController controller;
  late final FormControllers formControllers;
  late final ValidationController validationController;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    controller = Get.find<AuthController>();
    formControllers = Get.find<FormControllers>();
    validationController = Get.find<ValidationController>();

    // Sanitize carried-over state: clear error and only keep a valid email
    final currentEmail = formControllers.emailController.text;
    validationController.clearEmailError();
    if (!validationController.isEmailValid(currentEmail)) {
      formControllers.emailController.clear();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Show confirmation overlay dialog
  void _showConfirmationOverlay() {
    final isFrench = Get.locale?.languageCode == 'fr';
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AppDialog(
          title:
              isFrench
                  ? AppStrings.forgotDialogTitleFrench
                  : AppStrings.forgotDialogTitle,
          body:
              isFrench
                  ? AppStrings.forgotDialogBodyFrench
                  : AppStrings.forgotDialogBody,
          decoratedHero: false,
          imageAsset: 'assets/ASCOA/Forgot_Password_confirm_Icon.png',
          imageWidth: AppDimensions.dialogImageWidth,
          imageHeight: AppDimensions.dialogImageHeight,
          primaryActionLabel:
              isFrench
                  ? AppStrings.forgotDialogButtonFrench
                  : AppStrings.forgotDialogButton,
          onPrimaryAction: () {
            final form = Get.find<FormControllers>();
            final validation = Get.find<ValidationController>();
            final currentEmail = form.emailController.text;
            validation.clearEmailError();
            if (!validation.isEmailValid(currentEmail)) {
              form.emailController.clear();
            }
            Get.back();
            Get.offAllNamed(AppRoutes.login);
          },
        );
      },
    );
  }

  // Handle forgot password operation
  void _handleForgotPassword() {
    final isFrench = Get.locale?.languageCode == 'fr';

    // Validate email before sending
    validationController.validateEmail(formControllers.emailController.text);

    if (validationController.emailError.value == null &&
        formControllers.emailController.text.isNotEmpty) {
      controller
          .forgotPassword(formControllers.emailController.text)
          .then((result) {
            switch (result) {
              case 'success':
                _showConfirmationOverlay();
                break;
              case 'user-not-found':
                _showErrorSnackbar(
                  isFrench
                      ? 'Aucun utilisateur trouvé avec cette adresse email.'
                      : 'No user found with this email address.',
                );
                break;
              case 'invalid-email':
                _showErrorSnackbar(
                  isFrench
                      ? 'Adresse email invalide.'
                      : 'Invalid email address.',
                );
                break;
              case 'too-many-requests':
                _showErrorSnackbar(
                  isFrench
                      ? 'Trop de tentatives. Réessayez plus tard.'
                      : 'Too many attempts. Try again later.',
                );
                break;
              default:
                _showErrorSnackbar(
                  isFrench
                      ? 'Une erreur est survenue. Réessayez plus tard.'
                      : 'An error occurred. Try again later.',
                );
            }
          })
          .catchError((error) {
            _showErrorSnackbar(
              isFrench
                  ? 'Une erreur est survenue. Réessayez plus tard.'
                  : 'An error occurred. Try again later.',
            );
          });
    }
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: AppColors.error,
      colorText: AppColors.pureWhite,
      snackPosition: SnackPosition.TOP,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isFrench = Get.locale?.languageCode == 'fr';

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        color: AppColors.background,
        child: Stack(
          children: [
            // Top background image
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: size.height * AppDimensions.forgotBgTopHeight,
              child: Image.asset(
                'assets/ASCOA/Forgot_Password_Screen_Top.png',
                fit: BoxFit.cover,
              ),
            ),
            // Bottom background image
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: size.height * AppDimensions.forgotBgBottomHeight,
              child: Image.asset(
                'assets/ASCOA/Forgot_Password_Screen_Bottom.png',
                fit: BoxFit.cover,
              ),
            ),
            // Content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPadding,
                  vertical: AppDimensions.verticalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Back Button - Styled like login screen
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () {
                          final form = Get.find<FormControllers>();
                          final validation = Get.find<ValidationController>();
                          final currentEmail = form.emailController.text;
                          validation.clearEmailError();
                          if (!validation.isEmailValid(currentEmail)) {
                            form.emailController.clear();
                          }
                          Get.back();
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color:
                              AppColors
                                  .buttonGreen, // Green color matching login
                          size: AppDimensions.iconBackSize,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),

                    SizedBox(
                      height: size.height * AppDimensions.titleTopSpacing,
                    ),

                    //Icon
                    Image.asset(
                      'assets/ASCOA/ForgotPasswordIcon.png',
                      height:
                          size.height * AppDimensions.forgotPasswordIconSize,
                    ),

                    SizedBox(height: size.height * AppDimensions.inputSpacing),
                    // Title - Same style as login
                    Text(
                      isFrench
                          ? AppStrings.forgotPasswordTitleFrench
                          : AppStrings.forgotPasswordTitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading2, // Same as login screen
                    ),

                    SizedBox(
                      height: size.height * AppDimensions.halfInputSpacing,
                    ),

                    // Subtitle
                    Text(
                      isFrench
                          ? AppStrings.forgotPasswordTextFrench
                          : AppStrings.forgotPasswordText,
                      style:
                          AppTextStyles.bodySecondary, // Same as login screen
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(
                      height: size.height * AppDimensions.halfInputSpacing,
                    ),
                    // Email Input Field - EXACTLY like login screen using CustomInputField
                    Obx(
                      () => FloatingLabelInputField(
                        label: AppStrings.emailLabel,
                        controller: formControllers.emailController,
                        hint: AppStrings.emailHint,
                        obscure: false,
                        supportText: validationController.emailError.value,
                        isError: validationController.emailError.value != null,
                        onChanged: validationController.validateEmail,
                      ),
                    ),

                    SizedBox(height: size.height * AppDimensions.buttonSpacing),

                    // Send Reset Link Button - Using PrimaryButton like login
                    Obx(
                      () => PrimaryButton(
                        label:
                            controller.isLoadingForgotPassword.value
                                ? (isFrench
                                    ? AppStrings.sendingResetLinkFrench
                                    : AppStrings.sendingResetLink)
                                : (isFrench
                                    ? AppStrings.sendResetLinkFrench
                                    : AppStrings.sendResetLink),
                        onPressed:
                            controller.isLoadingForgotPassword.value
                                ? () {} // Empty function instead of null
                                : _handleForgotPassword,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===============================================
// FORGOT PASSWORD CONFIRMATION SCREEN
// ===============================================

// ForgotPasswordConfirmationScreen removed. Using overlay dialog instead.

// ===============================================
// END FORGOT PASSWORD SCREENS
// ===============================================
