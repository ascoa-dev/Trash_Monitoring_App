# ASCOA Trash Monitoring App

Flutter app using GetX, Firebase Auth, and a shared design system.

## 🚀 Highlights

- Modular architecture with shared widgets and centralized tokens
- Auth flows with improved UX (floating labels, live password checklist)
- Deep-link driven Reset Password screen that reuses shared validation, shows the new success dialog artwork, and routes back to Login after completion
- **Profile module now includes a dedicated Change Password flow** with strong password validation, bilingual copy, and success/error snackbars aligned with the signup UX.
- Forgot Password uses an overlay dialog (no separate confirmation screen)
- **New: Firebase Analytics + Crashlytics integration** via a centralized `Analytics` wrapper (screen views, key events, non-fatal error reporting)
- Shared `FormBinding` injects `FormControllers` and `ValidationController`
- Consistent spacing/colors/strings via `AppDimensions`, `AppColors`, `AppStrings`
- New: Avatar upload with crop, WebP compression, thumbnail generation, and Firebase Storage integration. Uses a shared `AvatarPhotoHandler` with caching via `cached_network_image`, plus tap-to-zoom full-screen preview.

## 📂 Project Structure

See [Structure.md](Structure.md) for a detailed overview of architecture and folder organization.

Key docs:

- [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) — setup, architecture, and best practices
- [SHARED_COMPONENTS_GUIDE.md](SHARED_COMPONENTS_GUIDE.md) — shared tokens and widgets
- [Forgot Password feature](lib/modules/auth/forgot_password.md) — flow and `AppDialog` usage
- Analytics & Crash reporting: see the “Analytics & Crash Reporting (Firebase)” section in [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md)

Note: The `AuthController` now loads/creates a user document in Cloud Firestore on sign-in/signup and uses a `UserModel` to represent profile data. New route `AppRoutes.completeProfile` is used when a user's profile is incomplete.

## 🔑 Authentication Notes

- Login/Signup reuse shared `FormControllers` and `ValidationController` via `FormBinding`.
- Navigation hygiene: only carry valid emails between auth screens; clear password when switching Login ↔ Signup.
- Signup: PasswordStrengthChecklist remains visible during typing, even when valid.
- Signup: Terms checkbox shows an inline error and error border if not accepted on submit.

Obsolete (removed): `SignupBinding`, `SignupFormController` (replaced by `FormBinding`).

## 🧪 Run locally

```pwsh
flutter pub get
flutter analyze
flutter run -d windows
```

Initial route is determined at runtime: signed-in users go to Home; otherwise Login.

## 📈 Analytics & Crash Reporting (Firebase)

This app uses **Firebase Analytics** and **Firebase Crashlytics** through a single wrapper: `lib/shared/analytics/analytics_service.dart`.

- In **debug** builds, analytics/crash reporting are disabled and events are printed to the console for easy verification.
- In **profile/release** builds, events and non-fatal errors are sent to Firebase.

Add new events/properties in:

- `lib/shared/analytics/analytics_events.dart`
- `lib/shared/analytics/analytics_props.dart`

How to test sending real events:

- `flutter run --profile` (recommended for local validation)

More details (conventions, privacy rules, patterns) are in [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md).

## Recent changes

### Reset Password deep link flow

- Added a reset-password module under `lib/modules/auth/`:
  - `views/reset_password_screen.dart` mirrors the change-password layout without the current-password field, integrates the password checklist, and presents a blocking success dialog that clears auth state before returning to Login.
  - `controllers/reset_password_controller.dart` coordinates validation, interacts with `AuthController.resetPasswordWithCode`, and centralizes snackbar feedback for all Firebase error codes.
  - `bindings/reset_password_binding.dart` injects the controller and forwards the out-of-band code (`oobCode`) passed from deep links or manual navigation.
  - `models/reset_password_status.dart` enumerates the result states used by both the controller and the auth service layer.
