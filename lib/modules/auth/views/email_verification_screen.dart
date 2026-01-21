import 'dart:async';
import 'package:ascoa_app/app/controllers/auth_controller.dart';
import 'package:ascoa_app/app/controllers/haptic_controller.dart';
import 'package:ascoa_app/app/routes/app_routes.dart';
import 'package:ascoa_app/shared/controllers/form_controllers.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/constants/app_images.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/services/snackbar_service.dart';
import 'package:ascoa_app/shared/utils/size_utils.dart';
import 'package:ascoa_app/shared/widgets/primary_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ascoa_app/shared/widgets/circular_loader.dart';
import 'package:ascoa_app/shared/analytics/analytics_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final User _user;
  late final Timer _timer;
  bool isResending = false;
  final haptics = Get.find<HapticController>();

  @override
  void initState() {
    super.initState();
    Analytics.screenView(AnalyticsEvents.emailVerificationViewed);
    _user = _auth.currentUser!;
    _user.reload();
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkVerification(),
    );
  }

  Future<void> _checkVerification() async {
    await _auth.currentUser?.reload();
    final user = _auth.currentUser!;
    if (user.emailVerified) {
      _timer.cancel();
      haptics.medium();
      Analytics.track(AnalyticsEvents.emailVerified);
      SnackbarService.success(
        AppStrings.emailVerifiedSuccessTitle,
        AppStrings.emailVerifiedSuccessBody,
      );
      final AuthController controller = Get.find<AuthController>();
      controller.handleUserPostVerification(user, 'email');
    }
  }

  Future<void> _resendEmail() async {
    setState(() => isResending = true);
    try {
      await _user.sendEmailVerification();
      Analytics.track(AnalyticsEvents.emailVerificationResent);
      SnackbarService.success(
        AppStrings.emailVerificationSentTitle,
        AppStrings.emailVerificationSentBody.replaceFirst(
          '%s',
          _user.email ?? '',
        ),
      );
    } catch (e) {
      SnackbarService.error(
        AppStrings.errorTitle,
        'Failed to resend verification email: $e',
      );
    } finally {
      setState(() => isResending = false);
    }
  }

  void _goToLoginAndClear() async {
    haptics.selectionClick();
    // Clear shared form controllers if available
    if (Get.isRegistered<FormControllers>()) {
      final form = Get.find<FormControllers>();
      form.resetAuthFields();
      form.resetProfileFields();
    }
    // Sign out via AuthController if available
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      await auth.logout();
    } else {
      await FirebaseAuth.instance.signOut();
    }
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFrench = Get.locale?.languageCode == 'fr';

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double viewportHeight = constraints.maxHeight;
          final double viewportWidth = constraints.maxWidth;

          return Container(
            width: viewportWidth,
            height: viewportHeight,
            color: AppColors.background,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Top background image
                Positioned(
                  left: AppDimensions.zero,
                  right: AppDimensions.zero,
                  top: AppDimensions.zero,
                  height: viewportHeight * AppDimensions.forgotBgTopHeight,
                  child: Image.asset(
                    AppImages.forgotPasswordTop,
                    width: viewportWidth,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
                // Bottom background image
                Positioned(
                  left: AppDimensions.zero,
                  right: AppDimensions.zero,
                  bottom: AppDimensions.zero,
                  height: viewportHeight * AppDimensions.forgotBgBottomHeight,
                  child: Image.asset(
                    AppImages.forgotPasswordBottom,
                    width: viewportWidth,
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
                // Main content
                SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: SizeUtils.w(context, AppDimensions.screenPadding),
                      right: SizeUtils.w(context, AppDimensions.screenPadding),
                      top: SizeUtils.h(context, AppDimensions.verticalPadding),
                      bottom: SizeUtils.h(
                        context,
                        AppDimensions.verticalPadding,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Back button
                        Align(
                          alignment: Alignment.topLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            iconSize: SizeUtils.r(
                              context,
                              AppDimensions.iconBackSize,
                            ),
                            color: AppColors.accentGreen,
                            onPressed: _goToLoginAndClear,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        SizedBox(
                          height:
                              viewportHeight *
                              AppDimensions.confirmTitleTopSpacing,
                        ),
                        // Main icon
                        Image.asset(
                          AppImages.verifyEmailIcon,
                          width: SizeUtils.w(
                            context,
                            AppDimensions.emailVerificationIconWidth,
                          ),
                          height: SizeUtils.h(
                            context,
                            AppDimensions.emailVerificationIconHeight,
                          ),
                          alignment: Alignment.center,
                        ),
                        SizedBox(
                          height: SizeUtils.h(
                            context,
                            AppDimensions.smallSpacing,
                          ),
                        ),
                        // Heading
                        Text(
                          isFrench
                              ? AppStrings.emailVerificationTitleFrench
                              : AppStrings.emailVerificationTitle,
                          style: AppTextStyles.heading2(context).copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: SizeUtils.h(
                              context,
                              AppDimensions.emailVerificationHeading,
                            ),
                            height:
                                SizeUtils.h(
                                  context,
                                  AppDimensions.emailVerificationHeading,
                                ) /
                                SizeUtils.h(
                                  context,
                                  AppDimensions.heading2FontSize,
                                ),
                            letterSpacing:
                                AppDimensions.dialogTitleLetterSpacing,
                            color: AppColors.textDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                          height: SizeUtils.h(
                            context,
                            AppDimensions.verticalPadding,
                          ),
                        ),
                        // Subheading
                        Text(
                          (isFrench
                                  ? AppStrings.emailVerificationBodyFrench
                                  : AppStrings.emailVerificationBody)
                              .replaceFirst('%s', _user.email ?? ''),
                          style: AppTextStyles.body(context).copyWith(
                            fontFamily: AppTextStyles.rubik,
                            fontWeight: FontWeight.w400,
                            fontSize: SizeUtils.h(
                              context,
                              AppDimensions.emailVerificationSubheading,
                            ),
                            height:
                                SizeUtils.h(
                                  context,
                                  AppDimensions.dialogBodyLineHeight,
                                ) /
                                SizeUtils.h(
                                  context,
                                  AppDimensions.dialogBodyFontSize,
                                ),
                            letterSpacing:
                                AppDimensions.dialogBodyLetterSpacing,
                            color: AppColors.textDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                          height: SizeUtils.h(
                            context,
                            AppDimensions.screenPadding,
                          ),
                        ),
                        // Circular progress indicator
                        CircularInfiniteLoader(
                          size: AppDimensions.circularLoaderSize,
                          strokeWidth: AppDimensions.circularLoaderStrokeWidth,
                          trackColor: AppColors.loaderTrack,
                          activeColor: AppColors.loaderActive,
                        ),
                        SizedBox(
                          height: SizeUtils.h(
                            context,
                            AppDimensions.screenPaddingVerification,
                          ),
                        ),
                        Text(
                          isFrench
                              ? AppStrings.emailVerificationSpamNoteFrench
                              : AppStrings.emailVerificationSpamNote,
                          style: AppTextStyles.body(context).copyWith(
                            fontFamily: AppTextStyles.rubik,
                            fontWeight: FontWeight.w400,
                            fontSize: SizeUtils.h(
                              context,
                              AppDimensions.emailVerificationSubheading,
                            ),
                            height:
                                SizeUtils.h(
                                  context,
                                  AppDimensions.inputFontSize + 4,
                                ) /
                                SizeUtils.h(
                                  context,
                                  AppDimensions.emailVerificationSubheading,
                                ),
                            letterSpacing:
                                AppDimensions.dialogBodyLetterSpacing,
                            color: AppColors.textDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                          height: SizeUtils.h(
                            context,
                            AppDimensions.verticalPaddingVerification,
                          ),
                        ),
                        // Primary button: Resend email
                        PrimaryButton(
                          label:
                              isResending
                                  ? (isFrench
                                      ? AppStrings
                                          .emailVerificationResendingFrench
                                      : AppStrings.emailVerificationResending)
                                  : (isFrench
                                      ? AppStrings
                                          .emailVerificationResendLinkFrench
                                      : AppStrings.emailVerificationResendLink),
                          onPressed: () {
                            if (!isResending) _resendEmail();
                          },
                        ),
                        SizedBox(
                          height: SizeUtils.h(
                            context,
                            AppDimensions.smallSpacing,
                          ),
                        ),
                        // Outlined button: Use another email
                        SizedBox(
                          width: double.infinity,
                          height: SizeUtils.h(
                            context,
                            AppDimensions.buttonHeight,
                          ),
                          child: OutlinedButton(
                            onPressed: _goToLoginAndClear,
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
                            child: Text(
                              isFrench
                                  ? AppStrings.emailVerificationUseAnotherFrench
                                  : AppStrings.emailVerificationUseAnother,
                              style: AppTextStyles.buttonPrimaryText(
                                context,
                              ).copyWith(color: AppColors.textDark),
                            ),
                          ),
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
