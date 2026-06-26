import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:we_monitor/app/routes/app_routes.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:we_monitor/modules/profile/models/change_password_status.dart';
import 'package:we_monitor/modules/auth/models/reset_password_status.dart';
import 'package:we_monitor/app/models/user.dart';
import 'package:we_monitor/shared/analytics/analytics_service.dart';
import 'package:we_monitor/shared/services/snackbar_service.dart';
import 'package:hive/hive.dart';

class AuthController extends GetxController {
  late final FirebaseAuth _auth;
  late Box<UserModel> userBox;
  late final Future<void> _hiveReady;
  Rxn<User> firebaseUser = Rxn<User>();
  Rxn<UserModel> currentUserModel = Rxn<UserModel>();
  RxBool isCompletingProfile = false.obs;
  RxBool isUpdatingProfile = false.obs;

  // ===============================================
  // SNACKBAR MESSAGE SYSTEM
  // Controllers emit messages, widgets display them
  // ===============================================

  /// Observable snackbar message that widgets listen to
  /// Set this value to emit a snackbar - widgets will display and clear it
  final Rxn<SnackbarMessage> snackbarMessage = Rxn<SnackbarMessage>();

  /// Emit a snackbar message (widgets will display it)
  void _emitSnackbar(
    String title,
    String message, {
    SnackbarType type = SnackbarType.info,
  }) {
    snackbarMessage.value = SnackbarMessage(
      title: title,
      message: message,
      type: type,
    );
  }

  /// Emit a success snackbar
  void _emitSuccess(String title, String message) {
    _emitSnackbar(title, message, type: SnackbarType.success);
  }

  /// Emit an error snackbar
  void _emitError(String title, String message) {
    _emitSnackbar(title, message, type: SnackbarType.error);
  }

  /// Emit a warning snackbar
  void _emitWarning(String title, String message) {
    _emitSnackbar(title, message, type: SnackbarType.warning);
  }

  /// Emit an info snackbar
  void _emitInfo(String title, String message) {
    _emitSnackbar(title, message, type: SnackbarType.error);
  }

  @override
  void onInit() {
    super.onInit();
    _auth = FirebaseAuth.instance;
    firebaseUser.bindStream(_auth.authStateChanges());
    // Ensure Hive box is available as early as possible.
    // AuthGate can run before onReady() depending on routing timing.
    _hiveReady = _initHive();
    debugPrint('AuthController initialized');
  }

  @override
  Future<void> onReady() async {
    super.onReady();
    await _hiveReady;
  }

  Future<void> _initHive() async {
    userBox = await Hive.openBox<UserModel>('user_profile');
  }

  Future<User?> _getStableUser() async {
    final current = _auth.currentUser;
    if (current != null) return current;

    // On cold start, FirebaseAuth can briefly report null while restoring state.
    try {
      return await _auth.authStateChanges().first.timeout(
        const Duration(seconds: 2),
      );
    } catch (_) {
      return _auth.currentUser;
    }
  }

  Future<void> _handleUserPostLogin(User user, String signUpMethod) async {
    // Store the signup method for AuthGate to use
    _pendingSignUpMethod = signUpMethod;

    // Route to AuthGate - it will handle all async checks
    Get.offAllNamed(AppRoutes.authGate);
  }

  // Store signup method temporarily for AuthGate resolution
  String? _pendingSignUpMethod;

