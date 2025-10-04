import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ascoa_app/modules/profile/controllers/change_password_controller.dart';
import 'package:ascoa_app/modules/profile/models/change_password_status.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_images.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/constants/app_typography.dart';
import 'package:ascoa_app/shared/widgets/floating_label_input_field.dart';
import 'package:ascoa_app/shared/widgets/password_strength_checklist.dart';
import 'package:ascoa_app/shared/widgets/primary_button.dart';

class ChangePasswordScreen extends GetWidget<ChangePasswordController> {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isFrench = Get.locale?.languageCode == 'fr';
    final title =
        isFrench
            ? AppStrings.changePasswordTitleFrench
            : AppStrings.changePasswordTitle;
    final subtitle =
        isFrench
            ? AppStrings.changePasswordSubtitleFrench
            : AppStrings.changePasswordSubtitle;
    final currentPasswordLabel =
        isFrench
            ? AppStrings.currentPasswordLabelFrench
            : AppStrings.currentPasswordLabel;
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
            ? AppStrings.changePasswordButtonFrench
            : AppStrings.changePasswordButton;
    final submittingLabel =
        isFrench
            ? AppStrings.changePasswordSavingFrench
            : AppStrings.changePasswordSaving;
    final cancelLabel =
        isFrench
            ? AppStrings.changePasswordCancelFrench
            : AppStrings.changePasswordCancel;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final viewportHeight = constraints.maxHeight;
            final viewportWidth = constraints.maxWidth;

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
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.screenPadding,
                        // vertical: AppDimensions.verticalPadding,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppDimensions.profileContentMaxWidth,
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
                                    onPressed: () => Get.back(),
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: AppColors.buttonGreen,
                                      size: AppDimensions.iconBackSize,
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
                                  style: AppTextStyles.heading2.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: AppDimensions.heading2FontSize,
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
                                const SizedBox(
                                  height: AppDimensions.smallSpacing,
                                ),
                                Text(
                                  subtitle,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body.copyWith(
                                    fontSize: AppDimensions.subtitleFontSize,
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
                                  () => FloatingLabelInputField(
                                    controller:
                                        controller.currentPasswordController,
                                    label: currentPasswordLabel,
                                    hint: '••••••••',
                                    obscure: true,
                                    supportText:
                                        controller.currentPasswordError.value,
                                    isError:
                                        controller.currentPasswordError.value !=
                                        null,
                                    onChanged:
                                        controller.validateCurrentPassword,
                                    textInputAction: TextInputAction.next,
                                  ),
                                ),
                                const SizedBox(
                                  height: AppDimensions.fieldVerticalSpacing,
                                ),
                                Obx(
                                  () => Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      FloatingLabelInputField(
                                        controller:
                                            controller.newPasswordController,
                                        label: newPasswordLabel,
                                        hint: '••••••••',
                                        obscure: true,
                                        supportText:
                                            validation
                                                    .showPasswordChecklist
                                                    .value
                                                ? null
                                                : validation
                                                    .passwordError
                                                    .value,
                                        isError:
                                            validation.passwordError.value !=
                                                null &&
                                            !validation
                                                .showPasswordChecklist
                                                .value,
                                        onChanged:
                                            controller.validateNewPassword,
                                        onFocusChange:
                                            controller.handleNewPasswordFocus,
                                        textInputAction: TextInputAction.next,
                                      ),
                                      if (validation
                                          .showPasswordChecklist
                                          .value)
                                        const PasswordStrengthChecklist(
                                          padding: EdgeInsets.only(
                                            top:
                                                AppDimensions.inputErrorSpacing,
                                            left:
                                                AppDimensions
                                                    .chipHorizontalPadding,
                                            right:
                                                AppDimensions
                                                    .chipHorizontalPadding,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: AppDimensions.fieldVerticalSpacing,
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
                                    onPressed: () async {
                                      if (isSubmitting) return;
                                      FocusScope.of(context).unfocus();
                                      final result = await controller.submit();
                                      if (result ==
                                          ChangePasswordStatus.success) {
                                        if (!context.mounted) {
                                          return;
                                        }
                                        await Navigator.of(context).maybePop();
                                        Get.back(result: true);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(
                                  height: AppDimensions.smallSpacing,
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  height: AppDimensions.buttonHeight,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: AppColors.buttonGreen,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppDimensions.borderRadius,
                                        ),
                                      ),
                                    ),
                                    onPressed: () => Get.back(),
                                    child: Text(
                                      cancelLabel,
                                      style: AppTextStyles.buttonPrimaryText
                                          .copyWith(color: AppColors.textDark),
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
      ),
    );
  }
}
