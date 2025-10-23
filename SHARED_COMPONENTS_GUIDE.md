# Shared Components Guide

Quick reference for reusable components, constants, and utilities in the ASCOA app.

Shared folder index

This guide documents the contents of `lib/shared/`. At a glance the folder contains:

- `constants/` — shared design tokens and strings. Key files: `app_colors.dart`, `app_dimensions.dart`, `app_images.dart`, `app_strings.dart`, `app_text_styles.dart`, `app_typography.dart`.
- `controllers/` — small shared controllers used across screens (form controllers, validation, etc.).
- `widgets/` — small reusable widgets used across features (see the Widgets section below for specifics).
- `utils/` — helper utilities (parsers, formatters) used by shared widgets and controllers.
- `services/` — app-wide services (Firebase, caching, or config). Key files: `avatar_uploader.dart`, `cities_service.dart`.

What changed recently / guidance

- AppImages: image asset paths were centralized into `lib/shared/constants/app_images.dart`. When adding or using an image, add a constant to `AppImages` and reference `AppImages.<name>` from widgets instead of writing raw `'assets/...'` strings.
- AppTypography: small, reusable typography tokens (letter spacing & line-height) were added in `app_typography.dart`. Prefer `AppTypography.letterSpacingSmall` instead of literal `0.1` values.
- AppDimensions: several auth spacing multipliers and small helpers were added (for example `authSmallSpacerFactor`, `authXSmallSpacerFactor`, `bottomSheetHeightFactor`, and `profileCardTextWidthOffset`) to replace magic viewport multipliers and numeric offsets.
- AppTextStyles now references `AppTypography` tokens and many widgets were updated to use these shared tokens.
- Avatar photos: a shared `AvatarPhotoHandler` was added in `lib/shared/utils/avatar_photo_handler.dart` to standardize pick → crop → compress → upload across screens. Profile images are rendered via `CachedNetworkImage`; tap-to-zoom uses `modules/profile/widgets/full_image_overlay.dart`.

Constants responsibilities (quick map)

- `app_colors.dart` — canonical color palette and legacy aliases. Use `AppColors` for any color used in UI.
- `app_dimensions.dart` — spacing, sizes, responsive multipliers, and component-specific constants (avatar sizes, nav bar, dialog sizes).
- `app_images.dart` — centralized image asset paths (add new constants here when adding assets to `pubspec.yaml`).
- `app_strings.dart` — app strings and localized labels used across screens.
- `app_text_styles.dart` — cohesive TextStyle definitions used across screens; prefer using and copying these rather than inlining TextStyle literal objects.
- `app_typography.dart` — small letter-spacing / line-height tokens used by `AppTextStyles` and widgets.

## Constants (shared/constants/)

### Colors (`app_colors.dart`)

```dart
import 'package:ascoa_app/shared/constants/app_colors.dart';

// Usage
Container(color: AppColors.primary)  // Background color (off-white)
```

- `AppColors.primary` - Off-white page background (0xFFFBFFF4)
- `AppColors.accent` - Accent green (0xFF658638)
- `AppColors.buttonPrimary` - Button green (0xFF419310)
- `AppColors.white` - Historical alias to background (kept for compatibility)
- `AppColors.google` - Google blue (0xFF4285F4)
- `AppColors.facebook` - Facebook blue (0xFF4267B2)
- `AppColors.profileAvatarBackground` - Soft yellow circle behind avatar placeholder (0xFFFCF1AA)
- `AppColors.profileAvatarAccent` - Accent golden highlight used for avatar glyph (0xFFFBB825)
- `AppColors.black87` - Legacy alias used in a few places for text (0xDD000000)
- `AppColors.error` - Error/validation color (0xFFFBB825)

### Text Styles (`app_text_styles.dart`)

```dart
import 'package:ascoa_app/shared/constants/app_text_styles.dart';

// Usage
Text('Welcome', style: AppTextStyles.heading1)
```

- `AppTextStyles.heading1` - Large page titles (uses `AppColors.textPrimary` / black)
- `AppTextStyles.label` - Form labels
- `AppTextStyles.body` - Regular body text (uses `AppColors.textBlack`)
- `AppTextStyles.bodySecondary` - Secondary body text (uses `AppColors.textBlack70`)
- `AppTextStyles.buttonLink` - Clickable link-style text
- `AppTextStyles.dividerText` - Small text used in dividers ("OR")
- `AppTextStyles.termsBase` / `termsLink` - Styles for terms text and links
- `AppTextStyles.errorText` - Small red error text used for inline validation messages

#### Typography tokens (`app_typography.dart`)

Small, reusable typography tokens keep letter-spacing and line-height consistent across components. Examples:

```dart
import 'package:ascoa_app/shared/constants/app_typography.dart';

Text('Label', style: AppTextStyles.body.copyWith(letterSpacing: AppTypography.letterSpacingSmall))
```

Prefer `AppTypography.letterSpacingSmall` over literal `0.1` values.

### Images (`app_images.dart`)

```dart
import 'package:ascoa_app/shared/constants/app_images.dart';

Image.asset(AppImages.profilePlaceholder)
```

- `AppImages` centralizes every image declared in `pubspec.yaml` so widgets never hard-code `'assets/...'` strings. This catches typos at compile time and makes asset discovery easier during refactors.
- Constants are grouped by comment blocks to mirror the folder structure (`ASCOA/`, `ASCOA/Profile_Page_Icons/`, `ASCOA/Nav_bar_icons/`, `Google/`, etc.). Keep related assets together when adding new constants.

Common categories currently exposed:

- **Brand & hero artwork:** `logo`, `loginTop`, `signupTop`, `forgotPasswordTop`, `loginBottom`, `completeProfileTop`, `profileScreenBottom`, etc. These map to large PNG hero illustrations reused in auth/profile flows.
- **Profile & settings icons:** `policy`, `faq`, `contact`, `signout` under `Profile_Page_Icons/`. Used by `ProfileActionTile` and `ProfileSignOutButton`.
- **Navigation icons:** `navHome`, `navStats`, `navAdd`, `navNews`, `navProfile` consumed by the shared bottom navigation bar.
- **3rd-party logos:** `googleNeutral2x`, `facebookPrimary` for social buttons.
- **Forgot password assets:** `forgotConfirmIcon`, `forgotPasswordBottom`, `forgotPasswordIcon` powering the forgot-password screen and confirmation dialog.

Adding a new asset checklist:

1. Drop the optimized PNG/SVG into the appropriate folder under `assets/` (create a subfolder if grouping is needed).
2. Declare the asset path in `pubspec.yaml` alongside the existing entries so Flutter bundles it.
3. Add a new `static const` to `AppImages` that points at the exact asset path. Follow the lowerCamelCase naming already in the file and add a short comment grouping if needed.
4. Reference the new constant from widgets (`Image.asset(AppImages.myNewIcon)`, `const AssetImage(AppImages.myNewBackground)`) instead of hard-coded strings.

Usage notes:

- Prefer `const AssetImage(AppImages.logo)` when assigning to `DecorationImage`, `CircleAvatar`, or other widgets that accept an `ImageProvider`.
- If you need responsive sizing, combine `AppImages` with `AppDimensions` tokens so layout adjustments stay centralized.
- When removing an asset, delete it from `pubspec.yaml`, remove the constant from `AppImages`, and run `flutter pub get` to ensure the cache is updated before running tests.

### Spacing (`app_dimensions.dart`)

```dart
import 'package:ascoa_app/shared/constants/app_dimensions.dart';

// Usage
Padding(padding: EdgeInsets.all(AppDimensions.screenPadding))
```

