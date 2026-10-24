# Agent notes — We Monitor (Flutter app)

Flutter app for ASCOA (`com.ascoa.wemonitor`), GetX + Firebase (project `trash-monitoring-app-88131`).
Full reference: `PROJECT_MASTER-ASCOA.md` (one level up, outside this repo). Store/release guide: `APPSTORE_PUBLISHING.md`.

Current version: **1.1.1** (`pubspec.yaml` 1.1.1+11). 1.1.0 is live on Google Play and the App Store.

## Releasing a new version — required steps

1. Bump `version:` in `pubspec.yaml` (and `build-script.ps1`, which is gitignored).
2. Android: build the AAB locally and upload to Play Console (EN + FR notes, each ≤ 500 characters).
3. iOS: push to `main` → Xcode Cloud workflow **Default** archives and uploads to TestFlight. Submit the build in App Store Connect.
4. **When the new version is live in a store, update Firestore `config/app_version`.**
   Otherwise existing users never see the in-app "Update available" dialog
   (`lib/shared/services/update_service.dart` compares the installed version with this doc on launch).
   ```bash
   cd "../Firebase Functions/scripts"   # has firebase-admin installed
   node --input-type=module -e "import admin from 'firebase-admin'; admin.initializeApp({projectId:'trash-monitoring-app-88131'}); await admin.firestore().doc('config/app_version').set({android:{latest:'X.Y.Z'}, ios:{latest:'X.Y.Z'}}, {merge:true}); process.exit(0)"
   ```
   - `latest`: newest store version (dismissible prompt). `min`: oldest allowed version (forced prompt; raise only for breaking changes).
   - Update each platform only after its store shows the version. Needs `gcloud auth application-default login`.
5. Update `APPSTORE_PUBLISHING.md` (version header, What's New) and `PROJECT_MASTER-ASCOA.md` (§0, §13).

## Conventions

- All user-facing strings are translated: add keys to both EN and FR maps in `lib/shared/i18n/strings_*.dart`.
- Hive adapters (`*.g.dart`) are edited by hand when `build_runner` can't resolve; keep field numbers unique.
- Never commit `build-script.ps1`, `android/key.properties`, `android/app/key.jks` or `.env`.
- `ios/ci_scripts/*.sh` must keep LF line endings (enforced by `.gitattributes`).
- Run `flutter analyze` and `flutter test` before pushing.
