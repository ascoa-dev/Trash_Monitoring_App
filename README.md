# ASCOA Trash Monitoring App

Flutter app using GetX, Firebase Auth, and a shared design system.

## 🚀 Highlights

- Modular architecture with shared widgets and centralized tokens
- Auth flows with improved UX (floating labels, live password checklist)
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

- Tokenization sweep: replaced many hard-coded UI strings and some color literals with shared tokens. New/updated constants live in `lib/shared/constants/app_strings.dart` and `lib/shared/constants/app_colors.dart`.
- Profile UI updates: the profile screen support icons were replaced with PNG assets under `assets/ASCOA/Profile_Page_Icons/` (policy.png, faq.png, contact.png, signout.png). The shared `ProfileActionTile` now accepts either an `IconData` or a custom `leading` widget so images can be used without changing layout sizing.
- Validators centralized: `lib/shared/utils/validators.dart` now returns messages from `AppStrings` so validation copy is centralized and bilingual-ready.
- Files updated: notable edits include `email_verification_screen.dart`, `forgot_password_screen.dart`, `complete_profile_screen.dart`, `home_screen.dart`, `app_dialog.dart`, `auth_header.dart`, `password_strength_checklist.dart`, and shared widget token usage.
- Verification: ran focused forgot-password tests (all passed) and a quick `flutter analyze` (1 info lint unrelated to tokenization).

- Tooling cleanup: `tool/country_parser_probe.dart` was unused and has been removed from the repository. If you relied on that script, restore it from history or recreate it under `tool/`.
