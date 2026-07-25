# Flutter → iOS App Store: Complete Publishing Guide

*Current as of July 2026. Confidence tags: [Certain] = verified against Apple's own docs, [Likely] = confirmed by multiple current sources but not Apple's primary docs, [Guessing] = my best inference, verify yourself.*

---

## 0. The thing that blocks everything else

As of **April 28, 2026**, Apple requires every new app and every app update uploaded to App Store Connect to be built with **Xcode 26 or later**, using the **iOS 26 SDK or later** [Certain]. This is not about your app's minimum supported iOS version (deployment target) — it's about which SDK Xcode used to *build* it. Builds made with older Xcode versions get rejected at upload with an error like `ITMS-90725`.

For Flutter specifically: you need **Flutter 3.38 or newer** for reliable Xcode 26 support [Likely]. Older Flutter versions can fail to build against the iOS 26 SDK, or build but crash on launch due to a UIKit scene-lifecycle change Apple is pushing apps toward [Likely].

**Before you do anything below, run this and confirm the numbers:**

```bash
flutter --version
xcodebuild -version
```

You want Flutter 3.38+ and Xcode 26.x. If you're behind, update Xcode via the App Store (or developer.apple.com/download) and update Flutter (`flutter upgrade` or reinstall) before continuing. If your project was created a while ago and you get a null-check/xcode_backend.dart type build error after upgrading, that's a known friction point between older Flutter iOS templates and Xcode 26.2 specifically — the fix is usually running `flutter clean`, deleting `ios/Pods` and `ios/Podfile.lock`, then `pod install` again inside `ios/` [Likely].

---

## 1. What you already have vs. what's still missing

You said you have: Flutter app running, tested on a real device via release build, paid Apple Developer account, signing logged in with "Automatic managing" enabled.

That covers device testing and your account. It does **not** yet cover:

- Toolchain version compliance (see §0)
- A registered Bundle ID and App Store Connect app record
- App icon at the exact spec
- Screenshots at exact pixel dimensions
- Privacy manifest / App Privacy questionnaire
- Age rating questionnaire (new system, more on this below)
- Export compliance answer
- Store listing text (description, keywords, etc.)
- A privacy policy URL (required even for the simplest app)
- An actual release archive uploaded through App Store Connect (device testing via `flutter run --release` is not the same pipeline as an App Store archive)

That gap is the rest of this document.

---

## 2. Apple Developer Portal: confirm your Bundle ID

1. Go to `developer.apple.com/account` → **Certificates, Identifiers & Profiles** → **Identifiers**.
2. Check whether your app's Bundle ID already exists here. In Xcode, open `ios/Runner.xcworkspace`, select the **Runner** target → **General** tab → **Bundle Identifier**. It'll look like `com.yourcompany.appname`.
3. If it's not registered yet, click **+** in the portal, choose **App IDs** → **App**, enter a description and that exact bundle ID, enable any capabilities you use (Push Notifications, Sign in with Apple, In-App Purchase, etc. — only check what your app actually uses), and register it.
4. Since you have "Automatic managing" on in Xcode, Xcode will handle creating your Distribution Certificate and Provisioning Profile automatically the first time you archive for App Store distribution — but this only works cleanly if your Apple ID has **Admin** or **App Manager** role on the team in App Store Connect. If you're the sole developer on your own paid account, you're fine. If this is a team/company account and you were added later, confirm your role, or the archive step will silently fail to find a valid signing identity.

---

## 3. App Store Connect: create the app record

1. Go to `appstoreconnect.apple.com` → **Apps** → **+** → **New App**.
2. Platform: **iOS**.
3. Name: your public app name (up to 30 characters, must be unique across the entire App Store — check availability first, Apple will reject a duplicate at submission).
4. Primary language.
5. Bundle ID: select the one you registered in §2.
6. SKU: an internal-only identifier, not shown to users. Convention: your bundle ID or something like `appname001`.
7. User Access: leave as Full Access unless you're on a team.

This creates the app record (in "Prepare for Submission" state) where everything else in this guide gets filled in.

---

## 4. Get a privacy policy URL sorted now

