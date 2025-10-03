import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'app/routes/app_routes.dart';
import 'modules/auth/views/login_screen_v2.dart';
import 'modules/auth/views/signup_screen.dart';
import 'app/controllers/auth_controller.dart';
import 'shared/controllers/form_binding.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'modules/main/views/main_screen.dart';
import 'modules/auth/views/forgot_password_screen.dart';
import 'modules/auth/views/complete_profile_screen.dart';
import 'modules/auth/views/email_verification_screen.dart';
import 'modules/profile/views/edit_profile_screen.dart';
import 'modules/profile/bindings/edit_profile_binding.dart';
import 'package:ascoa_app/shared/constants/app_images.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Register AuthController globally and permanently
  await GoogleSignIn.instance.initialize();
  Get.put(AuthController(), permanent: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<String> _getInitialRoute() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return AppRoutes.login;

    if (!user.emailVerified) {
      try {
        await user.sendEmailVerification();
      } catch (e) {
        Get.snackbar('Error', 'Failed to send verification email: $e');
      }
      return AppRoutes.emailVerification;
    }
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final userData = doc.data();

      if (userData == null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'firstName': '',
          'lastName': '',
          'phoneNumber': '',
          'city': '',
          'isProfileComplete': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'signUpMethod': 'email',
        });
        return AppRoutes.completeProfile;
      }

      if (userData['isProfileComplete'] == true) {
        return AppRoutes.home;
      } else {
        return AppRoutes.completeProfile;
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return AppRoutes.login;
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getInitialRoute(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return MaterialApp(
            home: Scaffold(body: Center(child: Image.asset(AppImages.logo))),
          );
        }
        return GetMaterialApp(
          title: 'Trash Monitoring App',
          initialRoute: snapshot.data!,
          getPages: [
            GetPage(
              name: AppRoutes.login,
              page: () => const LoginScreenV2(),
              bindings: [FormBinding()],
            ),
            GetPage(
              name: AppRoutes.signup,
              page: () => const SignupScreen(),
              bindings: [FormBinding()],
            ),
            GetPage(name: AppRoutes.home, page: () => const MainScreen()),

            GetPage(
              name: AppRoutes.forgotPassword,
              page: () => ForgotPasswordScreen(),
              bindings: [FormBinding()],
            ),
            GetPage(
              name: AppRoutes.completeProfile,
              page: () => CompleteProfileScreen(),
              bindings: [FormBinding()],
            ),
            GetPage(
              name: AppRoutes.editProfile,
              page: () => const EditProfileScreen(),
              bindings: [FormBinding(), EditProfileBinding()],
            ),
            GetPage(
              name: AppRoutes.emailVerification,
              page: () => EmailVerificationScreen(),
            ),
            // Add more GetPages for other routes
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
        );
      },
    );
  }
}
