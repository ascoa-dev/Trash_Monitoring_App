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
import 'package:ascoa_app/shared/constants/app_images.dart';
import 'package:ascoa_app/shared/utils/size_utils.dart';

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
          imageAsset: AppImages.forgotConfirmIcon,
          imageWidth: SizeUtils.w(context, AppDimensions.dialogImageWidth),
          imageHeight: SizeUtils.h(context, AppDimensions.dialogImageHeight),
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
                      ? AppStrings.forgotUserNotFoundFrench
                      : AppStrings.forgotUserNotFound,
                );
                break;
              case 'invalid-email':
                _showErrorSnackbar(
                  isFrench
                      ? AppStrings.forgotInvalidEmailFrench
                      : AppStrings.forgotInvalidEmail,
                );
                break;
              case 'too-many-requests':
                _showErrorSnackbar(
                  isFrench
                      ? AppStrings.forgotTooManyRequestsFrench
                      : AppStrings.forgotTooManyRequests,
                );
                break;
              default:
                _showErrorSnackbar(
                  isFrench
                      ? AppStrings.forgotGenericErrorFrench
                      : AppStrings.forgotGenericError,
                );
            }
          })
          .catchError((error) {
            _showErrorSnackbar(
              isFrench
                  ? AppStrings.forgotGenericErrorFrench
                  : AppStrings.forgotGenericError,
            );
          });
    }
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      Get.locale?.languageCode == 'fr'
          ? AppStrings.errorTitleFrench
          : AppStrings.errorTitle,
      message,
      backgroundColor: AppColors.error,
      colorText: AppColors.pureWhite,
      snackPosition: SnackPosition.TOP,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();
    final isFrench = Get.locale?.languageCode == 'fr';

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double viewportHeight = constraints.maxHeight;
          final double viewportWidth = constraints.maxWidth;
          final double keyboardHeight =
              MediaQuery.of(context).viewInsets.bottom;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (keyboardHeight == 0 && scrollController.hasClients) {
              scrollController.jumpTo(0);
            }
          });

          return Container(
            width: viewportWidth,
            height: viewportHeight,
            color: AppColors.background,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: AppDimensions.zero,
                  right: AppDimensions.zero,
                  top: AppDimensions.zero,
                  height: viewportHeight * AppDimensions.forgotBgTopHeight,
                  child: Image.asset(
                    AppImages.forgotPasswordTop,
                    width: viewportWidth,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
                Positioned(
                  left: AppDimensions.zero,
                  right: AppDimensions.zero,
                  bottom: AppDimensions.zero,
                  height: viewportHeight * AppDimensions.forgotBgBottomHeight,
                  child: Image.asset(
                    AppImages.forgotPasswordBottom,
                    width: viewportWidth,
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics:
                        keyboardHeight > 0
                            ? const AlwaysScrollableScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: SizeUtils.w(context, AppDimensions.screenPadding),
                      right: SizeUtils.w(context, AppDimensions.screenPadding),
                      top: SizeUtils.h(context, AppDimensions.verticalPadding),
                      bottom:
                          keyboardHeight > 0
                              ? keyboardHeight
                              : SizeUtils.h(
                                context,
                                AppDimensions.verticalPadding,
                              ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () {
                              Get.back();
                            },
                            icon: Icon(
                              Icons.arrow_back,
                              color: AppColors.buttonGreen,
                              size: SizeUtils.r(
                                context,
                                AppDimensions.iconBackSize,
                              ),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        SizedBox(
                          height:
                              viewportHeight *
                              AppDimensions.forgotTitleTopSpacing,
                        ),
                        Image.asset(
                          AppImages.forgotPasswordIcon,
                          height:
                              viewportHeight *
                              AppDimensions.forgotPasswordIconSize,
                        ),
                        // SizedBox(
                        //   height: viewportHeight * AppDimensions.inputSpacing,
                        // ),
                        Text(
                          isFrench
                              ? AppStrings.forgotPasswordTitleFrench
                              : AppStrings.forgotPasswordTitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading2(context),
                        ),
                        SizedBox(
                          height:
                              viewportHeight * AppDimensions.halfInputSpacing,
                        ),
                        Text(
                          isFrench
                              ? AppStrings.forgotPasswordTextFrench
                              : AppStrings.forgotPasswordText,
                          style: AppTextStyles.bodySecondary(context),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                          height:
                              viewportHeight * AppDimensions.halfInputSpacing,
                        ),
                        Obx(
                          () => FloatingLabelInputField(
                            label: AppStrings.emailLabel,
                            controller: formControllers.emailController,
                            hint: AppStrings.emailHint,
                            obscure: false,
                            supportText: validationController.emailError.value,
                            isError:
                                validationController.emailError.value != null,
                            onChanged: validationController.validateEmail,
                          ),
                        ),
                        SizedBox(
                          height: viewportHeight * AppDimensions.buttonSpacing,
                        ),
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
                                    ? () {}
                                    : _handleForgotPassword,
                          ),
                        ),
                        SizedBox(
                          height: SizeUtils.h(
                            context,
                            AppDimensions.smallSpacing,
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: SizeUtils.h(
                            context,
                            AppDimensions.buttonHeight,
                          ),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.buttonGreen,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  SizeUtils.r(
                                    context,
                                    AppDimensions.borderRadius,
                                  ),
                                ),
                              ),
                            ),
                            onPressed: () {
                              final form = Get.find<FormControllers>();
                              final validation =
                                  Get.find<ValidationController>();
                              final currentEmail = form.emailController.text;
                              validation.clearEmailError();
                              if (!validation.isEmailValid(currentEmail)) {
                                form.emailController.clear();
                              }
                              Get.offAllNamed(AppRoutes.login);
                            },
                            child: Text(
                              isFrench
                                  ? AppStrings.editProfileCancelFrench
                                  : AppStrings.editProfileCancel,
                              style: AppTextStyles.buttonPrimaryText(
                                context,
                              ).copyWith(color: AppColors.textDark),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
