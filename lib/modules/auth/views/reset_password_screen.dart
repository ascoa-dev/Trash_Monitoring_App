import 'package:ascoa_app/app/controllers/haptic_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ascoa_app/app/routes/app_routes.dart';
import 'package:ascoa_app/modules/auth/controllers/reset_password_controller.dart';
import 'package:ascoa_app/modules/auth/models/reset_password_status.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_images.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/constants/app_typography.dart';
import 'package:ascoa_app/shared/controllers/form_controllers.dart';
import 'package:ascoa_app/shared/controllers/validation_controller.dart';
import 'package:ascoa_app/shared/utils/size_utils.dart';
import 'package:ascoa_app/shared/widgets/app_dialog.dart';
import 'package:ascoa_app/shared/widgets/floating_label_input_field.dart';
import 'package:ascoa_app/shared/widgets/password_strength_checklist.dart';
import 'package:ascoa_app/shared/widgets/primary_button.dart';

class ResetPasswordScreen extends GetWidget<ResetPasswordController> {
  const ResetPasswordScreen({super.key});

  Future<void> _showSuccessDialog(BuildContext context) async {
    final isFrench = Get.locale?.languageCode == 'fr';
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AppDialog(
          title:
              isFrench
                  ? AppStrings.resetPasswordSuccessTitleFrench
                  : AppStrings.resetPasswordSuccessTitle,
          decoratedHero: false,
          imageAsset: AppImages.passwordUpdateSuccessful,
          imageWidth: SizeUtils.w(ctx, AppDimensions.dialogImageWidth),
          imageHeight: SizeUtils.h(ctx, AppDimensions.dialogImageHeight),
          body: null,
          primaryActionLabel:
              isFrench
                  ? AppStrings.resetPasswordSuccessButtonFrench
                  : AppStrings.resetPasswordSuccessButton,
          onPrimaryAction: () {
            Navigator.of(ctx).pop();
            _navigateToLogin();
          },
        );
      },
    );
  }

  void _navigateToLogin() {
    Get.find<HapticController>().selectionClick();
    if (Get.isRegistered<FormControllers>()) {
      Get.find<FormControllers>().resetAuthFields();
    }
    if (Get.isRegistered<ValidationController>()) {
      final validation = Get.find<ValidationController>();
      validation.clearEmailError();
      validation.clearPasswordValidation();
    }
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> _handleSubmit(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final status = await controller.submit();
    if (status == ResetPasswordStatus.success && context.mounted) {
      Get.find<HapticController>().medium();
      await _showSuccessDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();
    final isFrench = Get.locale?.languageCode == 'fr';
    final title =
        isFrench
            ? AppStrings.resetPasswordTitleFrench
            : AppStrings.resetPasswordTitle;
    final subtitle =
        isFrench
            ? AppStrings.resetPasswordSubtitleFrench
            : AppStrings.resetPasswordSubtitle;
    final newPasswordLabel =
        isFrench
            ? AppStrings.newPasswordLabelFrench
            : AppStrings.newPasswordLabel;
    final confirmPasswordLabel =
        isFrench
            ? AppStrings.confirmPasswordLabelFrench
            : AppStrings.confirmPasswordLabel;
    final submitLabel =
        isFrench
            ? AppStrings.resetPasswordButtonFrench
            : AppStrings.resetPasswordButton;
    final submittingLabel =
        isFrench
            ? AppStrings.resetPasswordSavingFrench
            : AppStrings.resetPasswordSaving;
    final cancelLabel =
        isFrench
            ? AppStrings.changePasswordCancelFrench
            : AppStrings.changePasswordCancel;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewportHeight = constraints.maxHeight;
          final viewportWidth = constraints.maxWidth;
          final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

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
                  height:
                      viewportHeight *
                      AppDimensions.profileTopBackgroundHeightFactor,
                  child: Image.asset(
                    AppImages.signupTop,
                    width: viewportWidth,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
                Positioned(
                  left: AppDimensions.zero,
                  right: AppDimensions.zero,
                  bottom: AppDimensions.zero,
                  height:
                      viewportHeight * AppDimensions.editProfileHeightFactor,
                  child: Image.asset(
                    AppImages.editProfileBottom,
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
                      top: SizeUtils.h(
                        context,
                        AppDimensions.verticalPadding * 0.6,
                      ),
                      bottom: keyboardHeight > 0 ? keyboardHeight : 0,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: SizeUtils.w(
                            context,
                            AppDimensions.profileContentMaxWidth,
                          ),
                        ),
                        child: Obx(() {
                          final validation = controller.validationController;
                          final isSubmitting = controller.isSubmitting.value;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  onPressed: _navigateToLogin,
                                  padding: EdgeInsets.zero,
                                  icon: Icon(
                                    Icons.arrow_back,
                                    color: AppColors.buttonGreen,
                                    size: SizeUtils.r(
                                      context,
                                      AppDimensions.iconBackSize,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height:
                                    viewportHeight *
                                    AppDimensions.changePasswordTopSpacing,
                              ),
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.heading2(context).copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: SizeUtils.h(
                                    context,
                                    AppDimensions.heading2FontSize,
                                  ),
                                  color: AppColors.textDark,
                                  letterSpacing:
                                      AppTypography.letterSpacingSmall,
                                ),
                              ),
                              SizedBox(
                                height:
                                    viewportHeight *
                                    AppDimensions.halfInputSpacing,
                              ),
                              Image.asset(
                                AppImages.forgotPasswordIcon,
                                height:
                                    viewportHeight *
                                    AppDimensions.changePasswordIconSize,
                              ),
                              SizedBox(
                                height: SizeUtils.h(
                                  context,
                                  AppDimensions.smallSpacing,
                                ),
                              ),
                              Text(
                                subtitle,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.body(context).copyWith(
                                  fontSize: SizeUtils.h(
                                    context,
                                    AppDimensions.subtitleFontSize,
                                  ),
                                  letterSpacing:
                                      AppTypography.letterSpacingSmall,
                                  color: AppColors.textDark,
                                ),
                              ),
                              SizedBox(
                                height:
                                    viewportHeight *
                                    AppDimensions
                                        .changePasswordHalfInputSpacing,
                              ),
                              Obx(
                                () => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FloatingLabelInputField(
                                      controller:
                                          controller.newPasswordController,
                                      label: newPasswordLabel,
                                      hint: '••••••••',
                                      obscure: true,
                                      supportText:
                                          validation.showPasswordChecklist.value
                                              ? null
                                              : validation.passwordError.value,
                                      isError:
                                          validation.passwordError.value !=
                                              null &&
                                          !validation
                                              .showPasswordChecklist
                                              .value,
                                      onChanged: controller.validateNewPassword,
                                      onFocusChange:
                                          controller.handleNewPasswordFocus,
                                      textInputAction: TextInputAction.next,
                                    ),
                                    if (validation.showPasswordChecklist.value)
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
                                height: SizeUtils.h(
                                  context,
                                  AppDimensions.fieldVerticalSpacing,
                                ),
                              ),
                              Obx(
                                () => FloatingLabelInputField(
                                  controller:
                                      controller.confirmPasswordController,
                                  label: confirmPasswordLabel,
                                  hint: '••••••••',
                                  obscure: true,
                                  supportText:
                                      controller.confirmPasswordError.value,
                                  isError:
                                      controller.confirmPasswordError.value !=
                                      null,
                                  onChanged:
                                      (value) =>
                                          controller.validateConfirmPassword(
                                            value,
                                            fromConfirmField: true,
                                          ),
                                  textInputAction: TextInputAction.done,
                                ),
                              ),
                              SizedBox(
                                height:
                                    viewportHeight *
                                    AppDimensions.buttonSpacing,
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: PrimaryButton(
                                  label:
                                      isSubmitting
                                          ? submittingLabel
                                          : submitLabel,
                                  onPressed: () {
                                    if (isSubmitting) {
                                      return;
                                    }
                                    _handleSubmit(context);
                                  },
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
                                  onPressed: _navigateToLogin,
                                  child: Text(
                                    cancelLabel,
                                    style: AppTextStyles.buttonPrimaryText(
                                      context,
                                    ).copyWith(color: AppColors.textDark),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
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
