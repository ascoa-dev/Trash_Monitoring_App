import 'package:ascoa_app/app/routes/app_routes.dart';
import 'package:ascoa_app/modules/profile/controllers/edit_profile_controller.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/constants/app_typography.dart';
import 'package:ascoa_app/shared/constants/app_images.dart';
import 'package:ascoa_app/shared/widgets/country_code_selector_field.dart';
import 'package:ascoa_app/shared/widgets/floating_label_input_field.dart';
import 'package:ascoa_app/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditProfileScreen extends GetWidget<EditProfileController> {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isFrench = Get.locale?.languageCode == 'fr';
    final title =
        isFrench
            ? AppStrings.editProfileTitleFrench
            : AppStrings.editProfileTitle;
    final subtitle =
        isFrench
            ? AppStrings.editProfileSubtitleFrench
            : AppStrings.editProfileSubtitle;
    final firstNameLabel =
        isFrench ? AppStrings.firstNameLabelFrench : AppStrings.firstNameLabel;
    final lastNameLabel =
        isFrench ? AppStrings.lastNameLabelFrench : AppStrings.lastNameLabel;
    final phoneLabel =
        isFrench
            ? AppStrings.phoneNumberLabelFrench
            : AppStrings.phoneNumberLabel;
    final countryLabel =
        isFrench
            ? AppStrings.countryCodeLabelFrench
            : AppStrings.countryCodeLabel;
    final cityLabel =
        isFrench ? AppStrings.cityLabelFrench : AppStrings.cityLabel;
    final saveLabel =
        isFrench
            ? AppStrings.editProfileSaveButtonFrench
            : AppStrings.editProfileSaveButton;
    final savingLabel =
        isFrench
            ? AppStrings.editProfileSavingFrench
            : AppStrings.editProfileSaving;
    final cancelLabel =
        isFrench
            ? AppStrings.editProfileCancelFrench
            : AppStrings.editProfileCancel;
    final editPhotoLabel =
        isFrench ? AppStrings.editPhotoLabelFrench : AppStrings.editPhotoLabel;
    final editPhotoComingSoon =
        isFrench
            ? AppStrings.editPhotoComingSoonFrench
            : AppStrings.editPhotoComingSoon;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final viewportHeight = constraints.maxHeight;
            final viewportWidth = constraints.maxWidth;
            final mediaPadding = MediaQuery.of(context).padding;

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
                    child: Padding(
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
                            final availableHeight = viewportHeight;
                            final fallbackHeight =
                                viewportHeight - mediaPadding.vertical;
                            final double targetHeight =
                                availableHeight > 0
                                    ? availableHeight
                                    : (fallbackHeight > 0
                                        ? fallbackHeight
                                        : viewportHeight);

                            if (controller.isLoading.value) {
                              return SizedBox(
                                height: targetHeight,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final validation = controller.validationController;
                            final forms = controller.formControllers;
                            final auth = controller.authController;
                            final selectedCountry = controller.selectedCountry;
                            final emailText =
                                controller.email.value ?? AppStrings.emailHint;
                            final isSaving = auth.isUpdatingProfile.value;
                            final firstController = forms.firstNameController;
                            final lastController = forms.lastNameController;

                            return SizedBox(
                              height: targetHeight,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: IconButton(
                                      onPressed: Get.back,
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(
                                        Icons.arrow_back,
                                        color: AppColors.buttonGreen,
                                        size: AppDimensions.iconBackSize,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: AppDimensions.screenPadding,
                                  ),
                                  Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.heading2.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: AppDimensions.heading2FontSize,
                                      color: AppColors.textDark,
                                      letterSpacing:
                                          AppTypography.letterSpacingSmall,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: AppDimensions.smallSpacing,
                                  ),
                                  Image.asset(
                                    AppImages.profilePlaceholder,
                                    width: AppDimensions.profileAvatarSize,
                                    height: AppDimensions.profileAvatarSize,
                                  ),
                                  const SizedBox(
                                    height: AppDimensions.smallSpacing,
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Get.snackbar(
                                        editPhotoLabel,
                                        editPhotoComingSoon,
                                        snackPosition: SnackPosition.TOP,
                                        backgroundColor: AppColors.buttonGreen,
                                        colorText: AppColors.pureWhite,
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      foregroundColor: AppColors.textDark,
                                      overlayColor: AppColors.transparent,
                                    ),
                                    child: Text(
                                      editPhotoLabel,
                                      style: AppTextStyles.body.copyWith(
                                        fontSize:
                                            AppDimensions.floatingLabelFontSize,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing:
                                            AppTypography.letterSpacingSmall,
                                        decoration: TextDecoration.underline,
                                        decorationColor: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: AppDimensions.editProfileSpacing,
                                  ),
                                  ValueListenableBuilder<TextEditingValue>(
                                    valueListenable: firstController,
                                    builder: (context, firstValue, _) {
                                      return ValueListenableBuilder<
                                        TextEditingValue
                                      >(
                                        valueListenable: lastController,
                                        builder: (context, lastValue, _) {
                                          final firstName =
                                              firstValue.text.trim();
                                          final lastName =
                                              lastValue.text.trim();
                                          final combined = [firstName, lastName]
                                              .where((part) => part.isNotEmpty)
                                              .join(' ');
                                          final displayName =
                                              combined.isEmpty
                                                  ? AppStrings
                                                      .profileNamePlaceholder
                                                  : combined;

                                          return Text(
                                            displayName,
                                            textAlign: TextAlign.center,
                                            style: AppTextStyles.profileName,
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  Text(
                                    emailText,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.body.copyWith(
                                      fontSize: AppDimensions.linkFontSize,
                                      color: AppColors.textDark,
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppColors.textDark,
                                      letterSpacing:
                                          AppTypography.letterSpacingSmall,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: AppDimensions.screenPadding,
                                  ),
                                  Text(
                                    subtitle,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.body.copyWith(
                                      fontSize: AppDimensions.subtitleFontSize,
                                      color: AppColors.textDark,
                                      letterSpacing:
                                          AppTypography.letterSpacingSmall,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: AppDimensions.fieldVerticalSpacing,
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      FloatingLabelInputField(
                                        controller: forms.firstNameController,
                                        label: firstNameLabel,
                                        hint: AppStrings.firstNameHint,
                                        supportText:
                                            validation.firstNameError.value,
                                        isError:
                                            validation.firstNameError.value !=
                                            null,
                                        onChanged: validation.validateFirstName,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        textInputAction: TextInputAction.next,
                                      ),
                                      const SizedBox(
                                        height:
                                            AppDimensions
                                                .editProfileInputSpacing,
                                      ),
                                      FloatingLabelInputField(
                                        controller: forms.lastNameController,
                                        label: lastNameLabel,
                                        hint: AppStrings.lastNameHint,
                                        supportText:
                                            validation.lastNameError.value,
                                        isError:
                                            validation.lastNameError.value !=
                                            null,
                                        onChanged: validation.validateLastName,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        textInputAction: TextInputAction.next,
                                      ),
                                      const SizedBox(
                                        height:
                                            AppDimensions
                                                .editProfileInputSpacingTwo,
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 5,
                                            child: CountryCodeSelectorField(
                                              selectedCountry: selectedCountry,
                                              onChanged:
                                                  controller
                                                      .updateSelectedCountry,
                                              label: countryLabel,
                                              topSpacing: AppDimensions.zero,
                                            ),
                                          ),
                                          const SizedBox(
                                            width:
                                                AppDimensions
                                                    .editProfileInputSpacing,
                                          ),
                                          Expanded(
                                            flex: 7,
                                            child: FloatingLabelInputField(
                                              controller:
                                                  forms.phoneNumberController,
                                              label: phoneLabel,
                                              hint: AppStrings.phoneNumberHint,
                                              supportText:
                                                  validation
                                                      .phoneNumberError
                                                      .value,
                                              isError:
                                                  validation
                                                      .phoneNumberError
                                                      .value !=
                                                  null,
                                              onChanged:
                                                  (value) => validation
                                                      .validatePhoneNumber(
                                                        '+${selectedCountry.phoneCode}',
                                                        value,
                                                      ),
                                              keyboardType: TextInputType.phone,
                                              textInputAction:
                                                  TextInputAction.next,
                                              topSpacing: AppDimensions.zero,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height:
                                            AppDimensions
                                                .editProfileInputSpacing,
                                      ),
                                      FloatingLabelInputField(
                                        controller: forms.cityController,
                                        label: cityLabel,
                                        hint: AppStrings.cityHint,
                                        supportText: validation.cityError.value,
                                        isError:
                                            validation.cityError.value != null,
                                        onChanged: validation.validateCity,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        textInputAction: TextInputAction.done,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: AppDimensions.screenPadding,
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: PrimaryButton(
                                      label: isSaving ? savingLabel : saveLabel,
                                      onPressed: () async {
                                        if (isSaving) return;
                                        FocusScope.of(context).unfocus();
                                        debugPrint(
                                          'EditProfile: calling submitChanges',
                                        );
                                        final success =
                                            await controller.submitChanges();
                                        debugPrint(
                                          'EditProfile: submitChanges returned: $success',
                                        );
                                        if (success) {
                                          debugPrint(
                                            'EditProfile: submitChanges succeeded, attempting to pop edit screen',
                                          );

                                          if (!context.mounted) {
                                            return;
                                          }

                                          final popped =
                                              await Navigator.of(
                                                context,
                                              ).maybePop();

                                          if (!popped) {
                                            debugPrint(
                                              'EditProfile: pop failed, navigating to profile tab via home route',
                                            );
                                            Get.offNamed(
                                              AppRoutes.home,
                                              arguments: const {
                                                'initialTab': 'profile',
                                              },
                                            );
                                          }
                                        } else {
                                          final isFrench =
                                              Get.locale?.languageCode == 'fr';
                                          Get.snackbar(
                                            isFrench
                                                ? AppStrings.errorTitleFrench
                                                : AppStrings.errorTitle,
                                            isFrench
                                                ? AppStrings
                                                    .editProfileErrorFrench
                                                : AppStrings.editProfileError,
                                            backgroundColor: AppColors.error,
                                            colorText: AppColors.pureWhite,
                                            snackPosition: SnackPosition.TOP,
                                          );
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
                                      onPressed: Get.back,
                                      child: Text(
                                        cancelLabel,
                                        style: AppTextStyles.buttonPrimaryText
                                            .copyWith(
                                              color: AppColors.textDark,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
