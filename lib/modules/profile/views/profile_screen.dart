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
import 'package:ascoa_app/shared/utils/size_utils.dart';
import 'dart:math' as math;

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
                  child: Image.asset(
                    AppImages.profileScreenBottom,
                    width: viewportWidth,
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeUtils.w(
                        context,
                        AppDimensions.screenPadding,
                      ),
                      vertical: SizeUtils.h(
                        context,
                        AppDimensions.verticalPadding,
                      ),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: SizeUtils.w(
                            context,
                            AppDimensions.profileContentMaxWidth,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: math.min(
                                SizeUtils.h(
                                  context,
                                  AppDimensions.profileHeaderTopGap,
                                ),
                                AppDimensions.profileHeaderTopGap,
                              ),
                            ),
                            Text(
                              AppStrings.profileManagementTitle,
                              style: AppTextStyles.profileHeading.copyWith(
                                fontSize: SizeUtils.h(context, 28),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(
                              height: math.min(
                                SizeUtils.h(
                                  context,
                                  AppDimensions.profileNameTopGap,
                                ),
                                AppDimensions.profileNameTopGap,
                              ),
                            ),
                            SizedBox(
                              width: SizeUtils.r(
                                context,
                                AppDimensions.profileAvatarSize,
                              ),
                              height: SizeUtils.r(
                                context,
                                AppDimensions.profileAvatarSize,
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  AppImages.profilePlaceholder,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: math.min(
                                SizeUtils.h(
                                  context,
                                  AppDimensions.profileNameTopGap,
                                ),
                                AppDimensions.profileNameTopGap,
                              ),
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
                                    style: AppTextStyles.profileName.copyWith(
                                      fontSize: SizeUtils.h(context, 22),
                                    ),
                                    textAlign: TextAlign.center,
                                  );
                                }
                              },
                            ),
                            SizedBox(
                              height: math.min(
                                SizeUtils.h(
                                  context,
                                  AppDimensions.profileSectionSpacing,
                                ),
                                AppDimensions.profileSectionSpacing,
                              ),
                            ),
                            ProfileActionTile(
                              icon: Icons.edit_outlined,
                              title: AppStrings.profileEditTitle,
                              subtitle: AppStrings.profileEditSubtitle,
                              onTap: () => Get.toNamed(AppRoutes.editProfile),
                            ),
                            SizedBox(
                              height: math.min(
                                SizeUtils.h(
                                  context,
                                  AppDimensions.profileCardSpacing,
                                ),
                                AppDimensions.profileCardSpacing,
                              ),
                            ),
                            ProfileActionTile(
                              icon: Icons.lock_outline,
                              title: AppStrings.profileChangePasswordTitle,
                              subtitle:
                                  AppStrings.profileChangePasswordSubtitle,
                              onTap:
                                  () => Get.toNamed(AppRoutes.changePassword),
                            ),
                            SizedBox(
                              height: math.min(
                                SizeUtils.h(
                                  context,
                                  AppDimensions.profileSectionSupportSpacing,
                                ),
                                AppDimensions.profileSectionSupportSpacing,
                              ),
                            ),
                            SizedBox(
                              width:
                                  SizeUtils.w(
                                    context,
                                    AppDimensions.profileCardWidth,
                                  ) -
                                  SizeUtils.w(
                                    context,
                                    AppDimensions.profileCardTextWidthOffset,
                                  ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  AppStrings.profileSupportSection,
                                  style: AppTextStyles.profileCaption,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: math.min(
                                SizeUtils.h(
                                  context,
                                  AppDimensions.profileCaptionSpacing,
                                ),
                                AppDimensions.profileCaptionSpacing,
                              ),
                            ),
                            ProfileActionTile(
                              leading: Image.asset(
                                AppImages.policy,
                                width: SizeUtils.r(
                                  context,
                                  AppDimensions.profileCardIconSize,
                                ),
                                height: SizeUtils.r(
                                  context,
                                  AppDimensions.profileCardIconSize,
                                ),
                                fit: BoxFit.contain,
                              ),
                              title: AppStrings.profilePolicyTitle,
                              subtitle: AppStrings.profilePolicySubtitle,
                            ),
                            SizedBox(
                              height: math.min(
                                SizeUtils.h(
                                  context,
                                  AppDimensions.profileCardSpacing,
                                ),
                                AppDimensions.profileCardSpacing,
                              ),
                            ),
                            ProfileActionTile(
                              leading: Image.asset(
                                AppImages.faq,
                                width: SizeUtils.r(
                                  context,
                                  AppDimensions.profileCardIconSize,
                                ),
                                height: SizeUtils.r(
                                  context,
                                  AppDimensions.profileCardIconSize,
                                ),
                                fit: BoxFit.contain,
                              ),
                              title: AppStrings.profileFaqTitle,
                              subtitle: AppStrings.profileFaqSubtitle,
                            ),
                            SizedBox(
                              height: math.min(
                                SizeUtils.h(
                                  context,
                                  AppDimensions.profileCardSpacing,
                                ),
                                AppDimensions.profileCardSpacing,
                              ),
                            ),
                            ProfileActionTile(
                              leading: Image.asset(
                                AppImages.contact,
                                width: SizeUtils.r(
                                  context,
                                  AppDimensions.profileCardIconSize,
                                ),
                                height: SizeUtils.r(
                                  context,
                                  AppDimensions.profileCardIconSize,
                                ),
                                fit: BoxFit.contain,
                              ),
                              title: AppStrings.profileContactTitle,
                              subtitle: AppStrings.profileContactSubtitle,
                            ),
                            SizedBox(
                              height: math.min(
                                SizeUtils.h(
                                  context,
                                  AppDimensions.profileSectionSignoutSpacing,
                                ),
                                AppDimensions.profileSectionSignoutSpacing,
                              ),
                            ),
                            ProfileSignOutButton(
                              onPressed: () async {
                                await authController.logout();
                                Get.offAllNamed(AppRoutes.login);
                              },
                            ),
                            SizedBox(
                              height: SizeUtils.h(
                                context,
                                AppDimensions.smallSpacing,
                              ),
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
