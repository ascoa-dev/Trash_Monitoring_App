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

## Analytics & Crash Reporting (Firebase)

This project uses **Firebase Analytics** and **Firebase Crashlytics** via a single wrapper:

- Entry point: `lib/shared/analytics/analytics_service.dart` (class `Analytics`)
- Event names: `lib/shared/analytics/analytics_events.dart` (class `AnalyticsEvents`)
- Property keys: `lib/shared/analytics/analytics_props.dart` (class `AnalyticsProps`)
- User identity helpers: `lib/shared/analytics/analytics_user.dart` (class `AnalyticsUser`)

  Dependencies (see `pubspec.yaml`):

  - `firebase_analytics`
  - `firebase_crashlytics`
  - `package_info_plus` (used to enrich events with app version)

  ### How it works

  - `Analytics.init()` is called during app startup (after `Firebase.initializeApp()` in `main.dart`).
  - In **debug** builds (`kDebugMode`):
    - Analytics + Crashlytics collection are disabled.
    - Calls to `Analytics.track(...)`, `Analytics.screenView(...)`, and `Analytics.error(...)` log to console only.
  - In **profile/release** builds:
    - Events are sent to Firebase Analytics.
    - Errors are recorded in Crashlytics (both fatal and non-fatal).

  ### Usage patterns

  - Track a user action/event:
    - `Analytics.track(AnalyticsEvents.loginAttempted, { AnalyticsProps.method: AuthMethods.email })`
  - Track a screen view:
    - `Analytics.screenView('login')`
  - Report a non-fatal error:
    - `Analytics.error(e, stack, reason: 'news_fetch_failed')`

  Important: screens/controllers should call **the wrapper** (`Analytics.*`) and not call Firebase Analytics / Crashlytics directly.

  ### Event naming & properties

  - Event names are **snake_case** and centralized in `AnalyticsEvents`.
  - Reuse property keys from `AnalyticsProps` (e.g., `method`, `reason`, `source`, `environment`).
  - Avoid high-cardinality / noisy properties (e.g., raw exception strings) unless it’s a bounded set.

  ### Privacy rules (non-negotiable)

  Do not send any of the following in analytics events or Crashlytics custom keys/logs:

  - Passwords, tokens, secrets
  - Email, phone number
  - Exact GPS coordinates
  - Full names or other direct identifiers

  Use `Analytics.identify(user.uid)` after successful auth. Only set safe user properties (e.g., bucketed counts or coarse city).

  ### Testing / validation

  - Local verification in debug: watch the console output for `[Analytics] ...` logs.
  - Validate real event ingestion (recommended):
    - `flutter run --profile`
    - Open Firebase Console → Analytics → DebugView / Events

  Crashlytics notes:

  - Crashlytics collection is disabled in debug, so test crash/error ingestion using profile/release builds.

## Constants Usage Guidelines

### Why Use Shared Constants?

All hardcoded values (colors, dimensions, strings, text styles) must be defined in `lib/shared/constants/` to ensure:

1. **Consistency** - Same values used across the entire app
2. **Maintainability** - Update once, change everywhere
3. **i18n Ready** - Centralized strings ready for localization
4. **Refactoring Safety** - Find all usages easily
5. **Design System** - Enforces design token discipline

### Constants Files Structure

```dart
lib/shared/constants/
├── app_colors.dart       // All color values
├── app_dimensions.dart   // All sizing constants
├── app_strings.dart      // All UI strings (i18n ready)
├── app_text_styles.dart  // All text styling
├── app_typography.dart   // Letter spacing, line heights
└── app_images.dart       // All asset paths
```

### When Adding New Features

**ALWAYS follow this order:**

1. **Define constants FIRST** in shared folders:

   ```dart
   // app_dimensions.dart
   static const double myFeatureCardPadding = 16.0;
   static const double myFeatureIconSize = 24.0;

   // app_strings.dart
   static const String myFeatureTitle = 'My Feature';
   static const String myFeatureError = 'Something went wrong';

   // app_colors.dart
   static const Color myFeatureAccent = Color(0xFF419310);
   ```

2. **Use constants in your widgets**:

   ```dart
   Container(
     padding: EdgeInsets.all(AppDimensions.myFeatureCardPadding),
     child: Text(
       AppStrings.myFeatureTitle,
       style: AppTextStyles.heading1(context),
     ),
   )
   ```

3. **NEVER hardcode values** in widgets:

   ```dart
   // ❌ WRONG
   padding: EdgeInsets.all(16.0)
   Text('My Feature')
   fontSize: 24.0

   // ✅ CORRECT
   padding: EdgeInsets.all(AppDimensions.myFeatureCardPadding)
   Text(AppStrings.myFeatureTitle)
   fontSize: AppDimensions.myFeatureTitleFontSize
   ```

### Naming Conventions

**Module-specific constants:**

