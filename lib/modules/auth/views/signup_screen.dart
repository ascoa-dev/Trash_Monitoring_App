import 'package:we_monitor/app/controllers/auth_controller.dart';
import 'package:we_monitor/app/controllers/haptic_controller.dart';
import 'package:we_monitor/shared/services/snackbar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
// Using dedicated signup form controller for isolated lifecycle
import 'package:we_monitor/shared/controllers/form_controllers.dart';
import 'package:we_monitor/shared/controllers/validation_controller.dart';
import 'package:we_monitor/shared/widgets/floating_label_input_field.dart';
import 'package:we_monitor/shared/widgets/password_strength_checklist.dart';
import 'package:we_monitor/shared/widgets/primary_button.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:we_monitor/shared/widgets/social_button.dart';
import 'package:we_monitor/app/routes/app_routes.dart';
import 'package:we_monitor/shared/widgets/auth_header.dart';
import 'package:we_monitor/shared/constants/app_images.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:we_monitor/shared/analytics/analytics_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  @override
  void initState() {
    super.initState();
    Analytics.screenView(AnalyticsEvents.signupScreenViewed);
  }

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();
    final AuthController controller = Get.find<AuthController>();
    final FormControllers formControllers = Get.find<FormControllers>();
    final ValidationController validationController =
        Get.find<ValidationController>();

    // Scale for AuthHeader like Login V2
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

          final double scale = (viewportWidth /
                  AppDimensions.loginReferenceWidth)
              .clamp(AppDimensions.authScaleMin, AppDimensions.authScaleMax);

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
                    AppImages.signupTop,
                    width: viewportWidth,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
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
                        SizedBox(
                          height:
                              viewportHeight *
                              AppDimensions.authScreenXLargeSpacer,
                        ),
                        AuthHeader(scale: scale),
                        SizedBox(
                          height: SizeUtils.h(
                            context,
                            AppDimensions.verticalPadding,
                          ),
                        ),
                        Text(
                          AppStrings.signupTitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading2(context),
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
                                    top: SizeUtils.h(
                                      context,
                                      AppDimensions.inputErrorSpacing,
                                    ),
                                    left: SizeUtils.w(
                                      context,
                                      AppDimensions.chipHorizontalPadding,
                                    ),
                                    right: SizeUtils.w(
                                      context,
                                      AppDimensions.chipHorizontalPadding,
                                    ),
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
                                    width: SizeUtils.r(
                                      context,
                                      AppDimensions.checkboxSize,
                                    ),
                                    height: SizeUtils.r(
                                      context,
                                      AppDimensions.checkboxSize,
                                    ),
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
                                                ? SizeUtils.w(
                                                  context,
                                                  AppDimensions
                                                      .inputBorderWidthError,
                                                )
                                                : SizeUtils.w(
                                                  context,
                                                  AppDimensions.borderWidth,
                                                ),
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        SizeUtils.r(
                                          context,
                                          AppDimensions.checkboxCornerRadius,
                                        ),
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
                                  SizedBox(
                                    width: SizeUtils.w(
                                      context,
                                      AppDimensions.tinySpacing,
                                    ),
                                  ),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: AppTextStyles.termsBase(context),
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
                                                    Get.find<HapticController>()
                                                        .selectionClick();
                                                    SnackbarService.info(
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
                                                    Get.find<HapticController>()
                                                        .selectionClick();
                                                    SnackbarService.info(
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
                                  padding: EdgeInsets.only(
                                    top: SizeUtils.h(
                                      context,
                                      AppDimensions.smallSpacing,
                                    ),
                                  ),
                                  child: Text(
                                    validationController.termsError.value!,
                                    style: AppTextStyles.errorText(context),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: viewportHeight * AppDimensions.sectionSpacing,
                        ),
                        PrimaryButton(
                          label: AppStrings.signupButton,
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
                              Get.find<HapticController>().medium();
                              Analytics.track(AnalyticsEvents.signupStarted);
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
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: SizeUtils.h(
                                  context,
                                  AppDimensions.dividerThickness,
                                ),
                                color: AppColors.divider,
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
                                AppStrings.otherSignUpOptions,
                                style: AppTextStyles.dividerText(context),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: SizeUtils.h(
                                  context,
                                  AppDimensions.dividerThickness,
                                ),
                                color: AppColors.divider,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: viewportHeight * AppDimensions.sectionSpacing,
                        ),
                        SocialButton(
                          icon: Image.asset(
                            AppImages.googleNeutral2x,
                            width: SizeUtils.r(
                              context,
                              AppDimensions.socialIconSize,
                            ),
                            height: SizeUtils.r(
                              context,
                              AppDimensions.socialIconSize,
                            ),
                          ),
                          color: AppColors.google,
                          onPressed: () => controller.loginWithGoogle(),
                        ),
                        SizedBox(
                          height: viewportHeight * AppDimensions.sectionSpacing,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppStrings.haveAccount,
                              style: AppTextStyles.bodySecondary(context),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                Get.find<HapticController>().selectionClick();
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
                              child: Text(
                                AppStrings.loginButton,
                                style: AppTextStyles.buttonLink(context),
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