- `AppDimensions.screenPadding` - 24.0 - Main screen horizontal padding
- `AppDimensions.verticalPadding` - 16.0 - Vertical padding used in page layouts
- `AppDimensions.smallSpacing` - 8.0 - Small gaps between inline elements
- `AppDimensions.tinySpacing` - 10.0 - Very small horizontal gaps
- `AppDimensions.dividerPadding` - 12.0 - Padding used around divider text
- `AppDimensions.socialButtonSpacing` - 16.0 - Gap between social buttons
- `AppDimensions.bottomSpacing` - 56.0 - Bottom safe-area spacing for footers

#### Button & Control Dimensions

- `AppDimensions.buttonHeight` - 48.0 - Standard full-width button height
- `AppDimensions.buttonHorizontalPadding` - 24.0 - Button internal horizontal padding
- `AppDimensions.buttonVerticalPadding` - 12.0 - Button internal vertical padding
- `AppDimensions.checkboxSize` - 24.0 - Square checkbox control size
- `AppDimensions.checkboxCornerRadius` - 5.0 - Small checkbox corner radius

#### Input & Field Dimensions

- `AppDimensions.inputFieldHeight` - 56.0 - Standard input field height
- `AppDimensions.inputHorizontalPadding` - 16.0 - Input left/right padding
- `AppDimensions.inputErrorSpacing` - 4.0 - Vertical gap above error messages
- `AppDimensions.fieldVerticalSpacing` - 12.0 - Vertical gap between stacked input fields

#### Tiny utilities

- `AppDimensions.smallRadius` - 4.0 - Small corner radius used for chips/inputs
- `AppDimensions.chipHorizontalPadding` - 4.0 - Horizontal padding for small label chips
- `AppDimensions.statusDotSize` - 14.0 - Checklist dot size
- `AppDimensions.statusDotBorderWidth` - 2.0 - Checklist dot border width
- `AppDimensions.statusIconSize` - 10.0 - Icon size inside checklist dot

#### Auth header reference sizes

- `AppDimensions.authHeaderBaseWidth` - 295.0 - Base width used by `AuthHeader`
- `AppDimensions.authHeaderBaseHeight` - 127.0 - Base height used by `AuthHeader`
- `AppDimensions.authHeaderLogoWidth` - 187.0 - Base logo width used by `AuthHeader`
- `AppDimensions.authHeaderLogoHeight` - 80.0 - Base logo height used by `AuthHeader`
- `AppDimensions.authHeaderTitleWidthOffset` - 18.0 - Title width offset used by `AuthHeader`
- `AppDimensions.authHeaderLogoLeft` / `authHeaderLogoTop` - Logo positioning offsets (base px, scaled)
- `AppDimensions.authHeaderByLeft` / `authHeaderByTop` - "by" overlay positioning offsets (base px, scaled)
- `AppDimensions.authHeaderTitleFontSizeBase` / `authHeaderTitleLineHeightBase` - Base typography sizes for header title
- `AppDimensions.authHeaderByFontSizeBase` / `authHeaderByLineHeightBase` - Base typography sizes for the small "by" text

#### Auth screen spacers & helpers

- `AppDimensions.authHeaderTopSpacing` - 0.24 - Large top gap used before auth header (relative to screen height)
- `AppDimensions.authScreenSpacerSmall` - 0.025 - Small vertical gap used between auth elements
- `AppDimensions.authScreenSpacerMedium` - 0.03 - Medium vertical gap used between auth elements
- `AppDimensions.authScreenLargeSpacer` - 0.08 - Larger vertical gap (e.g., icon groups)
- `AppDimensions.authScreenXLargeSpacer` - 0.10 - Extra-large spacer (used sparingly)
- `AppDimensions.iconBackSize` - 28.0 - Standard back/icon button size used across auth screens

#### Dialog / Overlay

- `AppDimensions.dialogWidth` - 320.0
- `AppDimensions.dialogHeight` - 300.0
- `AppDimensions.dialogRadius` - 28.0
- `AppDimensions.dialogHorizontalPadding` - 24.0
- `AppDimensions.dialogTopPadding` - 24.0
- `AppDimensions.dialogBottomPadding` - 20.0
- `AppDimensions.dialogTitleFontSize`/`dialogTitleLineHeight` - 28 / 40
- `AppDimensions.dialogBodyFontSize`/`dialogBodyLineHeight` - 16 / 22
- `AppDimensions.dialogHeroSize` - 80.0

Recent additions for profile/change-password flows:

- `AppDimensions.changePasswordTopSpacing`, `changePasswordIconSize`, and `changePasswordHalfInputSpacing` — control hero spacing, illustration height, and field rhythm on the change password screen.
- `AppDimensions.profileSignOutHeight`, `profileSignOutHorizontalPadding`, and `profileSignOutIconGap` — size the dedicated sign-out CTA so it lines up with `ProfileActionTile` cards.
- `AppDimensions.editProfileHeightFactor` and `changePasswordInputSpacing` — shared background/field spacing reused between edit profile and change password layouts.
- Avatar crop constants used by the cropping UI (see `AppDimensions`): `avatarCropPreviewSize`, `avatarCropOutputSize`, `avatarCropThumbSize`, `avatarCropMaxScale`, `avatarCropPadding`, `avatarCropHitTestSize`, `avatarCropLineWidth`, `avatarCropOverlayOpacity`, `avatarCropToolbarHeight`, `avatarCropHelpTextSize`, `avatarCropHelpTextPadding`.

#### Dividers

- `AppDimensions.dividerThickness` - 1.0
- `AppDimensions.authDividerSideWidthFactor` - 0.173 - Short side lines factor used around auth dividers label

### Text Content (`app_strings.dart`)

```dart
import 'package:ascoa_app/shared/constants/app_strings.dart';

// Usage
Text(AppStrings.loginTitle)  // "Login into Account"
```

- `AppStrings.loginTitle` - "Login into Account"
- `AppStrings.emailLabel` - "Email"
- `AppStrings.continueWithGoogle` - "Continue with Google"

Recent additions:

- Change password copy: titles, subtitles, snackbar strings (success, wrong current password, provider mismatch) and the "new password must differ" validation message—available in English and French.
- Email verification copy: resend, cancel, spam-note, and success messages backing the refreshed verification screen.
- Profile utilities: `profileSignOut`, `profileChangePasswordTitle`, and related subtitles for the new profile actions.
- Avatar flow: picker/crop/upload strings (English/French) used by `AvatarPhotoHandler` and cropping UI.

## Widgets (shared/widgets/)

### CustomInputField

```dart
import 'package:ascoa_app/shared/widgets/custom_input_field.dart';

CustomInputField(
  controller: emailController,
  hint: "Enter email",
  obscure: false,  // true for passwords
)
```

**Use for:** Email, password, and text inputs

Widgets index (lib/shared/widgets)

- `app_dialog.dart` — Reusable dialog used across auth flows and confirmations. Uses `AppDimensions.dialog*` sizes and `AppColors.dialogBackground`.
- `auth_header.dart` — Top-of-screen auth header with logo, title and subtitle; scales based on `AppDimensions` base values.
- `country_code_selector_field.dart` — Country picker input used alongside phone inputs; uses `AppDimensions.bottomSheetHeightFactor` for the picker.
- `custom_input_field.dart` — Lower-level input widget used by `FloatingLabelInputField` and other places.
- `floating_label_input_field.dart` — Main input used in forms with floating label, hint and support text.
- `nav_bar.dart` — Bottom navigation bar; uses `AppImages` for icons and `AppDimensions` for sizing.
- `password_strength_checklist.dart` — Small helper widget that renders password requirement checklist and colors using `AppColors`.

