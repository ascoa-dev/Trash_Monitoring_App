import 'dart:async';
import 'package:ascoa_app/app/controllers/auth_controller.dart';
import 'package:ascoa_app/app/routes/app_routes.dart';
import 'package:ascoa_app/shared/controllers/form_controllers.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_dimensions.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
    _user.reload();
    _timer = Timer.periodic(Duration(seconds: 5), (_) => _checkVerification());
  }

  Future<void> _checkVerification() async {
    await _auth.currentUser?.reload();
    final user = _auth.currentUser!;
    debugPrint(user.toString());
    debugPrint("Email Verification");
    if (user.emailVerified) {
      debugPrint("Verified");
      _timer.cancel();
      Get.snackbar(
        AppStrings.emailVerifiedSuccessTitle,
        AppStrings.emailVerifiedSuccessBody,
        snackPosition: SnackPosition.TOP,
      );
      final AuthController controller = Get.find<AuthController>();
      controller.handleUserPostVerification(user, 'email');
    }
  }

  Future<void> _resendEmail() async {
    setState(() => isResending = true);
    try {
      await _user.sendEmailVerification();
      Get.snackbar(
        AppStrings.emailVerificationSentTitle,
        AppStrings.emailVerificationSentBody.replaceFirst(
          '%s',
          _user.email ?? '',
        ),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        AppStrings.errorTitle,
        'Failed to resend verification email: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() => isResending = false);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.emailVerificationTitle),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.email_outlined,
              size: AppDimensions.emailVerificationIconSize,
              color: AppColors.emailVerification,
            ),
            const SizedBox(height: AppDimensions.smallSpacing * 2),
            Text(
              AppStrings.emailVerificationBodyTemplate.replaceFirst(
                '%s',
                _user.email ?? '',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimensions.smallSpacing * 4),
            const CircularProgressIndicator(),
            const SizedBox(height: AppDimensions.smallSpacing * 4),
            ElevatedButton.icon(
              onPressed: isResending ? null : _resendEmail,
              icon: const Icon(Icons.refresh),
              label: Text(
                isResending
                    ? AppStrings.emailVerificationResending
                    : AppStrings.emailVerificationResend,
              ),
            ),
            const SizedBox(height: AppDimensions.smallSpacing * 2),
            OutlinedButton(
              onPressed: () async {
                // Clear any form state and sign the user out, then navigate to login
                try {
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
                    // Fallback: sign out of Firebase directly
                    await FirebaseAuth.instance.signOut();
                  }

                  // Navigate back to login screen (fallback)
                  Get.offAllNamed(AppRoutes.login);
                } catch (e) {
                  Get.snackbar(
                    AppStrings.errorTitle,
                    'Failed to cancel and sign out: $e',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
              child: const Text(AppStrings.forgotDialogButton),
            ),
            const SizedBox(height: AppDimensions.smallSpacing * 2),
            TextButton(
              onPressed: _checkVerification,
              child: const Text(AppStrings.emailVerificationCheckAgain),
            ),
            const SizedBox(height: AppDimensions.smallSpacing * 2),
            Text(
              AppStrings.emailVerificationSpamNote,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
