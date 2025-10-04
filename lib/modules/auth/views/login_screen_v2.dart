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
import 'package:ascoa_app/shared/constants/app_images.dart';

/// New experimental Login Screen matching Figma absolute layout
/// while remaining responsive and using shared components.
class LoginScreenV2 extends StatelessWidget {
  const LoginScreenV2({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController controller = Get.find<AuthController>();
    final FormControllers formControllers = Get.find<FormControllers>();
    final ValidationController validationController =
        Get.find<ValidationController>();
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double viewportHeight = constraints.maxHeight;
          final double viewportWidth = constraints.maxWidth;
          final EdgeInsets viewPadding = MediaQuery.of(context).padding;

          const double referenceWidth = 440.0;
          final double scale = (viewportWidth / referenceWidth).clamp(
            0.8,
            1.25,
          );

          return Container(
            width: viewportWidth,
            height: viewportHeight,
            color: AppColors.background,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: AppDimensions.zero,
                  left: AppDimensions.zero,
                  right: AppDimensions.zero,
                  child: Image.asset(
                    AppImages.loginTop,
                    width: viewportWidth,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
                Positioned(
                  bottom: AppDimensions.zero,
                  left: AppDimensions.zero,
                  right: AppDimensions.zero,
                  child: Image.asset(
                    AppImages.loginBottom,
                    width: viewportWidth,
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.screenPadding,
                      vertical: AppDimensions.verticalPadding,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: viewportHeight - viewPadding.vertical,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height:
                                  viewportHeight *
                                  AppDimensions.authHeaderTopSpacing,
                            ),
                            AuthHeader(scale: scale),
                            Obx(
                              () => FloatingLabelInputField(
                                controller: formControllers.emailController,
                                label: AppStrings.emailLabel,
                                hint: AppStrings.emailHint,
                                obscure: false,
                                supportText:
                                    validationController.emailError.value,
                                isError:
                                    validationController.emailError.value !=
                                    null,
                                onChanged: validationController.validateEmail,
                              ),
                            ),
                            SizedBox(
                              height:
                                  viewportHeight * AppDimensions.buttonSpacing,
                            ),
                            Obx(
                              () => FloatingLabelInputField(
                                controller: formControllers.passwordController,
                                label: AppStrings.passwordLabel,
                                hint: AppStrings.passwordHint,
                                obscure: true,
                                supportText:
                                    validationController.passwordError.value,
                                isError:
                                    validationController.passwordError.value !=
                                    null,
                                onChanged:
                                    validationController
                                        .validatePasswordRequired,
                              ),
                            ),
                            SizedBox(
                              height:
                                  viewportHeight * AppDimensions.buttonSpacing,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  final form = Get.find<FormControllers>();
                                  final validation =
                                      Get.find<ValidationController>();
                                  final currentEmail =
                                      form.emailController.text;
                                  validation.clearEmailError();
                                  if (!validation.isEmailValid(currentEmail)) {
                                    form.emailController.clear();
                                  }
                                  Get.toNamed(AppRoutes.forgotPassword);
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  AppStrings.forgotPassword,
                                  style: AppTextStyles.buttonLink,
                                ),
                              ),
                            ),
                            SizedBox(
                              height:
                                  viewportHeight *
                                  AppDimensions.buttonForgotSpacing,
                            ),
                            Obx(() {
                              final isLoading = controller.isLoadingLogin.value;
                              return PrimaryButton(
                                label:
                                    isLoading
                                        ? AppStrings.loggingIn
                                        : AppStrings.loginButton,
                                onPressed:
                                    isLoading
                                        ? () {}
                                        : () {
                                          final ok =
                                              AuthFormUtils.validateLogin(
                                                validationController,
                                                formControllers
                                                    .emailController
                                                    .text,
                                                formControllers
                                                    .passwordController
                                                    .text,
                                              );
                                          if (ok) {
                                            controller.login(
                                              formControllers
                                                  .emailController
                                                  .text,
                                              formControllers
                                                  .passwordController
                                                  .text,
                                            );
                                          }
                                        },
                              );
                            }),
                            SizedBox(
                              height:
                                  viewportHeight *
                                  AppDimensions.authScreenSpacerSmall,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: SocialButton(
                                    icon: Image.asset(
                                      AppImages.googleNeutral2x,
                                      width: AppDimensions.socialIconSize,
                                      height: AppDimensions.socialIconSize,
                                    ),
                                    color: AppColors.google,
                                    onPressed:
                                        () => controller.loginWithGoogle(),
                                  ),
                                ),
                                const SizedBox(
                                  width: AppDimensions.socialButtonSpacing,
                                ),
                                Expanded(
                                  child: SocialButton(
                                    icon: Image.asset(
                                      AppImages.facebookPrimary,
                                      width: AppDimensions.socialIconSize,
                                      height: AppDimensions.socialIconSize,
                                    ),
                                    color: AppColors.facebook,
                                    onPressed:
                                        () => controller.loginWithFacebook(),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height:
                                  viewportHeight *
                                  AppDimensions.authScreenSpacerMedium,
                            ),
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
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
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
        },
      ),
    );
  }
}

// _LogoGroup extracted to shared widget: lib/shared/widgets/auth_header.dart