Latest changes (component review)

- Circular loader (`lib/shared/widgets/circular_loader.dart`): updated to fix an AnimatedBuilder signature bug and to add a small transparent gap between the loader track and active arc. The widget now consumes `AppDimensions.circularLoaderSize`, `circularLoaderStrokeWidth` and `circularLoaderGap` plus `AppColors.loaderTrack` / `AppColors.loaderActive` tokens. The gap is implemented with a saveLayer + BlendMode.clear technique to ensure it renders crisply on different backgrounds.
- Button sizing: To keep consistent sizing across auth flows, full-width `OutlinedButton` actions (for example "Use another email" / "Resend") should be wrapped in `SizedBox(width: double.infinity, height: SizeUtils.h(context, AppDimensions.buttonHeight))`. Primary buttons remain full-width by default via `PrimaryButton`.
- Tokens: Several new constants were added to `app_dimensions.dart` and `app_colors.dart` to support the verification screen and loader visuals. Prefer using these instead of inlining numeric values or color hex literals.
- Full image overlay: `modules/profile/widgets/full_image_overlay.dart` displays a fullscreen image viewer for the profile avatar. Provide a public URL and an asset placeholder.

Small guidance for maintainers:

- When authoring new small widgets that emulate auth-screen action rows, reuse `AppDimensions.buttonHeight` for vertical rhythm.
- For artwork-heavy screens (auth/profile), follow the `LayoutBuilder` + `Stack` + `Positioned` pattern used in `forgot_password_screen.dart` and `email_verification_screen.dart` so hero artwork remains anchored independent of content spacing changes.
- `primary_button.dart` — Standard full-width button used across screens; uses `AppDimensions.buttonHeight` and `AppColors.buttonGreen`.
- `social_button.dart` — Social login button with icon slot (now using `AppImages` for logos where applicable).
- `profile_signout_button.dart` (modules/profile/widgets) — Branded logout CTA sized with profile tokens; supply an `onPressed` that triggers `AuthController.logout()` or similar.

## Controllers (lib/shared/controllers)

These controllers are small, reusable Getx controllers registered via bindings and used across screens. Key controllers:

- `FormControllers` (`form_controllers.dart`)

  - Holds `TextEditingController` instances used across auth/profile forms:
    - `emailController`, `passwordController`, `firstNameController`, `lastNameController`, `phoneNumberController`, `cityController`.
  - Helpful methods:
    - `resetAuthFields()` — clears email/password controllers.
    - `resetProfileFields()` — clears first/last/phone/city controllers (used after profile save).

- `ValidationController` (`validation_controller.dart`)
  - Reactive validation state (Rx<String?>) for `emailError`, `passwordError`, `firstNameError`, `lastNameError`, `phoneNumberError`, `cityError` and `termsError`.
  - Password rule observables: `hasMinLength`, `hasUppercase`, `hasLowercase`, `hasNumber`, `hasSpecial`, `showPasswordChecklist`.
  - Key methods:
    - `validateEmail(String)` — sets `emailError` using shared `Validators`.
    - `validateFirstName(String)`, `validateLastName(String)`, `validateCity(String)` — basic required + regex checks.
    - `validatePhoneNumber(String dialCode, String number)` — validates combined dial code + number; used by phone inputs.
    - `validatePhoneNumberFull(String)` — validates a full E.164-style value.
    - `updatePasswordRules(String)` and `handlePasswordFocus(bool)` — control password checklist state.
    - `clearValidation()`, `clearPasswordValidation()`, `clearProfileValidation()` — convenience clearers for UI flows.

These controllers are commonly obtained via `Get.find<FormControllers>()` or `Get.find<ValidationController>()` inside widgets.

Other controllers in this folder:

- `cities_controller.dart` — orchestrates city selection state and validation wiring for `CitySelectorField`; consumes `CitiesService` and exposes reactive lists/selection.
- `form_binding.dart` — GetX binding that injects `FormControllers` and `ValidationController` for auth/profile routes so widgets can `Get.find()` them safely.

#### CitiesController (`shared/controllers/cities_controller.dart`)

Provides fuzzy-search-backed suggestions and validation helpers for city inputs.

Usage with an input field:

```dart
final cities = Get.find<CitiesController>();

// onChanged handler
void handleCityChanged(String value) {
  cities.searchCities(value);
  // cities.suggestions is an RxList<City>; bind it to your dropdown
}

final isValid = cities.isCityValid('Douala');
final allowCustom = cities.allowCustomCities;
```

#### FormBinding (`shared/controllers/form_binding.dart`)

Ensures `FormControllers` and `ValidationController` are available app-wide.

Register once:

```dart
GetMaterialApp(
  initialBinding: FormBinding(),
  // ... routes, theme, etc.
)
```

## Utils (lib/shared/utils)

Small helper utilities used by controllers and widgets.

- `validators.dart` — central validators for email, required fields, and strong password rules. `ValidationController` delegates to these functions.
- `auth_form_utils.dart` — small helpers used by auth forms (formatting and parsing helper functions). Check these before duplicating parsing logic in screens.
- `avatar_photo_handler.dart` — unified avatar photo pipeline (pick → crop → compress → upload → persist). Exposes a `handleEditPhoto` entrypoint from screens/controllers.
- `avatar_utils.dart` — small helpers like URL normalization for cache-busted Firebase Storage URLs.
- `size_utils.dart` — device-aware scaling helpers (`h`, `w`, `r`) used in build-time to apply `AppDimensions` responsively.
- `image_utils.dart` — compression/resizing helpers (WebP) used by the avatar flow.
- `city_search.dart` — fuzzy search utilities backing `CitySelectorField` and the Cities config feature.

### SizeUtils (`shared/utils/size_utils.dart`)

Responsive scaling helpers that preserve the emulator/Figma proportions across devices.

API:

- `SizeUtils.h(context, px)` — vertical sizes and font sizes (defaults to content-height scaling)
- `SizeUtils.w(context, px)` — horizontal sizes, paddings, and offsets
- `SizeUtils.r(context, px)` — general sizes/radii using an average scale

Example mapping in widgets:

```dart
// From tokens to runtime sizes
final buttonH = SizeUtils.h(context, AppDimensions.buttonHeight);
final cardRadius = SizeUtils.r(context, AppDimensions.borderRadius);
final sidePad = SizeUtils.w(context, AppDimensions.screenPadding);

SizedBox(height: buttonH);
Container(
  padding: EdgeInsets.symmetric(horizontal: sidePad),
  decoration: BoxDecoration(borderRadius: BorderRadius.circular(cardRadius)),
)
```

Guidance:

- Keep `AppDimensions` as the design source of truth; apply `SizeUtils` only at build-time in widgets.
- Use `h` for vertical rhythm and typography, `w` for horizontal spacing, `r` for radii and icon/container sizes.

### ImageUtils (`shared/utils/image_utils.dart`)

Compression and thumbnail helpers for avatar flow (WebP output, EXIF stripped).

API:

- `compressToWebP(File file, {required int targetSizePx, int quality = 75})` → `Future<File?>`
- `createThumbnail(File file, {int sizePx = 200, int quality = 70})` → `Future<File?>`
- `cleanupTempFiles(List<File> files)` → `Future<void>`

Usage (standalone):

```dart
final full = await ImageUtils.compressToWebP(srcFile, targetSizePx: 600, quality: 75);
final thumb = await ImageUtils.createThumbnail(srcFile, sizePx: 200, quality: 70);
if (full != null && thumb != null) {
  // upload then cleanup
  await ImageUtils.cleanupTempFiles([full, thumb]);
}
```

