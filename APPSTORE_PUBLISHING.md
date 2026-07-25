# App Store & Google Play Store Publishing Guide

> **Application Name**: We Monitor  
> **Package Identifier**: `com.ascoa.wemonitor`  
> **Target Version**: `1.0.0+8` (Version Name: `1.0.0`, Build/Version Code: `8`)  
> **Repository Context**: `Trash_Monitoring_App`  
> **Primary Release Target**: Google Play Console (Android)

---

## 📋 Table of Contents

1. [Commit Audit (Commits #34 to #5)]
   (#commit-audit-commits-34-to-5)
2. [Android Release Changelog (Version 1.0.0+8)]
   (#android-release-changelog-version-1008)
3. [Google Play Store Listing Metadata]
   (#google-play-store-listing-metadata)
4. [App Store Graphic Asset Specifications]
   (#app-store-graphic-asset-specifications)
5. [Android Technical & Publishing Checklist]
   (#android-technical--publishing-checklist)
6. [Data Safety & Privacy Declarations]
   (#data-safety--privacy-declarations)

---

## 🔍 Commit Audit (Commits #34 to #5)

Below is the detailed analysis of changes introduced in commits 34 through 5 in the `Trash_Monitoring_App` git repository:

| Commit Hash | Author        | Commit Message / Focus Area                                                     | Android Impact & Summary                                                                                                                                                                                                                 |
| :---------- | :------------ | :------------------------------------------------------------------------------ | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `7ed88da`   | Rohith Rathod | `Removed .env from pubspec`                                                     | Removed static `.env` bundling from app package; migrated config to runtime environment variables.                                                                                                                                       |
| `b4f2f3b`   | Rohith Rathod | `.env error fixed now CI/CD will use dart command and local will use .env`      | CI/CD build scripts pass flags via `--dart-define` for secure key management in production release.                                                                                                                                      |
| `e4a2aaf`   | Rohith Rathod | `Github workflow fix1`                                                          | Adjusted release action parameters for Android APK/AAB build steps.                                                                                                                                                                      |
| `8100739`   | Rohith Rathod | `Changed the release workflow to comnoco...`                                    | Maintenance update for GitHub Actions release runner dependencies.                                                                                                                                                                       |
| `12e8049`   | Rohith Rathod | `Rollback to default github action for release`                                 | Stabilized release action workflow pipeline.                                                                                                                                                                                             |
| `edf694a`   | Rohith Rathod | `Migrated the workflow to the new one`                                          | Streamlined GitHub Actions build stages for release tags.                                                                                                                                                                                |
| `7fb35e1`   | Rohith Rathod | `Improve UX and fix visual issues across login, stats, map, and news screens`   | • Added AuthGate loading screen during login resolution.<br>• Enhanced waste chart tooltip dismiss behavior.<br>• Rendered high-res crisp Google Maps markers without pixelation.<br>• Made map interaction fully responsive.            |
| `cf081ca`   | Rohith Rathod | `Removed the feature branch from the github build workflow`                     | Restricted automated release builds strictly to production branch.                                                                                                                                                                       |
| `4b8f58a`   | rohith0110    | `Improved offline support and added analytics`                                  | • Integrated `FirebaseAnalytics` & `FirebaseCrashlytics` event tracking.<br>• Hive local storage caching for offline cleanup submissions & user profile.<br>• Added developer architecture guide (`DEVELOPER_GUIDE.md`).                 |
| `2549066`   | rohith0110    | `Set Up proper Testing CI pipeline for non main branches...`                    | Automated Play Store build verification pipeline for non-main pull requests.                                                                                                                                                             |
| `25049d5`   | rohith0110    | `Renamed workflow`                                                              | Renamed Flutter CI workflow configuration files.                                                                                                                                                                                         |
| `6846578`   | rohith0110    | `fix(auth): OAuth verification bypass and centralized snackbar system`          | • OAuth (Google/Facebook) users no longer blocked by email verification.<br>• Replaced ad-hoc snackbars with centralized `SnackbarService` & `SnackbarListener`.<br>• Enhanced Auth screen visual aesthetics & "Can't log in?" help CTA. |
| `1d3a173`   | Rohith Rathod | `Update gradle.properties`                                                      | Android build system property tweaks for faster Gradle execution.                                                                                                                                                                        |
| `f4f5eb1`   | Rohith Rathod | `Update flutter_CI_debug.yaml`                                                  | Adjusted CI debug runner parameters.                                                                                                                                                                                                     |
| `63716ba`   | rohith0110    | `massive overhaul`                                                              | Comprehensive app architecture refactoring: updated views, bindings, and services for modular GetX pattern.                                                                                                                              |
| `99395ee`   | rohith0110    | `merge conflict`                                                                | Consolidated core feature modules.                                                                                                                                                                                                       |
| `f9b0d81`   | rohith0110    | `Changed the flutter version in the Ci workflows`                               | Upgraded Flutter toolchain in CI pipeline to match target SDK requirements.                                                                                                                                                              |
| `3b3824f`   | rohith0110    | `removed hardcoded jdk path`                                                    | Enabled flexible Java SDK paths for local & CI Android builds.                                                                                                                                                                           |
| `53f7f14`   | rohith0110    | `migrated github actions to v5`                                                 | Updated GitHub Action dependencies to v5.                                                                                                                                                                                                |
| `5b5fe8e`   | ascoa-dev     | `Merge pull request #7 from ascoa-dev/feature/stats-screen-and-offline-support` | Merged full stats screen analytics and offline persistence engine.                                                                                                                                                                       |
| `f77449b`   | rohith0110    | `admin adding functionality and fixed the map bounds`                           | • Implemented admin user permission management screen.<br>• Fixed Google Map auto-fit camera bounds logic for waste markers.                                                                                                             |
| `4ac7dc3`   | rohith0110    | `news section overhaul`                                                         | Redesigned News section with skeleton loading cards, article view, and live update feeds.                                                                                                                                                |
| `2c3316f`   | rohith0110    | `App name and all other things related to it changed`                           | • Rebranded app to **We Monitor**.<br>• Package identifier set to `com.ascoa.wemonitor`.<br>• Updated `google-services.json`, `AndroidManifest.xml`, and Kotlin package structure.                                                       |
| `0b44949`   | rohith0110    | `Perfected the logo`                                                            | Updated high-definition app launcher icon & Android 12+ native splash screen asset (`assets/ASCOA/Icon.png`).                                                                                                                            |
| `025b6ca`   | rohith0110    | `github CI fix`                                                                 | Fixed GitHub workflow artifact generation.                                                                                                                                                                                               |
| `8f9afc9`   | rohith0110    | `map clustering`                                                                | Implemented Google Maps marker clustering algorithm for dense waste hotspots.                                                                                                                                                            |
| `380e03e`   | rohith0110    | `minify and shrinking enabled`                                                  | Enabled R8 code minification (`isMinifyEnabled = true`) & resource shrinking (`isShrinkResources = true`) in `android/app/build.gradle.kts` for optimized APK size.                                                                      |
| `e8350e7`   | rohith0110    | `publishing changes`                                                            | Finalized release build configurations.                                                                                                                                                                                                  |
| `7e3e44f`   | rohith0110    | `Too many changes to list here`                                                 | Modular updates across cleanup forms, profile editing, and hotspot reporting modules.                                                                                                                                                    |
| `8b7099f`   | rohith0110    | `Version change and made changes to the git actions workflows`                  | Prepared release version tag `1.0.0+8`.                                                                                                                                                                                                  |

---

## 📱 Android Release Changelog (Version 1.0.0+8)

_This changelog strictly covers user-facing Android features introduced in the latest 4 commits (Build `1.0.0+8`). Dev/CI pipeline changes, backend config refreshes, and iOS-specific updates have been filtered out._

### ⚡ Google Play Console Ready Snippet (< 500 chars)

```xml
<en-US>
What's New in We Monitor v1.0.0 (Build 8):

• Account Deletion Request: Added option to request account deletion directly from settings.
• Full-Screen Photo Viewer: Tap to view cleanup and waste hotspot photos in high-resolution mode.
• Detail Screen Enhancements: Improved image previews and performance on cleanup & hotspot details.
</en-US>
```

_(Character Count: **351 characters** — well within the 500-character Play Console limit)_

---

### 🌟 Android User Features (Last 4 Commits)

- **In-App Account Deletion Request**: Added a dedicated account deletion flow (`delete_request_screen.dart`) accessible from profile settings.
- **Full-Screen Photo Viewer**: Added an interactive full-screen image viewer (`fullscreen_image_viewer.dart`) allowing users to pinch, zoom, and inspect cleanup and waste hotspot images.
- **Cleanup & Hotspot Detail Enhancements**: Improved photo section rendering and detail screen performance for logged cleanup activities and reported waste hotspots.

---

## 🏪 Google Play Store Listing Metadata

Copy and paste these exact text blocks into your **Google Play Console** product details form.

### 📌 Basic Details

- **App Name** _(Max 30 characters)_:  
  `We Monitor`

- **Short Description** _(Max 80 characters)_:  
  `Empower communities to track, report, and clean up environmental waste.`

- **App Category**:  
  `Tools` _(Secondary: `Environment` / `Productivity`)_

- **Tags / Keywords**:  
  `Environmental Cleanup, Waste Management, Ocean Cleanup, Community Action, ASCOA, Trash Tracker, Pollution Control`

---

### 📄 Full Description _(Max 4,000 characters)_

```text
Welcome to We Monitor – the official environmental action and trash tracking platform powered by ASCOA (Autonomous Security Organization for Plastic and Environmental Protection).

We Monitor connects volunteers, environmental advocates, and community leaders to log, track, and eliminate plastic pollution and mismanaged waste in local communities.

Key Features:

🌍 INTERACTIVE MAP & WASTE CLUSTERING
Discover cleanup drives, report waste hotspots, and track high-density plastic pollution areas in real-time. Smart map clustering makes navigating large data sets easy and intuitive.

📊 IMPACT & WASTE STATISTICAL DASHBOARD
Visualize your environmental contributions! Monitor total weight collected, breakdown of waste materials (plastics, glass, metals, organic), and track community milestones with rich interactive charts.

📶 OFFLINE WORKFLOW SUPPORT
Working in remote areas with limited connectivity? We Monitor allows you to record cleanup locations and photos offline. Your data automatically uploads as soon as your internet connection is restored.

📰 COMMUNITY NEWS & UPDATES
Stay informed with the latest environmental news, regional policy updates, and ASCOA community stories right inside the app.

🔐 SECURE & SEAMLESS AUTHENTICATION
Log in effortlessly using email or social accounts (Google/Facebook). Manage your user profile, update credentials, and stay connected with community leaders.

Join the Movement:
Whether you are organizing a beach cleanup, reporting illegal dumping, or tracking community waste metrics, We Monitor provides the tools you need to make a measurable difference.

Download We Monitor today and help us create a cleaner, greener world!
```

---

## 🎨 App Store Graphic Asset Specifications

Prepare the following visual assets prior to publishing on the Play Console:

| Asset Type                     | Specifications & Dimensions                                                                                                            | Required | Purpose                                                                                 |
| :----------------------------- | :------------------------------------------------------------------------------------------------------------------------------------- | :------: | :-------------------------------------------------------------------------------------- |
| **App Icon**                   | • 512 x 512 pixels<br>• 32-bit PNG with alpha channel<br>• Max file size: 1024 KB                                                      | **Yes**  | Displays on Play Store search results & app home screen. (Use `assets/ASCOA/Icon.png`). |
| **Feature Graphic**            | • 1024 x 500 pixels<br>• PNG or JPEG<br>• Max file size: 15 MB                                                                         | **Yes**  | Banner image featured at the top of your store listing.                                 |
| **Phone Screenshots**          | • Minimum 2 screenshots, maximum 8<br>• 16:9 or 9:16 aspect ratio<br>• Side dimensions: Min 320px, Max 3840px<br>• Format: PNG or JPEG | **Yes**  | Highlight key screens: Map, Waste Stats, Cleanup Log Form, News Feed.                   |
| **7-Inch Tablet Screenshots**  | • 16:9 or 9:16 aspect ratio<br>• Format: PNG or JPEG                                                                                   | Optional | Displays listing layout on small tablets.                                               |
| **10-Inch Tablet Screenshots** | • 16:9 or 9:16 aspect ratio<br>• Format: PNG or JPEG                                                                                   | Optional | Displays listing layout on large tablets.                                               |

---

## ⚙️ Android Technical & Publishing Checklist

Before uploading `app-release.aab` to Google Play Console:

### 1. Build & Package Configuration

- [x] **Application ID**: Verified as `com.ascoa.wemonitor` in `android/app/build.gradle.kts`.
- [x] **Version Code & Name**: Set to `versionCode = 8` and `versionName = "1.0.0"` in `pubspec.yaml` (`1.0.0+8`).
- [x] **Min SDK**: Set to Flutter default (`minSdk = 21` / Android 5.0 Lollipop).
- [x] **Target SDK**: Set to latest stable Flutter target SDK (API 34/35).
- [x] **R8 Shrinking**: Confirmed `isMinifyEnabled = true` and `isShrinkResources = true` in `release` build block.

### 2. Android Manifest & Permissions (`android/app/src/main/AndroidManifest.xml`)

- [x] `android.permission.INTERNET` (Cloud data sync & API interaction)
- [x] `android.permission.ACCESS_NETWORK_STATE` (Connectivity check for offline mode)
- [x] `android.permission.ACCESS_FINE_LOCATION` (GPS hotspot mapping & cleanup entry locations)
- [x] `android.permission.ACCESS_COARSE_LOCATION` (Cellular/Wi-Fi location fallback)
- [x] **Google Maps API Key**: Embedded in `<meta-data android:name="com.google.android.geo.API_KEY" .../>`.
- [x] **Deep Linking Filter**: Configured auto-verify host `app.ascoa-cm.org` for auth/password reset actions.

### 3. Signing Keystore & Release Command

Ensure your signing properties are placed in `android/key.properties` or set via environment variables:

```properties
storeFile=key.jks
storePassword=<YOUR_KEYSTORE_PASSWORD>
keyAlias=<YOUR_KEY_ALIAS>
keyPassword=<YOUR_KEY_PASSWORD>
```

Build the Android App Bundle (AAB) for Google Play upload:

```bash
flutter build aab --release --build-name=1.0.0 --build-number=8
```

The output file will be located at:
`build/app/outputs/bundle/release/app-release.aab`

---

## 🔒 Data Safety & Privacy Declarations

When completing the **Data Safety Questionnaire** in Google Play Console, declare the following:

1. **Location Data**:
   - **Collected**: Yes (Precise & Approximate Location).
   - **Purpose**: App functionality (mapping waste hotspots and tagging cleanup locations).
   - **Ephemeral / Optional**: Location is requested when adding entries or viewing nearby maps.

2. **Personal Information**:
   - **Collected**: Name, Email Address, User ID.
   - **Purpose**: Account management, user identification, and administrative access control.

3. **Photos & Images**:
   - **Collected**: Photos uploaded during trash reporting/cleanup verification.
   - **Purpose**: App functionality & community reporting.

4. **Security Practices**:
   - Data is encrypted in transit using HTTPS/TLS.
   - Users can request account and data deletion via profile/support.

5. **Privacy Policy Link**:  
   `https://app.ascoa-cm.org/privacy-policy` _(or official ASCOA website privacy URL)_

---

_Created automatically for We Monitor (ASCOA) release planning._
