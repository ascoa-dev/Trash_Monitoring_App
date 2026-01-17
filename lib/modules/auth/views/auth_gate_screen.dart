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
      backgroundColor: AppColors.background,
      body: FutureBuilder<void>(
        future: _resolveFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Could not start the app.',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${snapshot.error}',
                      style: TextStyle(color: AppColors.textBlack),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

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