Notes:

- Returns `null` on failure; always handle `null` before proceeding to upload.
- Temp files are created under the app cache directory; call `cleanupTempFiles` after successful upload.

### CitySearch (`shared/utils/city_search.dart`)

Fuzzy search over the Firestore-driven cities list with configurable thresholds.

Key methods and getters:

- `search(String query)` → `List<City>` (returns all when empty)
- `getAllCities()` → `List<City>`
- `allowCustomCities` → `bool`
- `maxSuggestions` / `fuzzyThreshold`

Usage:

```dart
final service = Get.find<CitiesService>();
final cfg = service.config; // ensure CitiesService.init() ran
if (cfg != null) {
  final search = CitySearch(cfg);
  final results = search.search('dou');
  // feed results to your suggestions list
}
```

## Services (lib/shared/services)

- `avatar_uploader.dart` — encapsulates Firebase Storage uploads for avatars (main + thumbnail) and Firestore updates for `avatarUrl`, `thumbUrl`, and `avatarUpdatedAt`. Also updates `FirebaseAuth.currentUser.photoURL` when available.
- `cities_service.dart` — GetX service that loads `config/cities` from Firestore, caches it locally (Hive), and exposes reactive config used by `cities_controller.dart` and `CitySelectorField`.

### AvatarUploader (`shared/services/avatar_uploader.dart`)

Uploads avatar and thumbnail to Firebase Storage and updates the user doc in Firestore, then syncs FirebaseAuth `photoURL` and refreshes `AuthController`.

API:

- `uploadAvatar({required File avatarFile, required File thumbnailFile, required void Function(double) onProgress})` → `Future<String>`
- `deleteAvatar()` → `Future<void>`

Usage (advanced; prefer using `AvatarPhotoHandler` which wraps this end-to-end):

```dart
final uploader = AvatarUploader();
final progress = 0.0.obs;

final url = await uploader.uploadAvatar(
  avatarFile: full,
  thumbnailFile: thumb,
  onProgress: (p) => progress.value = p, // 0.0 - 1.0
);

// Later, to remove avatar
await uploader.deleteAvatar();
```

Notes:

- Storage paths: `avatars/{uid}/avatar.webp` and `avatars/{uid}/thumb.webp`.
- Firestore fields: `avatarUrl` (cache-busted), `thumbUrl`, `avatarUpdatedAt`, `photoURL` (clean), `updatedAt`.
- Throws if user is not authenticated; wrap in try/catch in custom flows.

### CitiesService (`shared/services/cities_service.dart`)

Loads and caches the `config/cities` document. Exposes the parsed `CitiesConfig` reactively via `config` getter.

API:

- `init()` → `Future<CitiesService>` — loads from Hive, then fetches latest from Firestore
- `fetchAndCache()` / `loadFromLocal()` — manual refresh or local load
- `initializeOnAppStart()` — ensures fresh data at app boot

App initialization example:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cities = Get.put(CitiesService());
  await cities.init();
  runApp(const App());
}
```

Consumption:

```dart
final cities = Get.find<CitiesService>();
final cfg = cities.config; // may be null briefly until init completes
```

Usage tips

- Use `FormControllers` instead of creating local `TextEditingController` instances when working with flows that cross widgets or persist across routes.
- Prefer `ValidationController` for form validation to keep UI reactive and DRY; it centralizes messages and regex patterns.

### PrimaryButton

```dart
import 'package:ascoa_app/shared/widgets/primary_button.dart';

PrimaryButton(
  label: 'Login',
  onPressed: () => handleLogin(),
)
```

**Use for:** Main action buttons (Login, Submit, etc.)

**Sizing note:** `PrimaryButton` is full-width by default to match input fields. You can override sizing with the optional `fixedWidth` and `fixedHeight` parameters when a fixed size is needed:

```dart
// Full-width (default)
PrimaryButton(
  label: 'Login',
  onPressed: handleLogin,
)

// Fixed size
PrimaryButton(
  label: 'Continue',
  fixedWidth: 200,
  fixedHeight: 48,
  onPressed: handleContinue,
)
```

### SocialButton

```dart
import 'package:ascoa_app/shared/widgets/social_button.dart';

SocialButton(
  icon: Image.asset('assets/google_icon.png'),
  label: "Continue with Google",
  color: AppColors.google,
  onPressed: () => handleGoogleLogin(),
)
```

**Use for:** Social login buttons (Google, Facebook)

### New Shared Components

These components were added to support recent UI/validation improvements. Use them to keep auth screens consistent.

### ProfileActionTile (`modules/profile/widgets/profile_action_tile.dart`)

The `ProfileActionTile` was updated to accept an optional `leading` widget alongside the existing `icon` parameter. This enables using asset images (PNGs) for leading visuals without changing the tile's sizing or spacing. Use `leading` when you need to render `Image.asset(...)`, otherwise continue to use `icon` for Material icons.

Example:

```dart
ProfileActionTile(
  leading: Image.asset(AppImages.contact,
    width: AppDimensions.profileCardIconSize,
    height: AppDimensions.profileCardIconSize,
    fit: BoxFit.contain,
  ),
  title: AppStrings.profileContactTitle,
  subtitle: AppStrings.profileContactSubtitle,
)
```

Assets available under `assets/ASCOA/Profile_Page_Icons/` (declared in `pubspec.yaml`):

- `contact.png`
- `faq.png`
- `policy.png`
- `signout.png`

Image assets guidance

Image asset paths are centralized in `lib/shared/constants/app_images.dart` as `AppImages` constants. When adding or using images in widgets prefer referencing `AppImages.<name>` so paths remain discoverable and consistent across the app. Example:

```dart
import 'package:ascoa_app/shared/constants/app_images.dart';

Image.asset(AppImages.policy)
```

#### AuthHeader (`shared/widgets/auth_header.dart`)

```dart
import 'package:ascoa_app/shared/widgets/auth_header.dart';

