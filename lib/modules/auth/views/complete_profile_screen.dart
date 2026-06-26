import 'package:we_monitor/app/controllers/auth_controller.dart';
import 'package:we_monitor/app/controllers/haptic_controller.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/constants/app_typography.dart';
import 'package:we_monitor/shared/controllers/form_controllers.dart';
import 'package:we_monitor/shared/controllers/validation_controller.dart';
import 'package:we_monitor/shared/widgets/country_code_selector_field.dart';
import 'package:we_monitor/shared/widgets/floating_label_input_field.dart';
import 'package:we_monitor/shared/widgets/city_selector_field.dart';
import 'package:we_monitor/shared/widgets/primary_button.dart';
import 'package:we_monitor/shared/utils/avatar_photo_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:we_monitor/shared/constants/app_images.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:we_monitor/shared/analytics/analytics_service.dart';

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
  String? _uploadedAvatarUrl;
  String? _uploadedThumbUrl;
  final AvatarPhotoHandler _avatarPhotoHandler = AvatarPhotoHandler();
  final haptics = Get.find<HapticController>();

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
    Analytics.screenView(AnalyticsEvents.profileCompletionViewed);
    authController = Get.find<AuthController>();
    formControllers = Get.find<FormControllers>();
    validationController = Get.find<ValidationController>();
    validationController.clearProfileValidation();
    _selectedCountry = _defaultCountry();
  }

  void _handleEditPhoto() async {
    haptics.selectionClick();
    await _avatarPhotoHandler.handleEditPhoto(
      context: context,
      onSuccess: (url) async {
        Analytics.track(AnalyticsEvents.profilePhotoUploaded);
        // Fetch the user profile to get the thumbUrl
        final profileData = await authController.fetchCurrentUserProfile();
        setState(() {
          _uploadedAvatarUrl = url;
          _uploadedThumbUrl = profileData?.thumbUrl?.toString();
        });
      },
    );
  }

  Future<void> _submitProfile() async {
    FocusScope.of(context).unfocus();
    Analytics.track(AnalyticsEvents.profileCompletionStarted);
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

    final result = await authController.completeProfile(
      firstName: firstName,
      lastName: lastName,
      phoneNumber: '+${_selectedCountry.phoneCode} $phone',
      countryCode: _selectedCountry.countryCode,
      city: city,
    );

    if (result != null) {
      haptics.medium();
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
              width: SizeUtils.r(context, AppDimensions.avatarDiameter),
              height: SizeUtils.r(context, AppDimensions.avatarDiameter),
              child: ClipOval(
                child:
                    _uploadedThumbUrl != null || _uploadedAvatarUrl != null
                        ? CachedNetworkImage(
                          // Use thumbnail for preview, fallback to full avatar
                          imageUrl: _uploadedThumbUrl ?? _uploadedAvatarUrl!,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                color: AppColors.profileAvatarBackground,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.buttonGreen,
                                    ),
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Image.asset(
                                AppImages.profilePlaceholder,
                                fit: BoxFit.cover,
                              ),
                        )
                        : Image.asset(
                          AppImages.profilePlaceholder,
                          fit: BoxFit.cover,
                        ),
              ),
            ),
            Positioned(
              bottom: SizeUtils.h(
                context,
                AppDimensions.avatarEditOffsetBottom,
              ),
              right: SizeUtils.w(context, AppDimensions.avatarEditOffsetRight),
              child: Container(
                width: SizeUtils.r(context, AppDimensions.avatarEditButtonSize),
                height: SizeUtils.r(
                  context,
                  AppDimensions.avatarEditButtonSize,
                ),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.textDark,
                    width: SizeUtils.r(
                      context,
                      AppDimensions.avatarEditBorderWidth,
                    ),
                  ),
                ),
                child: GestureDetector(
                  onTap: _handleEditPhoto,
                  child: Icon(
                    Icons.edit,
                    size: SizeUtils.r(
                      context,
                      AppDimensions.avatarEditIconSize,
                    ),
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: SizeUtils.h(context, AppDimensions.smallSpacing)),
        GestureDetector(
          onTap: _handleEditPhoto,
          child: Text(
            isFrench
                ? AppStrings.editPhotoLabelFrench
                : AppStrings.editPhotoLabel,
            style: AppTextStyles.body(context).copyWith(
              fontSize: SizeUtils.h(context, AppDimensions.linkFontSize),
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
    final ScrollController scrollController = ScrollController();
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

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double viewportHeight = constraints.maxHeight;
          final double viewportWidth = constraints.maxWidth;
          final EdgeInsets viewPadding = MediaQuery.of(context).padding;
          final double keyboardHeight =
              MediaQuery.of(context).viewInsets.bottom;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (keyboardHeight == 0 && scrollController.hasClients) {
              scrollController.jumpTo(0);
            }
          });

          return Stack(
            children: [
              Container(color: AppColors.background),
              Positioned(
                top: AppDimensions.zero,
                left: AppDimensions.zero,
                right: AppDimensions.zero,
                child: Image.asset(
                  AppImages.completeProfileTop,
                  width: viewportWidth,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
              Positioned(
                left: AppDimensions.zero,
                right: AppDimensions.zero,
                bottom: -viewPadding.bottom,
                child: Image.asset(
                  AppImages.forgotPasswordBottom,
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
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
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
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: AppDimensions.profileContentMaxWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height:
                                viewportHeight *
                                AppDimensions.authSmallSpacerFactor,
                          ),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.heading2(context).copyWith(
                              fontSize: SizeUtils.h(
                                context,
                                AppDimensions.heading2FontSize,
                              ),
                              fontWeight: FontWeight.w500,
                              letterSpacing: AppTypography.letterSpacingSmall,
                              color: AppColors.pureWhite,
                            ),
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
                              height:
                                  SizeUtils.h(
                                    context,
                                    AppDimensions.dialogBodyLineHeight,
                                  ) /
                                  SizeUtils.h(
                                    context,
                                    AppDimensions.subtitleFontSize,
                                  ),
                              letterSpacing: 0.1,
                              color: AppColors.pureWhite,
                            ),
                          ),
                          SizedBox(
                            height:
                                viewportHeight *
                                AppDimensions.authSmallSpacerFactor,
                          ),
                          _buildAvatarSection(isFrench),
                          SizedBox(
                            height:
                                viewportHeight *
                                AppDimensions.authXSmallSpacerFactor,
                          ),
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
                              onChanged: validationController.validateFirstName,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          SizedBox(
                            height: SizeUtils.h(
                              context,
                              AppDimensions.screenPadding,
                            ),
                          ),
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
                              onChanged: validationController.validateLastName,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          SizedBox(
                            height: SizeUtils.h(
                              context,
                              AppDimensions.screenPadding,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                              top: SizeUtils.h(
                                context,
                                AppDimensions.fieldVerticalSpacing,
                              ),
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
                                      validationController.validatePhoneNumber(
                                        '+${country.phoneCode}',
                                        formControllers
                                            .phoneNumberController
                                            .text,
                                      );
                                    },
                                    label: countryLabel,
                                    topSpacing: AppDimensions.zero,
                                  ),
                                ),
                                SizedBox(
                                  width: SizeUtils.w(
                                    context,
                                    AppDimensions.smallSpacing,
                                  ),
                                ),
                                Expanded(
                                  flex: 7,
                                  child: Obx(
                                    () => FloatingLabelInputField(
                                      controller:
                                          formControllers.phoneNumberController,
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
                                      topSpacing: AppDimensions.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: SizeUtils.h(
                              context,
                              AppDimensions.screenPadding,
                            ),
                          ),
                          Obx(
                            () => CitySelectorField(
                              controller: formControllers.cityController,
                              label: cityLabel,
                              hint: AppStrings.cityHint,
                              supportText: validationController.cityError.value,
                              isError:
                                  validationController.cityError.value != null,
                              onChanged: validationController.validateCity,
                            ),
                          ),
                          SizedBox(
                            height: SizeUtils.h(
                              context,
                              AppDimensions.screenPadding,
                            ),
                          ),
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
                          SizedBox(
                            height: SizeUtils.h(
                              context,
                              AppDimensions.profileSectionSignoutSpacing,
                            ),
                          ),
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
    );
  }
}
