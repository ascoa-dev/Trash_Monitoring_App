import 'package:ascoa_app/app/controllers/haptic_controller.dart';
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
import 'package:ascoa_app/shared/utils/size_utils.dart';
import 'package:ascoa_app/shared/analytics/analytics_service.dart';

/// New experimental Login Screen matching Figma absolute layout
/// while remaining responsive and using shared components.
class LoginScreenV2 extends StatefulWidget {
  const LoginScreenV2({super.key});

  @override
  State<LoginScreenV2> createState() => _LoginScreenV2State();
}

class _LoginScreenV2State extends State<LoginScreenV2> {
  @override
  void initState() {
    super.initState();
    Analytics.screenView(AnalyticsEvents.loginScreenViewed);
  }

  @override
  Widget build(BuildContext context) {
    final haptics = Get.find<HapticController>();
    final ScrollController scrollController = ScrollController();
    final AuthController controller = Get.find<AuthController>();
    final FormControllers formControllers = Get.find<FormControllers>();
    final ValidationController validationController =
        Get.find<ValidationController>();
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double viewportHeight = constraints.maxHeight;
          final double viewportWidth = constraints.maxWidth;
          final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
          final EdgeInsets viewPadding = MediaQuery.of(context).padding;
          final double contentHeight =
              viewportHeight - viewPadding.top - viewPadding.bottom;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (keyboardHeight == 0 && scrollController.hasClients) {
              scrollController.jumpTo(0);
            }
          });

          final double referenceWidth = AppDimensions.loginReferenceWidth;
          final double scale = (viewportWidth / referenceWidth).clamp(
            AppDimensions.authScaleMin,
            AppDimensions.authScaleMax,
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
                  child: Hero(
                    tag: 'authTopImage',
                    child: Image.asset(
                      AppImages.loginTop,
                      width: viewportWidth,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
                Positioned(
                  bottom: AppDimensions.zero,
                  left: AppDimensions.zero,
                  right: AppDimensions.zero,
                  child: Hero(
                    tag: 'authBottomImage',
                    child: Image.asset(
                      AppImages.loginBottom,
                      width: viewportWidth,
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: SizeUtils.w(context, AppDimensions.screenPadding),
                      right: SizeUtils.w(context, AppDimensions.screenPadding),
                      top: SizeUtils.h(context, AppDimensions.verticalPadding),
                      bottom:
                          keyboardHeight > 0
                              ? keyboardHeight
                              : 0, // Only add padding when keyboard is visible
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: AppDimensions.profileContentMaxWidth,
                        ),
                        child: SingleChildScrollView(
                          controller: scrollController,
                          physics:
                              keyboardHeight > 0
                                  ? const AlwaysScrollableScrollPhysics()
                                  : const NeverScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: contentHeight,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height:
                                      (contentHeight *
                                          AppDimensions.authHeaderTopSpacing),
                                ),
                                Hero(
                                  tag: 'authHeader',
                                  child: Material(
                                    type: MaterialType.transparency,
                                    child: AuthHeader(scale: scale),
                                  ),
                                ),
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
                                    onChanged:
                                        validationController.validateEmail,
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      (contentHeight *
                                          AppDimensions.titleBottomSpacing),
                                ),
                                Obx(
                                  () => FloatingLabelInputField(
                                    controller:
                                        formControllers.passwordController,
                                    label: AppStrings.passwordLabel,
                                    hint: AppStrings.passwordHint,
                                    obscure: true,
                                    supportText:
                                        validationController
                                            .passwordError
                                            .value,
                                    isError:
                                        validationController
                                            .passwordError
                                            .value !=
                                        null,
                                    onChanged:
                                        validationController
                                            .validatePasswordRequired,
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      (contentHeight *
                                          AppDimensions.titleBottomSpacing),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      haptics.selectionClick();
                                      final form = Get.find<FormControllers>();
                                      final validation =
                                          Get.find<ValidationController>();
                                      final currentEmail =
                                          form.emailController.text;
                                      validation.clearEmailError();
                                      if (!validation.isEmailValid(
                                        currentEmail,
                                      )) {
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
                                    child: Text(
                                      AppStrings.forgotPassword,
                                      style: AppTextStyles.buttonLink(context),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      (contentHeight *
                                          AppDimensions.buttonForgotSpacing),
                                ),
                                Obx(() {
                                  final isLoading =
                                      controller.isLoadingLogin.value;
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
                                                Analytics.track(
                                                  AnalyticsEvents
                                                      .loginAttempted,
                                                );
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
                                      (contentHeight *
                                          AppDimensions.inputSpacing),
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
                                  height:
                                      (contentHeight *
                                          AppDimensions.titleBottomSpacing),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      AppStrings.noAccount,
                                      style: AppTextStyles.bodySecondary(
                                        context,
                                      ).copyWith(fontWeight: FontWeight.w500),
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () {
                                        haptics.selectionClick();
                                        final form =
                                            Get.find<FormControllers>();
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
                                      child: Text(
                                        AppStrings.signUp,
                                        style: AppTextStyles.buttonLink(
                                          context,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // const Spacer(),
                                SizedBox(
                                  height:
                                      (contentHeight *
                                          AppDimensions.inputSpacing),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                    // bottom: SizeUtils.h(context, AppDimensions.bottomSpacing),
                                  ),
                                  child: RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: AppTextStyles.termsBase(context),
                                      children: const [
                                        TextSpan(
                                          text: AppStrings.termsText,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        TextSpan(
                                          text: AppStrings.termsLink,
                                          style: AppTextStyles.termsLink,
                                        ),
                                        TextSpan(
                                          text: AppStrings.termsAnd,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
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
