# Apple App Store Publishing Guide

> **Application Name**: We Monitor  
> **Bundle Identifier**: `com.ascoa.wemonitor`  
> **Current Version**: `1.1.0` (`pubspec.yaml` 1.1.0+10; iOS build numbers are assigned by Xcode Cloud, e.g. `1.1.0 (15)`)  
> **Previous Version**: `1.0.0 (9)`  
> **Repository Context**: `Trash_Monitoring_App`  
> **Primary Release Target**: Apple App Store & TestFlight (iOS / iPadOS)

---

## 📋 Table of Contents

1. [Commit Audit (Commits #34 to #5)](#-commit-audit-commits-34-to-5)
2. [iOS App Store What's New & Release Notes](#-ios-app-store-whats-new--release-notes)
   - [Release checklist (every new version)](#-release-checklist-every-new-version)
3. [App Store Connect Metadata & Product Page Settings](#-app-store-connect-metadata--product-page-settings)
4. [App Store Screenshot & Visual Asset Master Guide](#-app-store-screenshot--visual-asset-master-guide)
   - [Required Screenshot Sizes & Resolutions](#1-required-screenshot-sizes--resolutions)
   - [Step-by-Step: How to Capture & Generate Screenshots](#2-step-by-step-how-to-capture--generate-screenshots)
   - [Recommended 5-Screenshot Store Flow](#3-recommended-5-screenshot-store-flow)
5. [Xcode & Apple Developer Portal Settings](#-xcode--apple-developer-portal-settings)
   - [App ID & Entitlements](#1-app-id--entitlements)
   - [Info.plist Privacy Keys Audit](#2-infoplist-privacy-keys-audit)
   - [Apple Social Login Requirement (Guideline 4.8)](#3-apple-social-login-requirement-guideline-48)
6. [iOS Build, IPA Archive & Upload Instructions](#-ios-build-ipa-archive--upload-instructions)
   - [Xcode Cloud (current method, no Mac needed)](#0-xcode-cloud-current-method-no-mac-needed)
   - [Build Preparation & Dart Defines](#1-build-preparation--dart-defines)
   - [Building the Release IPA (CLI Method)](#2-building-the-release-ipa-cli-method)
   - [Xcode GUI Archiving & Upload Method](#3-xcode-gui-archiving--upload-method)
   - [Transporter App Upload Method](#4-transporter-app-upload-method)
7. [App Privacy Nutrition Label Declaration](#-app-privacy-nutrition-label-declaration)
8. [Export Compliance & Encryption Declaration](#-export-compliance--encryption-declaration)
9. [TestFlight Beta Testing & App Store Review Submission Checklist](#-testflight-beta-testing--app-store-review-submission-checklist)

---

## 🔍 Commit Audit (Commits #34 to #5)

Below is the technical audit of recent repository changes in `Trash_Monitoring_App` and their iOS release impact:

| Commit Hash | Author        | Commit Message / Focus Area                                                     | iOS & App Store Impact                                                                                                                                                                                   |
| :---------- | :------------ | :------------------------------------------------------------------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `7ed88da`   | Rohith Rathod | `Removed .env from pubspec`                                                     | Removed static `.env` bundling from app package; migrated config to runtime `--dart-define` environment variables for iOS builds.                                                                        |
| `b4f2f3b`   | Rohith Rathod | `.env error fixed now CI/CD will use dart command and local will use .env`      | Production iOS release builds consume keys injected via `flutter build ipa --dart-define-from-file=.env`.                                                                                               |
| `e4a2aaf`   | Rohith Rathod | `Github workflow fix1`                                                          | Prepared automated workflow definitions for iOS artifact archiving.                                                                                                                                      |
| `8100739`   | Rohith Rathod | `Changed the release workflow to comnoco...`                                    | CI pipeline dependency updates.                                                                                                                                                                          |
| `12e8049`   | Rohith Rathod | `Rollback to default github action for release`                                 | Pipeline stabilization.                                                                                                                                                                                  |
| `edf694a`   | Rohith Rathod | `Migrated the workflow to the new one`                                          | Streamlined automated build stages.                                                                                                                                                                      |
| `7fb35e1`   | Rohith Rathod | `Improve UX and fix visual issues across login, stats, map, and news screens`   | • `AuthGate` prevents white screen blinks during auto-login resolution.<br>• Clean Google Maps marker rendering on Retina screens.<br>• Enhanced waste chart tooltip behavior on iOS touch screens.     |
| `cf081ca`   | Rohith Rathod | `Removed the feature branch from the github build workflow`                     | Restricted TestFlight/App Store automated builds strictly to the `main` production branch.                                                                                                              |
| `4b8f58a`   | rohith0110    | `Improved offline support and added analytics`                                  | • Integrated `FirebaseAnalytics` & `FirebaseCrashlytics` iOS SDKs.<br>• Hive local storage caching for offline cleanup submissions & user profile.                                                     |
| `2549066`   | rohith0110    | `Set Up proper Testing CI pipeline for non main branches...`                    | PR test build validation pipeline.                                                                                                                                                                       |
| `25049d5`   | rohith0110    | `Renamed workflow`                                                              | Workflow maintenance.                                                                                                                                                                                    |
| `6846578`   | rohith0110    | `fix(auth): OAuth verification bypass and centralized snackbar system`          | • OAuth (Google/Apple) users bypass manual email verification block.<br>• Centralized iOS toast/snackbar alerts using `top_snackbar_flutter`.                                                            |
| `1d3a173`   | Rohith Rathod | `Update gradle.properties`                                                      | Build property optimization.                                                                                                                                                                             |
| `f4f5eb1`   | Rohith Rathod | `Update flutter_CI_debug.yaml`                                                  | Debug workflow setup.                                                                                                                                                                                    |
| `63716ba`   | rohith0110    | `massive overhaul`                                                              | Full architecture refactoring to GetX structure across controllers, bindings, and views.                                                                                                               |
| `99395ee`   | rohith0110    | `merge conflict`                                                                | Core module consolidation.                                                                                                                                                                               |
| `f9b0d81`   | rohith0110    | `Changed the flutter version in the Ci workflows`                               | Xcode & SDK compatibility upgrade.                                                                                                                                                                       |
| `3b3824f`   | rohith0110    | `removed hardcoded jdk path`                                                    | Environment path fix.                                                                                                                                                                                    |
| `53f7f14`   | rohith0110    | `migrated github actions to v5`                                                 | CI action version upgrade.                                                                                                                                                                               |
| `5b5fe8e`   | ascoa-dev     | `Merge pull request #7 from ascoa-dev/feature/stats-screen-and-offline-support` | Merged full stats screen analytics and offline persistence engine.                                                                                                                                       |
| `f77449b`   | rohith0110    | `admin adding functionality and fixed the map bounds`                           | • Admin role management UI.<br>• Fixed Google Maps auto-fit camera bounds logic for waste markers.                                                                                                       |
| `4ac7dc3`   | rohith0110    | `news section overhaul`                                                         | Redesigned News section with skeleton loading cards, article view, and live update feeds.                                                                                                                |
| `2c3316f`   | rohith0110    | `App name and all other things related to it changed`                           | • Rebranded app to **We Monitor**.<br>• Bundle Identifier set to `com.ascoa.wemonitor`.<br>• Updated `GoogleService-Info.plist` & Xcode project configuration.                                            |
| `0b44949`   | rohith0110    | `Perfected the logo`                                                            | High-definition app launcher icon & iOS storyboard asset (`assets/ASCOA/Icon.png`).                                                                                                                     |
| `025b6ca`   | rohith0110    | `github CI fix`                                                                 | Artifact pipeline fix.                                                                                                                                                                                   |
| `8f9afc9`   | rohith0110    | `map clustering`                                                                | Implemented Google Maps marker clustering algorithm for dense waste hotspots.                                                                                                                            |
| `380e03e`   | rohith0110    | `minify and shrinking enabled`                                                  | Release build optimizations.                                                                                                                                                                             |
| `e8350e7`   | rohith0110    | `publishing changes`                                                            | Release configuration finalization.                                                                                                                                                                      |
| `8b7099f`   | rohith0110    | `Version change and made changes to the git actions workflows`                  | Updated release version tag `1.0.0+9`.                                                                                                                                                                   |

---

## 📱 iOS App Store What's New & Release Notes

Copy and paste into **"What's New in This Version"** in App Store Connect (Version `1.1.0`). Add each language separately.

**English (U.S.)**

```text
• Full French translation – switch language anytime
• Weekly streaks: log a cleanup or report a hotspot each week to keep yours going
• Offline uploads now sync automatically and resume where they stopped, with no duplicates
• Hotspot reports can be saved offline too
• You're told if a saved photo has gone missing; the rest still upload
• Clearer achievement progress bars
• Bug fixes and performance improvements
```

**French**

```text
• Application entièrement traduite en français
• Séries hebdomadaires : un nettoyage ou un point noir par semaine pour garder votre série
• Envois hors ligne automatiques, reprise là où ils s'étaient arrêtés, sans doublons
• Points noirs enregistrables hors ligne
• Alerte si une photo a disparu, les autres sont envoyées
• Barres de progression des succès plus claires
• Corrections de bugs
```

(Google Play limits each language to 500 characters; the French text above is 417.)

<details>
<summary>Previous: 1.0.0 notes</summary>


```text
What's New in We Monitor 1.0.0:

• Interactive Waste Mapping: Locate cleanup drives and report waste hotspots with smart map clustering.
• Detailed Environmental Analytics: Track collected weight, waste breakdown, and community impact metrics.
• Offline Reporting Mode: Record cleanups and geotag photos anywhere; data auto-syncs when online.
• Account Management & Deletion: In-app account management including streamlined account deletion options.
• Full-Screen Photo Inspector: Zoom and examine cleanup site photos in high definition.
• Social Authentication: Quick and secure sign-in with Apple and Google accounts.
```

</details>

---

## ✅ Release checklist (every new version)

1. Bump `version:` in `pubspec.yaml` (e.g. `1.1.0+10` → `1.2.0+11`). The version name is what users see; Android needs a higher build number every upload. Keep `build-script.ps1` in sync.
2. **Android:** build the AAB locally (`build-script.ps1` with `appbundle`), upload to Play Console with EN + FR notes (each ≤ 500 chars).
3. **iOS:** push to `main` (or start a build in App Store Connect → Xcode Cloud). The Default workflow archives, prepares for App Store Connect and uploads to TestFlight. Then create the version in App Store Connect, pick the build, add What's New (EN + FR) and submit for review.
4. **After the version is live in each store, update Firestore `config/app_version`** so the in-app update dialog appears:
   ```bash
   cd "Firebase Functions/scripts"
   node --input-type=module -e "import admin from 'firebase-admin'; admin.initializeApp({projectId:'trash-monitoring-app-88131'}); await admin.firestore().doc('config/app_version').set({android:{latest:'X.Y.Z'}, ios:{latest:'X.Y.Z'}}, {merge:true}); process.exit(0)"
   ```
   - `latest` = newest store version → users below it get a dismissible "Update available" dialog.
   - `min` = oldest version still allowed → users below it get a dialog they cannot dismiss. Raise it only for breaking changes.
   - Set each platform only once its store actually shows the new version, otherwise users are sent to a store page without the update.
   - Needs `gcloud auth application-default login` once.
5. Update `PROJECT_MASTER-ASCOA.md` (§0 What's New, §13 cheat sheet) and this file's version header.

---

## 🏪 App Store Connect Metadata & Product Page Settings

Navigate to **App Store Connect** > **My Apps** > **We Monitor** > **App Store Version (1.1.0)** and configure every field exactly as specified below:

### 📌 General Information

- **App Name** *(Max 30 characters)*:  
  `We Monitor`

- **Subtitle** *(Max 30 characters)*:  
  `Track & Clean Environmental Waste`

- **Bundle ID**:  
  `com.ascoa.wemonitor`

- **Primary Category**:  
  `Utilities` *(or `Lifestyle`)*

- **Secondary Category**:  
  `Productivity`

- **Content Rights**:  
  Does not contain third-party content, or all required rights have been obtained.

- **Age Rating / Content Rating Questionnaire Answers**:
  - Unrestricted Web Access: **No**
  - Gambling / Contests: **No**
  - Alcohol, Tobacco, or Drug Use Reference: **No**
  - Medical / Treatment Information: **No**
  - Sexual Content / Nudity: **No**
  - Violent Content: **No**
  - Profanity / Crude Humor: **No**
  - *Result*: **4+** (or **9+** for Infrequent/Mild News/User-Generated Content).

---

### 🔍 Search & Optimization

- **Keywords** *(Max 100 characters total, comma-separated, NO spaces after commas to save space)*:  
  `waste tracker,ocean cleanup,plastic pollution,environmental action,ascoa,trash monitoring,clean community`  
  *(Exact character count: 99 characters)*

---

### 🌐 Links & Contact Information

- **Support URL**:  
  `https://app.ascoa-cm.org`

- **Marketing URL**:  
  `https://app.ascoa-cm.org`

- **Privacy Policy URL**:  
  `https://app.ascoa-cm.org/privacy-policy`

---

### 📄 Full Description *(Max 4,000 characters)*

```text
Welcome to We Monitor – the official environmental action and trash tracking platform powered by ASCOA (Autonomous Security Organization for Plastic and Environmental Protection).

We Monitor empowers volunteers, environmental advocates, and community leaders to map, track, and eliminate plastic pollution and mismanaged waste in local communities worldwide.

Key Features:

🌍 INTERACTIVE MAP & WASTE CLUSTERING
Discover cleanup drives, report waste hotspots, and navigate high-density plastic pollution areas in real time. Smart map clustering ensures smooth visual navigation even in densely populated areas.

📊 IMPACT & WASTE STATISTICAL DASHBOARD
Visualize your environmental footprint! Monitor total weight collected, analyze material breakdowns (plastics, glass, metals, organic), and track collective community milestones with clear interactive charts.

📶 OFFLINE WORKFLOW SUPPORT
Working in remote coastal or rural areas with limited network connectivity? We Monitor allows you to log cleanup locations and geotag photos offline. Your data uploads automatically as soon as internet connectivity is restored.

📰 COMMUNITY NEWS & UPDATES
Stay informed with real-time environmental news, regional conservation policies, and ASCOA community stories right from inside the app.

🔐 SECURE & SEAMLESS AUTHENTICATION
Log in securely using Sign in with Apple, Google, or direct email registration. Manage your profile details, customize notification settings, or request account deletion easily within settings.

Join the Movement:
Whether organizing a beach cleanup, reporting illegal dumping, or auditing municipal waste data, We Monitor provides the tools you need to create a measurable, lasting environmental impact.

Download We Monitor today and help us create a cleaner, greener world!
```

---

### 📱 Promotional Text *(Max 170 characters, editable without a new release)*

```text
Join ASCOA in mapping and eliminating plastic pollution worldwide. Track cleanups, report waste hotspots, and view real-time environmental impact data today!
```

---

### 🧪 App Review Information (Mandatory for Review Team)

Apple human reviewers strictly test login, permissions, and core app features during submission.

- **Sign-In Required**: Check **Yes**.
- **Demo Account Credentials**:
  - **Username / Email**: `appstore.reviewer@ascoa-cm.org` *(Ensure this account is pre-created in Firebase Auth with verified status)*
  - **Password**: `<PROVIDE_SECURE_DEMO_PASSWORD>`
- **Contact Information**:
  - **First Name**: Rohith
  - **Last Name**: Rathod
  - **Phone Number**: `+1 (555) 019-2831` *(Provide active international phone number)*
  - **Email**: `dev@ascoa-cm.org`
- **Notes for Reviewer**:
  ```text
  Notes for App Reviewer:
  1. The demo credentials above grant access to a test user account with sample cleanup reports and waste hotspots already created on the interactive map.
  2. Location access is requested to pin waste hotspot coordinates and verify user proximity during cleanup logging.
  3. Camera & Photo Library access are required for users to photograph waste sites and update profile pictures.
  4. Account deletion is fully functional in App Settings > Request Account Deletion in compliance with Guideline 5.1.1(v).
  ```

---

## 🎨 App Store Screenshot & Visual Asset Master Guide

Apple enforces precise pixel dimensions and device aspect ratios. Images missing exact dimensions will be **rejected on upload**.

---

### 1. Required Screenshot Sizes & Resolutions

| Target Device Tier | Screen Size | Required Resolution (Portrait) | Aspect Ratio | Mandatory? | Recommended Device Simulator |
| :--- | :--- | :--- | :--- | :---: | :--- |
| **iPhone 6.7" Display** *(Latest Pro Max)* | 6.7 inch | **1290 x 2796 pixels** | 19.5:9 | **YES** | iPhone 16 Pro Max / 15 Pro Max |
| **iPhone 6.5" Display** *(Legacy Pro Max)* | 6.5 inch | **1242 x 2688 pixels** | 19.5:9 | **YES** | iPhone 11 Pro Max / XS Max |
| **iPhone 5.5" Display** *(Home Button)* | 5.5 inch | **1242 x 2208 pixels** | 16:9 | Optional | iPhone 8 Plus |
| **iPad 12.9" Display** *(6th Gen)* | 12.9 inch | **2048 x 2732 pixels** | 4:3 | Optional | iPad Pro (12.9-inch) (6th generation) |

> [!IMPORTANT]
> If you upload 6.7" and 6.5" screenshots, App Store Connect will automatically scale them down for smaller iPhone screen sizes (6.1", 5.8", 4.7"). Capturing **6.7" (1290x2796)** and **6.5" (1242x2688)** is the fastest way to cover all iPhones!

---

### 2. Step-by-Step: How to Capture & Generate Screenshots

#### Method A: Command Line Simulator Capture (Fastest & Most Accurate)

1. Open Xcode on macOS and boot the target iPhone Simulators:
   ```bash
   # List installed simulators
   xcrun simctl list devices
   
   # Boot iPhone 16 Pro Max (for 6.7" Screenshots)
   xcrun simctl boot "iPhone 16 Pro Max"
   ```
2. Launch **We Monitor** on the booted simulator:
   ```bash
   flutter run -d "iPhone 16 Pro Max" --release --dart-define-from-file=.env
   ```
3. Navigate to each screen in the app and capture loss-less PNG screenshots directly via `simctl`:
   ```bash
   # Create screenshots directory
   mkdir -p assets/appstore_screenshots/6.7_inch
   
   # Capture Screen 1: Interactive Map
   xcrun simctl io booted screenshot assets/appstore_screenshots/6.7_inch/1_map.png
   
   # Capture Screen 2: Impact Dashboard
   xcrun simctl io booted screenshot assets/appstore_screenshots/6.7_inch/2_stats.png
   
   # Capture Screen 3: Offline Cleanup Logging
   xcrun simctl io booted screenshot assets/appstore_screenshots/6.7_inch/3_cleanup.png
   
   # Capture Screen 4: Community News
   xcrun simctl io booted screenshot assets/appstore_screenshots/6.7_inch/4_news.png
   
   # Capture Screen 5: Profile & Settings
   xcrun simctl io booted screenshot assets/appstore_screenshots/6.7_inch/5_profile.png
   ```

4. Repeat for **iPhone 11 Pro Max** simulator to generate `6.5_inch` screenshots (`1242 x 2688`).

---

#### Method B: Framing Screenshots with Marketing Cards (Professional App Store Presentation)

To make your screenshots look like top-ranking App Store apps:

1. Use canvas tools like **Figma**, **Appkoncept**, **AppLaunchpad**, or **MockuPhone**.
2. Create frame dimensions: `1290 x 2796 px`.
3. Add a background gradient matching ASCOA branding (Primary Green: `#2E7D32`, Background: `#FBFFF4` or `#0F172A`).
4. Place headline text at the top (36pt bold font, white/dark contrast).
5. Place the device screenshot inside an iPhone 16 Pro Max device frame at the bottom 75% of the image.
6. Export as **PNG (RGB, non-transparent)**.

---

### 3. Recommended 5-Screenshot Store Flow

| Slot | Headline Title | Screen Content to Display | Key Visual Elements |
| :---: | :--- | :--- | :--- |
| **1** | **"Track Waste Hotspots in Real-Time"** | Interactive Map View (`map_view.dart`) | Map markers, waste clusters, location pin, bottom stats card. |
| **2** | **"Visualize Community Environmental Impact"** | Statistical Dashboard (`stats_view.dart`) | Material collection pie chart, total weight counter, monthly trend graphs. |
| **3** | **"Log Cleanups Offline Anywhere"** | Cleanup Reporting Form (`new_cleanup_view.dart`) | Photo attach preview, waste type pickers, coordinates geotagging. |
| **4** | **"Stay Updated with ASCOA News"** | Community News Feed (`news_view.dart`) | Article cards, environmental updates, skeleton loaders. |
| **5** | **"Secure Account & Data Control"** | User Profile Settings (`profile_view.dart`) | Verified badge, profile details, quick account controls & privacy settings. |

---

## ⚙️ Xcode & Apple Developer Portal Settings

---

### 1. App ID & Entitlements

1. Log into [developer.apple.com](https://developer.apple.com) > **Certificates, Identifiers & Profiles** > **Identifiers**.
2. Click `+` and register App ID `com.ascoa.wemonitor`.
3. Enable the following **Capabilities**:
   - [x] **Sign In with Apple**
   - [x] **Associated Domains** *(Set domain: `applinks:app.ascoa-cm.org` for deep linking)*
   - [x] **Push Notifications** *(If Firebase Messaging is enabled)*

---

### 2. Info.plist Privacy Keys Audit

Apple requires explicit, user-friendly reasons for every requested permission in `ios/Runner/Info.plist`.

Verify that `ios/Runner/Info.plist` contains the exact strings below:

```xml
<key>NSCameraUsageDescription</key>
<string>We Monitor needs access to your camera to take photos of cleanups and update your profile picture.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>We Monitor needs access to your photo library to select photos for cleanups and profile pictures.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>ASCOA needs access to your location to mark cleanup sites on the map.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>ASCOA needs access to your location to mark cleanup sites on the map.</string>

<key>NSMicrophoneUsageDescription</key>
<string>We Monitor needs access to your microphone if capturing video reports.</string>
```

> [!WARNING]
> Generic descriptions like *"Needs camera access"* will cause an immediate rejection under **App Store Review Guideline 5.1.1**. Ensure every string explains the specific benefit to the user.

---

### 3. Apple Social Login Requirement (Guideline 4.8)

Because **We Monitor** supports third-party OAuth logins (Google Sign-In), **Sign in with Apple MUST be presented as an equivalent option on iOS**.

- Package verified in `pubspec.yaml`: `sign_in_with_apple: ^6.1.0`.
- Verify on iOS login screen (`login_view.dart`): The **"Sign in with Apple"** button must be visible, properly aligned, and functional on iOS builds.

---

## 🛠️ iOS Build, IPA Archive & Upload Instructions

Follow these exact commands on macOS with Xcode 15+ installed.

---

### 0. Xcode Cloud (current method, no Mac needed)

iOS builds run on **Xcode Cloud** (App Store Connect → Xcode Cloud → workflow **Default**):

- **Start condition:** changes on `main`. **Action:** Archive - iOS, Distribution Preparation **App Store Connect**. **Post-action:** TestFlight Internal Testing.
- **Environment variable:** `GOOGLE_MAPS_API_KEY` (mark it *Secret*).
- `ios/ci_scripts/ci_post_clone.sh` installs Flutter 3.44.2 and CocoaPods, creates an empty `.env`, runs `flutter build ios --config-only`, `pod install`, and writes `Package.resolved` (Xcode Cloud won't resolve Swift packages itself).
- `ios/Runner.xcworkspace` is committed (un-ignored in `.gitignore`); the Podfile forces every pod to iOS 15.0.
- Xcode Cloud assigns the **build number** (overrides `pubspec.yaml`'s `+N`); the **version** (1.1.0) comes from `pubspec.yaml`.
- Logs: build → Archive - iOS → Artifacts → *Logs for Runner archive*. Upload/validation errors (e.g. `90717` icon alpha) only show in App Store Connect → TestFlight → the failed build.

The sections below are the older manual (Mac) methods, kept for reference.

### 1. Build Preparation & Dart Defines

Run dependency cleanup and install iOS Pods:

```bash
# 1. Clean Flutter cache
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Navigate to iOS directory and update CocoaPods
cd ios
pod deintegrate
pod install --repo-update
cd ..
```

---

### 2. Building the Release IPA (CLI Method)

Build the unsigned/signed release bundle directly from terminal:

```bash
flutter build ipa --release \
  --build-name=1.1.0 \
  --build-number=<next build number> \
  --dart-define-from-file=.env \
  --export-options-plist=ios/ExportOptions.plist
```

> The output `.ipa` file will be generated at:  
> `build/ios/ipa/We Monitor.ipa`

---

### 3. Xcode GUI Archiving & Upload Method

If you prefer building through Xcode:

1. Open workspace in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. Select **Runner** in project navigator:
   - **General** > **Identity** > App Category: `Utilities`.
   - **Signing & Capabilities** > Select Team: `Autonomous Security Organization...`.
   - Select Provisioning Profile: `AppStore com.ascoa.wemonitor`.
3. Set build target device: **Any iOS Device (arm64)**.
4. Go to top menu: **Product** > **Archive**.
5. When build finishes, **Organizer window** automatically opens.
6. Click **Distribute App** > Select **App Store Connect** > **Upload**.
7. Keep standard options checked (*Strip Swift symbols*, *Manage Version and Build Number*).
8. Click **Upload**.

---

### 4. Transporter App Upload Method (Alternative)

If uploading directly from macOS without opening Xcode:

1. Download **Transporter** from the macOS Mac App Store.
2. Log in with your Apple ID / Developer Credentials.
3. Click `+` and select `build/ios/ipa/We Monitor.ipa`.
4. Click **Deliver**.

---

## 🔒 App Privacy Nutrition Label Declaration

When completing the mandatory **App Privacy Questionnaire** in App Store Connect, declare the following responses:

| Data Type | Data Category | Collected? | Linked to Identity? | Used for Tracking? | Primary Purpose |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **Contact Info** | Name, Email Address | **Yes** | **Yes** | **No** | App Functionality, Account Creation |
| **Location** | Precise Location | **Yes** | **Yes** | **No** | App Functionality (Tagging cleanup sites & hotspot map) |
| **User Content** | Photos / Photos | **Yes** | **Yes** | **No** | App Functionality (Cleanup site evidence & profile picture) |
| **Identifiers** | User ID / Device ID | **Yes** | **Yes** | **No** | App Functionality & Authentication |
| **Diagnostics** | Crash Logs, Performance | **Yes** | **No** | **No** | Analytics (Firebase Crashlytics & Analytics) |

- **Third-Party Data Tracking**: Select **"No, we do not track users across third-party apps or websites."**

---

## ⚖️ Export Compliance & Encryption Declaration

When App Store Connect asks about **Export Compliance Encryption**:

1. Question: *"Does your app use encryption?"*  
   - Select **YES**.
2. Question: *"Does your app qualify for exemptions under Category 5, Part 2?"*  
   - Select **YES** *(App Store uses standard HTTPS/TLS protocols via standard iOS framework libraries for Firebase and Google APIs)*.

> [!NOTE]
> Since 1.1.0, `ios/Runner/Info.plist` sets `ITSAppUsesNonExemptEncryption` to `false`, so App Store Connect no longer asks this question for each build.

---

## 🧪 TestFlight Beta Testing & App Store Review Submission Checklist

Before submitting **Version 1.1.0** (Xcode Cloud build) for final App Store Review:

### 1. TestFlight Internal & External Testing

- [x] Build uploaded to App Store Connect.
- [x] Added internal QA team to TestFlight internal group.
- [x] Verified login, location map pin drop, photo upload, and account deletion flows on physical iOS devices.

### 2. Final Submission Checklist

- [x] **Screenshots**: Uploaded 6.7" and 6.5" screenshots to App Store Connect.
- [x] **App Icon**: `1024x1024` PNG in `AppIcon.appiconset` with **no alpha channel** (fixed in 1.1.0 after error 90717; `remove_alpha_ios: true` in `pubspec.yaml` keeps regenerated icons opaque).
- [x] **Sign In with Apple**: Confirmed button visible and functional on iOS.
- [x] **Account Deletion**: Confirmed in-app deletion button works (`delete_request_screen.dart`).
- [x] **Reviewer Demo Credentials**: Valid credentials provided in App Review Information section.
- [x] **Copyright notice**: `© 2026 ASCOA. All rights reserved.`
- [x] Click **Save**, then click **Add for Review** > **Submit to App Review**.
- [ ] **After approval:** set Firestore `config/app_version.ios.latest` (see the release checklist above).

---

*Updated exclusively for Apple App Store & TestFlight publishing of We Monitor (ASCOA).*
