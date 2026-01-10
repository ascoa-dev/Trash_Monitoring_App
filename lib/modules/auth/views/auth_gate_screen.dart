import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ascoa_app/app/controllers/auth_controller.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';

/// AuthGate: A neutral decision screen that resolves auth flow asynchronously
/// Shows a loading indicator while determining the user's destination:
/// - Email verification screen (if email not verified)
/// - Complete profile screen (if profile incomplete)
/// - Home screen (if everything is ready)
///
/// This prevents the "flash" effect of routing to home and bouncing back.
class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<void>(
        future: authController.resolveAuthFlow(),
        builder: (context, snapshot) {
          // Show loader while resolving
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                const SizedBox(height: 24),
                Text(
                  'Loading...',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
