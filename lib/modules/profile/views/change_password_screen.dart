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
import 'package:ascoa_app/shared/utils/size_utils.dart';

class ChangePasswordScreen extends GetWidget<ChangePasswordController> {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();
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
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: SizeUtils.w(context, AppDimensions.screenPadding),
                      right: SizeUtils.w(context, AppDimensions.screenPadding),
                      top: SizeUtils.h(
                        context,
                        AppDimensions.verticalPadding * 0.6,
                      ),
                      bottom:
                          keyboardHeight > 0
                              ? keyboardHeight
                              : 0, // Add padding for keyboard
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
                                  onPressed: () => Get.back(),
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
                                  onChanged: controller.validateCurrentPassword,
                                  textInputAction: TextInputAction.next,
                                ),
                              ),
                              SizedBox(
                                height: SizeUtils.h(
                                  context,
                                  AppDimensions.fieldVerticalSpacing,
                                ),
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
                                  onPressed: () => Get.back(),
                                  child: Text(
                                    cancelLabel,
                                    style: AppTextStyles.buttonPrimaryText(context).copyWith(color: AppColors.textDark),
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
