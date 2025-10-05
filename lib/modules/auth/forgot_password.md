# Forgot Password Feature – ASCOA App

## Purpose

Allows users to request a password reset link via email. Integrates with **AuthController** and uses **GetX** for state management. Supports **English** and **French** automatically.

---

## Key Components

### Screens

- **ForgotPasswordScreen**

  - Input: Email
  - Features: Real-time email validation, loading state, bilingual labels/messages
  - Action: Sends password reset request via `AuthController`
  - Success: Shows an in-place overlay dialog (AppDialog) with confirmation and a button back to Login

### Controllers

- **AuthController**

  - `RxBool isLoadingForgotPassword` – tracks loading state
  - `Future<String> forgotPassword(String email)` – sends reset email
  - Returns:
    - `'success'` → Email sent
    - `'user-not-found'` → No user found
    - `'invalid-email'` → Invalid email format
    - `'too-many-requests'` → Rate limit
    - `'error'` → General Firebase error

- **FormControllers** – Manages `emailController` for input
- **ValidationController** – Validates email in real-time and sets error messages

---

### Full Flow (with overlay)

```dart
// Navigate to Forgot Password screen
Get.toNamed(AppRoutes.forgotPassword);

// On success, show overlay
showDialog(
  context: context,
  builder: (_) => AppDialog(
    title: 'Forgot Password',
    body: 'We have sent an email to\nuser@example.com with instructions\nto reset your password.',
  hero: Icon(Icons.mark_email_read, size: 40, color: AppColors.pureWhite),
    primaryActionLabel: 'Back to Login',
    onPrimaryAction: () { Get.offAllNamed(AppRoutes.login); },
  ),
);
```

### Controller Only

```dart
final AuthController authController = Get.find<AuthController>();
final result = await authController.forgotPassword('user@example.com');

if(result == 'success'){
  // trigger overlay dialog in the screen's UI layer
}
```

Confirmation screen was removed in favor of the overlay dialog.

---

## Features

- Real-time email validation with error feedback
- Loading state disables button during request
- Bilingual support (English/French) using `Get.locale`
- Error handling via snackbars
- Modern UI matching app color scheme
- Footer includes Terms & Privacy Policy

---

## Recent Changes

- Replaced confirmation screen with `AppDialog` for in-place overlay confirmation.
- Added bilingual support for labels and messages.
- Updated `AuthController` with `forgotPassword` method.
- Improved navigation hygiene: Clears email errors and resets validation state on transitions.
  AuthController now integrates with Cloud Firestore: after sign-in/signup it loads or creates a `users` document. The app uses a `UserModel` (see `lib/app/models/user.dart`) to represent user profile data. If `isProfileComplete` is false the user is routed to `AppRoutes.completeProfile` to fill profile details.

## Notes for Developers

User model: new `UserModel` contains fields such as `uid`, `email`, `firstName`, `lastName`, `phoneNumber`, `city`, `isProfileComplete`, `createdAt`, and `signUpMethod`. Keep `toMap()` and `fromMap()` in sync with Firestore document fields.

Routing: The new `AppRoutes.completeProfile` route must be handled by your navigation setup (screens/route definitions) and should provide UI to collect required profile information. Auth flows now call `_handleUserPostLogin` which may `Get.offAllNamed(AppRoutes.completeProfile)` for incomplete profiles.

Testing: Because the `AuthController` now reads/writes Firestore documents, unit/widget tests should continue to use `TestAuthController` (or mock `FirebaseFirestore.instance`) to avoid network calls. Update test helpers if you need to simulate Firestore-backed profile states (e.g., `isProfileComplete: true/false`).

## Migration notes for teammates

- When updating copy, edit `lib/shared/constants/app_strings.dart` (EN/FR variants).
- If you need the decorated circular hero with gradient/shadow, pass `icon` or set `decoratedHero: true`.
- For full-background images, prefer the `Stack`+`Positioned` approach used in `forgot_password_screen.dart` so content scrolls above imagery.

## Usage Notes

- Ensure `FormBinding` is registered in `main.dart` to provide shared controllers.
- Use `ValidationController` for real-time email validation and error handling.

## How to test locally

Run the analyzer and app, then navigate: Login → Forgot Password → submit a valid email, and confirm the overlay appears.

```powershell
flutter analyze
flutter run -d windows
```

### Localization

- The Forgot Password feature now uses `AppStrings` for all error messages and labels, ensuring bilingual support.

### Recent implementation notes

- `lib/shared/constants/app_dimensions.dart` added `forgotTitleTopSpacing` (0.12) to tweak top spacing for some forgot-password layouts. If you adjust the layout in `forgot_password_screen.dart`, prefer changing the token here rather than hard-coding a new value in the screen.
- The `ForgotPasswordScreen` and related shared widgets were updated to use `SizeUtils` wrappers when rendering `AppDimensions` tokens. This preserves the tokens while ensuring the UI scales on different device sizes. Follow the mapping in `SHARED_COMPONENTS_GUIDE.md` when making similar changes.