// AuthHeader is responsive and scales from a Figma base. Provide the
// `scale` value computed from screen width relative to the design reference.
AuthHeader(scale: computedScale),
```

Use for: Top-of-screen header on login/signup screens. It renders the logo,
page title, and optional subtitle with responsive spacing. Prefer passing the
same `scale` value used by the surrounding screen to keep type and image
proportions in sync.

Related module docs:

- `lib/modules/auth/forgot_password.md` — implementation notes, assets, and examples for the Forgot Password screen and dialog.

Migration notes: Replace local `_LogoGroup` or duplicated header widgets with
`AuthHeader`. Use `AppDimensions` auth header base constants to compute `scale`.

### Recent sizing tokens and widget updates

We recently added several `AppDimensions` tokens to centralize sizes used across the auth flows. Prefer these tokens instead of raw numbers when creating or updating UI:

- Avatar & profile sizes: `AppDimensions.avatarDiameter`, `avatarIconSize`, `avatarEditButtonSize`, `avatarEditIconSize`
- Input and typography sizes: `AppDimensions.inputFontSize`, `floatingLabelFontSize`, `supportTextFontSize`, `heading2FontSize`, `subtitleFontSize`, `linkFontSize`
- Small control sizes: `AppDimensions.flagEmojiSize`, `selectorIconSize`, `selectorSmallGap`
- Dialog/actions/checklist: `AppDimensions.dialogActionFontSize`, `checklistFontSize`
- Change-password layout: `AppDimensions.changePasswordTopSpacing`, `changePasswordIconSize`, `changePasswordHalfInputSpacing`, and `changePasswordInputSpacing`
- Profile logout CTA: `AppDimensions.profileSignOutHeight`, `profileSignOutHorizontalPadding`, `profileSignOutIconGap`

Widget changes to be aware of:

## Recent code changes (detailed)

The following is an exhaustive summary of code-level changes made under `lib/` since the last commit. These notes are written for teammates who will rely on the repo docs when reviewing or integrating features.

### General pattern applied

Many shared widgets were updated to use the `SizeUtils` helpers (from `lib/shared/utils/size_utils.dart`) instead of using raw `AppDimensions` literals directly in widget build code. This keeps sizing responsive while preserving the original `AppDimensions` tokens as the design source of truth. The mapping used is conservative:

- `SizeUtils.h(context, px)` — vertical sizes and font sizes
- `SizeUtils.w(context, px)` — horizontal sizes, paddings, and offsets
- `SizeUtils.r(context, px)` — radii and icon/container sizes

### Files updated to use `SizeUtils` wrappers (high-level summary)

- `lib/shared/widgets/app_dialog.dart` — typography sizes, spacing, button heights, box shadows and offsets wrapped with `SizeUtils`.
- `lib/shared/widgets/auth_header.dart` — auth header base width/height, logo offsets, and typography base sizes scaled via `SizeUtils`.
- `lib/shared/widgets/country_code_selector_field.dart` — many paddings, heights, font sizes and icon sizes converted to `SizeUtils`.
- `lib/shared/widgets/custom_input_field.dart` — input field height, borders, radii, shadow radii and offsets, paddings converted.
- `lib/shared/widgets/floating_label_input_field.dart` — padding, field heights, font sizes, paddings, chip offsets, and error spacing converted.
- `lib/shared/widgets/nav_bar.dart` — nav sizing, paddings, shadow offsets and blur radii converted.
- `lib/shared/widgets/password_strength_checklist.dart` — checklist dot size, spacing and font sizes converted.
- `lib/shared/widgets/primary_button.dart` — button height now scaled and border radius scaled with `SizeUtils`.
- `lib/shared/widgets/social_button.dart` — social button height, border width, shadow radii/offsets, icon container sizes and spacings converted.

### Why this matters

These changes keep the existing `AppDimensions` tokens untouched as the single source of truth, but make runtime layouts responsive by applying `SizeUtils` at render-time. If you're adding a new widget that uses `AppDimensions` directly, follow the conservative mapping above and use `SizeUtils` wrappers in build-time code.

### Other functional changes (profile / auth flows)

- `lib/modules/auth/views/login_screen_v2.dart`

  - Fixed the unintended always-scroll behavior: `SingleChildScrollView` now uses `AlwaysScrollableScrollPhysics()` when keyboard is visible and `NeverScrollableScrollPhysics()` otherwise. This prevents the page from scrolling when the keyboard is not shown.
  - Screen continues to compute a `scale` factor for the `AuthHeader` from reference width and passes it to the header.

- `lib/modules/profile/views/change_password_screen.dart` and `lib/modules/profile/views/edit_profile_screen.dart`
  - Small layout token adjustments and use of `SizeUtils` in a number of places. These screens were updated to use the new `AppDimensions` tokens added for change-password and edit-profile flows.

### Token updates

- `lib/shared/constants/app_dimensions.dart`
  - Added `forgotTitleTopSpacing` (0.12) to support a more compact layout for some forgot-password variants.
  - Adjusted profile spacing tokens (e.g. `profileSectionSpacing` changed to 14.0 and `profileCardMinHeight` changed to 68.0) to better match Figma refinements.

### Files you should review when changing layout or copy

- `lib/shared/constants/app_dimensions.dart` — authoritative sizing tokens. If you change values here, verify in multiple screens and run `flutter analyze`.
- `lib/shared/utils/size_utils.dart` — scaling helpers used across updated widgets. Do not change the function semantics without reviewing all callers.
- Any widget that previously used raw `AppDimensions` values in `build()` — consider whether it should be wrapped with `SizeUtils` like the files listed above.

If you need a full per-file diff for review, run:

```powershell
git --no-pager diff -- lib
```

- `FloatingLabelInputField` now derives its input/hint/floating-label/support font sizes from `AppDimensions` (use `topSpacing` to adjust vertical spacing between stacked fields).
- `CountryCodeSelectorField` uses `AppDimensions.flagEmojiSize` and `selectorIconSize` to ensure consistent flag and chevron sizing.
- `AppDialog` action text now uses `AppDimensions.dialogActionFontSize` to standardize button text across dialogs.
- `ProfileSignOutButton` wraps the logout CTA layout used on the profile screen; reuse it (and its dimensions) when adding additional profile actions that need the same look.

If you add new widgets that need specific, consistent sizing, add a new semantic token to `app_dimensions.dart` rather than using raw numbers.

#### FloatingLabelInputField (`shared/widgets/floating_label_input_field.dart`)

```dart
FloatingLabelInputField(
  controller: formControllers.emailController,
  label: AppStrings.emailLabel,
  hint: AppStrings.emailHint,
  supportText: validationController.emailError.value,
  isError: validationController.emailError.value != null,
  onChanged: validationController.validateEmail,
  keyboardType: TextInputType.emailAddress,
  textInputAction: TextInputAction.next,
)
```

Use for: Inputs that require a floating label animation (email, password, profile fields). It preserves accessibility and supports reactive error text through `supportText`. Border thickness increases on focus; error increases further per `AppDimensions.inputBorderWidthError`.

Key options:

- `topSpacing` — adjust spacing when composed inside rows (e.g., alongside `CountryCodeSelectorField`).
- `keyboardType`, `textCapitalization`, `textInputAction`, `inputFormatters` — tune keyboard/layout behavior per field.
- `onSubmitted`/`onEditingComplete` — hook into IME actions.

Migration notes: `FloatingLabelInputField` wraps `CustomInputField` styling but provides the floating-label UX; prefer it for new auth forms. Use new spacing/keyboard hooks to avoid ad-hoc wrappers.

Visual feedback: Input fields now increase their border thickness when focused and increase further when showing a validation error. Use `isError`/`errorText` to trigger the error state; focus is detected automatically.

#### CountryCodeSelectorField (`shared/widgets/country_code_selector_field.dart`)

```dart
CountryCodeSelectorField(
  selectedCountry: selectedCountry,
  onChanged: (country) => setState(() => selectedCountry = country),
  label: AppStrings.countryCodeLabel,
  supportText: validationController.phoneNumberError.value,
  isError: validationController.phoneNumberError.value != null,
)
```

Use for: Dial code + flag selection with floating label styling. Internally wraps the `country_picker` modal (full international list, with Cameroon favorited by default when using `_defaultCountry()` from the complete profile screen).

Key options: `topSpacing` to align with adjacent fields, `enabled` to disable interactions when the form is submitting.

#### CitySelectorField (`shared/widgets/city_selector_field.dart`)

```dart
CitySelectorField(
  controller: formControllers.cityController,
  label: AppStrings.cityLabel,
  hint: AppStrings.cityHint,
  supportText: validationController.cityError.value,
  isError: validationController.cityError.value != null,
  onChanged: validationController.validateCity,
)
```

Use for: City input with fuzzy search autocomplete and Material Design 3 dropdown styling. Fetches city list from Firestore `config/cities` document, caches locally with Hive, and provides intelligent fuzzy matching across city names and alternative names.

**Features:**

- Fuzzy search with tokenization (e.g., "abele" matches "ab leila")
- Smart refocus behavior: shows filtered results based on current input, or all cities if empty
- Custom city warnings from Firestore config when no matches found
- **Validation enforcement**: When `allowCustomCities` is false, prevents saving with cities not in the list
- No gap between input and dropdown for seamless visual experience
- All dimensions use `AppDimensions` constants
- Material Design 3 shadows (`AppColors.shadowMedium`, `AppColors.shadowLight`)

**Validation:**

- When `allowCustomCities` is `false`: Users must select from the list. Shows error "Please select a city from the list" if validation fails.
- When `allowCustomCities` is `true`: Users can type any city name freely.

**Key options:**

- `topSpacing` — adjust vertical spacing (default: `AppDimensions.fieldVerticalSpacing`)
- `onChanged` — validation callback triggered on text change

**Constants used:**

- `AppDimensions.citySelectorMaxWidth` (300px)
- `AppDimensions.citySelectorMaxHeight` (240px)
- `AppDimensions.citySelectorItemHeight` (48px)
- `AppDimensions.citySelectorTextSize` (18px)
- `AppStrings.citySelectorNoCitiesFound`

See `CITIES_CONFIG_IMPLEMENTATION.md` for complete architecture documentation.

#### AvatarCropScreen (`shared/widgets/avatar_crop_screen.dart`)

Provides the in-app avatar cropping UI used by `AvatarPhotoHandler`.

- Uses the Croppy package to render a circular crop viewport sized via `AppDimensions.avatarCrop*` tokens.
- Produces both a full-size square and a smaller thumbnail for upload via `AvatarUploader`.
- All paddings, hit areas, and help text sizes are driven by `AppDimensions`.

Usage: this screen is typically pushed by `AvatarPhotoHandler.handleEditPhoto(context, ...)` after the user picks an image. Prefer calling the handler instead of navigating to the screen directly.

Direct (advanced) usage:

```dart
final file = await Get.to<File?>(() => AvatarCropScreen(imageFile: pickedFile));
if (file != null) {
  // compress & upload
}
```

#### ImagePickerDialog (`shared/widgets/image_picker_dialog.dart`)

Small bottom sheet that lets users choose Camera or Gallery when changing their avatar.

- Labels come from `AppStrings` (English/French).
- Button sizes and spacing derive from `AppDimensions`.
- Consumed by `AvatarPhotoHandler` — prefer the handler instead of showing this dialog directly.

Direct (advanced) usage:

```dart
// Returns ImageSource.camera or ImageSource.gallery or null
final source = await Get.dialog<ImageSource?>(const ImagePickerDialog());
```

#### PasswordStrengthChecklist (`shared/widgets/password_strength_checklist.dart`)

```dart
PasswordStrengthChecklist(
  hasMinLength: validationController.hasMinLength,
  hasUppercase: validationController.hasUppercase,
  hasLowercase: validationController.hasLowercase,
  hasNumber: validationController.hasNumber,
  hasSpecial: validationController.hasSpecial,
)
```

Use for: Signup password fields to show real-time completion of password rules. The checklist is shown during typing/focus and remains visible even when all rules are satisfied.

Migration notes: When showing the checklist, suppress the aggregated `validateStrongPassword` error message to avoid duplicate feedback.

#### AuthFormUtils (`shared/utils/auth_form_utils.dart`)

#### AppDialog (`shared/widgets/app_dialog.dart`)

```dart
showDialog(
  context: context,
  barrierDismissible: true,
  builder: (_) => AppDialog(
    title: 'Title',
    body: 'Optional body copy',
    hero: Icon(Icons.info, color: Colors.white),
    primaryActionLabel: 'Okay',
    onPrimaryAction: () => Get.back(),
  ),
);
```

Use for: Reusable overlay dialogs with consistent styling. Title/body/action are configurable; pass an optional `hero` widget for an icon or illustration.

Extended AppDialog usage (new API):

```dart
// Icon-based hero (auto-decorated circular hero)
AppDialog(
  title: 'Check your email',
  body: 'We sent a password reset link',
  icon: Icons.mark_email_read,
  primaryActionLabel: 'Back to login',
  onPrimaryAction: () => Get.offAllNamed(AppRoutes.login),
);

