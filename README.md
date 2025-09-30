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