- Introduced a dedicated `AppRoutes.resetPassword` entry, wired into `main.dart` alongside existing auth routes, and updated the shared `FormBinding` registration so the screen can reuse global controllers.
- Hooked up deep links using the [`app_links`](https://pub.dev/packages/app_links) plugin. The app now listens for Firebase reset-password emails targeting `https://accounts.ascoa-cm.org/reset?mode=resetPassword&oobCode=...` and navigates directly into the new flow.
- Updated `AuthController` with `resetPasswordWithCode`, which calls `FirebaseAuth.confirmPasswordReset` and translates its exceptions into the new enum.
- Android configuration:
  - `MainActivity` package renamed to `com.ascoa.app`, with Gradle namespace/applicationId updated to match.
  - `AndroidManifest.xml` now contains an auto-verified `<intent-filter>` for the production reset-password host/path and keeps the activity in singleTask mode.
- Firebase configuration files (`google-services.json`, `firebase_options.dart`, `firebase.json`) refreshed with the new app IDs and project metadata.
- Assets and strings:
  - Added `assets/ASCOA/Password_update_successful.png` and exposed it via `AppImages.passwordUpdateSuccessful` for the success dialog artwork.
  - Expanded `AppStrings` with English/French copy for the reset-password screen, errors, and success states.
- Added the `app_links` dependency in `pubspec.yaml` and re-generated platform plugin registrants for Linux, macOS, and Windows.

### Avatar upload & profile photos

- Added a unified avatar flow driven by `shared/utils/avatar_photo_handler.dart`:

  - Lets users pick from Camera/Gallery, crop to a circle-aligned square, compress to WebP, and upload to Firebase Storage.
  - Uploads two assets per user: `avatars/{uid}/avatar.webp` (600×600) and `avatars/{uid}/thumb.webp` (200×200).
  - Firestore user doc now stores `avatarUrl`, `thumbUrl`, and `avatarUpdatedAt` (plus `photoURL` on the Firebase user where supported).
  - UI displays the thumbnail when available and falls back to the full-size avatar.
  - `ProfileScreen` adds a tap-to-zoom overlay (`modules/profile/widgets/full_image_overlay.dart`) to view the full-resolution avatar.
  - Network images use `CachedNetworkImage` with placeholders and error fallbacks; URLs are normalized to handle cache-busting query params.

- User model additions in `lib/app/models/user.dart`:

  - New fields: `avatarUrl`, `thumbUrl`, `avatarUpdatedAt`, and `photoURL`.
  - `AuthController` now prefers the typed `currentUserModel` over raw Firestore maps for consistency.

- Screen/controller integrations:

  - `complete_profile_screen.dart`: “Edit” now invokes the avatar flow and immediately previews the uploaded image.
  - `edit_profile_controller.dart` and `edit_profile_screen.dart`: reactive `avatarUrl`/`thumbUrl` fields, edit button triggers the upload flow.
  - `profile_screen.dart`: renders the avatar via `CachedNetworkImage`, with a fullscreen viewer on tap.

- New/updated tokens and strings:

  - `AppDimensions`: avatar crop constants (preview size, output sizes, overlay opacity, etc.).
    - `AppStrings`: bilingual strings for picker/crop/upload flows.
    - `AppColors`: added `black87` legacy alias.

- Dependencies added (see `pubspec.yaml`): `image_picker`, `croppy`, `extended_image`, `flutter_image_compress`, `firebase_storage`, `cached_network_image`, `uuid`, `path_provider`, `path`.

  - In debug builds we force Croppy’s pure-Dart solver to avoid native FFI on unsupported targets: set in `main.dart` with `croppy.croppyForceUseCassowaryDartImpl = true`.
  - Lockfile indicates a minimum Flutter SDK of 3.35.0.

- **Change Password feature:** Added `ChangePasswordScreen`, controller, binding, and `ChangePasswordStatus` model. The screen mirrors signup validation (strong password checklist, mismatch handling, new-vs-current guard) and surfaces localized snackbars for success, wrong current password, and generic failures.
- **Profile updates:** Profile screen now links to Change Password and uses a new `ProfileSignOutButton` widget that keeps sizing consistent with the profile cards while calling `AuthController.logout()`.
- **Email verification improvements:** `EmailVerificationScreen` polls verification status, exposes resend/cancel actions, and clears shared form state when a user backs out.
- **Auth controller enhancements:** Login surfaces friendlier copy for `invalid-credential`, and `changePassword` now handles recent-login/provider edge cases with localized strings and snackbar feedback. Forgot Password sanitizes carried-over email state before validation.
- **Design tokens:** `AppStrings` and `AppDimensions` gained change-password copy, email-verification strings, and spacing tokens (e.g., `changePasswordTopSpacing`, `profileSignOutHeight`). Use these instead of hard-coded values when extending the flows.
- Verification: `flutter analyze`

Older refactors (tokenization sweep, image constants, typography tokens, validator centralization) remain in effect; see commit history for details.

Latest updates (auth & UI fixes)

- Reworked `EmailVerificationScreen` to match the visual structure used by the Forgot Password flow (stacked background images anchored to viewport height, SafeArea + SingleChildScrollView padding, and full-width button sizing). This prevents background artwork from moving when screen content spacing changes.
- Fixed `CircularInfiniteLoader` crash (AnimatedBuilder signature bug) and added a small transparent gap between the loader track and the active arc for improved contrast. The loader now uses shared constants from `lib/shared/constants/app_dimensions.dart` and `app_colors.dart`.
- Enforced server-driven city validation: when the configuration `allowCustomCities` is false, the Complete Profile / Edit Profile flows will block saving if a custom/unrecognized city is entered. Validation logic lives in `lib/shared/controllers/validation_controller.dart` and `lib/shared/controllers/cities_controller.dart`.
- Standardized button sizing for resend / use-another-email actions to match the Forgot Password screen (OutlinedButton wrapped in a SizedBox using `AppDimensions.buttonHeight` and `screenPadding`).
- Fixed Forgot Password back button behavior (now only navigates back without acting as cancel). The Cancel flow still clears form controllers as intended.

Files touched (high-level):

- lib/modules/auth/views/email_verification_screen.dart
- lib/modules/auth/views/forgot_password_screen.dart
- lib/modules/auth/views/complete_profile_screen.dart
- lib/shared/widgets/circular_loader.dart
- lib/shared/constants/app_dimensions.dart
- lib/shared/constants/app_colors.dart
- lib/shared/constants/app_strings.dart
- lib/shared/controllers/cities_controller.dart

Testing & verification:

- Ran `flutter analyze` after edits (no static analyzer issues reported).
- Focused unit/UI tests (forgot password spec) were executed during the changeset iteration.

If you maintain CI or localization files, please check the newly added `AppStrings` keys before merging to avoid missing translations.
