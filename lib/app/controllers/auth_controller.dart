import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:ascoa_app/app/routes/app_routes.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Rxn<User> firebaseUser = Rxn<User>();

  @override
  void onInit() {
    firebaseUser.bindStream(_auth.authStateChanges());
    super.onInit();
  }

  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      Get.snackbar('Login Successful', 'Welcome back!');
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      Get.snackbar('Login Failed', e.toString());
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        Get.snackbar('Login Failed', 'Google sign-in was cancelled.');
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        Get.snackbar('Error', 'Failed to get authentication tokens.');
        return;
      }
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      Get.snackbar('Login Successful', 'Logged in with Google!');
      Get.offAllNamed(AppRoutes.home);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        // Try to get the email and fetch sign-in methods
        Get.snackbar(
          'Account Exists',
          'This email is already registered with another sign-in method. Please use that method first.',
        );
      } else {
        Get.snackbar('Google Login Failed', e.message ?? 'Unknown error');
      }
    } catch (e) {
      Get.snackbar('Google Login Failed', e.toString());
    }
  }

  Future<void> loginWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.cancelled) {
        Get.snackbar('Login Failed', 'Facebook login was cancelled.');
        return;
      }

      if (result.status == LoginStatus.failed) {
        Get.snackbar(
          'Facebook Login Failed',
          result.message ?? 'Unknown error',
        );
        return;
      }

      final OAuthCredential facebookAuthCredential =
          FacebookAuthProvider.credential(result.accessToken!.token);

      await _auth.signInWithCredential(facebookAuthCredential);
      Get.snackbar('Login Successful', 'Logged in with Facebook!');
      Get.offAllNamed(AppRoutes.home);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        // Try to get the email and fetch sign-in methods
        Get.snackbar(
          'Account Exists',
          'This email is already registered with another sign-in method. Please use that method first.',
        );
      } else {
        Get.snackbar('Facebook Login Failed', e.message ?? 'Unknown error');
      }
    } catch (e) {
      Get.snackbar('Facebook Login Failed', e.toString());
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    Get.snackbar('Logout', 'You have been logged out.');
  }

  Future<void> signup(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      Get.snackbar('Signup Successful', 'Welcome to ASCOA!');
      Get.offAllNamed(AppRoutes.home);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        Get.snackbar(
          'Signup Failed',
          'This email is already in use. Please use a different email.',
        );
      } else {
        Get.snackbar(
          'Signup Failed',
          e.message ?? 'An unknown error occurred.',
        );
      }
    } catch (e) {
      Get.snackbar('Signup Failed', e.toString());
    }
  }
}
