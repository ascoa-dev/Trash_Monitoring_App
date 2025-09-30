# ASCOA Trash Monitoring App - Developer Guide

## Project Overview

Flutter app using **GetX** for state management and **modular architecture** for scalability.

## Structure Summary

```plaintext
lib/
├── main.dart                # App entry + Firebase setup
├── app/                     # Global routes & controllers
├── modules/                 # Feature-based organization
└── shared/                  # Reusable components & constants
```

## What Was Implemented

### 1. Main App Setup (`main.dart`)

- Firebase initialization
- Global AuthController registration with `permanent: true`
- GetX app configuration

- Dynamic initial route: the app now checks `FirebaseAuth.instance.currentUser` after initialization and sets the initial route to `AppRoutes.home` when a user is already signed in; otherwise it uses `AppRoutes.login`.

````plaintext

### 2. Authentication Module (`modules/auth/`)

Screens:
- `login_screen_v2.dart` — floating label inputs, divider, social buttons
- `signup_screen.dart` — floating label inputs + PasswordStrengthChecklist; Terms checkbox with inline error and error border when not accepted
- `forgot_password_screen.dart` — in-place overlay confirmation via `AppDialog` (confirmation screen removed)

Controllers and bindings:
- Global `AuthController` (permanent)
- AuthController now interacts with Cloud Firestore to load/create a `users` document after sign-in/signup. See `lib/app/models/user.dart` for the `UserModel` structure.
- Shared `FormBinding` injects `FormControllers` and `ValidationController`
- Obsolete: `SignupBinding` and `SignupFormController` removed

Navigation hygiene:
- Only carry email between screens if valid; clear email errors before navigating
- Clear password when switching Login ↔ Signup

### 3. Shared Design System (`shared/constants/`)

Centralized tokens to replace hard-coded values:

- `AppColors` — background/accent/text/social/error colors
- `AppTextStyles` — headings, body, labels, divider, terms, error
- `AppDimensions` — spacers, border widths; includes `inputBorderWidthFocused`, `inputBorderWidthError`, and `authDividerSideWidthFactor`
- `AppStrings` — all user-facing copy (e.g., `otherSignUpOptions`)

### 4. Reusable Components (`shared/widgets/`)

- `FloatingLabelInputField` — inputs with focus/error border thickness
- `PasswordStrengthChecklist` — live password rules
- `AuthHeader` — Figma-inspired header block
- `AppDialog` — reusable overlay dialog with internal decorative background
- `PrimaryButton`, `SocialButton` — actions and social sign-ins

### 5. Utilities (`shared/utils/`)

**Validators** - Form validation functions:
- Email format checking
- Password strength validation
- Reusable across all forms

### 6. Form Management (`shared/controllers/`)

`FormControllers` — shared email/password controllers

`ValidationController` — centralized validation state and helpers
- `isTermsAccepted` (RxBool)
- `termsError` (RxString?)
- `isEmailValid(String)` and `clearEmailError()`
- `showPasswordChecklist` kept visible during typing even when valid

## Key Architectural Decisions

1. **GetX Permanent Controller** - AuthController persists across navigation
2. **Modular Structure** - Features organized in separate folders
3. **Shared Constants** - No more hard-coded values
4. **Design System** - Consistent UI across the app
5. **Form Validation** - Centralized validation logic

## Recent Updates

### Forgot Password Feature
- Added `ForgotPasswordScreen` with real-time email validation and bilingual support.
- Integrated `AppDialog` for in-place overlay confirmation.
- Removed obsolete confirmation screen.
- Updated `AuthController` with `forgotPassword` method for handling reset requests.
- Navigation hygiene: Clears email errors and resets password validation state on screen transitions.
- Breaking Change: Removed `SignupBinding` and `SignupFormController`.
 - New behavior: After successful authentication, the app will check the Firestore `users` document. If `isProfileComplete` is false the user will be routed to `AppRoutes.completeProfile` to complete profile information. This adds a required setup step for new users.

## Quick Reference

**Adding New Features:**
```plaintext

lib/modules/feature_name/
├── views/ # Screens
├── widgets/ # Feature-specific widgets
└── controllers/ # Feature controllers

````

**Using Shared Components:**

```dart
// Import shared constants
import 'package:ascoa_app/shared/constants/app_colors.dart';

// Use in widgets
color: AppColors.primary
```

**Best Practices:**

- Use shared constants instead of hard-coding
- Check `shared/` before creating new components
- Keep features self-contained in modules
- Follow responsive design patterns from login screen

This structure makes the app maintainable and allows team members to work independently on different features.
