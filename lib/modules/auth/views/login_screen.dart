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
import 'package:ascoa_app/shared/constants/app_images.dart';
import 'package:ascoa_app/shared/utils/size_utils.dart';

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
          color: AppColors.background, // Page background
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: SizeUtils.w(context, AppDimensions.screenPadding),
              vertical: SizeUtils.h(context, AppDimensions.verticalPadding),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: size.height * AppDimensions.titleTopSpacing),

                // Title
                Text(
                  AppStrings.loginTitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading1(context),
                ),

                SizedBox(
                  height: size.height * AppDimensions.titleBottomSpacing,
                ),

                // Email Label
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppStrings.emailLabel,
                    style: AppTextStyles.label(context),
                  ),
                ),
                SizedBox(
                  height: SizeUtils.h(context, AppDimensions.smallSpacing),
                ),

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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppStrings.passwordLabel,
                    style: AppTextStyles.label(context),
                  ),
                ),
                SizedBox(
                  height: SizeUtils.h(context, AppDimensions.smallSpacing),
                ),

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
                      final form = Get.find<FormControllers>();
                      final validation = Get.find<ValidationController>();
                      final currentEmail = form.emailController.text;
                      // Do not carry over error state
                      validation.clearEmailError();
                      // Only keep a valid email, otherwise clear on next screen
                      if (!validation.isEmailValid(currentEmail)) {
                        form.emailController.clear();
                      }
                      Get.toNamed(AppRoutes.forgotPassword);
                    },
                    child: Text(
                      AppStrings.forgotPassword,
                      style: AppTextStyles.buttonLink(context),
                    ),
                  ),
                ),
                SizedBox(height: size.height * AppDimensions.sectionSpacing),

                // OR Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color:
                            AppColors
                                .divider, // Light gray for white background
                        thickness: SizeUtils.h(
                          context,
                          AppDimensions.dividerThickness,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: SizeUtils.w(
                          context,
                          AppDimensions.dividerPadding,
                        ),
                      ),
                      child: Text(
                        AppStrings.dividerOr,
                        style: AppTextStyles.dividerText(context),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color:
                            AppColors
                                .divider, // Light gray for white background
                        thickness: SizeUtils.h(
                          context,
                          AppDimensions.dividerThickness,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: size.height * AppDimensions.sectionSpacing),

                // Google Button
                SocialButton(
                  icon: Image.asset(
                    AppImages.googleNeutral2x,
                    width: SizeUtils.r(context, AppDimensions.socialIconSize),
                    height: SizeUtils.r(context, AppDimensions.socialIconSize),
                    fit: BoxFit.contain,
                  ),
                  label: AppStrings.continueWithGoogle,
                  color: AppColors.google,
                  onPressed: () => controller.loginWithGoogle(),
                ),

                SizedBox(
                  height: SizeUtils.h(
                    context,
                    AppDimensions.socialButtonSpacing,
                  ),
                ),

                // Facebook Button
                SocialButton(
                  icon: Image.asset(
                    AppImages.facebookPrimary,
                    width: SizeUtils.r(context, AppDimensions.socialIconSize),
                    height: SizeUtils.r(context, AppDimensions.socialIconSize),
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
                    Text(
                      AppStrings.noAccount,
                      style: AppTextStyles.bodySecondary(context),
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
                        validation.clearEmailError();
                        if (!validation.isEmailValid(email)) {
                          form.emailController.clear();
                        }
                        form.passwordController.clear();
                        // Prevent password error/checklist state from leaking into Signup
                        validation.clearPasswordValidation();
                        Get.offNamed(AppRoutes.signup);
                      },
                      child: Text(
                        AppStrings.signUp,
                        style: AppTextStyles.buttonLink(context),
                      ),
                    ),
                  ],
                ),

                SizedBox(
                  height: SizeUtils.h(context, AppDimensions.bottomSpacing),
                ),

                // Terms
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTextStyles.termsBase(context),
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