- Prefix with module name: `stats*`, `profile*`, `home*`, `cleanup*`
- Examples: `statsCardBorderRadius`, `profileAvatarSize`, `homeScreenHeaderHeight`

**Shared/generic constants:**

- Use semantic names: `screenPadding`, `cardBorderRadius`, `buttonHeight`
- These can be reused across modules

**Dimension categories:**

- Layout: `*Padding`, `*Margin`, `*Spacing`, `*Height`, `*Width`
- Visual: `*BorderRadius`, `*BorderWidth`, `*ShadowBlur`, `*ShadowOffset`
- Icons/Images: `*IconSize`, `*ImageHeight`

### Constants vs Configuration Values

**DO use constants for:**

- ✅ UI dimensions (padding, margins, sizes)
- ✅ UI strings (titles, labels, messages)
- ✅ Colors and visual styling
- ✅ Text styles and typography
- ✅ Asset paths

**DO NOT use constants for:**

- ❌ Alpha/opacity values (0.1, 0.5, 0.9) - these are visual effects
- ❌ Map zoom levels (5, 6, 10) - these are configuration
- ❌ Flex ratios (1, 2, 5) - these are layout ratios
- ❌ maxLines counts (2, 3) - these are text constraints
- ❌ Duration milliseconds (2000, 300) - these are timing
- ❌ Data values (0, 1) - these are business logic
- ❌ Conditional padding (keyboard visible: padding vs 0)

### Responsive Sizing with SizeUtils

Always wrap dimension constants with `SizeUtils` for responsive scaling:

```dart
// Horizontal spacing
SizeUtils.w(context, AppDimensions.screenPadding)

// Vertical spacing
SizeUtils.h(context, AppDimensions.cardHeight)

// Radius (uses smaller dimension)
SizeUtils.r(context, AppDimensions.cardBorderRadius)
```

### Module Refactoring Checklist

When refactoring a module to use shared constants:

1. **Search for hardcoded values:**

   - Colors: `Color(0x`, `Colors.red`, etc.
   - Dimensions: `padding: 16`, `size: 24`, etc.
   - Strings: `'Text'`, `"Label"`, etc.