// Image asset hero (plain image, no decoration)
AppDialog(
  title: 'Check your email',
  body: 'We sent a password reset link',
  imageAsset: 'assets/ASCOA/Forgot_Password_confirm_Icon.png',
  decoratedHero: false, // render the asset as-is
  imageWidth: AppDimensions.dialogImageWidth,
  imageHeight: AppDimensions.dialogImageHeight,
  primaryActionLabel: 'Back to login',
  onPrimaryAction: () => Get.offAllNamed(AppRoutes.login),
);
```

API details (key props):

- `title` (String, required): dialog headline

- `body` (String?): optional paragraph text

- `hero` (Widget?): advanced override for a custom hero

- `icon` (IconData?): simple icon that will be wrapped in the circular gradient hero

- `imageAsset` (String?): path to an asset used as the hero

  - `decoratedHero` (bool): when true (default), the hero is rendered inside the gradient circle; when false, the image/icon is shown plain

  - `imageWidth` / `imageHeight` (double?): explicit image dimensions for non-square assets

  - Decorative background: The dialog renders a fixed decorative background image behind its content when appropriate. This decorative image is internal to `AppDialog` and is not configurable by callers — there are no background-related props. The asset, opacity, flip, and height are fixed by design.

  - `primaryActionLabel` (String): button text

  - `onPrimaryAction` (VoidCallback): handler invoked when primary button pressed

Notes:

- Prefer `icon` or `imageAsset` for most dialogs. Use `hero` only if you need custom layout/animation.
- The decorative background image is internal to `AppDialog`. Callers do not configure it.
- Styling and sizes use `AppDimensions` constants.

New dimensions (see `app_dimensions.dart`):

- `AppDimensions.dialogImageWidth` (double): default width for dialog images (134.0)

- `AppDimensions.dialogImageHeight` (double): default height for dialog images (94.0)

- `AppDimensions.forgotBgTopHeight` (double): screen-relative top background image height (~0.235)

- `AppDimensions.forgotBgBottomHeight` (double): screen-relative bottom background image height (~0.306)

```dart
// Centralized helpers used by auth screens
AuthFormUtils.validateLogin(validationController, email, password);
AuthFormUtils.handleSignupPasswordChange(validationController, password);
```

Use for: Centralized validation wiring to avoid duplicated logic between login and signup screens. Keep the UI layer thin and use these helpers in screen `onChanged`/`onPressed` handlers.

Migration notes: Replace inline ad-hoc validation wiring with `AuthFormUtils` calls when possible to reduce duplication.

## Utilities (shared/utils/)

### Validators (`validators.dart`)

```dart
import 'package:ascoa_app/shared/utils/validators.dart';

// Email validation
String? error = Validators.validateEmail(email);

// Password validation
String? error = Validators.validatePassword(password);

// Strong password (signup)
String? error = Validators.validateStrongPassword(password);
```

### Migration Notes

- Many screens now use `AppDimensions` multipliers instead of hardcoded `size.height * <number>` values. When updating or adding layouts, prefer these constants and add new entries to `app_dimensions.dart` if a new semantic gap is needed.
- `AuthHeader` previously used inline numbers; switch to `AuthHeader(scale: computedScale)` and reuse `AppDimensions.authHeader*` base values.
- If you see a direct pixel number used in a widget (e.g., `size: 28`), replace it with a semantically named constant in `AppDimensions` (e.g., `iconBackSize`).

**Available validators:**

- `validateEmail()` - Checks email format
- `validatePassword()` - Min 6 characters
- `validateStrongPassword()` - 8+ chars, uppercase, lowercase, number, special
- `validateConfirmPassword()` - Matches original password

## Controllers (shared/controllers/)

### FormControllers (`form_controllers.dart`)

```dart
// Usage in screen (automatically injected via FormBinding)
final formControllers = Get.find<FormControllers>();

