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

### Change Password Flow (Profile Module)

- Added `ChangePasswordScreen`, `ChangePasswordController`, `ChangePasswordBinding`, and `ChangePasswordStatus` enum under `lib/modules/profile/`.
- Screen mirrors signup validation: strong password checklist powered by `ValidationController`, confirm-password mismatch handling, and a guard that blocks reusing the current password.
- Controller orchestrates bilingual snackbars for success, wrong current password, validation errors, and generic failures. It delegates to `AuthController.changePassword`, which reauthenticates, enforces provider/recency checks, and updates the password.
- Profile screen now links to the new route (`AppRoutes.changePassword`) and includes a branded `ProfileSignOutButton` for consistent logout styling.

### Email Verification + Login Hardening

- `EmailVerificationScreen` polls Firebase every five seconds, lets users resend the verification email, and provides a cancel/try-again path that clears shared form controllers and signs out safely before returning to Login.
- `AuthController.login` surfaces clearer copy for `invalid-credential` responses, and `AuthController.changePassword` now treats both `wrong-password` and `invalid-credential` as “wrong current password” so the UI shows the custom snackbar instead of the generic Firebase error.
- Forgot Password initialization sanitizes carried-over email state (clears invalid addresses, resets validation errors) before showing the screen.

### Shared Tokens & Widgets

- `AppStrings` gained change-password and email-verification copy (English/French). Reference these keys instead of duplicating strings in UI layers.
- `AppDimensions` gained change-password layout tokens (`changePasswordTopSpacing`, `changePasswordIconSize`, `profileSignOutHeight`, etc.) to align new screens with the design system.
- New `ProfileSignOutButton` widget (modules/profile/widgets) encapsulates the logout CTA layout used on the profile screen; reuse it for future profile-related sign-out flows.

### Forgot Password Feature

- Added `ForgotPasswordScreen` with real-time email validation and bilingual support.
- Integrated `AppDialog` for in-place overlay confirmation.
- Removed obsolete confirmation screen.
- Updated `AuthController` with `forgotPassword` method for handling reset requests.
- Navigation hygiene: Clears email errors and resets password validation state on screen transitions.
- Breaking Change: Removed `SignupBinding` and `SignupFormController`.
- New behavior: After successful authentication, the app will check the Firestore `users` document. If `isProfileComplete` is false the user will be routed to `AppRoutes.completeProfile` to complete profile information. This adds a required setup step for new users.

### Recent lib/ changes (notes for reviewers)

- Several shared widgets were converted to use `SizeUtils` wrappers around existing `AppDimensions` tokens so layouts scale across devices. See `SHARED_COMPONENTS_GUIDE.md` for detailed per-widget notes and the conservative mapping of `.h`, `.w`, and `.r`.
- Small token changes in `lib/shared/constants/app_dimensions.dart` (added `forgotTitleTopSpacing`, adjusted `profileSectionSpacing` and `profileCardMinHeight`). Review these when changing profile or forgot-password layouts.
- `login_screen_v2.dart` had a UX fix: the main scrollable now disables scrolling when the keyboard is hidden to prevent accidental scrolling.

### Tokenization sweep (strings/colors/validators)

- A recent maintenance pass replaced several hard-coded UI strings and some literal color values with shared tokens to improve consistency and enable easier localization. Key highlights:

  - `lib/shared/constants/app_strings.dart`: new keys added for email verification, validation messages, auth header texts, dialog labels, and password-rule texts.
  - `lib/shared/constants/app_colors.dart`: new color tokens added where small isolated hard-coded color literals existed (e.g., dialog background token).

  Notes on recent tokenization

  - `lib/shared/constants/app_images.dart` - Central place for image asset paths. When adding new images, add a constant here and reference `AppImages.<name>` from widgets. Avoid inline `'assets/...'` strings in widgets.
  - `lib/shared/constants/app_typography.dart` - Small typography tokens like `letterSpacingSmall` and `lineHeightLong`. Use these for consistent letter-spacing instead of literal values like `0.1`.
  - `lib/shared/constants/app_dimensions.dart` - New auth spacer factors (for auth screens) and other small helpers such as `authSmallSpacerFactor` and `authXSmallSpacerFactor` to replace magic viewport multipliers.
  - `lib/shared/utils/validators.dart`: validator functions now use `AppStrings` keys for all returned messages.
  - UI files updated to consume tokens: `email_verification_screen.dart`, `forgot_password_screen.dart`, `complete_profile_screen.dart`, `signup_screen.dart`, `login_screen.dart`, `home_screen.dart`, `app_dialog.dart`, `auth_header.dart`, and several shared widgets.

Verification performed:

- Ran `flutter analyze` after the edits (one info-level lint unrelated to tokenization was found).
- Ran focused tests: `test/forgot_password/forgot_password_screen_test.dart` — all tests passed.

Notes for reviewers: check `lib/shared/constants/app_strings.dart` and `lib/shared/constants/app_colors.dart` for newly added keys if you need to update translations or use the tokenized strings in other screens.

### Refactor Notes

- Removed hardcoded strings in `forgot_password_screen.dart`.
- Added constants in `app_strings.dart` for bilingual support in the Forgot Password feature.

## Very recent maintenance

- AppImages: A new `lib/shared/constants/app_images.dart` centralizes image asset paths used across auth/profile screens. When adding new assets, declare them here and reference the constant instead of hard-coded asset strings.
- AppTypography: A new `lib/shared/constants/app_typography.dart` centralizes small typography tokens (e.g., `letterSpacingSmall`) to keep spacing consistent across `AppTextStyles` and widgets.
- Edit Profile phone parsing: `EditProfileController` strips stored international dial codes from phone values when loading user profiles. Save now returns to the Profile tab on success; `MainScreen` reads `Get.arguments['initialTab']` to support the fallback navigation.

### Complete Profile Flow

- Implemented `CompleteProfileScreen` mirroring Figma background layers, profile avatar placeholder, and floating-label inputs.
- Added bilingual copy and button states via new `AppStrings` entries.
- Reused `CountryCodeSelectorField` for dial-code selection (defaults to Cameroon) and hooked validation into shared controllers.
- `AuthController.completeProfile` now persists profile data to Firestore, marks `isProfileComplete`, and navigates the user home on success.

Recent updates (quick reviewer notes)

- Email verification screen: reworked to mirror the Forgot Password layout pattern (Stack + Positioned top/bottom artwork anchored to the viewport height). This prevents artwork repositioning when button spacing or content changes. See `lib/modules/auth/views/email_verification_screen.dart`.
- Circular loader: fixed AnimatedBuilder signature and implemented a small transparent gap between the track and active arc for improved contrast. The implementation uses a saveLayer + BlendMode.clear trick inside `lib/shared/widgets/circular_loader.dart` and relies on `AppDimensions.circularLoaderGap` and color tokens in `app_colors.dart`.
- City validation: validation is now driven by `lib/shared/controllers/cities_controller.dart` and enforced from `ValidationController` when `allowCustomCities` is false in the runtime config. This prevents saving custom city inputs when the server expects selections from the provided city list.

Migration notes for reviewers:

- When adding translations, include the new email verification and change-password keys found in `lib/shared/constants/app_strings.dart`.
- If tests read `AppStrings` by exact string, update them to use the new keys to avoid brittle assertions.
- UI reviewers: verify the resend/use-another-email actions use the same `AppDimensions.buttonHeight` as other auth actions; `OutlinedButton`s should be wrapped in a `SizedBox(width: double.infinity, height: SizeUtils.h(context, AppDimensions.buttonHeight))`.

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
