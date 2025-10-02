import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ascoa_app/app/controllers/auth_controller.dart';
import 'package:ascoa_app/app/routes/app_routes.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/widgets/primary_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController auth = Get.find<AuthController>();

    // Return only the content; MainScreen provides the Scaffold and bottom nav.
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPadding,
        vertical: AppDimensions.verticalPadding,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top spacing
            const SizedBox(height: AppDimensions.screenPadding),

            // Title
            const Text(AppStrings.homeTitle, style: AppTextStyles.heading1),

            const Expanded(child: SizedBox()),

            // Logout button
            PrimaryButton(
              label: AppStrings.logout,
              onPressed: () async {
                await auth.logout();
                Get.offAllNamed(AppRoutes.login);
              },
            ),
          ],
        ),
      ),
    );
  }
}
