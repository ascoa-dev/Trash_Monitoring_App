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

Screens:

- `login_screen_v2.dart` — floating label inputs, divider, social buttons
- `signup_screen.dart` — floating label inputs + PasswordStrengthChecklist; Terms checkbox with inline error and error border when not accepted
- `forgot_password_screen.dart` — in-place overlay confirmation via `AppDialog` (confirmation screen removed)

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

- `FloatingLabelInputField` — inputs with focus/error border thickness, optional spacing, keyboard types, and formatter hooks
- `PasswordStrengthChecklist` — live password rules
- `AuthHeader` — Figma-inspired header block
- `AppDialog` — reusable overlay dialog with internal decorative background
- `PrimaryButton`, `SocialButton` — actions and social sign-ins
- `CountryCodeSelectorField` — floating-label dial code selector powered by `country_picker`

### 5. Utilities (`shared/utils/`)

**Validators** - Form validation functions:

- Email format checking
- Password strength validation
- Reusable across all forms

### 6. Form Management (`shared/controllers/`)

`FormControllers` — shared controllers for auth and profile flows (email, password, first/last name, phone, city)

`ValidationController` — centralized validation state and helpers

- `isTermsAccepted` (RxBool)
- `termsError` (RxString?)
- `isEmailValid(String)` and `clearEmailError()`
- `showPasswordChecklist` kept visible during typing even when valid
- `validateFirstName/LastName/City` and `validatePhoneNumber` for the complete profile flow

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

### Tokenization sweep (strings/colors/validators)

- A recent maintenance pass replaced several hard-coded UI strings and some literal color values with shared tokens to improve consistency and enable easier localization. Key highlights:
  - `lib/shared/constants/app_strings.dart`: new keys added for email verification, validation messages, auth header texts, dialog labels, and password-rule texts.
  - `lib/shared/constants/app_colors.dart`: new color tokens added where small isolated hard-coded color literals existed (e.g., dialog background token).
  - `lib/shared/utils/validators.dart`: validator functions now use `AppStrings` keys for all returned messages.
  - UI files updated to consume tokens: `email_verification_screen.dart`, `forgot_password_screen.dart`, `complete_profile_screen.dart`, `signup_screen.dart`, `login_screen.dart`, `home_screen.dart`, `app_dialog.dart`, `auth_header.dart`, and several shared widgets.

Verification performed:

- Ran `flutter analyze` after the edits (one info-level lint unrelated to tokenization was found).
- Ran focused tests: `test/forgot_password/forgot_password_screen_test.dart` — all tests passed.

Notes for reviewers: check `lib/shared/constants/app_strings.dart` and `lib/shared/constants/app_colors.dart` for newly added keys if you need to update translations or use the tokenized strings in other screens.

### Refactor Notes

- Removed hardcoded strings in `forgot_password_screen.dart`.
- Added constants in `app_strings.dart` for bilingual support in the Forgot Password feature.

### Complete Profile Flow

- Implemented `CompleteProfileScreen` mirroring Figma background layers, profile avatar placeholder, and floating-label inputs.
- Added bilingual copy and button states via new `AppStrings` entries.
- Reused `CountryCodeSelectorField` for dial-code selection (defaults to Cameroon) and hooked validation into shared controllers.
- `AuthController.completeProfile` now persists profile data to Firestore, marks `isProfileComplete`, and navigates the user home on success.

## Quick Reference

**Adding New Features:**

```plaintext

lib/modules/feature_name/
├── views/ # Screens
├── widgets/ # Feature-specific widgets
└── controllers/ # Feature controllers

```

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

## Small API & tooling notes

- ProfileActionTile API: The profile action tile now supports a `leading` widget in addition to the legacy `icon` parameter. This allows dropping in image assets (for example `Image.asset('assets/ASCOA/Profile_Page_Icons/policy.png')`) without affecting existing layout sizing. When authoring new tiles, prefer `leading` for custom images and `icon` for Material icons.

- Tooling cleanup: the `tool/country_parser_probe.dart` script was unused and has been removed. If you depended on it for ad-hoc parsing, recreate it under `tool/` or move any reusable parts into `shared/utils/`.
