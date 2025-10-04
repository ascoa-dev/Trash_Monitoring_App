import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ascoa_app/app/controllers/auth_controller.dart';
import 'package:ascoa_app/app/routes/app_routes.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_images.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/modules/profile/widgets/profile_action_tile.dart';
import 'package:ascoa_app/modules/profile/widgets/profile_signout_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double viewportHeight = constraints.maxHeight;
          final double viewportWidth = constraints.maxWidth;
          return Container(
            width: viewportWidth,
            height: viewportHeight,
            color: AppColors.background,
            child: Stack(
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
                      viewportHeight *
                      AppDimensions.profileBottomBackgroundHeightFactor,
                  child: Transform(
                    transform:
                        Matrix4.identity()..scaleByDouble(
                          AppDimensions.one,
                          AppDimensions.zero,
                          AppDimensions.zero,
                          AppDimensions.zero,
                        ),
                    alignment: Alignment.bottomCenter,
                    child: Image.asset(
                      AppImages.profileScreenBottom,
                      width: viewportWidth,
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
                    ),
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
                        constraints: const BoxConstraints(
                          maxWidth: AppDimensions.profileContentMaxWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: AppDimensions.profileHeaderTopGap,
                            ),
                            const Text(
                              AppStrings.profileManagementTitle,
                              style: AppTextStyles.profileHeading,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(
                              height: AppDimensions.profileNameTopGap,
                            ),
                            SizedBox(
                              width: AppDimensions.profileAvatarSize,
                              height: AppDimensions.profileAvatarSize,
                              child: ClipOval(
                                child: Image.asset(
                                  AppImages.profilePlaceholder,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: AppDimensions.profileNameTopGap,
                            ),
                            FutureBuilder<String>(
                              future: authController.getName(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Text(
                                    AppStrings.profileNamePlaceholder,
                                    style: AppTextStyles.profileName,
                                    textAlign: TextAlign.center,
                                  );
                                } else if (snapshot.hasError) {
                                  return Text(
                                    AppStrings.profileNamePlaceholder,
                                    style: AppTextStyles.profileName,
                                    textAlign: TextAlign.center,
                                  );
                                } else {
                                  return Text(
                                    snapshot.data?.isNotEmpty == true
                                        ? snapshot.data!
                                        : AppStrings.profileNamePlaceholder,
                                    style: AppTextStyles.profileName,
                                    textAlign: TextAlign.center,
                                  );
                                }
                              },
                            ),
                            const SizedBox(
                              height: AppDimensions.profileSectionSpacing,
                            ),
                            ProfileActionTile(
                              icon: Icons.edit_outlined,
                              title: AppStrings.profileEditTitle,
                              subtitle: AppStrings.profileEditSubtitle,
                              onTap: () => Get.toNamed(AppRoutes.editProfile),
                            ),
                            const SizedBox(
                              height: AppDimensions.profileCardSpacing,
                            ),
                            ProfileActionTile(
                              icon: Icons.lock_outline,
                              title: AppStrings.profileChangePasswordTitle,
                              subtitle:
                                  AppStrings.profileChangePasswordSubtitle,
                              onTap:
                                  () => Get.toNamed(AppRoutes.changePassword),
                            ),
                            const SizedBox(
                              height:
                                  AppDimensions.profileSectionSupportSpacing,
                            ),
                            const SizedBox(
                              width:
                                  AppDimensions.profileCardWidth -
                                  AppDimensions.profileCardTextWidthOffset,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  AppStrings.profileSupportSection,
                                  style: AppTextStyles.profileCaption,
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: AppDimensions.profileCaptionSpacing,
                            ),
                            ProfileActionTile(
                              leading: Image.asset(
                                AppImages.policy,
                                width: AppDimensions.profileCardIconSize,
                                height: AppDimensions.profileCardIconSize,
                                fit: BoxFit.contain,
                              ),
                              title: AppStrings.profilePolicyTitle,
                              subtitle: AppStrings.profilePolicySubtitle,
                            ),
                            const SizedBox(
                              height: AppDimensions.profileCardSpacing,
                            ),
                            ProfileActionTile(
                              leading: Image.asset(
                                AppImages.faq,
                                width: AppDimensions.profileCardIconSize,
                                height: AppDimensions.profileCardIconSize,
                                fit: BoxFit.contain,
                              ),
                              title: AppStrings.profileFaqTitle,
                              subtitle: AppStrings.profileFaqSubtitle,
                            ),
                            const SizedBox(
                              height: AppDimensions.profileCardSpacing,
                            ),
                            ProfileActionTile(
                              leading: Image.asset(
                                AppImages.contact,
                                width: AppDimensions.profileCardIconSize,
                                height: AppDimensions.profileCardIconSize,
                                fit: BoxFit.contain,
                              ),
                              title: AppStrings.profileContactTitle,
                              subtitle: AppStrings.profileContactSubtitle,
                            ),
                            const SizedBox(
                              height:
                                  AppDimensions.profileSectionSignoutSpacing,
                            ),
                            ProfileSignOutButton(
                              onPressed: () async {
                                await authController.logout();
                                Get.offAllNamed(AppRoutes.login);
                              },
                            ),
                            const SizedBox(
                              height: AppDimensions.profileHeaderTopGap,
                            ),
                          ],
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
