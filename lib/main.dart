import 'dart:async';
import 'package:ascoa_app/app/controllers/haptic_controller.dart';
import 'package:ascoa_app/app/controllers/pending_cleanups_controller.dart';
import 'package:ascoa_app/modules/start_cleanup/views/new_cleanup_screen.dart';
import 'package:ascoa_app/modules/pending_cleanups/views/pending_cleanups_screen.dart';
import 'package:ascoa_app/modules/pending_cleanups/bindings/pending_cleanups_binding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:croppy/croppy.dart' as croppy;
import 'package:flutter/foundation.dart';
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
import 'modules/auth/views/reset_password_screen.dart';
import 'modules/auth/views/complete_profile_screen.dart';
import 'modules/auth/views/email_verification_screen.dart';
import 'modules/profile/views/edit_profile_screen.dart';
import 'modules/profile/bindings/edit_profile_binding.dart';
import 'package:ascoa_app/shared/constants/app_images.dart';
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'modules/profile/views/change_password_screen.dart';
import 'modules/profile/bindings/change_password_binding.dart';
import 'modules/auth/bindings/reset_password_binding.dart';
import 'modules/start_cleanup/bindings/cleanup_form_binding.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/models/city_model.dart';
import 'app/models/cities_config.dart';
import 'app/models/post.dart';
import 'app/models/user.dart';
import 'shared/services/cities_service.dart';
import 'shared/controllers/cities_controller.dart';
import 'shared/controllers/connectivity_controller.dart';
import 'app/models/pending_cleanup_model.dart';
import 'app/models/cached_cleanup_model.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  if (kDebugMode) {
    await dotenv.load(fileName: ".env").catchError((_) {
      debugPrint('No .env file found, proceeding without it.');
    });
    // Use the pure Dart solver in debug so we do not depend on the native FFI lib.
    croppy.croppyForceUseCassowaryDartImpl = true;
  }
  // Initialize Hive and register adapters for cities config
  await Hive.initFlutter();
  Hive.registerAdapter(CityAdapter());
  Hive.registerAdapter(CitiesConfigAdapter());
  Hive.registerAdapter(PostAdapter());
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(PendingCleanupModelAdapter());
  Hive.registerAdapter(CachedCleanupModelAdapter());
  // Register AuthController globally and permanently
  if (kIsWeb) {
    await GoogleSignIn.instance.initialize(
      clientId:
          "677557829420-gp8j8k67or2nbkv9f9u310scfe48mb89.apps.googleusercontent.com",
    );
  } else {
    await GoogleSignIn.instance.initialize();
  }
  Get.put(AuthController(), permanent: true);
  Get.put(HapticController(), permanent: true);
  Get.put(PendingCleanupsController(), permanent: true);
  // Register and initialize CitiesService
  final citiesService = await CitiesService().init();
  Get.put<CitiesService>(citiesService, permanent: true);
  Get.put(CitiesController());
  // Register ConnectivityController
  Get.put(ConnectivityController(), permanent: true);
  await _initDeepLinks();
  runApp(const MyApp());
}

final AppLinks _appLinks = AppLinks();

Future<void> _initDeepLinks() async {
  try {
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      debugPrint('Initial URI: $initialUri');
      _handleIncomingUri(initialUri);
    }
    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) _handleIncomingUri(uri);
    });
  } catch (e) {
    debugPrint('Error initializing deep links: $e');
  }
}

void _handleIncomingUri(Uri uri) {
  debugPrint('Received deep link: $uri');

  final mode = uri.queryParameters['mode'];
  final oobCode = uri.queryParameters['oobCode'];

  if (mode == 'resetPassword' && oobCode != null) {
    Get.offAllNamed(AppRoutes.resetPassword, arguments: {'oobCode': oobCode});
  }
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
      // Prefer using the typed UserModel from AuthController when available
      final authController = Get.find<AuthController>();
      // Ensure we have a current model loaded (fetch if necessary)
      if (authController.currentUserModel.value == null) {
        await authController.fetchCurrentUserProfile();
      }

      final userModel = authController.currentUserModel.value;
      if (userModel == null) {
        // If still null, create a minimal document and force profile completion
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'firstName': '',
          'lastName': '',
          'phoneNumber': '',
          'city': '',
          'countryCode': '',
          'isProfileComplete': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'signUpMethod': 'email',
        });
        return AppRoutes.completeProfile;
      }

      return userModel.isProfileComplete
          ? AppRoutes.home
          : AppRoutes.completeProfile;
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
            //change background colour to primary color
            home: Scaffold(
              body: Center(child: Image.asset(AppImages.logo)),
              backgroundColor: AppColors.primary,
            ),
          );
        }
        return GetMaterialApp(
          title: 'Trash Monitoring App',
          // Clamp global text scale to 1.0 for visual consistency across devices
          // (optional: remove if you want to respect system font scaling)
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                // Replace deprecated textScaleFactor with textScaler
                textScaler: const TextScaler.linear(1.0),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
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
              name: AppRoutes.resetPassword,
              page: () => const ResetPasswordScreen(),
              bindings: [FormBinding(), ResetPasswordBinding()],
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
              name: AppRoutes.changePassword,
              page: () => const ChangePasswordScreen(),
              bindings: [FormBinding(), ChangePasswordBinding()],
            ),
            GetPage(
              name: AppRoutes.emailVerification,
              page: () => EmailVerificationScreen(),
            ),
            GetPage(
              name: AppRoutes.newCleanUp,
              page: () => const NewCleanUpScreen(),
              bindings: [CleanupFormBinding()],
            ),
            GetPage(
              name: AppRoutes.pendingCleanups,
              page: () => const PendingCleanupsScreen(),
              bindings: [PendingCleanupsBinding()],
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
