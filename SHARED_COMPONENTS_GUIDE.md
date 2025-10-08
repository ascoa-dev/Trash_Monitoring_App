# Shared Components Guide

Quick reference for reusable components, constants, and utilities in the ASCOA app.

## Constants (shared/constants/)

### Colors (`app_colors.dart`)

```dart
import 'package:ascoa_app/shared/constants/app_colors.dart';

// Usage
Container(color: AppColors.primary)  // Background color (white)
```

- `AppColors.primary` - White background (0xFFFFFFFF)
- `AppColors.accent` - Green accent color (0xFFA4C639)
- `AppColors.buttonPrimary` - Green button color (0xFF228B22)
- `AppColors.white` - Pure white (Colors.white)
- `AppColors.google` - Google blue (0xFF4285F4)
- `AppColors.facebook` - Facebook blue (0xFF4267B2)
- `AppColors.error` - Red color used for inline error messages (0xFFFF0000)

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

- `AppDimensions.screenPadding` - 24px main padding
- `AppDimensions.smallSpacing` - 8px small gaps
- `AppDimensions.verticalPadding` - 16px vertical space

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
- `termsError` (Rx<String?>) — holds an inline error string for the terms checkbox; signup displays this below the checkbox similar to other field errors.

### ValidationController (`validation_controller.dart`)

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

- FormBinding automatically injects FormControllers and ValidationController
- Controllers are lazy-loaded and auto-disposed
- Login uses validateRequired() for password, signup will use validateStrongPassword()
- Follow GetX binding pattern as defined in Structure.md

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
