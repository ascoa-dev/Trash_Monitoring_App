# Store screenshots

Demo data on the **local Firebase emulators** (never production) → captured on Android emulators → framed with captions for Play and App Store. EN and FR, 1:1.

1. `npm install` and copy `firestore.rules` + `storage.rules` from `../../../Firebase Functions/` into `rules/` (once), then `firebase emulators:start --only auth,firestore,storage --project trash-monitoring-app-88131`
2. Seed: `FIRESTORE_EMULATOR_HOST=127.0.0.1:8085 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 FIREBASE_STORAGE_EMULATOR_HOST=127.0.0.1:9199 node seed.mjs`
   (wipes the emulators first; demo login `amina.demo@example.com` / `wemonitor2026`)
3. App: `flutter build apk --debug --dart-define=USE_EMULATOR=true`, install, then `adb reverse tcp:PORT tcp:PORT` for 8085, 9099, 9199.
4. Device size: phone = AVD `9_Pro_XL`; 7" = `adb shell wm size 1200x1920 && adb shell wm density 320`; 10" = `wm size 1600x2560`.
5. Capture: `./run.sh <phone|tablet_7> <en|fr>` covers most screens (10" positions not scripted yet; see the `case` block).
   The cleanup form is filled by hand, then `./cap.sh <device> <lang> 02_cleanup_items`. `./demo_bar.sh` gives a clean 9:41 status bar.
6. Frame: `python compose.py` → `../../store_screenshots/<play|apple>/<en|fr>/<slot>/`.

Captions and order are in `SHOTS` in `compose.py`. Output sizes: Play phone 1080×1920, 7" 1200×2133, 10" 1440×2560 (all 9:16); Apple iPhone 6.9" 1290×2796, iPad 13" 2064×2752.
