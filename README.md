# ASCOA Trash Monitoring App

Flutter app using GetX, Firebase Auth, and a shared design system.

## 🚀 Highlights

- Modular architecture with shared widgets and centralized tokens
- Auth flows with improved UX (floating labels, live password checklist)
- **Profile module now includes a dedicated Change Password flow** with strong password validation, bilingual copy, and success/error snackbars aligned with the signup UX.
- Forgot Password uses an overlay dialog (no separate confirmation screen)
- Shared `FormBinding` injects `FormControllers` and `ValidationController`
- Consistent spacing/colors/strings via `AppDimensions`, `AppColors`, `AppStrings`

## 📂 Project Structure

See [Structure.md](Structure.md) for a detailed overview of architecture and folder organization.

Key docs:

- [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) — setup, architecture, and best practices
- [SHARED_COMPONENTS_GUIDE.md](SHARED_COMPONENTS_GUIDE.md) — shared tokens and widgets
- [Forgot Password feature](lib/modules/auth/forgot_password.md) — flow and `AppDialog` usage

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

## Recent changes

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
