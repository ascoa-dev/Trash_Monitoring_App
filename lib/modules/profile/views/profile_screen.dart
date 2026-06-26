import 'package:we_monitor/app/controllers/haptic_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:we_monitor/app/controllers/auth_controller.dart';
import 'package:we_monitor/app/routes/app_routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:we_monitor/shared/constants/app_images.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/modules/profile/widgets/profile_action_tile.dart';
import 'package:we_monitor/modules/profile/widgets/profile_signout_button.dart';
import 'package:we_monitor/modules/profile/widgets/full_image_overlay.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';
import 'package:we_monitor/shared/controllers/connectivity_controller.dart';
import 'package:we_monitor/shared/widgets/app_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final ConnectivityController connectivityController =
        Get.find<ConnectivityController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double viewportHeight = constraints.maxHeight;
          final double viewportWidth = constraints.maxWidth;
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
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
                  child: Padding(
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
                                    Get.find<HapticController>()
                                        .selectionClick();
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
                              onTap: () {
                                if (!connectivityController.isOnline.value) {
                                  _showOfflineDialog(
                                    context,
                                    AppStrings.profileEditTitle,
                                    AppStrings.profileEditNoInternet,
                                  );
                                } else {
                                  Get.toNamed(AppRoutes.editProfile);
                                }
                              },
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
                              onTap: () {
                                if (!connectivityController.isOnline.value) {
                                  _showOfflineDialog(
                                    context,
                                    AppStrings.profileChangePasswordTitle,
                                    AppStrings.profileChangePasswordNoInternet,
                                  );
                                } else {
                                  Get.toNamed(AppRoutes.changePassword);
                                }
                              },
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
                              icon: Icons.history_outlined,
                              title: 'My Clean Ups',
                              subtitle: 'Search and edit submitted cleanups',
                              onTap: () => Get.toNamed(AppRoutes.myCleanups),
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
                              icon: Icons.cloud_upload_outlined,
                              title: AppStrings.profilePendingCleanupsTitle,
                              subtitle:
                                  AppStrings.profilePendingCleanupsSubtitle,
                              onTap:
                                  () => Get.toNamed(AppRoutes.pendingCleanups),
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
                              icon: Icons.report_problem_outlined,
                              title: 'Pending Hotspots',
                              subtitle:
                                  'View and upload offline hotspot reports',
                              onTap:
                                  () => Get.toNamed(AppRoutes.pendingHotspots),
                            ),
                            FutureBuilder<bool>(
                              future: _isCurrentUserAdmin(),
                              builder: (context, snapshot) {
                                if (snapshot.data != true) {
                                  return const SizedBox.shrink();
                                }
                                return Column(
                                  children: [
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
                                      icon: Icons.admin_panel_settings_outlined,
                                      title: 'Admin Management',
                                      subtitle:
                                          'Add, search, and remove admins',
                                      onTap:
                                          () => Get.toNamed(
                                            AppRoutes.adminManagement,
                                          ),
                                    ),
                                  ],
                                );
                              },
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
                              onTap:
                                  () => _launchURL(
                                    context,
                                    AppStrings.profileTermsUrl,
                                  ),
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
                              onTap:
                                  () => _launchURL(
                                    context,
                                    AppStrings.profilePrivacyUrl,
                                  ),
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
                              onTap:
                                  () => _launchURL(
                                    context,
                                    'mailto:${AppStrings.profileContactEmail}',
                                  ),
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
                                Get.find<HapticController>().medium();
                                await authController.logout();
                                Get.offAllNamed(AppRoutes.login);
                              },
                            ),
                            SizedBox(
                              height: SizeUtils.h(
                                context,
                                AppDimensions.homeScreenBottomGap,
                                useContentHeight: false,
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

  Future<bool> _isCurrentUserAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final doc =
        await FirebaseFirestore.instance
            .collection('admins')
            .doc(user.uid)
            .get();
    return doc.exists;
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

  void _showOfflineDialog(
    BuildContext context,
    String featureName,
    String message,
  ) {
    Get.find<HapticController>().selectionClick();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (_) => AppDialog(
            title: AppStrings.profileNoInternetTitle,
            body: message,
            icon: Icons.wifi_off_rounded,
            decoratedHero: true,
            primaryActionLabel: 'OK',
            onPrimaryAction: () => Get.back(),
          ),
    );
  }

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      final success = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!context.mounted) return;
      if (!success) {
        _showErrorDialog(context, 'Could not open link.');
      }
    } catch (e) {
      if (!context.mounted) return;
      _showErrorDialog(context, 'Error opening link: $e');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (_) => AppDialog(
            title: 'Error',
            body: message,
            icon: Icons.error_outline_rounded,
            decoratedHero: true,
            primaryActionLabel: 'OK',
            onPrimaryAction: () => Get.back(),
          ),
    );
  }
}
