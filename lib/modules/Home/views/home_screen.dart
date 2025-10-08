import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ascoa_app/app/controllers/auth_controller.dart';
import 'package:ascoa_app/app/routes/app_routes.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController auth = Get.find<AuthController>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding,
          vertical: AppDimensions.verticalPadding,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top spacing
              const SizedBox(height: 24),

              // Title
              const Text('Home', style: AppTextStyles.heading1),

              const Expanded(child: SizedBox()),

              // Logout button
              ElevatedButton(
                onPressed: () async {
                  await auth.logout();
                  Get.offAllNamed(AppRoutes.login);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
