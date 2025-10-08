# Forgot Password Widget Tests

This folder contains a comprehensive widget test suite for the Forgot Password screen.

## What is covered

- Rendering: Title, email field, submit button
- Init cleanup: clears invalid carried email and resets prior email errors
- Validation: live email validation helper text via `ValidationController`
- Guard: no submit call when email is invalid
- Success flow: loading label → confirmation dialog → navigation to `AppRoutes.login`
- Error handling: shows GetX snackbars for known error codes (`user-not-found`, `invalid-email`, `too-many-requests`) and a generic `error`
- I18n: verifies French locale title and dialog button text

## Key testing techniques

- Firebase isolation: `TestAuthController` extends `AuthController` but overrides `onInit` to avoid binding to Firebase. It exposes a controllable `completer` and `result` to simulate outcomes without hitting the network.
  Note: `AuthController` in the app now loads/creates a Firestore `users` document after sign-in/signup and may navigate to `AppRoutes.completeProfile` when the profile is incomplete. Tests in this folder intentionally use a lightweight `TestAuthController` to avoid Firestore and Firebase network calls. If you add tests that need to simulate Firestore-backed behavior, extend `TestAuthController` to expose the expected `UserModel` behavior or mock `FirebaseFirestore.instance`.

- Snackbar stability: GetX snackbars start animations and timers. Tests explicitly call `Get.closeAllSnackbars()` and drain with extra `pump`/`pumpAndSettle` to prevent ticker/timer leaks during teardown.

## Files of interest

- `forgot_password_screen_test.dart`: The test suite implementation.

## How to run

Run only this suite:

```powershell
flutter test test/forgot_password/forgot_password_screen_test.dart -r compact
```

Run all tests:

```powershell
flutter test -r compact
```

## Notes

- If you add new assets used by the screen, the `_TestAssetBundle` will still return the 1x1 PNG for all `.png` paths, so no extra adjustments are needed.
- If snackbar assertions become flaky, prefer asserting `Get.isSnackbarOpen` and always close/drain after each display.
