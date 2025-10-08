import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/routes/app_routes.dart';
import 'modules/auth/views/login_screen.dart';
import 'modules/auth/views/signup_screen.dart';
import 'app/controllers/auth_controller.dart';
import 'shared/controllers/form_binding.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'modules/home/views/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Register AuthController globally and permanently
  Get.put(AuthController(), permanent: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final initialRoute =
        FirebaseAuth.instance.currentUser == null
            ? AppRoutes.login
            : AppRoutes.home;

    return GetMaterialApp(
      title: 'Trash Monitoring App',
      initialRoute: initialRoute,
      getPages: [
        GetPage(
          name: AppRoutes.login,
          page: () => const LoginScreen(),
          bindings: [FormBinding()],
        ),
        GetPage(
          name: AppRoutes.signup,
          page: () => const SignupScreen(),
          bindings: [FormBinding()],
        ),
        GetPage(name: AppRoutes.home, page: () => const HomeScreen()),
        // Add more GetPages for other routes
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
    );
  }
}
