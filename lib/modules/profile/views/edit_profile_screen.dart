import 'package:ascoa_app/app/controllers/haptic_controller.dart';
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
import 'package:ascoa_app/shared/widgets/city_selector_field.dart';
import 'package:ascoa_app/shared/widgets/primary_button.dart';
import 'package:ascoa_app/shared/utils/avatar_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ascoa_app/shared/utils/size_utils.dart';
import 'package:get/get.dart';
import 'package:ascoa_app/shared/widgets/app_dialog.dart';

class EditProfileScreen extends GetWidget<EditProfileController> {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();
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

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: false, // KEY CHANGE: Prevent screen resize
        body: LayoutBuilder(
          builder: (context, constraints) {
            final viewportHeight = constraints.maxHeight;
            final viewportWidth = constraints.maxWidth;
            final mediaPadding = MediaQuery.of(context).padding;
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
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: SizeUtils.w(context, AppDimensions.screenPadding),
                        right: SizeUtils.w(
                          context,
                          AppDimensions.screenPadding,
                        ),
                        bottom:
                            keyboardHeight > 0
                                ? keyboardHeight
                                : 0, // Only add padding when keyboard is visible
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

                            return SingleChildScrollView(
                              controller: scrollController,
                              physics:
                                  keyboardHeight > 0
                                      ? const AlwaysScrollableScrollPhysics()
                                      : const NeverScrollableScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: targetHeight,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: IconButton(
                                        onPressed: () {
                                          Get.find<HapticController>()
                                              .selectionClick();
                                          Get.back();
                                        },
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
                                      height: SizeUtils.h(
                                        context,
                                        AppDimensions.editProfileInputSpacing,
                                      ),
                                    ),
                                    Text(
                                      title,
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.heading2(
                                        context,
                                      ).copyWith(
                                        fontWeight: FontWeight.w700,
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
                                      height: SizeUtils.h(
                                        context,
                                        AppDimensions.smallSpacing,
                                      ),
                                    ),
                                    Obx(
                                      () => SizedBox(
                                        width: SizeUtils.r(
                                          context,
                                          AppDimensions.profileAvatarSize,
                                        ),
                                        height: SizeUtils.r(
                                          context,
                                          AppDimensions.profileAvatarSize,
                                        ),
                                        child: ClipOval(
                                          child:
                                              controller.thumbUrl.value != null
                                                  ? CachedNetworkImage(
                                                    imageUrl:
                                                        AvatarUtils.normalizeUrl(
                                                          controller
                                                              .thumbUrl
                                                              .value!,
                                                        ),
                                                    fit: BoxFit.cover,
                                                    placeholder:
                                                        (
                                                          context,
                                                          url,
                                                        ) => Container(
                                                          color:
                                                              AppColors
                                                                  .profileAvatarBackground,
                                                          child: Center(
                                                            child: CircularProgressIndicator(
                                                              valueColor:
                                                                  AlwaysStoppedAnimation<
                                                                    Color
                                                                  >(
                                                                    AppColors
                                                                        .buttonGreen,
                                                                  ),
                                                            ),
                                                          ),
                                                        ),
                                                    errorWidget:
                                                        (
                                                          context,
                                                          url,
                                                          error,
                                                        ) => Image.asset(
                                                          AppImages
                                                              .profilePlaceholder,
                                                          fit: BoxFit.cover,
                                                        ),
                                                  )
                                                  : Image.asset(
                                                    AppImages
                                                        .profilePlaceholder,
                                                    fit: BoxFit.cover,
                                                  ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: SizeUtils.h(
                                        context,
                                        AppDimensions.smallSpacing,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Get.find<HapticController>()
                                            .selectionClick();
                                        controller.handleEditPhoto();
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
                                        style: AppTextStyles.body(
                                          context,
                                        ).copyWith(
                                          fontSize: SizeUtils.h(
                                            context,
                                            AppDimensions.floatingLabelFontSize,
                                          ),
                                          fontWeight: FontWeight.w500,
                                          letterSpacing:
                                              AppTypography.letterSpacingSmall,
                                          decoration: TextDecoration.underline,
                                          decorationColor: AppColors.textDark,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: SizeUtils.h(
                                        context,
                                        AppDimensions.editProfileSpacing,
                                      ),
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
                                            final combined = [
                                                  firstName,
                                                  lastName,
                                                ]
                                                .where(
                                                  (part) => part.isNotEmpty,
                                                )
                                                .join(' ');
                                            final displayName =
                                                combined.isEmpty
                                                    ? AppStrings
                                                        .profileNamePlaceholder
                                                    : combined;

                                            return Text(
                                              displayName,
                                              textAlign: TextAlign.center,
                                              style: AppTextStyles.profileName(
                                                context,
                                              ).copyWith(
                                                fontSize: SizeUtils.h(
                                                  context,
                                                  AppDimensions
                                                      .profileNameFontSize,
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    Text(
                                      emailText,
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.body(
                                        context,
                                      ).copyWith(
                                        fontSize: SizeUtils.h(
                                          context,
                                          AppDimensions.linkFontSize,
                                        ),
                                        color: AppColors.textDark,
                                        decoration: TextDecoration.underline,
                                        decorationColor: AppColors.textDark,
                                        letterSpacing:
                                            AppTypography.letterSpacingSmall,
                                      ),
                                    ),
                                    SizedBox(
                                      height: SizeUtils.h(
                                        context,
                                        AppDimensions.editProfileInputSpacing,
                                      ),
                                    ),
                                    Text(
                                      subtitle,
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.body(
                                        context,
                                      ).copyWith(
                                        fontSize: SizeUtils.h(
                                          context,
                                          AppDimensions.subtitleFontSize,
                                        ),
                                        color: AppColors.textDark,
                                        letterSpacing:
                                            AppTypography.letterSpacingSmall,
                                      ),
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
                                          onChanged:
                                              validation.validateFirstName,
                                          textCapitalization:
                                              TextCapitalization.words,
                                          textInputAction: TextInputAction.next,
                                        ),
                                        SizedBox(
                                          height: SizeUtils.h(
                                            context,
                                            AppDimensions.inputFontSize,
                                          ),
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
                                          onChanged:
                                              validation.validateLastName,
                                          textCapitalization:
                                              TextCapitalization.words,
                                          textInputAction: TextInputAction.next,
                                        ),
                                        SizedBox(
                                          height: SizeUtils.h(
                                            context,
                                            AppDimensions
                                                .editProfileInputSpacing,
                                          ),
                                        ),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              flex: 5,
                                              child: CountryCodeSelectorField(
                                                selectedCountry:
                                                    selectedCountry,
                                                onChanged:
                                                    controller
                                                        .updateSelectedCountry,
                                                label: countryLabel,
                                                topSpacing: AppDimensions.zero,
                                              ),
                                            ),
                                            SizedBox(
                                              width: SizeUtils.w(
                                                context,
                                                AppDimensions
                                                    .editProfileInputSpacing,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 7,
                                              child: FloatingLabelInputField(
                                                controller:
                                                    forms.phoneNumberController,
                                                label: phoneLabel,
                                                hint:
                                                    AppStrings.phoneNumberHint,
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
                                                keyboardType:
                                                    TextInputType.phone,
                                                textInputAction:
                                                    TextInputAction.next,
                                                topSpacing: AppDimensions.zero,
                                              ),
                                            ),
                                          ],
                                        ),
                                        CitySelectorField(
                                          controller: forms.cityController,
                                          label: cityLabel,
                                          hint: AppStrings.cityHint,
                                          supportText:
                                              validation.cityError.value,
                                          isError:
                                              validation.cityError.value !=
                                              null,
                                          onChanged: validation.validateCity,
                                          topSpacing:
                                              AppDimensions.inputFontSize,
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: SizeUtils.h(
                                        context,
                                        AppDimensions.screenPadding,
                                      ),
                                    ),
                                    SizedBox(
                                      width: double.infinity,
                                      child: PrimaryButton(
                                        label:
                                            isSaving ? savingLabel : saveLabel,
                                        onPressed: () async {
                                          if (isSaving) return;
                                          Get.find<HapticController>().medium();
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

                                            // Show success dialog and navigate to profile tab
                                            await showDialog<void>(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (ctx) {
                                                final isFrench =
                                                    Get.locale?.languageCode ==
                                                    'fr';
                                                return AppDialog(
                                                  title:
                                                      isFrench
                                                          ? AppStrings
                                                              .editProfileSuccessDialogTitle
                                                          : AppStrings
                                                              .editProfileSuccessDialogTitle,
                                                  decoratedHero: false,
                                                  imageAsset:
                                                      AppImages
                                                          .profileUpdateSuccessful,
                                                  imageWidth: SizeUtils.w(
                                                    ctx,
                                                    AppDimensions
                                                        .dialogImageWidth,
                                                  ),
                                                  imageHeight: SizeUtils.h(
                                                    ctx,
                                                    AppDimensions
                                                        .dialogImageHeight,
                                                  ),
                                                  body: null,
                                                  primaryActionLabel:
                                                      isFrench
                                                          ? AppStrings
                                                              .editProfileSuccessDialogButton
                                                          : AppStrings
                                                              .editProfileSuccessDialogButton,
                                                  onPrimaryAction: () {
                                                    Navigator.of(ctx).pop();
                                                    Get.offNamed(
                                                      AppRoutes.home,
                                                      arguments: const {
                                                        'initialTab': 'profile',
                                                      },
                                                    );
                                                  },
                                                );
                                              },
                                            );
                                          } else {
                                            final isFrench =
                                                Get.locale?.languageCode ==
                                                'fr';
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
                                        onPressed: () {
                                          Get.find<HapticController>()
                                              .selectionClick();
                                          Get.back();
                                        },
                                        child: Text(
                                          cancelLabel,
                                          style:
                                              AppTextStyles.buttonPrimaryText(
                                                context,
                                              ).copyWith(
                                                color: AppColors.textDark,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
