import 'package:ascoa_app/app/controllers/auth_controller.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/controllers/form_controllers.dart';
import 'package:ascoa_app/shared/controllers/validation_controller.dart';
import 'package:ascoa_app/shared/widgets/country_code_selector_field.dart';
import 'package:ascoa_app/shared/widgets/floating_label_input_field.dart';
import 'package:ascoa_app/shared/widgets/primary_button.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  late final AuthController authController;
  late final FormControllers formControllers;
  late final ValidationController validationController;
  late Country _selectedCountry;

  Country _defaultCountry() {
    return Country(
      phoneCode: '237',
      countryCode: 'CM',
      e164Sc: 0,
      geographic: true,
      level: 1,
      name: 'Cameroon',
      displayName: 'Cameroon',
      displayNameNoCountryCode: 'Cameroon',
      example: '6 70 00 00 00',
      e164Key: '237CM',
    );
  }

  @override
  void initState() {
    super.initState();
    authController = Get.find<AuthController>();
    formControllers = Get.find<FormControllers>();
    validationController = Get.find<ValidationController>();
    validationController.clearProfileValidation();
    _selectedCountry = _defaultCountry();
  }

  void _handleEditPhoto() {
    final isFrench = Get.locale?.languageCode == 'fr';
    Get.snackbar(
      isFrench ? AppStrings.editPhotoLabelFrench : AppStrings.editPhotoLabel,
      isFrench
          ? AppStrings.editPhotoComingSoonFrench
          : AppStrings.editPhotoComingSoon,
      backgroundColor: AppColors.buttonGreen40,
      colorText: AppColors.pureWhite,
      snackPosition: SnackPosition.TOP,
    );
  }

  Future<void> _submitProfile() async {
    FocusScope.of(context).unfocus();
    final firstName = formControllers.firstNameController.text.trim();
    final lastName = formControllers.lastNameController.text.trim();
    final phone = formControllers.phoneNumberController.text.trim();
    final city = formControllers.cityController.text.trim();

    validationController.validateFirstName(firstName);
    validationController.validateLastName(lastName);
    validationController.validatePhoneNumber(
      '+${_selectedCountry.phoneCode}',
      phone,
    );
    validationController.validateCity(city);

    if (!validationController.isProfileFormValid) {
      return;
    }

    final success = await authController.completeProfile(
      firstName: firstName,
      lastName: lastName,
      phoneNumber: '+${_selectedCountry.phoneCode} $phone',
      countryCode: _selectedCountry.countryCode,
      city: city,
    );

    if (success) {
      formControllers.resetProfileFields();
      validationController.clearProfileValidation();
      setState(() {
        _selectedCountry = _defaultCountry();
      });
    }
  }

  Widget _buildAvatarSection(bool isFrench) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: AppDimensions.avatarDiameter,
              height: AppDimensions.avatarDiameter,
              child: ClipOval(
                child: Image.asset(
                  'assets/ASCOA/profileplaceholder.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: AppDimensions.avatarEditOffsetBottom,
              right: AppDimensions.avatarEditOffsetRight,
              child: Container(
                width: AppDimensions.avatarEditButtonSize,
                height: AppDimensions.avatarEditButtonSize,
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.textDark,
                    width: AppDimensions.avatarEditBorderWidth,
                  ),
                ),
                child: const Icon(
                  Icons.edit,
                  size: AppDimensions.avatarEditIconSize,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.smallSpacing),
        GestureDetector(
          onTap: _handleEditPhoto,
          child: Text(
            isFrench
                ? AppStrings.editPhotoLabelFrench
                : AppStrings.editPhotoLabel,
            style: AppTextStyles.body.copyWith(
              fontSize: AppDimensions.linkFontSize,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFrench = Get.locale?.languageCode == 'fr';
    final title =
        isFrench
            ? AppStrings.completeProfileTitleFrench
            : AppStrings.completeProfileTitle;
    final subtitle =
        isFrench
            ? AppStrings.completeProfileSubtitleFrench
            : AppStrings.completeProfileSubtitle;
    final firstNameLabel =
        isFrench ? AppStrings.firstNameLabelFrench : AppStrings.firstNameLabel;
    final lastNameLabel =
        isFrench ? AppStrings.lastNameLabelFrench : AppStrings.lastNameLabel;
    final phoneLabel =
        isFrench
            ? AppStrings.phoneNumberLabelFrench
            : AppStrings.phoneNumberLabel;
    final cityLabel =
        isFrench ? AppStrings.cityLabelFrench : AppStrings.cityLabel;
    final countryLabel =
        isFrench
            ? AppStrings.countryCodeLabelFrench
            : AppStrings.countryCodeLabel;
    final buttonLabel =
        isFrench
            ? AppStrings.completeProfileButtonFrench
            : AppStrings.completeProfileButton;
    final savingLabel =
        isFrench
            ? AppStrings.completeProfileSavingFrench
            : AppStrings.completeProfileSaving;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final double viewportHeight = constraints.maxHeight;
            final double viewportWidth = constraints.maxWidth;
            final EdgeInsets viewPadding = MediaQuery.of(context).padding;

            return Stack(
              children: [
                Container(color: AppColors.background),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    'assets/ASCOA/Complete_Profile_Top.png',
                    width: viewportWidth,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -viewPadding.bottom,
                  child: Image.asset(
                    'assets/ASCOA/Forgot_Password_Screen_Bottom.png',
                    width: viewportWidth,
                    height:
                        viewportHeight *
                        AppDimensions.completeProfileBottomHeight,
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
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: viewportHeight * 0.02),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.heading2.copyWith(
                                fontSize: AppDimensions.heading2FontSize,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.1,
                                color: AppColors.pureWhite,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body.copyWith(
                                fontSize: AppDimensions.subtitleFontSize,
                                height: 22 / AppDimensions.subtitleFontSize,
                                letterSpacing: 0.1,
                                color: AppColors.pureWhite,
                              ),
                            ),
                            SizedBox(height: viewportHeight * 0.02),
                            _buildAvatarSection(isFrench),
                            SizedBox(height: viewportHeight * 0.01),
                            Obx(
                              () => FloatingLabelInputField(
                                controller: formControllers.firstNameController,
                                label: firstNameLabel,
                                hint: AppStrings.firstNameHint,
                                supportText:
                                    validationController.firstNameError.value,
                                isError:
                                    validationController.firstNameError.value !=
                                    null,
                                onChanged:
                                    validationController.validateFirstName,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            SizedBox(height: AppDimensions.screenPadding),
                            Obx(
                              () => FloatingLabelInputField(
                                controller: formControllers.lastNameController,
                                label: lastNameLabel,
                                hint: AppStrings.lastNameHint,
                                supportText:
                                    validationController.lastNameError.value,
                                isError:
                                    validationController.lastNameError.value !=
                                    null,
                                onChanged:
                                    validationController.validateLastName,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            SizedBox(height: AppDimensions.screenPadding),
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppDimensions.fieldVerticalSpacing,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: CountryCodeSelectorField(
                                      selectedCountry: _selectedCountry,
                                      onChanged: (country) {
                                        setState(() {
                                          _selectedCountry = country;
                                        });
                                        validationController
                                            .validatePhoneNumber(
                                              '+${country.phoneCode}',
                                              formControllers
                                                  .phoneNumberController
                                                  .text,
                                            );
                                      },
                                      label: countryLabel,
                                      topSpacing: 0,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 7,
                                    child: Obx(
                                      () => FloatingLabelInputField(
                                        controller:
                                            formControllers
                                                .phoneNumberController,
                                        label: phoneLabel,
                                        hint: AppStrings.phoneNumberHint,
                                        supportText:
                                            validationController
                                                .phoneNumberError
                                                .value,
                                        isError:
                                            validationController
                                                .phoneNumberError
                                                .value !=
                                            null,
                                        onChanged:
                                            (value) => validationController
                                                .validatePhoneNumber(
                                                  '+${_selectedCountry.phoneCode}',
                                                  value,
                                                ),
                                        keyboardType: TextInputType.phone,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'[0-9 ]'),
                                          ),
                                        ],
                                        textInputAction: TextInputAction.next,
                                        topSpacing: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: AppDimensions.screenPadding),
                            Obx(
                              () => FloatingLabelInputField(
                                controller: formControllers.cityController,
                                label: cityLabel,
                                hint: AppStrings.cityHint,
                                supportText:
                                    validationController.cityError.value,
                                isError:
                                    validationController.cityError.value !=
                                    null,
                                onChanged: validationController.validateCity,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.done,
                              ),
                            ),
                            SizedBox(height: AppDimensions.screenPadding),
                            Obx(() {
                              final isSaving =
                                  authController.isCompletingProfile.value;
                              return PrimaryButton(
                                label: isSaving ? savingLabel : buttonLabel,
                                onPressed: () {
                                  if (!isSaving) {
                                    _submitProfile();
                                  }
                                },
                              );
                            }),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
