import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:ascoa_app/app/routes/app_routes.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ascoa_app/modules/profile/models/change_password_status.dart';

class AuthController extends GetxController {
  late final FirebaseAuth _auth;
  Rxn<User> firebaseUser = Rxn<User>();
  RxBool isCompletingProfile = false.obs;
  RxBool isUpdatingProfile = false.obs;

  @override
  void onInit() {
    _auth = FirebaseAuth.instance;
    firebaseUser.bindStream(_auth.authStateChanges());
    super.onInit();
  }

  Future<void> _handleUserPostLogin(User user, String signUpMethod) async {
    if (!user.emailVerified && signUpMethod == 'email') {
      debugPrint('Email not verified: ${user.email}');
      try {
        await user.sendEmailVerification();
        Get.snackbar(
          'Email Sent',
          'A verification link has been sent to ${user.email}',
        );
      } catch (e) {
        Get.snackbar('Error', 'Failed to send verification email: $e');
      }
      Get.toNamed(AppRoutes.emailVerification);
      return;
    }
    await handleUserPostVerification(user, signUpMethod);
  }

  Future<void> handleUserPostVerification(
    User user,
    String signUpMethod,
  ) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        if (userData['signUpMethod'] != signUpMethod) {
          Get.snackbar(
            'Login Failed',
            'This account was registered using ${userData['signUpMethod']}. Please login with that method.',
          );
          await _signOutAll(); // Sign out from all providers
          return;
        }
        if (userData['isProfileComplete'] == true) {
          Get.snackbar(
            'Login Successful',
            'Welcome back ${userData['firstName']} ${userData['lastName']}!',
          );
          Get.offAllNamed(AppRoutes.home);
        } else {
          Get.snackbar(
            'Incomplete Profile',
            'Please complete your profile information.',
          );
          Get.offAllNamed(AppRoutes.completeProfile);
        }
      } else {
        // New user - create document
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'firstName': '',
          'lastName': '',
          'phoneNumber': '',
          'city': '',
          'isProfileComplete': false,
          'createdAt': FieldValue.serverTimestamp(), // Good practice
          'signUpMethod': signUpMethod,
        });
        Get.snackbar('Welcome!', 'Please complete your profile information.');
        Get.offAllNamed(AppRoutes.completeProfile);
      }
    } on FirebaseException catch (e) {
      Get.snackbar('Error', 'Failed to load user data: ${e.message}');
      await _signOutAll(); // Sign out if profile loading fails
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred: $e');
      await _signOutAll(); // Sign out if profile loading fails
    }
  }

  Future<void> login(String email, String password) async {
    isLoadingLogin.value = true;
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user found after sign-in.');
      await _handleUserPostLogin(user, 'email');
    } on FirebaseAuthException catch (e) {
      // More specific error messages
      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid email or password.';
      }
      Get.snackbar('Login Failed', message);
    } catch (e) {
      Get.snackbar('Login Failed', e.toString());
    } finally {
      isLoadingLogin.value = false;
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      // Use the package singleton and its authenticate flow. `authenticate`
      // returns a GoogleSignInAccount (or throws) and the account's
      // `authentication` getter is synchronous (returns a
      // GoogleSignInAuthentication), so do NOT `await` it.
      final googleUser = await GoogleSignIn.instance.authenticate();

      // `authenticate` returns a signed-in account or throws. The
      // GoogleSignInAuthentication exposed here contains an idToken (the
      // package version used does not expose an accessToken), so use idToken
      // when creating the Firebase credential.
      final googleAuth = googleUser.authentication; // synchronous getter
      if (googleAuth.idToken == null) {
        throw Exception('Failed to get ID token from Google sign-in.');
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user found after Google sign-in.');
      await _handleUserPostLogin(user, 'google');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        Get.snackbar(
          'Account Exists',
          'This email is already registered with another sign-in method. Please use that method first.',
        );
      } else {
        Get.snackbar('Google Login Failed', e.message ?? 'Unknown error');
      }
      await _signOutAll();
    } catch (e) {
      Get.snackbar('Google Login Failed', e.toString());
      await _signOutAll();
    }
  }

  Future<void> loginWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.cancelled) {
        // User cancelled - don't show error
        return;
      }

      if (result.status == LoginStatus.failed) {
        Get.snackbar(
          'Facebook Login Failed',
          result.message ?? 'Unknown error',
        );
        return;
      }
      // Official example: create credential directly from tokenString
      if (result.status == LoginStatus.success) {
        final OAuthCredential credential = FacebookAuthProvider.credential(
          result.accessToken!.tokenString,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
        debugPrint('Facebook sign-in successful1221');

        final user = _auth.currentUser;
        if (user != null) {
          await _handleUserPostLogin(user, 'facebook');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        Get.snackbar(
          'Account Exists',
          'This email is already registered with another sign-in method.',
        );
      } else {
        Get.snackbar('Facebook Login Failed', e.message ?? 'Unknown error');
      }
      // Clean up Facebook sign-in state
      await FacebookAuth.instance.logOut();
    } catch (e) {
      Get.snackbar('Facebook Login Failed', e.toString());
      await FacebookAuth.instance.logOut();
    }
  }

  Future<void> logout() async {
    await _signOutAll();
    Get.snackbar('Logout', 'You have been logged out.');
  }

  Future<void> _signOutAll() async {
    try {
      await _auth.signOut();
      await GoogleSignIn.instance.signOut();
      await FacebookAuth.instance.logOut();
    } catch (e) {
      debugPrint(
        'Error during logout: $e',
      ); // Optional: log error for debugging
    }
  }

  Future<void> signup(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user found after sign-up.');

      // FIXED: Now calls _handleUserPostLogin to create user document
      await _handleUserPostLogin(user, 'email');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        Get.snackbar(
          'Signup Failed',
          'This email is already in use. Please use a different email.',
        );
      } else if (e.code == 'weak-password') {
        Get.snackbar(
          'Signup Failed',
          'Password is too weak. Please use a stronger password.',
        );
      } else if (e.code == 'invalid-email') {
        Get.snackbar('Signup Failed', 'Invalid email address.');
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

  // ===============================================
  // FORGOT PASSWORD FEATURE - Added by Michel
  // Branch: feature/forgot-password
  // Improved: by Rohith
  // ===============================================

  /// Loading state for forgot password
  RxBool isLoadingForgotPassword = false.obs;
  RxBool isLoadingLogin = false.obs;

  Future<bool> completeProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String countryCode,
    required String city,
  }) async {
    final user = _auth.currentUser;
    final isFrench = Get.locale?.languageCode == 'fr';
    if (user == null) {
      Get.snackbar(
        isFrench ? AppStrings.errorTitleFrench : AppStrings.errorTitle,
        isFrench
            ? 'Vous devez être connecté pour continuer.'
            : 'You must be signed in to continue.',
      );
      Get.offAllNamed(AppRoutes.login);
      return false;
    }

    isCompletingProfile.value = true;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'countryCode': countryCode,
        'city': city,
        'isProfileComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Get.snackbar(
        isFrench
            ? AppStrings.completeProfileTitleFrench
            : AppStrings.completeProfileTitle,
        isFrench
            ? AppStrings.completeProfileSuccessFrench
            : AppStrings.completeProfileSuccess,
      );
      Get.offAllNamed(AppRoutes.home);
      return true;
    } on FirebaseException catch (e) {
      debugPrint('completeProfile FirebaseException: ${e.message}');
      Get.snackbar(
        isFrench ? AppStrings.errorTitleFrench : AppStrings.errorTitle,
        isFrench
            ? AppStrings.completeProfileErrorFrench
            : AppStrings.completeProfileError,
      );
      return false;
    } catch (e) {
      debugPrint('completeProfile error: $e');
      Get.snackbar(
        isFrench ? AppStrings.errorTitleFrench : AppStrings.errorTitle,
        isFrench
            ? AppStrings.completeProfileErrorFrench
            : AppStrings.completeProfileError,
      );
      return false;
    } finally {
      isCompletingProfile.value = false;
    }
  }

  Future<Map<String, dynamic>?> fetchCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      return doc.data();
    } catch (e) {
      debugPrint('fetchCurrentUserProfile error: $e');
      return null;
    }
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String countryCode,
    required String city,
  }) async {
    final user = _auth.currentUser;
    final isFrench = Get.locale?.languageCode == 'fr';
    if (user == null) {
      Get.snackbar(
        isFrench ? AppStrings.errorTitleFrench : AppStrings.errorTitle,
        isFrench
            ? 'Vous devez être connecté pour continuer.'
            : 'You must be signed in to continue.',
      );
      Get.offAllNamed(AppRoutes.login);
      return false;
    }

    isUpdatingProfile.value = true;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'countryCode': countryCode,
        'city': city,
        'isProfileComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Get.snackbar(
        isFrench
            ? AppStrings.editProfileTitleFrench
            : AppStrings.editProfileTitle,
        isFrench
            ? AppStrings.editProfileSuccessFrench
            : AppStrings.editProfileSuccess,
      );
      return true;
    } on FirebaseException catch (e) {
      debugPrint('updateProfile FirebaseException: ${e.message}');
      Get.snackbar(
        isFrench ? AppStrings.errorTitleFrench : AppStrings.errorTitle,
        isFrench
            ? AppStrings.editProfileErrorFrench
            : AppStrings.editProfileError,
      );
      return false;
    } catch (e) {
      debugPrint('updateProfile error: $e');
      Get.snackbar(
        isFrench ? AppStrings.errorTitleFrench : AppStrings.errorTitle,
        isFrench
            ? AppStrings.editProfileErrorFrench
            : AppStrings.editProfileError,
      );
      return false;
    } finally {
      isUpdatingProfile.value = false;
    }
  }

  Future<ChangePasswordStatus> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final isFrench = Get.locale?.languageCode == 'fr';
    final errorTitle =
        isFrench ? AppStrings.errorTitleFrench : AppStrings.errorTitle;
    final successTitle =
        isFrench
            ? AppStrings.changePasswordTitleFrench
            : AppStrings.changePasswordTitle;
    final successMessage =
        isFrench
            ? AppStrings.changePasswordSuccessFrench
            : AppStrings.changePasswordSuccess;

    if (user == null || user.email == null) {
      Get.snackbar(
        errorTitle,
        isFrench
            ? AppStrings.changePasswordGenericErrorFrench
            : AppStrings.changePasswordGenericError,
        snackPosition: SnackPosition.TOP,
      );
      return ChangePasswordStatus.error;
    }

    final hasPasswordProvider = user.providerData.any(
      (info) => info.providerId == EmailAuthProvider.PROVIDER_ID,
    );
    if (!hasPasswordProvider) {
      Get.snackbar(
        errorTitle,
        isFrench
            ? AppStrings.changePasswordProviderUnsupportedFrench
            : AppStrings.changePasswordProviderUnsupported,
        snackPosition: SnackPosition.TOP,
      );
      return ChangePasswordStatus.providerMismatch;
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return ChangePasswordStatus.wrongPassword;
      }
      if (e.code == 'requires-recent-login') {
        Get.snackbar(
          errorTitle,
          isFrench
              ? AppStrings.changePasswordRecentLoginRequiredFrench
              : AppStrings.changePasswordRecentLoginRequired,
          snackPosition: SnackPosition.TOP,
        );
        return ChangePasswordStatus.requiresRecentLogin;
      }
      Get.snackbar(
        errorTitle,
        isFrench
            ? AppStrings.changePasswordGenericErrorFrench
            : AppStrings.changePasswordGenericError,
        snackPosition: SnackPosition.TOP,
      );
      return ChangePasswordStatus.error;
    } catch (e) {
      debugPrint('changePassword reauth error: $e');
      Get.snackbar(
        errorTitle,
        isFrench
            ? AppStrings.changePasswordGenericErrorFrench
            : AppStrings.changePasswordGenericError,
        snackPosition: SnackPosition.TOP,
      );
      return ChangePasswordStatus.error;
    }

    try {
      await user.updatePassword(newPassword);
      await user.reload();
      Get.snackbar(
        successTitle,
        successMessage,
        snackPosition: SnackPosition.TOP,
      );
      return ChangePasswordStatus.success;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        Get.snackbar(
          errorTitle,
          isFrench
              ? AppStrings.changePasswordRecentLoginRequiredFrench
              : AppStrings.changePasswordRecentLoginRequired,
          snackPosition: SnackPosition.TOP,
        );
        return ChangePasswordStatus.requiresRecentLogin;
      }
      if (e.code == 'weak-password') {
        Get.snackbar(
          errorTitle,
          AppStrings.validationPasswordStrength,
          snackPosition: SnackPosition.TOP,
        );
        return ChangePasswordStatus.error;
      }
      if (e.code == 'provider-already-linked') {
        Get.snackbar(
          errorTitle,
          isFrench
              ? AppStrings.changePasswordProviderUnsupportedFrench
              : AppStrings.changePasswordProviderUnsupported,
          snackPosition: SnackPosition.TOP,
        );
        return ChangePasswordStatus.providerMismatch;
      }
      debugPrint('changePassword update error: ${e.code} ${e.message}');
      Get.snackbar(
        errorTitle,
        isFrench
            ? AppStrings.changePasswordGenericErrorFrench
            : AppStrings.changePasswordGenericError,
        snackPosition: SnackPosition.TOP,
      );
      return ChangePasswordStatus.error;
    } catch (e) {
      debugPrint('changePassword unexpected error: $e');
      Get.snackbar(
        errorTitle,
        isFrench
            ? AppStrings.changePasswordGenericErrorFrench
            : AppStrings.changePasswordGenericError,
        snackPosition: SnackPosition.TOP,
      );
      return ChangePasswordStatus.error;
    }
  }

  /// Send password reset email
  /// Returns a string status for UI dialog handling
  Future<String> forgotPassword(String email) async {
    isLoadingForgotPassword.value = true;
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return 'success';
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'user-not-found';
        case 'invalid-email':
          return 'invalid-email';
        case 'too-many-requests':
          return 'too-many-requests';
        default:
          return 'error';
      }
    } catch (_) {
      return 'error';
    } finally {
      isLoadingForgotPassword.value = false;
    }
  }

  Future<String> getName() async {
    final user = _auth.currentUser;
    if (user == null) return '';
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final data = doc.data();
      if (data == null) return '';
      final firstName = data['firstName'] ?? '';
      final lastName = data['lastName'] ?? '';
      return '$firstName $lastName';
    } catch (e) {
      debugPrint('Error fetching user name: $e');
      return '';
    }
  }

  Future<String> getFirstName() async {
    final user = _auth.currentUser;
    if (user == null) return '';
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final data = doc.data();
      if (data == null) return '';
      return data['firstName'] ?? '';
    } catch (e) {
      debugPrint('Error fetching user first name: $e');
      return '';
    }
  }

  Future<String> getLastName() async {
    final user = _auth.currentUser;
    if (user == null) return '';
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final data = doc.data();
      if (data == null) return '';
      final lastName = data['lastName'] ?? '';
      return lastName;
    } catch (e) {
      debugPrint('Error fetching user last name: $e');
      return '';
    }
  }

  Future<String> getCity() async {
    final user = _auth.currentUser;
    if (user == null) return '';
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final data = doc.data();
      if (data == null) return '';
      final city = data['city'] ?? '';
      return city;
    } catch (e) {
      debugPrint('Error fetching user city: $e');
      return '';
    }
  }

  // ===============================================
  // END FORGOT PASSWORD FEATURE - Michel
  // ===============================================
}
