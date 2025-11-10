import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ascoa_app/app/controllers/auth_controller.dart';
import 'package:ascoa_app/app/routes/app_routes.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_images.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/modules/profile/widgets/profile_action_tile.dart';
import 'package:ascoa_app/modules/profile/widgets/profile_signout_button.dart';
import 'package:ascoa_app/modules/profile/widgets/full_image_overlay.dart';
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
                              style: AppTextStyles.profileHeading(
                                context,
                              ).copyWith(
                                fontSize: SizeUtils.h(
                                  context,
                                  AppDimensions.heading2FontSize,
                                ),
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
                            Obx(() {
                              // React to currentUserModel changes
                              final userModel =
                                  authController.currentUserModel.value;
                              final thumbUrl = userModel?.thumbUrl;
                              final avatarUrl = userModel?.avatarUrl;

                              // Use thumbnail for preview, fallback to full avatar
                              final previewUrl = thumbUrl ?? avatarUrl;
                              final fullUrl = avatarUrl;

                              return GestureDetector(
                                onTap: () {
                                  // Only show overlay if we have a full-resolution avatar
                                  if (fullUrl != null && fullUrl.isNotEmpty) {
                                    final normalizedFullUrl =
                                        _normalizeCacheBustedUrl(fullUrl);
                                    FullImageOverlay.show(
                                      context,
                                      imageUrl: normalizedFullUrl,
                                      placeholderAsset:
                                          AppImages.profilePlaceholder,
                                    );
                                  }
                                },
                                child: SizedBox(
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
                                        previewUrl != null &&
                                                previewUrl.isNotEmpty
                                            ? CachedNetworkImage(
                                              imageUrl:
                                                  _normalizeCacheBustedUrl(
                                                    previewUrl,
                                                  ),
                                              fit: BoxFit.cover,
                                              placeholder:
                                                  (context, url) => Container(
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
                                                  (context, url, error) =>
                                                      Image.asset(
                                                        AppImages
                                                            .profilePlaceholder,
                                                        fit: BoxFit.cover,
                                                      ),
                                            )
                                            : Image.asset(
                                              AppImages.profilePlaceholder,
                                              fit: BoxFit.cover,
                                            ),
                                  ),
                                ),
                              );
                            }),
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
                                    style: AppTextStyles.profileName(context),
                                    textAlign: TextAlign.center,
                                  );
                                } else if (snapshot.hasError) {
                                  return Text(
                                    AppStrings.profileNamePlaceholder,
                                    style: AppTextStyles.profileName(context),
                                    textAlign: TextAlign.center,
                                  );
                                } else {
                                  return Text(
                                    snapshot.data?.isNotEmpty == true
                                        ? snapshot.data!
                                        : AppStrings.profileNamePlaceholder,
                                    style: AppTextStyles.profileName(
                                      context,
                                    ).copyWith(
                                      fontSize: SizeUtils.h(
                                        context,
                                        AppDimensions.profileNameFontSize,
                                      ),
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
                                  style: AppTextStyles.profileCaption(context),
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

  static String _normalizeCacheBustedUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final params = Map<String, String>.from(uri.queryParameters);

      final token = params['token'];
      if (token != null && token.contains('?v=')) {
        final parts = token.split('?v=');
        params['token'] = parts.first;
        if (parts.length > 1 && !params.containsKey('v')) {
          params['v'] = parts.last;
        }
      }

      if (!params.containsKey('v') && url.contains('?v=')) {
        final suffix = url.split('?v=').last;
        if (suffix.isNotEmpty && !suffix.contains('&')) {
          params['v'] = suffix;
        }
      }

      if (params.isEmpty) {
        return url;
      }

      return uri.replace(queryParameters: params).toString();
    } catch (_) {
      return url;
    }
  }
}
