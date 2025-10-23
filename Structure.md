# 📂 Project Structure

This project uses a **modular architecture** with `GetX` for state management, navigation, and dependency injection.  
The structure ensures **separation of concerns**, **reusability**, and easy scalability.

````plaintext
lib/
│
├── main.dart
│
├── app/                     # Core app setup
│   ├── routes/              # Global navigation setup
│   │   └── app_routes.dart
│   ├── controllers/         # Global state controllers
│   │   └── auth_controller.dart
│   └── models/              # Global models (User, Post, etc.)
│       └── user.dart
│       └── posts.dart
│
├── modules/                 # Feature-based modules
│   ├── auth/                # Login/Signup/Forgot Password/Verification
│   │   ├── views/           # Screens
│   │   │   ├── login_screen_v2.dart
│   │   │   ├── signup_screen.dart
│   │   │   ├── forgot_password_screen.dart
│   │   │   ├── complete_profile_screen.dart
│   │   │   └── email_verification_screen.dart
│   │   ├── widgets/         # Widgets used inside auth
│   │   └── (bindings are centralized in shared/controllers/form_binding.dart)
│   │
│   ├── home/                # Home/dashboard
│   │   └── views/
│   │       └── home_screen.dart
│   │
│   ├── profile/             # User profile management
│   │   ├── bindings/
│   │   │   ├── edit_profile_binding.dart
│   │   │   └── change_password_binding.dart
│   │   ├── controllers/
│   │   │   ├── edit_profile_controller.dart
│   │   │   └── change_password_controller.dart
│   │   ├── models/
│   │   │   └── change_password_status.dart
│   │   ├── views/
│   │   │   ├── profile_screen.dart
│   │   │   ├── edit_profile_screen.dart
│   │   │   └── change_password_screen.dart
│   │   └── widgets/
│   │       ├── profile_action_tile.dart
│   │       └── profile_signout_button.dart
│   │   │   ├── post_list_screen.dart
│   │   │   └── post_detail_screen.dart
│   │   └── widgets/
│   │
│   ├── search/              # Search feature
│   │       └── search_screen.dart
│   │
│   └── settings/            # Settings
│
    ├── widgets/             # Buttons, text fields, loaders
    ├── constants/           # Colors, strings, sizes
    ├── utils/               # Validators, formatters, helpers
    └── themes/              # Light/dark theme, text styles



```dart
// shared/controllers/form_binding.dart
class FormBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<FormControllers>()) {
      Get.put<ValidationController>(ValidationController(), permanent: true);
    }
  }
````

Used in routes for Login, Signup, and Forgot Password.

Latest updates

A quick overview of the project structure and what goes where:

---

---

- **controllers/** → Global state controllers (e.g. auth). And communicate with external APIs like Firebase.
- **models/** → Shared data models used across features (e.g. `User`, `Post`).

Typical structure inside a module:

- **views/** → Screens for the feature.
- **widgets/** → Reusable widgets specific to that feature. Like a Login form widget for the login screen, because its only used in the login screen we do not put it in the shared widgets library.
- **bindings/** → Dependency injection for controllers/services. See [Bindings in GetX](#-bindings-in-getx)

Examples of modules: `auth/`, `home/`, `profile/`, `posts/`, `search/`, `settings/`.

---

## `shared/`

Holds everything that can be reused across multiple modules.

- **widgets/** → Common UI components (buttons, inputs, loaders).
- **constants/** → Central values like colors, strings, dimensions. This is good so that we dont have to keep defining colours, we can just define them once and use them everywhere.
- **utils/** → Helper functions (validators, formatters, date helpers). Example: a password strength shecker which validates the strench of the password
- **themes/** → Light/dark theme setup and text styles.(Optional)

---

### Updated Modules

#### Auth Module

- `forgot_password_screen.dart` - Handles Forgot Password flow with overlay dialog.
- `email_verification_screen.dart` - Polls verification status, exposes resend/cancel actions, and routes verified users through `AuthController.handleUserPostVerification`.
- `complete_profile_screen.dart` - Collects first/last name, phone, and city with country selector.
- Shared bindings: `FormBinding` for controllers.

- `change_password_screen.dart` mirrors signup password validation with snackbar feedback; paired with `ChangePasswordController`, `ChangePasswordBinding`, and `ChangePasswordStatus` model.
- `profile_signout_button.dart` provides a reusable CTA with consistent spacing/branding for logout actions.
- `edit_profile_screen.dart` reuses shared validation/controllers and now aligns background/spacing with the change password flow.
- Avatar editing/viewing: `edit_profile_screen.dart` and `complete_profile_screen.dart` integrate a shared `AvatarPhotoHandler` to pick/crop/compress/upload avatars. The `profile_screen.dart` shows the cached avatar (thumb preferred) and supports tap-to-zoom via `modules/profile/widgets/full_image_overlay.dart`.

#### Shared Components

- `app_dialog.dart` - Overlay dialog for confirmations.
- `validation_controller.dart` - Centralized validation logic.
- `form_binding.dart` - Shared bindings for form state management.

---

### 🔗 Bindings in GetX

Bindings in GetX are a clean way to manage dependency injection. Instead of creating controllers or services directly inside your UI files, you declare them once in a Binding. When a route loads, GetX automatically initializes the required dependencies and disposes of them when the route is removed. This keeps your code organized, avoids repeating initialization logic everywhere, and makes it easier to scale when controllers need new dependencies.

<!-- markdownlint-disable MD033 -->
<details>
  <summary>📌 Example (click to expand)</summary>

```dart
// main.dart (excerpt)
GetPage(
  name: AppRoutes.login,
  page: () => const LoginScreenV2(),
  bindings: [FormBinding()],
),
GetPage(
  name: AppRoutes.signup,
  page: () => const SignupScreen(),
  bindings: [FormBinding()],
),
GetPage(
  name: AppRoutes.forgotPassword,
  page: () => ForgotPasswordScreen(),
  bindings: [FormBinding()],
),
```

<!-- markdownlint-enable MD033 -->
