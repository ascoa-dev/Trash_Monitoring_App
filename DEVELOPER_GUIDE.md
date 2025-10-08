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

````plaintext

### 2. Authentication Module (`modules/auth/`)

**Login Screen** - Responsive UI with form validation
- Uses shared constants (colors, text styles, dimensions)
- Integrates with global AuthController
- Custom widgets for consistent design

AuthController behavior changes:
- `login` now navigates to `AppRoutes.home` on successful email/password login.
- `logout` calls `FirebaseAuth.signOut()` and shows a snackbar confirmation.

### 3. Shared Design System (`shared/constants/`)

Created centralized constants to replace hard-coded values:

- **AppColors** - Primary, secondary, social button colors
- **AppTextStyles** - Typography system (headings, body, labels)
- **AppDimensions** - Spacing, padding, sizing values
- **AppStrings** - All text content for easy localization

### 4. Reusable Components (`shared/widgets/`)

- **CustomInputField** - Styled text inputs with validation
- **PrimaryButton** - Main action buttons
- **SocialButton** - Google/Facebook login buttons

### 5. Utilities (`shared/utils/`)

**Validators** - Form validation functions:
- Email format checking
- Password strength validation
- Reusable across all forms

### 6. Form Management (`shared/controllers/`)

**FormControllers** - Manages TextEditingControllers with automatic cleanup

**ValidationController** updates:
- New reactive `isTermsAccepted` (tracks checkbox state for terms and conditions).
- New reactive `termsError` (string) to hold inline validation error for the terms checkbox; the signup UI displays this inline like other field errors.

## Key Architectural Decisions

1. **GetX Permanent Controller** - AuthController persists across navigation
2. **Modular Structure** - Features organized in separate folders
3. **Shared Constants** - No more hard-coded values
4. **Design System** - Consistent UI across the app
5. **Form Validation** - Centralized validation logic

## Quick Reference

**Adding New Features:**
```plaintext

lib/modules/feature_name/
├── views/ # Screens
├── widgets/ # Feature-specific widgets
└── controllers/ # Feature controllers

````

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
