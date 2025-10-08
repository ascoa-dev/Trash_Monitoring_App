import 'package:ascoa_app/app/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
// Using dedicated signup form controller for isolated lifecycle
import 'package:ascoa_app/shared/controllers/form_controllers.dart';
import 'package:ascoa_app/shared/controllers/validation_controller.dart';
import 'package:ascoa_app/shared/widgets/floating_label_input_field.dart';
import 'package:ascoa_app/shared/widgets/password_strength_checklist.dart';
import 'package:ascoa_app/shared/widgets/primary_button.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/widgets/social_button.dart';
import 'package:ascoa_app/app/routes/app_routes.dart';
import 'package:ascoa_app/shared/widgets/auth_header.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final AuthController controller = Get.find<AuthController>();
    final FormControllers formControllers = Get.find<FormControllers>();
    final ValidationController validationController =
        Get.find<ValidationController>();

    // Scale for AuthHeader like Login V2
    const double referenceWidth = 440.0;
    final double scale = (size.width / referenceWidth).clamp(0.8, 1.25);

    return Scaffold(
      body: Stack(
        children: [
          // Background base color
          Container(color: AppColors.background),

          // Top decorative image per Figma
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/ASCOA/Signup_Screen_Top.png',
              width: size.width,
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPadding,
                vertical: AppDimensions.verticalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: size.height * AppDimensions.authScreenXLargeSpacer,
                  ),

                  // Auth header like Login V2
                  AuthHeader(scale: scale),

                  // Title below header per Figma
                  const SizedBox(height: 16),
                  const Text(
                    AppStrings.signupTitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading2,
                  ),

                  SizedBox(
                    height: size.height * AppDimensions.titleBottomSpacing,
                  ),

                  // Email Input (floating label like login v2)
                  Obx(
                    () => FloatingLabelInputField(
                      controller: formControllers.emailController,
                      label: AppStrings.emailLabel,
                      hint: AppStrings.emailHint,
                      obscure: false,
                      supportText: validationController.emailError.value,
                      isError: validationController.emailError.value != null,
                      onChanged: validationController.validateEmail,
                    ),
                  ),

                  SizedBox(height: size.height * AppDimensions.inputSpacing),

                  // Password Input + Always-visible Checklist when focused/typed (even if valid)
                  Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FloatingLabelInputField(
                          controller: formControllers.passwordController,
                          label: AppStrings.passwordLabel,
                          hint: AppStrings.passwordHint,
                          obscure: true,
                          supportText:
                              validationController.showPasswordChecklist.value
                                  ? null
                                  : validationController.passwordError.value,
                          onChanged: (val) {
                            validationController.updatePasswordRules(val);
                            validationController.validateStrongPassword(val);
                            // Visibility is driven by focus; no-op here
                          },
                          onFocusChange: (focused) {
                            if (focused) {
                              validationController.showPasswordChecklist.value =
                                  true;
                            } else {
                              // Hide only if text is empty to avoid flicker during quick nav
                              if (validationController
                                  .passwordText
                                  .value
                                  .isEmpty) {
                                validationController
                                    .showPasswordChecklist
                                    .value = false;
                              }
                            }
                          },
                        ),
                        if (validationController.showPasswordChecklist.value)
                          PasswordStrengthChecklist(
                            padding: EdgeInsets.only(
                              top: AppDimensions.inputErrorSpacing,
                              left: AppDimensions.chipHorizontalPadding,
                              right: AppDimensions.chipHorizontalPadding,
                            ),
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: size.height * AppDimensions.inputSpacing),

                  // Terms and Conditions
                  Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: AppDimensions.checkboxSize,
                              height: AppDimensions.checkboxSize,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color:
                                      validationController.termsError.value !=
                                              null
                                          ? AppColors.error
                                          : AppColors.accentGreen,
                                  width:
                                      validationController.termsError.value !=
                                              null
                                          ? AppDimensions.inputBorderWidthError
                                          : AppDimensions.borderWidth,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.checkboxCornerRadius,
                                ),
                              ),
                              child: Checkbox(
                                value:
                                    validationController.isTermsAccepted.value,
                                onChanged: (val) {
                                  validationController.isTermsAccepted.value =
                                      val ?? false;
                                  if (val == true) {
                                    validationController.termsError.value =
                                        null;
                                  }
                                },
                                activeColor: AppColors.accentGreen,
                                checkColor: AppColors.pureWhite,
                                side: BorderSide.none, // Remove black border
                              ),
                            ),
                            const SizedBox(width: AppDimensions.tinySpacing),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: AppTextStyles.termsBase,
                                  children: [
                                    const TextSpan(
                                      text: AppStrings.termsTextSignUp,
                                    ),
                                    TextSpan(
                                      text: AppStrings.termsLink,
                                      style: AppTextStyles.termsLink,
                                      recognizer:
                                          TapGestureRecognizer()
                                            ..onTap = () {
                                              Get.snackbar(
                                                AppStrings.termsLink,
                                                AppStrings.termsNav,
                                              );
                                            },
                                    ),
                                    const TextSpan(text: AppStrings.termsAnd),
                                    TextSpan(
                                      text: AppStrings.privacyPolicyLink,
                                      style: AppTextStyles.termsLink,
                                      recognizer:
                                          TapGestureRecognizer()
                                            ..onTap = () {
                                              Get.snackbar(
                                                AppStrings.privacyPolicyLink,
                                                AppStrings.privacyPolicyNav,
                                              );
                                            },
                                    ),
                                    const TextSpan(
                                      text: AppStrings.termsPeriod,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (validationController.termsError.value != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: AppDimensions.smallSpacing,
                            ),
                            child: Text(
                              validationController.termsError.value!,
                              style: AppTextStyles.errorText,
                            ),
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: size.height * AppDimensions.sectionSpacing),

                  // Create Account Button
                  PrimaryButton(
                    label: AppStrings.signupTitle,
                    onPressed: () {
                      // Validate form
                      validationController.validateEmail(
                        formControllers.emailController.text,
                      );
                      validationController.validateStrongPassword(
                        formControllers.passwordController.text,
                      );

                      if (!validationController.isTermsAccepted.value) {
                        validationController.termsError.value =
                            'You must accept the terms and conditions to proceed.';
                      }

                      // Only proceed if form is valid
                      if (validationController.isFormValid &&
                          validationController.isTermsAccepted.value) {
                        controller.signup(
                          formControllers.emailController.text,
                          formControllers.passwordController.text,
                        );
                      }
                    },
                  ),

                  SizedBox(height: size.height * AppDimensions.sectionSpacing),

                  // Divider matching Figma (short lines and centered label)
                  Builder(
                    builder: (context) {
                      final sideWidth =
                          MediaQuery.of(context).size.width *
                          AppDimensions.authDividerSideWidthFactor;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: sideWidth,
                            height: AppDimensions.dividerThickness,
                            color: AppColors.divider,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppDimensions.dividerPadding,
                            ),
                            child: Text(
                              AppStrings.otherSignUpOptions,
                              style: AppTextStyles.dividerText,
                            ),
                          ),
                          Container(
                            width: sideWidth,
                            height: AppDimensions.dividerThickness,
                            color: AppColors.divider,
                          ),
                        ],
                      );
                    },
                  ),

                  SizedBox(height: size.height * AppDimensions.sectionSpacing),

                  // Social buttons row (outlined, icon-only to match login V2 style)
                  Row(
                    children: [
                      Expanded(
                        child: SocialButton(
                          icon: Image.asset(
                            'assets/Google/android_neutral_rd_na@2x.png',
                            width: AppDimensions.socialIconSize,
                            height: AppDimensions.socialIconSize,
                          ),
                          color: AppColors.google,
                          onPressed: () => controller.loginWithGoogle(),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.socialButtonSpacing),
                      Expanded(
                        child: SocialButton(
                          icon: Image.asset(
                            'assets/Facebook/Facebook_Logo_Primary.png',
                            width: AppDimensions.socialIconSize,
                            height: AppDimensions.socialIconSize,
                          ),
                          color: AppColors.facebook,
                          onPressed: () => controller.loginWithFacebook(),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: size.height * AppDimensions.sectionSpacing),

                  // Already have an account? Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        AppStrings.haveAccount,
                        style: AppTextStyles.bodySecondary,
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          final form = Get.find<FormControllers>();
                          final validation = Get.find<ValidationController>();
                          final email = form.emailController.text;
                          // Clear email error; keep email only if valid
                          validation.clearEmailError();
                          if (!validation.isEmailValid(email)) {
                            form.emailController.clear();
                          }
                          // Never carry password between login/signup
                          form.passwordController.clear();
                          // Clear password validation state to avoid leakage into Login
                          validation.clearPasswordValidation();
                          Get.offNamed(AppRoutes.login);
                        },
                        child: const Text(
                          AppStrings.loginButton,
                          style: AppTextStyles.buttonLink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
