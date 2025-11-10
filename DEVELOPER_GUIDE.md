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

### 2. Home module and news integration (`lib/modules/home/`)

The Home module renders the dashboard and a horizontally scrolling News section backed by WordPress posts from [ascoa-cm.org](https://ascoa-cm.org).

- Binding: `HomeBinding` lazily provides `HomePostsController` with `fenix: true` so it survives tab switches.
- Controller: `HomePostsController` loads posts, deduplicates media requests, and caches results in Hive (`home_posts_cache`) for instant warm-starts and basic offline display.
- Services: `ApiService` wraps HTTP calls to WordPress REST endpoints for posts and media. Minimal fields are requested to reduce payload.
- Models: `Post` (Hive typeId 10) and `MediaModel` live under `lib/app/models/`. `PostAdapter` is registered in `main.dart`.
- Views/Widgets: `HomeScreen` composes the dashboard layout (hero, Start Cleanup card, Highlights carousel, News list, Blog card). News tiles use `HomeNewsCard` with `CachedNetworkImage` and fall back to an asset placeholder. A `NewsSkeletonCard` provides a shimmer-like placeholder while loading.
- Assets: new artwork added under `assets/ASCOA/` and `assets/ASCOA/Dashboard_Icons/` (declared in `pubspec.yaml`). Paths are centralized in `AppImages`.
- Tokens: multiple Home-specific `AppDimensions.homeScreen*` constants were added for precise Figma alignment; sizes are applied at build-time via `SizeUtils`.
- External links: tapping a news card opens `link` in the system browser via `url_launcher`.

Dependencies added in `pubspec.yaml` (already declared): `http`, `cached_network_image`, `url_launcher`, `hive`, `hive_flutter`.

Initialization notes:

- `main.dart` registers `PostAdapter` with Hive and initializes Hive early alongside the existing Cities config adapters.
- The initial route computation still resolves to `AppRoutes.home` for authenticated, verified users with a completed profile. The Home module is rendered inside `MainScreen`.

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

### Home module + WordPress News feed

- Implemented `lib/modules/home/` with GetX binding/controller/services and a responsive UI that mirrors the design. Posts are fetched from WordPress (`/wp-json/wp/v2/posts`) and associated media is fetched in parallel only for unique `featured_media` IDs to minimize calls.
- Added `Post` and `MediaModel` under `lib/app/models/` and registered `PostAdapter` in `main.dart` for Hive caching. The controller reads from cache on init, then updates with fresh network data and re-caches results.
- Introduced `HomeNewsCard` and `NewsSkeletonCard` widgets for the news rail; cards rely on new tokens in `AppDimensions` and colors in `AppColors`. News links open externally via `url_launcher`.
- New assets for the dashboard hero and icons have been added and centralized under `AppImages` along with corresponding `pubspec.yaml` entries.

### Reset Password deep link flow

- Added a reset-password feature set in `lib/modules/auth/`:
  - `views/reset_password_screen.dart` mirrors the change-password layout (minus the current-password field), reuses the shared password checklist, and blocks navigation until the success dialog closes.
  - `controllers/reset_password_controller.dart` wraps validation, handles localized snackbar messaging, and delegates to `AuthController.resetPasswordWithCode` for Firebase updates.
  - `bindings/reset_password_binding.dart` injects the controller and extracts the `oobCode` argument passed via `Get.toNamed` or deep links.
  - `models/reset_password_status.dart` enumerates result states shared between the controller and the auth service.
- `main.dart` now bootstraps the [`app_links`](https://pub.dev/packages/app_links) listener in `_initDeepLinks`; incoming URLs with `mode=resetPassword` and an `oobCode` automatically navigate to `AppRoutes.resetPassword`.
- `AuthController` exposes `resetPasswordWithCode`, translating `FirebaseAuth.confirmPasswordReset` errors into strongly typed results so the UI can react consistently.
- Android manifest adds an auto-verified VIEW intent filter for `https://accounts.ascoa-cm.org/reset`, ensuring Firebase password-reset emails launch the installed app when available. The Gradle namespace/applicationId and Kotlin package were updated to `com.ascoa.app` to match the production bundle ID.
- Shared resources received additions to support the flow:
  - `AppStrings` gained English/French copy for reset-password titles, buttons, and error states.
  - `AppImages.passwordUpdateSuccessful` points to the new dialog artwork declared in `pubspec.yaml`.
  - Plugin registrants for desktop targets were regenerated to include `AppLinks`.
- Firebase configuration files (`firebase_options.dart`, `firebase.json`, `android/app/google-services.json`) were refreshed to point at the `trash-monitoring-app-88131` project used by the new Android application ID.

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

### Date Picker & Location Search (new shared widgets)

- Added `shared/widgets/custom_date_picker.dart` — a Material 3 single-date picker dialog with month/year dropdowns, swipe navigation, and fully tokenized dimensions (`AppDimensions.datePicker*`). Use `CustomDatePicker.show(context, ...)` to retrieve a `DateTime?`.
- Added `shared/widgets/location_search_field.dart` — Google Places–powered autocomplete input with overlay suggestions; debounced search, bounded overlay height, reused shadow & corner tokens from the city selector. Loader and suggestion row sizing use new `locationField*` tokens in `AppDimensions`.
- Added supporting dimension tokens in `app_dimensions.dart` (date picker: menu offsets, header icon container size, text button paddings; location search: loader/suggestion sizes).

### Avatar Flow Enhancements

- `image_picker_dialog.dart` now uses `AppDimensions.profileNameFontSize` and `smallIconSize` tokens for consistent sizing, replacing literals.
- `avatar_crop_screen.dart` updated to use dedicated crop tokens (`avatarCropCornerSize`, `avatarCropCornerThickness`, `avatarCropCircleStrokeWidth`, plus generic `cropper*` tokens for gesture padding and rotate icon size) for clearer maintenance.
- Dialog success flows (change password, edit profile, cleanup saved) now standardized on `AppDialog` with new image size tokens (`dialogImageWidth`, `dialogImageHeight`).

### Dimension & Typography Token Sweep

- Extended `app_dimensions.dart` with: `datePickerVerticalPadding`, `datePickerMenuIconSize`, `datePickerHeaderIconContainerSize`, `datePickerTextButton*` tokens, `inputLineHeight`, `inputContentVerticalPadding`, `floatingLabelLineHeight`, `supportTextLineHeight`, and location-specific `locationField*` tokens.
- Ensured all recently modified shared widgets wrap numeric layout values via `SizeUtils` (`h`, `w`, `r`) for responsive scaling.
- Added/used `mediumFontSize` and `smallFontSize` for suggestion row text in `LocationSearchField`.

### Updated Shared Components Guide

- `SHARED_COMPONENTS_GUIDE.md` expanded to document new widgets (CustomDatePicker, LocationSearchField, ImagePickerDialog) and all newly added dimension tokens so future contributors have an authoritative reference.
- Added explicit sections for Date Picker and Location Search tokens; clarified usage and feature sets.

### Consistency Improvements

- Replaced remaining literal icon/spacing values across shared widgets with semantic tokens (e.g., icon sizes 18/20 → `datePickerMenuIconSize`, `smallIconSize`).
- Centralized loader spacing & stroke widths (`circularLoaderGap`, `circularLoaderStrokeWidth`, `smallLoaderStrokeWidth`) and applied them in the circular loader implementation.
- Removed stray inline numbers from `app_dialog.dart`, `floating_label_input_field.dart`, `city_selector_field.dart`, and `custom_date_picker.dart` in favor of tokens.

### Developer Workflow Notes

- When adding a new shared widget: define semantic tokens in `app_dimensions.dart` first; avoid reusing unrelated tokens (e.g., don’t borrow a cleanup constant for a profile widget). Update both guides (`SHARED_COMPONENTS_GUIDE.md`, this file) in the same commit.
- Prefer adding a short “Key tokens” subsection in the shared guide for any non-trivial widget to speed onboarding.
- Run `flutter analyze` after token additions; mismatched or unused constants often surface as analyzer hints—clean them before merging.

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

### Avatar upload & profile photos

- A unified avatar flow is implemented via `lib/shared/utils/avatar_photo_handler.dart`. It handles pick → crop → compress → upload → persist → refresh. Internally uses `image_picker`, `croppy` (cropper), `flutter_image_compress` (WebP), `firebase_storage` (upload), and `cloud_firestore` (persist URLs).
- Storage layout: `avatars/{uid}/avatar.webp` (600×600) and `avatars/{uid}/thumb.webp` (200×200). Firestore user doc now includes `avatarUrl`, `thumbUrl`, and `avatarUpdatedAt`. We also update `FirebaseAuth.currentUser.photoURL` when supported.
- UI:
  - `complete_profile_screen.dart`: “Edit” triggers the handler and previews the result.
  - `edit_profile_controller.dart`/`edit_profile_screen.dart`: reactive `avatarUrl`/`thumbUrl` fields; button invokes `handleEditPhoto()`.
  - `profile_screen.dart`: shows a `CachedNetworkImage` avatar (thumb preferred), and a tap-to-zoom fullscreen overlay via `modules/profile/widgets/full_image_overlay.dart`.
- Model and controller improvements:
  - `lib/app/models/user.dart` adds `avatarUrl`, `thumbUrl`, `avatarUpdatedAt`, and `photoURL`.
  - `AuthController` now prefers the typed `currentUserModel` over map access in login/returning user flows and in profile getters (name/city).
- Debug note: In `main.dart`, debug builds set `croppy.croppyForceUseCassowaryDartImpl = true` to avoid native FFI for the constraint solver.
- Strings/tokens: `AppStrings` gained bilingual picker/crop/upload strings; `AppDimensions` added avatar crop constants.
- Dependencies added (see `pubspec.yaml`): `image_picker`, `croppy`, `extended_image`, `flutter_image_compress`, `firebase_storage`, `cached_network_image`, `uuid`, `path_provider`, `path`.
- Tooling/SDK: `pubspec.lock` indicates Flutter SDK >= 3.35.0; update local SDK if analyze/build fails due to version checks.

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
