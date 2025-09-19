import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ascoa_app/app/controllers/auth_controller.dart';
import 'package:ascoa_app/shared/controllers/form_controllers.dart';
import 'package:ascoa_app/shared/controllers/validation_controller.dart';
// import removed: legacy CustomInputField no longer used in V2
import 'package:ascoa_app/shared/widgets/floating_label_input_field.dart';
import 'package:ascoa_app/shared/widgets/auth_header.dart';
import 'package:ascoa_app/shared/utils/auth_form_utils.dart';
import 'package:ascoa_app/shared/widgets/primary_button.dart';
import 'package:ascoa_app/shared/widgets/social_button.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/app/routes/app_routes.dart';

/// New experimental Login Screen matching Figma absolute layout
/// while remaining responsive and using shared components.
class LoginScreenV2 extends StatelessWidget {
  const LoginScreenV2({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final AuthController controller = Get.find<AuthController>();
    final FormControllers formControllers = Get.find<FormControllers>();
    final ValidationController validationController =
        Get.find<ValidationController>();

    // Dynamic scaling relative to reference width 440 from design
    const double referenceWidth = 440.0;
    final double scale = (size.width / referenceWidth).clamp(0.8, 1.25);

    return Scaffold(
      body: Stack(
        children: [
          // Background base color
          Container(color: AppColors.background),

          // Top SVG decorative asset
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/ASCOA/Login_Top.png',
              width: size.width,
              fit: BoxFit.cover,
            ),
          ),

          // Bottom SVG decorative asset
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/ASCOA/Login_Bottom.png',
              width: size.width,
              fit: BoxFit.cover,
            ),
          ),

          // Scrollable content overlay
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPadding,
                vertical: AppDimensions.verticalPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      size.height - MediaQuery.of(context).padding.vertical,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height:
                            size.height * AppDimensions.authHeaderTopSpacing,
                      ),

                      // Shared auth header (logo + tagline)
                      AuthHeader(scale: scale),

                      // Floating label email field
                      Obx(
                        () => FloatingLabelInputField(
                          controller: formControllers.emailController,
                          label: AppStrings.emailLabel,
                          hint: AppStrings.emailHint,
                          obscure: false,
                          supportText: validationController.emailError.value,
                          isError:
                              validationController.emailError.value != null,
                          onChanged: validationController.validateEmail,
                        ),
                      ),
                      SizedBox(
                        height: size.height * AppDimensions.buttonSpacing,
                      ),
                      // Floating label password field
                      Obx(
                        () => FloatingLabelInputField(
                          controller: formControllers.passwordController,
                          label: AppStrings.passwordLabel,
                          hint: AppStrings.passwordHint,
                          obscure: true,
                          supportText: validationController.passwordError.value,
                          isError:
                              validationController.passwordError.value != null,
                          onChanged:
                              validationController.validatePasswordRequired,
                        ),
                      ),

                      SizedBox(
                        height: size.height * AppDimensions.buttonSpacing,
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            final form = Get.find<FormControllers>();
                            final validation = Get.find<ValidationController>();
                            final currentEmail = form.emailController.text;
                            validation.clearEmailError();
                            if (!validation.isEmailValid(currentEmail)) {
                              form.emailController.clear();
                            }
                            Get.toNamed(AppRoutes.forgotPassword);
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            AppStrings.forgotPassword,
                            style: AppTextStyles.buttonLink,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: size.height * AppDimensions.buttonForgotSpacing,
                      ),
                      // Login button (full width to match inputs)
                      PrimaryButton(
                        label: AppStrings.loginButton,
                        onPressed: () {
                          final ok = AuthFormUtils.validateLogin(
                            validationController,
                            formControllers.emailController.text,
                            formControllers.passwordController.text,
                          );
                          if (ok) {
                            controller.login(
                              formControllers.emailController.text,
                              formControllers.passwordController.text,
                            );
                          }
                        },
                      ),

                      // Forgot password link (align right)
                      SizedBox(
                        height:
                            size.height * AppDimensions.authScreenSpacerSmall,
                      ),

                      // Social buttons row (outlined style approx)
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
                          const SizedBox(
                            width: AppDimensions.socialButtonSpacing,
                          ),
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

                      SizedBox(
                        height:
                            size.height * AppDimensions.authScreenSpacerMedium,
                      ),

                      // Signup link row
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
                              final form = Get.find<FormControllers>();
                              final validation =
                                  Get.find<ValidationController>();
                              final email = form.emailController.text;
                              validation.clearEmailError();
                              if (!validation.isEmailValid(email)) {
                                form.emailController.clear();
                              }
                              form.passwordController.clear();
                              // Reset password-related validation so styles/checklist don't leak into Signup
                              validation.clearPasswordValidation();
                              Get.offNamed(AppRoutes.signup);
                            },
                            child: const Text(
                              AppStrings.signUp,
                              style: AppTextStyles.buttonLink,
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Terms
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppDimensions.bottomSpacing,
                        ),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: AppTextStyles.termsBase,
                            children: const [
                              TextSpan(text: AppStrings.termsText),
                              TextSpan(
                                text: AppStrings.termsLink,
                                style: AppTextStyles.termsLink,
                              ),
                              TextSpan(text: AppStrings.termsAnd),
                              TextSpan(
                                text: AppStrings.privacyPolicyLink,
                                style: AppTextStyles.termsLink,
                              ),
                              TextSpan(text: AppStrings.termsPeriod),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// _LogoGroup extracted to shared widget: lib/shared/widgets/auth_header.dart
