# Shared Components Guide

Quick reference for reusable components, constants, and utilities in the ASCOA app.

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

#### FloatingLabelInputField (`shared/widgets/floating_label_input_field.dart`)

```dart
FloatingLabelInputField(
  controller: formControllers.emailController,
  label: AppStrings.emailLabel,
  hintText: AppStrings.emailHint,
  isError: validationController.emailError != null,
  onChanged: validationController.validateEmail,
)
```

Use for: Inputs that require a floating label animation (email, password). It preserves accessibility and supports `supportText` and `isError` props. Border thickness increases on focus; error increases further per `AppDimensions.inputBorderWidthError`.

Migration notes: `FloatingLabelInputField` wraps `CustomInputField` styling but provides the floating-label UX; prefer it for new auth forms.

Visual feedback: Input fields now increase their border thickness when focused and increase further when showing a validation error. Use `isError`/`errorText` to trigger the error state; focus is detected automatically.

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
  padding: EdgeInsets.all(24),
  color: Color(0xFF5B92E5),
  child: Text('Hello', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
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
