import 'package:ascoa_app/app/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:ascoa_app/shared/controllers/form_controllers.dart';
import 'package:ascoa_app/shared/controllers/validation_controller.dart';
import 'package:ascoa_app/shared/widgets/custom_input_field.dart';
import 'package:ascoa_app/shared/widgets/primary_button.dart';
import 'package:ascoa_app/shared/widgets/social_button.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/app/routes/app_routes.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
                  AppStrings.loginTitle,
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

                SizedBox(height: size.height * AppDimensions.buttonSpacing),

                //Login Button
                PrimaryButton(
                  label: AppStrings.loginButton,
                  onPressed: () {
                    // Validate form
                    validationController.validateEmail(
                      formControllers.emailController.text,
                    );
                    validationController.validatePasswordRequired(
                      formControllers.passwordController.text,
                    );

                    // Only proceed if form is valid
                    if (validationController.isFormValid) {
                      controller.login(
                        formControllers.emailController.text,
                        formControllers.passwordController.text,
                      );
                    }
                  },
                ),

                SizedBox(
                  height: size.height * AppDimensions.buttonForgotSpacing,
                ),

                //Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Get.snackbar(
                        AppStrings.forgotPassword,
                        AppStrings.forgotPasswordNav,
                      );
                    },
                    child: const Text(
                      AppStrings.forgotPassword,
                      style: AppTextStyles.buttonLink,
                    ),
                  ),
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
                        AppStrings.dividerOr,
                        style: AppTextStyles.dividerText,
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
                  label: AppStrings.continueWithGoogle,
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
                  label: AppStrings.continueWithFacebook,
                  color: AppColors.facebook,
                  onPressed: () => controller.loginWithFacebook(),
                ),

                SizedBox(height: size.height * AppDimensions.sectionSpacing),

                // Sign Up (only 'Sign up' is a link)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      AppStrings.noAccount,
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
                          AppRoutes.signup,
                        ); // Navigate to Signup Screen
                      },
                      child: const Text(
                        AppStrings.signUp,
                        style: AppTextStyles.buttonLink,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.bottomSpacing),

                // Terms
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTextStyles.termsBase,
                    children: [
                      const TextSpan(text: AppStrings.termsText),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
