import 'package:we_monitor/shared/widgets/circular_loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:we_monitor/app/controllers/auth_controller.dart';
import 'package:we_monitor/shared/widgets/auth_header.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_dimensions.dart';
import 'package:we_monitor/shared/constants/app_images.dart';
import 'package:we_monitor/shared/utils/size_utils.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  late final Future<void> _resolveFuture;

  @override
  void initState() {
    super.initState();
    final AuthController authController = Get.find<AuthController>();
    _resolveFuture = authController.resolveAuthFlow();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double viewportHeight = constraints.maxHeight;
          final double viewportWidth = constraints.maxWidth;
          final EdgeInsets viewPadding = MediaQuery.of(context).padding;
          final double contentHeight =
              viewportHeight - viewPadding.top - viewPadding.bottom;

          // Calculate scale exactly as done in LoginScreenV2 for visual consistency
          final double referenceWidth = AppDimensions.loginReferenceWidth;
          final double scale = (viewportWidth / referenceWidth).clamp(
            AppDimensions.authScaleMin,
            AppDimensions.authScaleMax,
          );

          return Container(
            width: viewportWidth,
            height: viewportHeight,
            color: AppColors.background,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Top Background Image (Same as Login)
                Positioned(
                  top: AppDimensions.zero,
                  left: AppDimensions.zero,
                  right: AppDimensions.zero,
                  child: Hero(
                    tag: 'authTopImage',
                    child: Image.asset(
                      AppImages.loginTop,
                      width: viewportWidth,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),

                // 2. Bottom Background Image (Same as Login)
                Positioned(
                  bottom: AppDimensions.zero,
                  left: AppDimensions.zero,
                  right: AppDimensions.zero,
                  child: Hero(
                    tag: 'authBottomImage',
                    child: Image.asset(
                      AppImages.loginBottom,
                      width: viewportWidth,
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
                    ),
                  ),
                ),

                // 3. Content Area
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
                          maxWidth: AppDimensions.profileContentMaxWidth,
                          minHeight: contentHeight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Exact same spacing as Login screen so Logo doesn't jump
                            SizedBox(
                              height:
                                  (contentHeight *
                                      AppDimensions.authHeaderTopSpacing),
                            ),

                            // The Header (Logo)
                            Hero(
                              tag: 'authHeader',
                              child: Material(
                                type: MaterialType.transparency,
                                child: AuthHeader(scale: scale),
                              ),
                            ),

                            const SizedBox(height: 60),

                            // FUTURE BUILDER replaces inputs/buttons
                            Expanded(
                              child: FutureBuilder<void>(
                                future: _resolveFuture,
                                builder: (context, snapshot) {
                                  // --- Error State ---
                                  if (snapshot.hasError) {
                                    return Column(
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          color: Colors.redAccent,
                                          size: 40,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Could not verify account.',
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${snapshot.error}',
                                          style: TextStyle(
                                            color: AppColors.textBlack70,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 24),
                                        // Optional: Retry button logic could go here
                                      ],
                                    );
                                  }

                                  // --- Loading State ---
                                  return Column(
                                    children: [
                                      const CircularInfiniteLoader(),
                                      const SizedBox(height: 24),
                                      Text(
                                        'Verifying...',
                                        style: TextStyle(
                                          color: AppColors.textBlack70,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  );
                                },
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
