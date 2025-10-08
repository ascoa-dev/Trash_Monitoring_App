import 'package:ascoa_app/app/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:ascoa_app/shared/controllers/form_controllers.dart';
import 'package:ascoa_app/shared/controllers/validation_controller.dart';
import 'package:ascoa_app/shared/widgets/custom_input_field.dart';
import 'package:ascoa_app/shared/widgets/primary_button.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/widgets/social_button.dart';
import 'package:ascoa_app/app/routes/app_routes.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final AuthController controller = Get.find<AuthController>();
    final FormControllers formControllers = Get.find<FormControllers>();
    final ValidationController validationController =
        Get.find<ValidationController>();

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          color: AppColors.primary, // Background blue
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPadding,
              vertical: AppDimensions.verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: size.height * AppDimensions.titleTopSpacing),

                // Title
                const Text(
                  AppStrings.signupTitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading1,
                ),

                SizedBox(
                  height: size.height * AppDimensions.titleBottomSpacing,
                ),

                // Email Label
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppStrings.emailLabel,
                    style: AppTextStyles.label,
                  ),
                ),
                const SizedBox(height: AppDimensions.smallSpacing),

                // Email Input
                Obx(
                  () => CustomInputField(
                    controller: formControllers.emailController,
                    hint: AppStrings.emailHint,
                    obscure: false,
                    errorText: validationController.emailError.value,
                    onChanged: validationController.validateEmail,
                  ),
                ),

                SizedBox(height: size.height * AppDimensions.inputSpacing),

                // Password Label
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppStrings.passwordLabel,
                    style: AppTextStyles.label,
                  ),
                ),
                const SizedBox(height: AppDimensions.smallSpacing),

                // Password Input
                Obx(
                  () => CustomInputField(
                    controller: formControllers.passwordController,
                    hint: AppStrings.passwordHint,
                    obscure: true,
                    errorText: validationController.passwordError.value,
                    onChanged: validationController.validatePasswordRequired,
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
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.accent, // Green border
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Checkbox(
                              value: validationController.isTermsAccepted.value,
                              onChanged: (value) {
                                debugPrint('Checkbox changed: $value');
                                validationController.isTermsAccepted.value =
                                    value ?? false;
                                if (value == true) {
                                  validationController.termsError.value = null;
                                }
                              },
                              activeColor: AppColors.accent,
                              checkColor: AppColors.white,
                              side: BorderSide.none, // Remove black border
                            ),
                          ),
                          const SizedBox(width: 10),
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
                                  const TextSpan(text: AppStrings.termsPeriod),
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

                // OR Divider
                Row(
                  children: [
                    const Expanded(
                      child: Divider(
                        color:
                            AppColors
                                .divider, // Light gray for white background
                        thickness: AppDimensions.dividerThickness,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.dividerPadding,
                      ),
                      child: Text(
                        'OR',
                        style:
                            AppTextStyles.dividerText, // Use consistent style
                      ),
                    ),
                    const Expanded(
                      child: Divider(
                        color:
                            AppColors
                                .divider, // Light gray for white background
                        thickness: AppDimensions.dividerThickness,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: size.height * AppDimensions.sectionSpacing),

                // Google Button
                SocialButton(
                  icon: Image.asset(
                    'assets/Google/android_neutral_rd_na@2x.png',
                    width: AppDimensions.socialIconSize,
                    height: AppDimensions.socialIconSize,
                    fit: BoxFit.contain,
                  ),
                  label: 'Continue with Google',
                  color: AppColors.google,
                  onPressed: () => controller.loginWithGoogle(),
                ),

                const SizedBox(height: AppDimensions.socialButtonSpacing),

                // Facebook Button
                SocialButton(
                  icon: Image.asset(
                    'assets/Facebook/Facebook_Logo_Primary.png',
                    width: AppDimensions.socialIconSize,
                    height: AppDimensions.socialIconSize,
                    fit: BoxFit.contain,
                  ),
                  label: 'Continue with Facebook',
                  color: AppColors.facebook,
                  onPressed: () => controller.loginWithFacebook(),
                ),

                SizedBox(height: size.height * AppDimensions.sectionSpacing),

                // Sign Up (only 'Sign up' is a link)
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
                        Get.offAllNamed(
                          AppRoutes.login,
                        ); // Navigate to Login Screen
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
      ),
    );
  }
}