You need a hosted, publicly accessible privacy policy URL before you can submit — this is required for essentially every app now, not just ones with logins, because Apple treats crash reporting, analytics, and even basic device identifiers as data collection that needs disclosure [Likely].

Fastest free options if you don't already have a website:

- A GitHub Pages page (free, one static HTML file)
- A Notion page published publicly
- Google Sites

It needs to describe, in plain terms, what data your app collects (even "none" is a valid answer) and how it's used. Keep it simple and accurate — App Review does check that the App Privacy questionnaire answers (§9) match what's actually on this page.

---

## 5. Xcode project configuration

Open `ios/Runner.xcworkspace` (not `.xcodeproj`) in Xcode.

**Version numbers.** Flutter reads these from `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

`1.0.0` is the user-facing version (`CFBundleShortVersionString`), `1` is the build number (`CFBundleVersion`). Every single upload to App Store Connect needs a unique, incrementing build number — you can't re-upload build `1` twice, even for the same version string [Certain, per Apple's own build upload behavior]. Bump the number after the `+` each time you upload.

**Permissions (Info.plist).** If your app uses any of these, you need a usage-description string in `ios/Runner/Info.plist`, or Apple rejects it on review and it can also crash at runtime when the OS tries to show a permission prompt with no text:

```xml
<key>NSCameraUsageDescription</key>
<string>This app uses the camera to let you scan documents.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app accesses your photos so you can attach images.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app uses your location to show nearby results.</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app uses the microphone to record audio notes.</string>
```

Only add the keys for permissions you actually request. Each string should say specifically *why*, not just restate the permission name — Apple rejects vague ones like "We need your location."

**Privacy manifest.** Since May 2024, Apple requires a `PrivacyInfo.xcprivacy` file if your app or any bundled SDK uses a "Required Reason API" (things like UserDefaults, file timestamps, disk space checks, system boot time) [Certain]. Good news for Flutter: most actively-maintained plugins on pub.dev now ship their own privacy manifest bundled in, so a lot of this is handled for you automatically by Xcode merging manifests at build time. What you should still do:

1. In Xcode: File → New → File → scroll to **Resource** → **App Privacy File** → name it `PrivacyInfo.xcprivacy`, add it to the Runner target.
2. Declare what your own app code (not plugins) actually does — if you use `shared_preferences` or similar, that's UserDefaults, and you'd declare the standard "app functionality" reason.
3. Before submitting, check each third-party plugin in your `pubspec.yaml` for an outdated version — plugins that haven't been updated since mid-2024 may be missing their own manifest and could trigger a rejection or an ITMS warning at upload.

**Export compliance shortcut.** You'll get asked an encryption question on every upload unless you preempt it. If your app only uses standard HTTPS/TLS (the overwhelming majority of apps, including basically all Flutter apps unless you've deliberately bundled custom cryptography), add this to `Info.plist`:

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

This tells Apple upfront that you don't use non-exempt encryption, and skips the popup question at every future upload [Likely]. If you do use custom encryption (your own crypto, not just HTTPS), don't set this to false — you'd need to actually go through the real compliance questionnaire, which is out of scope for a first release and worth avoiding if you can.

---

## 6. App icon

- One master file: **1024×1024px**, PNG, **no transparency/alpha channel**, no rounded corners (the system applies rounding and, on iOS 26, a "Liquid Glass" glass effect automatically) [Certain for the 1024px/no-alpha spec, Likely for how iOS 26 renders it].
- In Xcode: select `Assets.xcassets` → `AppIcon` in the Runner folder, drag your 1024×1024 PNG into the App Store slot. Xcode auto-generates every smaller runtime size from this one file.
- Keep the design simple and bold. iOS 26's rendering adds depth/reflection effects on top of your flat icon, and busy or fine-detail icons can look muddy once that's applied [Likely]. If it looks fine in the simulator but you want to sanity-check across appearance modes, Xcode 26 ships a tool called **Icon Composer** (Xcode menu → Developer Tools) that previews your icon in the Liquid Glass context — optional, not required for submission.

---

## 7. Screenshots — exact specs

Pulled directly from Apple's current screenshot specification page [Certain]. You need at minimum one full set for iPhone. If you support iPad, you need a separate iPad set too — iPhone screenshots do **not** satisfy the iPad requirement.

| Device class | Screenshot size (portrait) | Requirement |
| --- | --- | --- |
| 6.9" iPhone (17 Pro Max, 16 Pro Max, 16 Plus, 15 Pro Max, 15 Plus, 14 Pro Max, Air) | 1320×2868 (or 1290×2796 or 1260×2736 depending on exact model) | This is the primary set Apple wants |
| 6.5" iPhone (14 Plus, 13/12/11 Pro Max, 11, XS Max, XR) | 1284×2778 or 1242×2688 | Required only if you don't provide the 6.9" set |
| 13" iPad (Pro M5/M4, Air M4/M3/M2) | 2064×2752 or 2048×2732 | Required if your app supports iPad at all |

Format: JPEG or PNG, **no alpha channel/transparency** [Certain]. Max 10 screenshots per localization, minimum 1.

**How to actually get these:**

1. Run your app in the iOS Simulator on an **iPhone 16 Pro Max** (or 17 Pro Max/Air) simulator specifically — simulator screenshots come out at the device's native pixel resolution automatically.
2. Navigate to the screen you want, then `Cmd+S` in the Simulator app (or Simulator menu → File → Save Screenshot). It saves straight to your Desktop at the correct pixel size.
3. Do the same on an iPad Pro simulator if you support iPad.
4. Don't just screenshot raw app UI and call it done — the best-converting App Store screenshots overlay a short caption per screenshot ("Track your spending in seconds", etc.) on top of real app UI. You can do this in Figma/Canva/Keynote by placing your raw screenshot inside a phone frame with text above or below it, then exporting the whole composition back out at the exact same pixel dimensions.
5. Your **first 3 screenshots matter most** — that's what's visible in search results before a user scrolls, and it's what most people base their download decision on [Likely]. Lead with your strongest, most self-explanatory screen.
6. Show your actual app. Apple's guidelines expect real in-app content, not marketing mockups of screens that don't exist.

Upload these under **App Store Connect → your app → the version you're preparing → Media Manager / Screenshots**.

---

## 8. App preview video (optional, skip for v1)

Not required. 15–30 seconds, H.264 or ProRes 422, `.mov`/`.m4v`/`.mp4`, must be actual footage from inside the app (no narration-over-mockup). I'd skip this for a first release — it adds real production time for a conversion lift that matters more once you already have installs to optimize against.

---

## 9. Writing the actual store listing

Fields you'll fill in under **App Information** and the version page in App Store Connect:

- **App Name** (30 char max): what shows under the icon everywhere. Front-load your most important word/keyword since it gets truncated on smaller displays.
- **Subtitle** (30 char max): appears right under the name in search results. This is prime real estate — use it to say what the app *does*, not a slogan. E.g. name "Ledger" + subtitle "Simple expense tracker", not subtitle "Your money, your way."
- **Promotional Text** (170 char max): shown above the description, and — unlike the description — you can edit this anytime **without** triggering a new App Review. Use it for anything time-sensitive (a current sale, a new feature you just shipped).
- **Description** (4000 char max): the full pitch. The first 2-3 sentences are what shows before "more" on the product page, so put your strongest value proposition there, not a generic intro. Then use short paragraphs or a bullet list of concrete features rather than dense marketing prose — people scan this, they don't read it top to bottom.
- **Keywords** (100 char max, comma-separated, no spaces after commas): this field is invisible to users but feeds App Store search. Don't repeat words already in your app name or subtitle (wasted characters, since those already count for search), don't use spaces you don't need, and don't stuff repeated variants — Apple's algorithm already handles basic pluralization.
- **Support URL** (required): a real page, even just a contact form or email-mailto page.
- **Marketing URL** (optional): your app's landing page if you have one.
- **Copyright**: usually `© 2026 Your Name/Company`.

---

## 10. App Privacy ("nutrition label")

Under **App Store Connect → your app → App Privacy**, answer the questionnaire about what data you collect: Contact Info, Health, Financial, Location, Browsing History, Identifiers, Usage Data, Diagnostics, etc. For each type you select, you also declare whether it's linked to the user's identity and whether it's used for tracking.

Be honest and match this to what your app and its third-party SDKs (crash reporting, analytics, ad SDKs if any) actually do. If you're not sure what an SDK collects, check its own privacy manifest documentation or its privacy policy page — App Review does spot-check this against your actual binary's network behavior, and a mismatch is a real, common rejection reason [Likely].

If your app collects genuinely nothing (no analytics, no accounts, fully offline), you select "Data Not Collected" and you're done with this section in under a minute.

---

## 11. Age rating questionnaire

Apple overhauled this system in 2025 [Certain]. It used to be 4+/9+/12+/17+. It's now **4+, 9+, 13+, 16+, 18+** [Certain]. Every app, including brand new submissions, now has to answer an expanded questionnaire covering:

- In-app parental controls
- App capabilities (does it have unrestricted web access, chat/messaging, user-generated content)
- Medical or wellness content
- Violent themes

Go to **App Store Connect → your app → App Information → Age Rating → Set Up Age Rating**, answer the 7-ish step questionnaire. Answer honestly and conservatively — an app with unmoderated user-generated content or open web access tends to get pushed to 13+ or higher automatically regardless of your intent [Likely]. Apple assigns the rating from your answers; you can only *raise* it afterward, not override downward.

---

## 12. Pricing and availability

Under **App Store Connect → your app → Pricing and Availability**:

- Pick a price tier (Free is a valid, common choice — you can add In-App Purchases later even on a free app).
- Choose which countries/regions to release in (default is all).
- If you're planning to monetize via IAP or subscriptions and expect under $1M/year in App Store revenue, opt into the **App Store Small Business Program** — it drops Apple's commission from 30% to 15% [Likely]. This is separate from your app submission and doesn't block anything, but worth doing before you have real revenue flowing since eligibility is checked going forward, not retroactively in every case.

---

## 13. Build the release archive

From your project root, with Xcode 26+ and Flutter 3.38+ confirmed (§0):

```bash
flutter clean
flutter pub get
flutter build ipa
```

This produces an `.xcarchive` at `build/ios/archive/` and an `.ipa` at `build/ios/ipa/`. For a first release, I'd skip `--obfuscate` — it makes crash reports harder to symbolicate and debug, and it's not worth the added risk on the release where you're least sure everything else works [Likely]. Add it later once you've got a clean release under your belt.

Before running the build, double check in Xcode (Runner target → General → Identity):

- **Version** matches what you want live (e.g. `1.0.0`)
- **Build** is a number you haven't uploaded before
- **Supported Destinations** — confirm iPad isn't accidentally checked if you haven't actually tested on iPad, since checking it triggers the iPad screenshot requirement from §7 whether you meant to support it or not.

---

## 14. Upload the build

Three ways, pick one:

**A. Xcode Organizer (recommended for your first upload)** — best because it shows you validation errors in a readable UI before you commit to uploading:

1. In Xcode: **Product → Archive** (make sure the run destination is set to "Any iOS Device (arm64)", not a simulator, or Archive will be greyed out).
2. When it finishes, the **Organizer** window opens automatically showing your archive.
3. Select it → **Distribute App** → **App Store Connect** → **Upload**.
4. With Automatic signing, Xcode handles picking the right distribution certificate and provisioning profile itself.
5. It'll run **Validate App** first — fix anything it flags before it lets you upload.

**B. Transporter app** (from the Mac App Store) — drag the `.ipa` from `build/ios/ipa/` into it, it validates and uploads. Useful if you already have the `.ipa` from the CLI build and don't want to reopen Xcode.

**C. Command line** via `xcrun altool` or an App Store Connect API key — this is the path for CI/CD automation, not something you need for a first manual release.

After upload, App Store Connect **processes** the build — this typically takes a few minutes to about 30 minutes, and you get an email when it's ready [Likely]. Until it's done processing, you can't attach it to a version or submit it.

---

## 15. TestFlight (do this before public release, seriously)

You already tested one release build on one device. TestFlight is how you get it on *other* people's devices before the whole world can download it, and it's part of the same App Store Connect pipeline, so it's basically free to do.

1. Once your build finishes processing, go to **TestFlight** tab in App Store Connect for your app.
2. Fill in **Test Information** (what to test, feedback email) — required.
3. **Internal Testing**: add up to 100 people who are already members of your Apple Developer team, no review needed, builds are available almost immediately.
4. **External Testing**: up to 10,000 testers via email or a public link, but your **first** external build has to go through a lightweight **Beta App Review** (usually faster than full App Review) before it goes out [Likely].
5. Export compliance gets asked here too if you didn't set the Info.plist key from §5 — same answer applies.

I'd genuinely install this on at least one friend's phone via TestFlight before you submit for real. A release build on your own dev-signed device doesn't catch every distribution-signing or App-Store-specific issue.

---

## 16. Submit for App Review

Back on your app's version page in App Store Connect:

1. Under **Build**, select the processed build you uploaded.
2. Fill in **App Review Information**:
   - Contact info (phone/email — Apple sometimes calls if something's ambiguous).
   - **Demo account username/password** if your app has a login. This is a very common, very avoidable rejection reason if skipped or if the credentials don't actually work at review time.
   - **Notes** field: use it to explain anything non-obvious — a feature that needs specific setup, a region-locked feature, whatever a reviewer might otherwise flag as broken when it's actually working as intended.
3. Choose release type: **Automatically release this version** (goes live the moment it's approved) or **Manually release** (you control exactly when it goes live after approval, useful if you want to coordinate a launch date).
4. Click **Add for Review**, then **Submit to App Review**.

---

## 17. What happens during review, and realistic timelines

Apple states roughly 90% of submissions get a decision within 24 hours [Likely], but real-world tracked data from mid-2026 shows first-time new app submissions commonly taking 2-5 days, sometimes longer during September (WWDC/iOS launch season) and December [Likely]. Budget a week of slack before any hard launch date, not 24 hours.

Common, avoidable rejection reasons worth double-checking before you submit:

- Broken or missing demo login credentials (§16)
- Crashes on launch — test the actual **uploaded build** via TestFlight, not just your local release build
- Placeholder/lorem-ipsum content still visible somewhere
- Permission usage strings that don't explain *why* (§5)
- Screenshots that don't match the actual current UI
- Privacy label answers that don't match actual data collection behavior
- Broken links (support URL, privacy policy URL) — Apple checks these
- Age rating that clearly doesn't match actual content (this is now checked more carefully under the new 2025/2026 questionnaire) [Likely]

If rejected, you get specific guideline citations back through **Resolution Center** in App Store Connect. You fix the issue and resubmit — it re-enters the same review queue, roughly the same timeline as before, not a penalty box [Likely].

---

## 18. After approval

- If you chose **Manual release**, go hit "Release This Version" whenever you actually want it live — it's instant.
- If **Automatic**, it goes live within a few hours of approval.
- The app appears in App Store search over the following hours to couple days as Apple's search index catches up — don't panic if it's not instantly searchable at minute one.
- For your *next* update: bump the version/build number in `pubspec.yaml`, repeat §13-16 (you don't need to redo the app record, icon, or most metadata unless it changed).

---

## Quick pre-submission checklist

- [ ] Xcode 26+, Flutter 3.38+ confirmed via terminal
- [ ] Bundle ID registered in Apple Developer portal
- [ ] App record created in App Store Connect
- [ ] Privacy policy hosted and linked
- [ ] Info.plist permission strings added for anything you actually use
- [ ] `ITSAppUsesNonExemptEncryption` set (almost always `false`)
- [ ] Privacy manifest file present, third-party plugins checked for currency
- [ ] 1024×1024 app icon, no alpha channel
- [ ] Screenshots at exact required pixel sizes for 6.9" iPhone (and 13" iPad if applicable), no alpha
- [ ] App name, subtitle, description, keywords, support URL written
- [ ] App Privacy questionnaire completed honestly
- [ ] Age rating questionnaire completed
- [ ] Pricing/availability set
- [ ] Release archive built and uploaded, processed successfully
- [ ] Tested via TestFlight on at least one device that isn't yours
- [ ] Demo account credentials (if applicable) verified working
- [ ] Submitted with a week of schedule slack before any hard launch date
