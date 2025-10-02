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
    final AuthController controller = Get.find<AuthController>();
    final FormControllers formControllers = Get.find<FormControllers>();
    final ValidationController validationController =
        Get.find<ValidationController>();

    // Scale for AuthHeader like Login V2
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double viewportHeight = constraints.maxHeight;
          final double viewportWidth = constraints.maxWidth;

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
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    'assets/ASCOA/Signup_Screen_Top.png',
                    width: viewportWidth,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
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
                          height:
                              viewportHeight *
                              AppDimensions.authScreenXLargeSpacer,
                        ),
                        AuthHeader(scale: scale),
                        const SizedBox(height: 16),
                        const Text(
                          AppStrings.signupTitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading2,
                        ),
                        SizedBox(
                          height:
                              viewportHeight * AppDimensions.titleBottomSpacing,
                        ),
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
                          height: viewportHeight * AppDimensions.inputSpacing,
                        ),
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
                                    validationController
                                            .showPasswordChecklist
                                            .value
                                        ? null
                                        : validationController
                                            .passwordError
                                            .value,
                                onChanged: (val) {
                                  validationController.updatePasswordRules(val);
                                  validationController.validateStrongPassword(
                                    val,
                                  );
                                },
                                onFocusChange: (focused) {
                                  if (focused) {
                                    validationController
                                        .showPasswordChecklist
                                        .value = true;
                                  } else {
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
                              if (validationController
                                  .showPasswordChecklist
                                  .value)
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
                        SizedBox(
                          height: viewportHeight * AppDimensions.inputSpacing,
                        ),
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
                                            validationController
                                                        .termsError
                                                        .value !=
                                                    null
                                                ? AppColors.error
                                                : AppColors.accentGreen,
                                        width:
                                            validationController
                                                        .termsError
                                                        .value !=
                                                    null
                                                ? AppDimensions
                                                    .inputBorderWidthError
                                                : AppDimensions.borderWidth,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppDimensions.checkboxCornerRadius,
                                      ),
                                    ),
                                    child: Checkbox(
                                      value:
                                          validationController
                                              .isTermsAccepted
                                              .value,
                                      onChanged: (val) {
                                        validationController
                                            .isTermsAccepted
                                            .value = val ?? false;
                                        if (val == true) {
                                          validationController
                                              .termsError
                                              .value = null;
                                        }
                                      },
                                      activeColor: AppColors.accentGreen,
                                      checkColor: AppColors.pureWhite,
                                      side: BorderSide.none,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: AppDimensions.tinySpacing,
                                  ),
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
                                          const TextSpan(
                                            text: AppStrings.termsAnd,
                                          ),
                                          TextSpan(
                                            text: AppStrings.privacyPolicyLink,
                                            style: AppTextStyles.termsLink,
                                            recognizer:
                                                TapGestureRecognizer()
                                                  ..onTap = () {
                                                    Get.snackbar(
                                                      AppStrings
                                                          .privacyPolicyLink,
                                                      AppStrings
                                                          .privacyPolicyNav,
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
                        SizedBox(
                          height: viewportHeight * AppDimensions.sectionSpacing,
                        ),
                        PrimaryButton(
                          label: AppStrings.signupTitle,
                          onPressed: () {
                            validationController.validateEmail(
                              formControllers.emailController.text,
                            );
                            validationController.validateStrongPassword(
                              formControllers.passwordController.text,
                            );

                            if (!validationController.isTermsAccepted.value) {
                              validationController.termsError.value =
                                  AppStrings.termsMustAccept;
                            }

                            if (validationController.isFormValid &&
                                validationController.isTermsAccepted.value) {
                              controller.signup(
                                formControllers.emailController.text,
                                formControllers.passwordController.text,
                              );
                            }
                          },
                        ),
                        SizedBox(
                          height: viewportHeight * AppDimensions.sectionSpacing,
                        ),
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
                        SizedBox(
                          height: viewportHeight * AppDimensions.sectionSpacing,
                        ),
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
                          height: viewportHeight * AppDimensions.sectionSpacing,
                        ),
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
                                final validation =
                                    Get.find<ValidationController>();
                                final email = form.emailController.text;
                                validation.clearEmailError();
                                if (!validation.isEmailValid(email)) {
                                  form.emailController.clear();
                                }
                                form.passwordController.clear();
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
        },
      ),
    );
  }
}
