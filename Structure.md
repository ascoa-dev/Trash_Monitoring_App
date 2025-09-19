# 📂 Project Structure

This project uses a **modular architecture** with `GetX` for state management, navigation, and dependency injection.  
The structure ensures **separation of concerns**, **reusability**, and easy scalability.

```plaintext
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
│   ├── auth/                # Login/Signup/Forgot Password
│   │   ├── views/           # Screens
│   │   │   ├── login_screen_v2.dart
│   │   │   ├── signup_screen.dart
│   │   │   └── forgot_password_screen.dart
│   │   ├── widgets/         # Widgets used inside auth
│   │   └── (bindings are centralized in shared/controllers/form_binding.dart)
│   │
│   ├── home/                # Home/dashboard
│   │   └── views/
│   │       └── home_screen.dart
│   │
│   ├── profile/             # User profile
│   │   └── views/
│   │       └── profile_screen.dart
│   │
│   ├── posts/               # Posts/feed
│   │   ├── views/
│   │   │   ├── post_list_screen.dart
│   │   │   └── post_detail_screen.dart
│   │   └── widgets/
│   │
│   ├── search/              # Search feature
│   │   └── views/
│   │       └── search_screen.dart
│   │
│   └── settings/            # Settings
│       └── views/
│           └── settings_screen.dart
│
└── shared/                  # Reusable across modules
    ├── widgets/             # Buttons, text fields, loaders
    ├── constants/           # Colors, strings, sizes
    ├── utils/               # Validators, formatters, helpers
    └── themes/              # Light/dark theme, text styles

```

### Shared Controllers and Bindings

Auth screens reuse the same form and validation state via a shared binding:

```dart
// shared/controllers/form_binding.dart
class FormBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<FormControllers>()) {
      Get.put<FormControllers>(FormControllers(), permanent: true);
    }
    if (!Get.isRegistered<ValidationController>()) {
      Get.put<ValidationController>(ValidationController(), permanent: true);
    }
  }
}
```

Used in routes for Login, Signup, and Forgot Password.

````

## 📂 Folder Guide

A quick overview of the project structure and what goes where:

---

### `main.dart`

- Entry point of the app.
- Sets up the root widget and initializes required bindings/services.

---

### `app/`

Core setup that holds global app logic.

- **routes/** → Centralized navigation (all `GetPages` live here).
- **controllers/** → Global state controllers (e.g. auth). And communicate with external APIs like Firebase.
- **models/** → Shared data models used across features (e.g. `User`, `Post`).

---

### `modules/`

Feature-based folders. Each feature is self-contained with its own screens, widgets, and bindings.

Typical structure inside a module:

- **views/** → Screens for the feature.
- **widgets/** → Reusable widgets specific to that feature. Like a Login form widget for the login screen, because its only used in the login screen we do not put it in the shared widgets library.
- **bindings/** → Dependency injection for controllers/services. See [Bindings in GetX](#-bindings-in-getx)

Examples of modules: `auth/`, `home/`, `profile/`, `posts/`, `search/`, `settings/`.

---

### `shared/`

Holds everything that can be reused across multiple modules.

- **widgets/** → Common UI components (buttons, inputs, loaders).
- **constants/** → Central values like colors, strings, dimensions. This is good so that we dont have to keep defining colours, we can just define them once and use them everywhere.
- **utils/** → Helper functions (validators, formatters, date helpers). Example: a password strength shecker which validates the strench of the password
- **themes/** → Light/dark theme setup and text styles.(Optional)

---

### Updated Modules

#### Auth Module
- `forgot_password_screen.dart` - Handles Forgot Password flow with overlay dialog.
- Shared bindings: `FormBinding` for controllers.

#### Shared Components
- `app_dialog.dart` - Overlay dialog for confirmations.
- `validation_controller.dart` - Centralized validation logic.
- `form_binding.dart` - Shared bindings for form state management.

---

### 🔗 Bindings in GetX

Bindings in GetX are a clean way to manage dependency injection. Instead of creating controllers or services directly inside your UI files, you declare them once in a Binding. When a route loads, GetX automatically initializes the required dependencies and disposes of them when the route is removed. This keeps your code organized, avoids repeating initialization logic everywhere, and makes it easier to scale when controllers need new dependencies.

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