  /// Helper: Resolve signup method from Firestore/cache
  /// This is the ONLY source of truth for signup method
  Future<String> _resolveSignUpMethod(String uid, String? fallback) async {
    // Try cached profile first (FAST)
    final cached = userBox.get(uid);
    if (cached != null) {
      return cached.signUpMethod;
    }

    // Fallback to Firestore (SLOW)
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        return doc.data()!['signUpMethod'] as String? ?? 'unknown';
      }
    } catch (e) {
      debugPrint('Error resolving signup method: $e');
    }

    // Last resort: use fallback or 'unknown'
    return fallback ?? 'unknown';
  }

  /// 🔒 AuthGate Resolution Logic
  /// This method determines where the user should be routed after login.
  /// It runs asynchronously in the AuthGate screen to prevent UI flicker.
  Future<void> resolveAuthFlow() async {
    await _hiveReady;

    final user = await _getStableUser();
    String? signUpMethod = _pendingSignUpMethod;

    // Guard: No user found
    if (user == null) {
      final cachedUser =
          userBox.values.isNotEmpty ? userBox.values.first : null;

      if (cachedUser != null) {
        currentUserModel.value = cachedUser;
        Get.offAllNamed(AppRoutes.home);
        return;
      }

      Get.offAllNamed(AppRoutes.login);
      return;
    }

    // ✅ CRITICAL: Resolve signup method from Firestore/cache FIRST
    final resolvedSignUpMethod = await _resolveSignUpMethod(
      user.uid,
      signUpMethod,
    );
    debugPrint(
      'Resolved signup method: $resolvedSignUpMethod for user ${user.email}',
    );

    // 1️⃣ Email verification check (ONLY for email/password signups)
    final isOAuth = resolvedSignUpMethod == 'google';

    if (!isOAuth && !user.emailVerified) {
      debugPrint('Email not verified: ${user.email}');
      try {
        await user.sendEmailVerification();
        _emitInfo(
          'Email Sent',
          'A verification link has been sent to ${user.email}',
        );
      } catch (e) {
        debugPrint('Failed to send verification email: $e');
      }
      Get.offAllNamed(AppRoutes.emailVerification);
      return;
    }

    // 2️⃣ Try cached profile first (FAST)
    final cached = userBox.get(user.uid);
    if (cached != null) {
      currentUserModel.value = cached;

      // Verify signup method matches
      if (cached.signUpMethod != resolvedSignUpMethod) {
        debugPrint(
          'Sign-up method mismatch: cache=${cached.signUpMethod}, current=$resolvedSignUpMethod',
        );
        _emitError(
          'Login Failed',
          'This account was registered using ${cached.signUpMethod}. Please login with that method.',
        );
        await _signOutAll();
        Get.offAllNamed(AppRoutes.login);
        return;
      }

      // Route based on cached profile
      _routeFromProfile(cached);

      // Refresh in background (don't await)
      _refreshProfileInBackground(user.uid, resolvedSignUpMethod);
      return;
    }

    // 3️⃣ Firestore fallback (SLOW - first time or cache miss)
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (!doc.exists || doc.data() == null) {
        // New user - create document
        final newDoc = {
          'email': user.email,
          'firstName': '',
          'lastName': '',
          'phoneNumber': '',
          'city': '',
          'countryCode': '',
          'isProfileComplete': false,
          'createdAt': FieldValue.serverTimestamp(),
          'signUpMethod': resolvedSignUpMethod,
        };
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(newDoc);

        currentUserModel.value = UserModel.fromMap(
          newDoc,
          uidFromDoc: user.uid,
        );
        await userBox.put(user.uid, currentUserModel.value!);

        _emitInfo('Welcome!', 'Please complete your profile information.');
        Get.offAllNamed(AppRoutes.completeProfile);
        return;
      }

      // Existing user
      final model = UserModel.fromMap(doc.data()!, uidFromDoc: user.uid);
      currentUserModel.value = model;
      await userBox.put(user.uid, model);

      // Verify signup method matches
      if (model.signUpMethod != resolvedSignUpMethod) {
        debugPrint(
          '1Sign-up method mismatch: firestore=${model.signUpMethod}, current=$resolvedSignUpMethod',
        );
        _emitError(
          'Login Failed',
          'This account was registered using ${model.signUpMethod}. Please login with that method.',
        );
        await Future.delayed(const Duration(milliseconds: 300));
        debugPrint(
          'XSign-up method mismatch: firestore=${model.signUpMethod}, current=$resolvedSignUpMethod',
        );
        await _signOutAll();
        Get.offAllNamed(AppRoutes.login);
        return;
      }

      _routeFromProfile(model);
    } on FirebaseException catch (e) {
      debugPrint('Firestore error during auth resolution: ${e.message}');

      // Offline fallback: use cached profile if available; otherwise allow home
      // with minimal assumptions (the Firebase user is still authenticated).
      final cached = userBox.get(user.uid);
      if (cached != null) {
        currentUserModel.value = cached;
        _routeFromProfile(cached);
        return;
      }

      _emitWarning(
        'Offline Mode',
        'Could not load your profile right now. Continuing with limited offline access.',
      );
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      debugPrint('Unexpected error during auth resolution: $e');
      _emitError('Error', 'An unexpected error occurred: $e');
      Get.offAllNamed(AppRoutes.login);
    } finally {
      _pendingSignUpMethod = null; // Clean up
    }
  }

  /// Helper: Route user based on profile completeness
  void _routeFromProfile(UserModel model) {
    if (!model.isProfileComplete) {
      _emitInfo(
        'Incomplete Profile',
        'Please complete your profile information.',
      );
      Get.offAllNamed(AppRoutes.completeProfile);
    } else {
      _emitSuccess(
        'Login Successful',
        'Welcome back ${model.firstName} ${model.lastName}!',
      );
      Get.offAllNamed(AppRoutes.home);
    }
  }

  /// Helper: Refresh profile in background (non-blocking)
  Future<void> _refreshProfileInBackground(
    String uid,
    String signUpMethod,
  ) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        final model = UserModel.fromMap(doc.data()!, uidFromDoc: uid);
        currentUserModel.value = model;
        await userBox.put(uid, model);
        debugPrint('Profile refreshed in background');
      }
    } catch (e) {
      debugPrint('Background profile refresh failed: $e');
      // Silent fail - user already has cached data
    }
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
        // populate typed model
        currentUserModel.value = UserModel.fromMap(
          userData,
          uidFromDoc: user.uid,
        );
        await userBox.put(user.uid, currentUserModel.value!);

        // Use typed model instead of map access
        final model = currentUserModel.value!;

        if (model.signUpMethod != signUpMethod) {
          debugPrint(
            '2Sign-up method mismatch: firestore=${model.signUpMethod}, current=$signUpMethod',
          );
          _emitError(
            'Login Failed',
            'This account was registered using ${model.signUpMethod}. Please login with that method.',
          );
          await _signOutAll(); // Sign out from all providers
          return;
        }

        if (model.isProfileComplete) {
          _emitSuccess(
            'Login Successful',
            'Welcome back ${model.firstName} ${model.lastName}!',
          );
          Get.offAllNamed(AppRoutes.home);
        } else {
          _emitInfo(
            'Incomplete Profile',
            'Please complete your profile information.',
          );
          Get.offAllNamed(AppRoutes.completeProfile);
        }
      } else {
        // New user - create document
        final newDoc = {
          'email': user.email,
          'firstName': '',
          'lastName': '',
          'phoneNumber': '',
          'city': '',
          'countryCode': '',
          'isProfileComplete': false,
          'createdAt': FieldValue.serverTimestamp(), // Good practice
          'signUpMethod': signUpMethod,
        };
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(newDoc);
        currentUserModel.value = UserModel.fromMap(
          newDoc,
          uidFromDoc: user.uid,
        );
        await userBox.put(user.uid, currentUserModel.value!);

        _emitInfo('Welcome!', 'Please complete your profile information.');
        Get.offAllNamed(AppRoutes.completeProfile);
      }
    } on FirebaseException catch (e) {
      debugPrint('Firestore error: ${e.message}');

      final cached = userBox.get(user.uid);
      if (cached != null) {
        currentUserModel.value = cached;
        Get.offAllNamed(AppRoutes.home);
      }
    } catch (e) {
      _emitError('Error', 'An unexpected error occurred: $e');
    }
  }

  Future<void> login(String email, String password) async {
    isLoadingLogin.value = true;
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user found after sign-in.');

      // Track successful login
      Analytics.track(AnalyticsEvents.loginSuccess, {
        AnalyticsProps.method: AuthMethods.email,
      });
      await Analytics.identify(user.uid);

      await _handleUserPostLogin(user, 'email');
    } on FirebaseAuthException catch (e) {
      // Track failed login
      Analytics.track(AnalyticsEvents.loginFailed, {
        AnalyticsProps.method: AuthMethods.email,
        AnalyticsProps.reason: e.code,
      });

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
      debugPrint('Login error: ${e.message}');
      _emitError('Login Failed', message);
    } catch (e) {
      Analytics.track(AnalyticsEvents.loginFailed, {
        AnalyticsProps.method: AuthMethods.email,
        AnalyticsProps.reason: 'unknown_error',
      });
      _emitError('Login Failed', e.toString());
    } finally {
      isLoadingLogin.value = false;
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        final googleUser = await GoogleSignIn.instance.authenticate();
        final googleAuth = googleUser.authentication;
        if (googleAuth.idToken == null) {
          throw Exception('Failed to get ID token from Google sign-in.');
        }
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }
      final user = userCredential.user;
      if (user == null) throw Exception('No user found after Google sign-in.');

      // Reload user to ensure provider data is synced
      await user.reload();

      // Track successful Google login
      Analytics.track(AnalyticsEvents.loginSuccess, {
        AnalyticsProps.method: AuthMethods.google,
      });
      await Analytics.identify(user.uid);

      await _handleUserPostLogin(user, 'google');
    } on FirebaseAuthException catch (e) {
      Analytics.track(AnalyticsEvents.loginFailed, {
        AnalyticsProps.method: AuthMethods.google,
        AnalyticsProps.reason: e.code,
      });
      if (e.code == 'account-exists-with-different-credential') {
        _emitError(
          'Account Exists',
          'This email is already registered with another sign-in method. Please use that method first.',
        );
      } else {
        _emitError('Google Login Failed', e.message ?? 'Unknown error');
      }
      await _signOutAll();
    } catch (e) {
      Analytics.track(AnalyticsEvents.loginFailed, {
        AnalyticsProps.method: AuthMethods.google,
        AnalyticsProps.reason: 'unknown_error',
      });
      debugPrint('Google login error: $e');
      _emitError('Google Login Failed', e.toString());
      await _signOutAll();
    }
  }

  Future<void> logout() async {
    Analytics.track(AnalyticsEvents.logoutClicked);
    await _signOutAll();
    Analytics.track(AnalyticsEvents.logoutSuccess);
    await Analytics.clearIdentity();
    _emitInfo('Logout', 'You have been logged out.');
  }

  Future<void> _signOutAll() async {
    try {
      await _auth.signOut();
      await GoogleSignIn.instance.signOut();
      await userBox.clear();
      currentUserModel.value = null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error during logout: $e');
      }
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

      // Track successful signup
      Analytics.track(AnalyticsEvents.signupSuccess, {
        AnalyticsProps.method: AuthMethods.email,
      });
      await Analytics.identify(user.uid);
      await Analytics.setUserProperties(signupMethod: AuthMethods.email);

      // FIXED: Now calls _handleUserPostLogin to create user document
      await _handleUserPostLogin(user, 'email');
    } on FirebaseAuthException catch (e) {
      Analytics.track(AnalyticsEvents.signupFailed, {
        AnalyticsProps.method: AuthMethods.email,
        AnalyticsProps.reason: e.code,
      });
      if (e.code == 'email-already-in-use') {
        _emitError(
          'Signup Failed',
          'This email is already in use. Please use a different email.',
        );
      } else if (e.code == 'weak-password') {
        _emitError(
          'Signup Failed',
          'Password is too weak. Please use a stronger password.',
        );
      } else if (e.code == 'invalid-email') {
        _emitError('Signup Failed', 'Invalid email address.');
      } else {
        _emitError('Signup Failed', e.message ?? 'An unknown error occurred.');
      }
    } catch (e) {
      _emitError('Signup Failed', e.toString());
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

  Future<UserModel?> completeProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String countryCode,
    required String city,
  }) async {
    final user = _auth.currentUser;
    final isFrench = Get.locale?.languageCode == 'fr';
    if (user == null) {
      _emitError(
        isFrench ? AppStrings.errorTitleFrench : AppStrings.errorTitle,
        isFrench
            ? 'Vous devez être connecté pour continuer.'
            : 'You must be signed in to continue.',
      );
      Get.offAllNamed(AppRoutes.login);
      return null;
    }

    isCompletingProfile.value = true;

    try {
      final updated = {
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'countryCode': countryCode,
        'city': city,
        'isProfileComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(updated, SetOptions(merge: true));

      // populate current model
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (doc.data() != null) {
        currentUserModel.value = UserModel.fromMap(
          doc.data()!,
          uidFromDoc: user.uid,
        );
        await userBox.put(user.uid, currentUserModel.value!);
      }

      // Track profile completion
      Analytics.track(AnalyticsEvents.profileCompletionCompleted);
      await Analytics.setUserProperties(hasCompletedProfile: true, city: city);

      _emitSuccess(
        isFrench
            ? AppStrings.completeProfileTitleFrench
            : AppStrings.completeProfileTitle,
        isFrench
            ? AppStrings.completeProfileSuccessFrench
            : AppStrings.completeProfileSuccess,
      );
      Get.offAllNamed(AppRoutes.home);
      return currentUserModel.value;
    } on FirebaseException catch (e) {
      Analytics.track(AnalyticsEvents.profileCompletionFailed, {
        AnalyticsProps.reason: 'firebase_error',
      });
      Analytics.error(e, null, reason: 'complete_profile_failed');
      if (kDebugMode) {
        debugPrint('completeProfile FirebaseException: ${e.message}');
      }
      _emitError(
        isFrench ? AppStrings.errorTitleFrench : AppStrings.errorTitle,
        isFrench
            ? AppStrings.completeProfileErrorFrench
            : AppStrings.completeProfileError,
      );
      return null;
    } catch (e, stack) {
      Analytics.track(AnalyticsEvents.profileCompletionFailed, {
        AnalyticsProps.reason: 'unknown_error',
      });
      Analytics.error(e, stack, reason: 'complete_profile_failed');
      if (kDebugMode) debugPrint('completeProfile error: $e');
      _emitError(
        isFrench ? AppStrings.errorTitleFrench : AppStrings.errorTitle,
        isFrench
            ? AppStrings.completeProfileErrorFrench
            : AppStrings.completeProfileError,
      );
      return null;
    } finally {
      isCompletingProfile.value = false;
    }
  }

  Future<UserModel?> fetchCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.serverAndCache));

      if (doc.data() != null) {
        final model = UserModel.fromMap(doc.data()!, uidFromDoc: user.uid);
        currentUserModel.value = model;
        await userBox.put(user.uid, model);
        return model;
      }
    } catch (_) {
      debugPrint('Using cached user profile');
    }

    final cached = userBox.get(user.uid);
    if (cached != null) {
      currentUserModel.value = cached;
      return cached;
    }

    return null;
  }

  Future<UserModel?> updateProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String countryCode,
    required String city,
  }) async {
    final user = _auth.currentUser;
    final isFrench = Get.locale?.languageCode == 'fr';
    if (user == null) {
      _emitError(
        isFrench ? AppStrings.errorTitleFrench : AppStrings.errorTitle,
        isFrench
            ? 'Vous devez être connecté pour continuer.'
            : 'You must be signed in to continue.',
      );
      Get.offAllNamed(AppRoutes.login);
      return null;
    }

    isUpdatingProfile.value = true;

    try {
      final updated = {
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'countryCode': countryCode,
        'city': city,
        'isProfileComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(updated, SetOptions(merge: true));

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (doc.data() != null) {
        currentUserModel.value = UserModel.fromMap(
          doc.data()!,
          uidFromDoc: user.uid,
        );
        await userBox.put(user.uid, currentUserModel.value!);
      }

      _emitSuccess(
        isFrench
            ? AppStrings.editProfileTitleFrench
            : AppStrings.editProfileTitle,
        isFrench
            ? AppStrings.editProfileSuccessFrench
            : AppStrings.editProfileSuccess,
      );
      return currentUserModel.value;
    } on FirebaseException catch (e) {
      debugPrint('updateProfile FirebaseException: ${e.message}');
      _emitError(
        isFrench ? AppStrings.errorTitleFrench : AppStrings.errorTitle,
        isFrench
            ? AppStrings.editProfileErrorFrench
            : AppStrings.editProfileError,
      );
      return null;
    } catch (e) {
      debugPrint('updateProfile error: $e');
      _emitError(
        isFrench ? AppStrings.errorTitleFrench : AppStrings.errorTitle,
        isFrench
            ? AppStrings.editProfileErrorFrench
            : AppStrings.editProfileError,
      );
      return null;
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
      _emitError(
        errorTitle,
        isFrench
            ? AppStrings.changePasswordGenericErrorFrench
            : AppStrings.changePasswordGenericError,
      );
      return ChangePasswordStatus.error;
    }

    final hasPasswordProvider = user.providerData.any(
      (info) => info.providerId == EmailAuthProvider.PROVIDER_ID,
    );
    if (!hasPasswordProvider) {
      _emitError(
        errorTitle,
        isFrench
            ? AppStrings.changePasswordProviderUnsupportedFrench
            : AppStrings.changePasswordProviderUnsupported,
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
        _emitError(
          errorTitle,
          isFrench
              ? AppStrings.changePasswordRecentLoginRequiredFrench
              : AppStrings.changePasswordRecentLoginRequired,
        );
        return ChangePasswordStatus.requiresRecentLogin;
      }
      _emitError(
        errorTitle,
        isFrench
            ? AppStrings.changePasswordGenericErrorFrench
            : AppStrings.changePasswordGenericError,
      );
      return ChangePasswordStatus.error;
    } catch (e) {
      debugPrint('changePassword reauth error: $e');
      _emitError(
        errorTitle,
        isFrench
            ? AppStrings.changePasswordGenericErrorFrench
            : AppStrings.changePasswordGenericError,
      );
      return ChangePasswordStatus.error;
    }

    try {
      await user.updatePassword(newPassword);
      await user.reload();
      Analytics.track(AnalyticsEvents.changePasswordSuccess);
      _emitSuccess(successTitle, successMessage);
      return ChangePasswordStatus.success;
    } on FirebaseAuthException catch (e) {
      Analytics.track(AnalyticsEvents.changePasswordFailed, {
        AnalyticsProps.reason: e.code,
      });
      if (e.code == 'requires-recent-login') {
        _emitError(
          errorTitle,
          isFrench
              ? AppStrings.changePasswordRecentLoginRequiredFrench
              : AppStrings.changePasswordRecentLoginRequired,
        );
        return ChangePasswordStatus.requiresRecentLogin;
      }
      if (e.code == 'weak-password') {
        _emitError(errorTitle, AppStrings.validationPasswordStrength);
        return ChangePasswordStatus.error;
      }
      if (e.code == 'provider-already-linked') {
        _emitError(
          errorTitle,
          isFrench
              ? AppStrings.changePasswordProviderUnsupportedFrench
              : AppStrings.changePasswordProviderUnsupported,
        );
        return ChangePasswordStatus.providerMismatch;
      }
      debugPrint('changePassword update error: ${e.code} ${e.message}');
      _emitError(
        errorTitle,
        isFrench
            ? AppStrings.changePasswordGenericErrorFrench
            : AppStrings.changePasswordGenericError,
      );
      return ChangePasswordStatus.error;
    } catch (e) {
      Analytics.track(AnalyticsEvents.changePasswordFailed, {
        AnalyticsProps.reason: 'unknown_error',
      });
      debugPrint('changePassword unexpected error: $e');
      _emitError(
        errorTitle,
        isFrench
            ? AppStrings.changePasswordGenericErrorFrench
            : AppStrings.changePasswordGenericError,
      );
      return ChangePasswordStatus.error;
    }
  }

  /// Send password reset email
  /// Returns a string status for UI dialog handling
  Future<String> forgotPassword(String email) async {
    isLoadingForgotPassword.value = true;
    Analytics.track(AnalyticsEvents.passwordResetRequested);
    try {
      ActionCodeSettings actionCodeSettings = ActionCodeSettings(
        url: 'https://accounts.ascoa-cm.org/reset',
        handleCodeInApp: true,
        androidPackageName: 'com.ascoa.wemonitor',
        androidInstallApp: false,
        androidMinimumVersion: '0',
        iOSBundleId: 'com.ascoa.wemonitor',
      );

      await _auth.sendPasswordResetEmail(
        email: email.trim(),
        actionCodeSettings: actionCodeSettings,
      );
      Analytics.track(AnalyticsEvents.passwordResetSuccess);
      return 'success';
    } on FirebaseAuthException catch (e) {
      Analytics.track(AnalyticsEvents.passwordResetFailed, {
        AnalyticsProps.reason: e.code,
      });
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
      Analytics.track(AnalyticsEvents.passwordResetFailed, {
        AnalyticsProps.reason: 'unknown_error',
      });
      return 'error';
    } finally {
      isLoadingForgotPassword.value = false;
    }
  }

  Future<ResetPasswordStatus> resetPasswordWithCode({
    required String oobCode,
    required String newPassword,
  }) async {
    if (oobCode.isEmpty) {
      return ResetPasswordStatus.invalidCode;
    }

    try {
      await _auth.confirmPasswordReset(code: oobCode, newPassword: newPassword);
      Analytics.track(AnalyticsEvents.passwordResetSuccess, {
        AnalyticsProps.method: 'code',
      });
      return ResetPasswordStatus.success;
    } on FirebaseAuthException catch (e) {
      Analytics.track(AnalyticsEvents.passwordResetFailed, {
        AnalyticsProps.reason: e.code,
      });
      if (e.code == 'expired-action-code') {
        return ResetPasswordStatus.expired;
      }
      if (e.code == 'invalid-action-code') {
        return ResetPasswordStatus.invalidCode;
      }
      if (e.code == 'weak-password') {
        return ResetPasswordStatus.validationError;
      }
      return ResetPasswordStatus.error;
    } catch (_) {
      Analytics.track(AnalyticsEvents.passwordResetFailed, {
        AnalyticsProps.reason: 'unknown_error',
      });
      return ResetPasswordStatus.error;
    }
  }

  Future<String> getName() async {
    final model = currentUserModel.value ?? await fetchCurrentUserProfile();
    if (model == null) return '';
    return '${model.firstName} ${model.lastName}';
  }

  Future<String> getFirstName() async {
    final model = currentUserModel.value ?? await fetchCurrentUserProfile();
    return model?.firstName ?? '';
  }

  Future<String> getLastName() async {
    final model = currentUserModel.value ?? await fetchCurrentUserProfile();
    return model?.lastName ?? '';
  }

  Future<String> getCity() async {
    final model = currentUserModel.value ?? await fetchCurrentUserProfile();
    return model?.city ?? '';
  }

  // ===============================================
  // END FORGOT PASSWORD FEATURE - Michel
  // ===============================================
}