CustomInputField(
  controller: formControllers.emailController,
  hint: "Email",
)
```

**Available controllers:**

- `emailController` - For email inputs
- `passwordController` - For password inputs

### ValidationController additions

- `isTermsAccepted` (RxBool) — tracks whether the user has accepted Terms & Conditions (used by signup UI).
- `termsError` (Rx<String?>) — inline error string; signup shows this below the checkbox and switches checkbox border to `AppColors.error` with `AppDimensions.inputBorderWidthError`.
- `isEmailValid(String)` and `clearEmailError()` — used to sanitize state between Login, Signup, and Forgot.

### ValidationController (`validation_controller.dart`)

#### Cross-screen email handoff (Login ↔ Forgot Password)

To prevent leaking error states between auth screens, email state is sanitized during navigation:

- Only carry the email text between screens if it is valid.
- Always clear the email error state before navigating.

Helpers available:

- `bool isEmailValid(String email)` — quick validity check without mutating state.
- `void clearEmailError()` — clears only the email error (keeps other validation state).

Recommended usage before navigating from Login → Forgot Password (and similarly on back/confirm from Forgot → Login):

```dart
final form = Get.find<FormControllers>();
final validation = Get.find<ValidationController>();

final currentEmail = form.emailController.text;
validation.clearEmailError();
if (!validation.isEmailValid(currentEmail)) {
  form.emailController.clear();
}
Get.toNamed(AppRoutes.forgotPassword);
```

Notes:

- `ForgotPasswordScreen` also sanitizes on init, so the UI won’t show stale errors even if callers forget. Pre-sanitizing on navigation is still recommended for clarity and consistency.

```dart
// Usage in screen (automatically injected via FormBinding)
final validationController = Get.find<ValidationController>();

// Validate email
validationController.validateEmail(email);

// Validate required field (login password)
validationController.validatePasswordRequired(password);
```

**Available methods:**

- `validateEmail()` - Validates email format
- `validatePasswordRequired()` - Checks password not empty (for login)
- `clearValidation()` - Clears all error states
- `isFormValid` - Returns true if no validation errors

**Auto cleanup:** Controllers are automatically disposed when not needed.

## Quick Reference

**Import Pattern:**

```dart
// Constants
import 'package:ascoa_app/shared/constants/app_colors.dart';
import 'package:ascoa_app/shared/constants/app_text_styles.dart';

// Widgets
import 'package:ascoa_app/shared/widgets/custom_input_field.dart';
import 'package:ascoa_app/shared/widgets/primary_button.dart';

// Utilities
import 'package:ascoa_app/shared/utils/validators.dart';
```

**Common Usage:**

```dart
// Styled container
Container(
  padding: EdgeInsets.all(AppDimensions.screenPadding),
  color: AppColors.primary,
  child: Text('Hello', style: AppTextStyles.heading1),
)

// Form field with validation
CustomInputField(
  controller: formControllers.emailController,
  hint: AppStrings.emailHint,
)

// Validated form submission
final emailError = Validators.validateEmail(email);
if (emailError != null) {
  // Show error
  return;
}
```

**Best Practices:**

- ✅ Use shared constants instead of hard-coding values
- ✅ Check this guide before creating new components
- ✅ Import from shared/ when available
- ✅ Use Get.find() to access controllers (never Get.put() in widgets)
- ✅ Controllers are automatically injected via FormBinding
- ❌ Don't recreate existing components
- ❌ Don't hard-code colors, text, or spacing
- ❌ Don't manually create controllers in widgets

**Architecture Notes:**

- `FormBinding` injects `FormControllers` and `ValidationController` for auth screens.
- Login uses `validatePasswordRequired`; Signup uses `validateStrongPassword` + live checklist.
- Forgot Password confirmation screen was removed; we use `AppDialog` overlay instead.

**When to Add New Shared Components:**

- Component is used in 2+ different screens
- Component follows a consistent design pattern
- Component can be reused by other team members

**Available Dimensions:**

### **Padding & Margins**

- `AppDimensions.screenPadding` - `24.0` - Main screen padding
- `AppDimensions.verticalPadding` - `16.0` - Vertical padding
- `AppDimensions.smallSpacing` - `8.0` - Small gaps
- `AppDimensions.dividerPadding` - `12.0` - Around divider text
- `AppDimensions.socialButtonSpacing` - `16.0` - Between social buttons
- `AppDimensions.bottomSpacing` - `56.0` - Bottom content spacing

#### **Icon Sizes**

- `AppDimensions.socialIconSize` - `24.0` - Social login icons

#### **Other Elements**

- `AppDimensions.dividerThickness` - `1.0` - Divider line thickness

#### **Screen Height Multipliers** (Responsive spacing)

- `AppDimensions.titleTopSpacing` - `0.16` - 16% of screen height
- `AppDimensions.titleBottomSpacing` - `0.02` - 2% of screen height
- `AppDimensions.inputSpacing` - `0.01` - 1% of screen height
- `AppDimensions.buttonSpacing` - `0.03` - 3% of screen height
- `AppDimensions.sectionSpacing` - `0.02` - 2% of screen height

**Usage for Responsive Design:**

```dart
SizedBox(
  height: MediaQuery.of(context).size.height * AppDimensions.titleTopSpacing,
)
```

---

### **app_strings.dart** - Text Content

```dart
import 'package:ascoa_app/shared/constants/app_strings.dart';

Text(AppStrings.loginTitle) // "Login into Account"
```

**Available Strings:**

#### **Login Screen Content**

- `AppStrings.loginTitle` - "Login into Account"
- `AppStrings.emailLabel` - "Email"
- `AppStrings.emailHint` - "<example@gmail.com>"
- `AppStrings.passwordLabel` - "Password"
- `AppStrings.passwordHint` - "Enter Password"
- `AppStrings.loginButton` - "Login"
- `AppStrings.forgotPassword` - "Forgot password?"

#### **Social Login**

- `AppStrings.dividerOr` - "OR"
- `AppStrings.continueWithGoogle` - "Continue with Google"
- `AppStrings.continueWithFacebook` - "Continue with Facebook"

#### **Navigation Text**

- `AppStrings.noAccount` - "Don't have an account? "
- `AppStrings.signUp` - "Sign up"

#### **Legal Text**

- `AppStrings.termsText` - "By using ASCOA, you agree to the \n"
- `AppStrings.termsLink` - "Terms"
- `AppStrings.termsAnd` - " and "
- `AppStrings.privacyPolicyLink` - "Privacy Policy"
- `AppStrings.termsPeriod` - "."

#### **Forgot Password Text**

- `AppStrings.forgotPasswordTitle` - "Reset Password"
- `AppStrings.forgotPasswordInstructions` - "Enter your email to receive password reset instructions."
- `AppStrings.forgotPasswordSuccessMessage` - "Password reset link sent! Check your email."
- `AppStrings.forgotPasswordErrorMessage` - "Error sending password reset email."

#### **Development Messages** (For navigation placeholders)

- `AppStrings.forgotPasswordNav` - "Navigate to Forgot Password screen"
- `AppStrings.signUpNav` - "Navigate to Sign Up screen"
- `AppStrings.termsNav` - "Navigate to Terms screen"
- `AppStrings.privacyPolicyNav` - "Navigate to Privacy Policy screen"

**Why centralized strings?**

- Easy localization (multiple languages)
- Consistent text across the app
- Easy to update content
- Prevents typos and inconsistencies

---

## 🧩 **shared/widgets/** - Reusable UI Components

### **CustomInputField** - Styled Text Input

```dart
import 'package:ascoa_app/shared/widgets/custom_input_field.dart';

