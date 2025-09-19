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
    hero: Icon(Icons.mark_email_read, size: 40, color: Colors.white),
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
