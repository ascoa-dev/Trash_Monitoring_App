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