CustomInputField(
  controller: emailController,
  hint: "Enter your email",
  obscure: false, // Set to true for passwords
)
```

**Properties:**

- `controller` (required) - TextEditingController for the input
- `hint` (required) - Placeholder text
- `obscure` (optional) - Set to `true` for password fields

**Features:**

- Consistent styling across the app
- White background with border
- Shadow for depth
- Automatic password hiding
- Responsive design

**When to use:**

- ✅ Email inputs
- ✅ Password inputs
- ✅ Any single-line text input
- ❌ Multi-line text (use TextFormField)
- ❌ Search fields (might need different styling)

---

### **PrimaryButton** - Main Action Button

```dart
import 'package:ascoa_app/shared/widgets/primary_button.dart';

PrimaryButton(
  label: 'Login',
  onPressed: () {
    // Handle button tap
    performLogin();
  },
)
```

**Properties:**

- `label` (required) - Button text
- `onPressed` (required) - Callback function when tapped

**Features:**

- Green background (`#4CAF50`)
- White text
- Rounded corners
- Elevation shadow
- Full width
- Consistent height

**When to use:**

- ✅ Primary actions (Login, Sign Up, Submit)
- ✅ Form submissions
- ✅ Main call-to-action buttons
- ❌ Secondary actions (use TextButton)
- ❌ Destructive actions (use different styling)

---

### **SocialButton** - Social Login Button

```dart
import 'package:ascoa_app/shared/widgets/social_button.dart';

SocialButton(
  icon: Image.asset('assets/google_icon.png'),
  label: "Continue with Google",
  color: AppColors.google,
  onPressed: () => handleGoogleLogin(),
)
```

**Properties:**

- `icon` (required) - Widget for the social platform icon
- `label` (required) - Button text
- `color` (required) - Brand color for the platform
- `onPressed` (required) - Callback function

**Features:**

- Left-aligned icon and text
- White background with border
- Consistent sizing
- Brand color integration
- Responsive design

**When to use:**

- ✅ Social login buttons (Google, Facebook, Apple)
- ✅ Third-party integrations
- ❌ Regular action buttons (use PrimaryButton)

---

## 🎮 **shared/controllers/** - Reusable Controllers

### **FormControllers** - Form Input Management

```dart
import 'package:ascoa_app/shared/controllers/form_controllers.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final formControllers = Get.find<FormControllers>();

    return CustomInputField(
      controller: formControllers.emailController,
      hint: "Email",
    );
  }
}
```

**Available Controllers:**

- `emailController` - For email input fields
- `passwordController` - For password input fields

**Features:**

- Automatic memory management (disposes controllers)
- GetX integration
- Reusable across multiple forms
- Prevents memory leaks

**When to extend:**

```dart
// If you need more form controllers
class FormControllers extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController(); // New field

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose(); // Don't forget to dispose
    super.onClose();
  }
}
```

---

## 🛠️ **shared/utils/** - Helper Functions

### **Validators** - Input Validation

```dart
import 'package:ascoa_app/shared/utils/validators.dart';

TextFormField(
  controller: emailController,
  validator: Validators.validateEmail, // Auto email validation
  decoration: InputDecoration(
    labelText: 'Email',
    errorText: Validators.validateEmail(emailController.text),
  ),
)
```

**Available Validators:**

#### **Email Validation**

```dart
String? emailError = Validators.validateEmail(userInput);
// Returns null if valid, error message if invalid
```

**Checks:**

- Required field
- Proper email format (e.g., `user@domain.com`)

#### **Password Validation (Basic)**

```dart
String? passwordError = Validators.validatePassword(userInput);
```

**Checks:**

- Required field
- Minimum 6 characters

#### **Strong Password Validation (For Signup)**

```dart
String? strongPasswordError = Validators.validateStrongPassword(userInput);
```

**Checks:**

- Required field
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number
- At least one special character

#### **Confirm Password**

```dart
String? confirmError = Validators.validateConfirmPassword(
  confirmPassword,
  originalPassword
);
```

**Checks:**

- Required field
- Matches original password

#### **Generic Required Field**

```dart
String? nameError = Validators.validateRequired(userInput, 'Full Name');
// Returns "Full Name is required" if empty
```

#### **Phone Number Validation**

```dart
String? phoneError = Validators.validatePhoneNumber(userInput);
// Optional field - returns null if empty, validates format if provided
```

**Usage Examples:**

**In Forms:**

```dart
TextFormField(
  validator: (value) => Validators.validateEmail(value),
  autovalidateMode: AutovalidateMode.onUserInteraction,
)
```

**Manual Validation:**

```dart
void _submitForm() {
  final emailError = Validators.validateEmail(_emailController.text);
  if (emailError != null) {
    // Show error message
    Get.snackbar('Error', emailError);
    return;
  }
  // Proceed with form submission
}
```

---

## 📖 **How to Use This Reference**

### **Before Creating New Components:**

1. **Check this reference** - Component might already exist
2. **Look at existing implementations** - Follow established patterns
3. **Consider shared vs module-specific** - Will others use this?

### **When Extending Shared Components:**

1. **Add to existing files** if it's a variation
2. **Create new files** if it's a completely different component
3. **Update this documentation** so teammates know about it
4. **Use consistent naming** - follow established conventions

### **Best Practices:**

```dart
// ✅ Good - Use constants
Container(
  padding: EdgeInsets.all(AppDimensions.screenPadding),
  color: AppColors.primary,
  child: Text('Hello', style: AppTextStyles.heading1),
)

// ❌ Avoid - Hard-coded values
Container(
  padding: EdgeInsets.all(AppDimensions.screenPadding),
  color: Color(0xFF5B92E5),
  child: Text('Hello', style: TextStyle(fontSize: AppDimensions.heading2FontSize, fontWeight: FontWeight.bold)),
)
```

```dart
// ✅ Good - Import from shared
import 'package:ascoa_app/shared/constants/app_colors.dart';

// ✅ Good - Use shared widgets
CustomInputField(controller: controller, hint: AppStrings.emailHint)

// ❌ Avoid - Recreating existing components
TextField(decoration: InputDecoration(/* custom styling */))
```

### **Contributing to Shared:**

1. **Identify reusable patterns** in your module code
2. **Extract to shared/** if used in multiple places
3. **Add comprehensive documentation**
4. **Test across different screens**
5. **Update this reference guide**

---

## 🚀 **Quick Reference Cheat Sheet**

```dart
// Colors
AppColors.primary, AppColors.white, AppColors.google

// Text Styles
AppTextStyles.heading1, AppTextStyles.label, AppTextStyles.body

// Dimensions
AppDimensions.screenPadding, AppDimensions.smallSpacing

// Strings
AppStrings.loginTitle, AppStrings.emailLabel

// Widgets
CustomInputField(controller: c, hint: "text")
PrimaryButton(label: "Click", onPressed: () => {})
SocialButton(icon: i, label: "text", color: c, onPressed: () => {})

// Validators
Validators.validateEmail(value)
Validators.validatePassword(value)

// Controllers
Get.find<FormControllers>().emailController
```

This shared system ensures consistency, reduces code duplication, and makes the app easier to maintain. When in doubt, check here first! 🎯