2. **Add missing constants** to shared folders (if they don't exist)

3. **Replace all hardcoded values** with constants

4. **Run `flutter analyze`** to catch errors

5. **Test the module** to ensure visual correctness

6. **Update documentation** (SHARED_COMPONENTS_GUIDE.md)

### Common Pitfalls

**❌ Don't create duplicate constants:**

```dart
// Bad - two constants for same value
static const double statsCardRadius = 12.0;
static const double profileCardRadius = 12.0;

// Good - reuse when semantic meaning is same
static const double cardBorderRadius = 12.0;
```

**❌ Don't mix units or contexts:**

```dart
// Bad - borrowing unrelated tokens
padding: EdgeInsets.all(AppDimensions.avatarCropCircleStrokeWidth)

// Good - use semantic token
padding: EdgeInsets.all(AppDimensions.screenPadding)
```

**❌ Don't skip SizeUtils:**

```dart
// Bad - not responsive
SizedBox(width: AppDimensions.cardWidth)

// Good - scales with screen size
SizedBox(width: SizeUtils.w(context, AppDimensions.cardWidth))
```

### Example: Stats Module Constants

The Stats module is a good example of proper constants usage:

```dart
// All colors defined
AppColors.statsChartFreshwater
AppColors.statsChartSaltwater
AppColors.statsActivityCardBg

// All dimensions defined
AppDimensions.statsHeaderHeight
AppDimensions.statsCardBorderRadius
AppDimensions.statsMarkerSize

// All strings defined
AppStrings.statsPageTitle
AppStrings.statsFilterDate
AppStrings.statsErrorNoData

// All text styles defined
AppTextStyles.statsTitle(context)
AppTextStyles.statsChartLabel(context)
AppTextStyles.statsError(context)
```

Result: **Zero hardcoded values** in the entire Stats module (stats_screen.dart, stats_header_widget.dart, waste_chart_widget.dart, stats_filter_widget.dart, stats_controller.dart).

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

### Stats Module + Offline Caching

- Implemented `lib/modules/stats/` with comprehensive offline support using Hive for local data persistence
- Architecture follows cache-first strategy: instant display of cached data → background sync → full repopulation
- Added `CachedCleanupModel` (Hive TypeId 4) - Hive-compatible version of `CleanupModel` for offline storage with conversion methods
- `StatsController` manages cache lifecycle:
  - `_initializeCache()` - Opens 'cached_cleanups' Hive box and loads cached data first
  - `_loadFromCache()` - Filters cached cleanups by current user, converts to CleanupModel, updates UI
  - `_saveToCache()` - Deletes old cache entries, saves fresh data after successful Firestore fetch
  - `fetchCleanups()` - Checks connectivity before fetching, falls back to cache if offline
  - `refresh()` - Manual refresh trigger with pull-to-refresh support
- Offline behavior:
  - First load: cached data displays instantly (no loading delay), fresh data syncs in background if online
  - Offline mode: all cached data accessible, charts/filters/maps work normally with cached coordinates
  - No cache: shows "No cached data" message; fetches and caches when connectivity returns
- Stats widgets (`stats_header_widget.dart`, `waste_chart_widget.dart`, `stats_filter_widget.dart`):
  - 7-category stacked bar chart using fl_chart with environment-based colors
  - Dual date slider with Figma-exact design (two separate sliders for from/to dates)
  - Google Maps integration with custom circle markers (24px) colored by environment type
  - Activity cards showing total cleanups and trash collected (KGs)
- All stats components use shared constants exclusively (zero hardcoded values)
- Registered `CachedCleanupModelAdapter` in `main.dart` alongside existing Hive adapters

### Cleanup Model Consolidation

- Consolidated to single source of truth: `CleanupModel` (`lib/app/models/cleanup_model.dart`)
- Removed duplicate/incorrect `cleanup.dart` model that had flat structure mismatching Firestore
- Fixed `StatsController` to use proper `CleanupModel` with correct field access:
  - `cleanup.environment` (not `environmentType`)
  - `cleanup.totalWeight` (not `trashCollectedKg`)
  - `cleanup.locationLatitude/locationLongitude` (not `latitude/longitude`)
  - Date parsing for string format (dd/mm/yyyy)
  - Environment mapping ("Inland" → "Land" for chart consistency)
- `CleanupModel` structure matches Firestore exactly with nested `categories` map and `CleanupItem` objects

### Offline Capabilities

- App launches successfully offline after initial setup
- User profile caching implemented via Hive - profiles load from cache
- Cities config, news posts, and user data cached locally
- Limitations: data submission features (cleanups, photo uploads) require connectivity
- No offline queue system yet - submissions fail gracefully with error messages when offline

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

### Photo upload (StartCleanUp)

- Implemented immediate photo uploads for the StartCleanUp flow. Key files added/modified:
  - `lib/modules/start_cleanup/controllers/media_upload_controller.dart` — new controller that handles selection, compression (via `flutter_image_compress`), upload (Firebase Storage), progress tracking, cancellation, and cleanup of unused photos.
  - `lib/modules/start_cleanup/views/photos_section.dart` — UI for selecting images (image-only, enforced max), responsive preview grid, per-photo progress overlay using `CircularUploadProgress`, and per-photo cancel/delete actions.
  - `lib/modules/start_cleanup/controllers/cleanup_form_controller.dart` — pre-generates a cleanup document ID to allow immediate uploads, waits for in-progress uploads during submit, and triggers storage cleanup of removed photos before final save.
  - `lib/shared/widgets/circular_upload_progress.dart` — static circular progress painter used by the photos grid to match the app loader style.

Key behaviors and design notes:

- Immediate upload: selected images start compressing and uploading as soon as they're picked. This reduces wait time on final submit and gives users instant feedback.
- Max photos: enforced by `MediaUploadConfig.maxPhotos` (default 5). The picker uses a limit plus a manual fallback to ensure the cap works across platforms.
- Pre-generated cleanupDocId: a Firestore doc ID is created before uploads so files are stored under `cleanups/{cleanupDocId}/{uuid}.jpg` and associated with the eventual cleanup document.
- Upload waiting: submitting the cleanup waits for in-progress uploads (with a 5-minute timeout) and warns the user if uploads did not finish.
- Storage cleanup: uploaded photos that are later removed from the UI are deleted from Firebase Storage during form submission to avoid orphaned files.

Tokens & strings added:

- `AppDimensions` additions: `photosActionButtonSize`, `photosActionButtonIconSize`, `photosGridChildAspectRatio`, `photosOverlayOpacity`, `photosActionButtonOffset`, `photosActionButtonShadowBlur`, `photosActionButtonShadowYOffset`, `photosBorderRadiusMultiplier`, `photosErrorIconSizeMultiplier`.
- `AppStrings` additions: `uploadImagesButton`, `previewLabel`, `waitingForPhotoUploads`.

Files & assets:

- `pubspec.yaml` updated to include `assets/ASCOA/clean_confirm.png` used by the cleanup confirmation dialog.

See `PHOTO_UPLOAD_IMPLEMENTATION.md` (root) for a detailed implementation guide, flow diagrams and customization notes.

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

## Future Changes Optimistic

- A mechanism for the users to look through their past clean ups and search for specific entries based on date/location/trash type/Team Name.
- Editing past clean ups to correct mistakes or add forgotten information.
- Expand logging, error reporting, and analytics coverage (Firebase Analytics + Crashlytics).
- Hotspot mapping to identify areas with high trash accumulation for targeted clean-up drives.
- CrossPlatform sharing of clean up achievements on social media to raise awareness and encourage participation.
- Maybe an admin panel for managing users, clean up events, and viewing statistics. (But i feel a website would be better for this).
