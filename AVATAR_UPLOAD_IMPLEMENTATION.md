# Avatar Upload Feature Implementation

## Overview

This document describes the implementation of the avatar upload feature with circular crop, WebP compression, Firebase Storage integration, and cached display across profile screens.

## Features Implemented

### 1. Unified flow with AvatarPhotoHandler

**File:** `lib/shared/utils/avatar_photo_handler.dart`

- Orchestrates the entire pipeline: pick → crop → compress → upload → persist → refresh UI.
- Presents a camera/gallery picker, handles permissions, and opens the cropper.
- Uses `croppy` for editing; in debug we force the pure-Dart solver (see `main.dart`).
- Emits progress, shows localized snackbars via `AppStrings`, and triggers profile refresh on success.

### 3. Image Compression Utilities

Compression is performed using `flutter_image_compress` under the hood. The handler produces two artifacts: a 600×600 WebP avatar and a 200×200 WebP thumbnail.

### 4. Firebase Storage Upload Service

Uploads go to Firebase Storage under `avatars/{uid}/avatar.webp` and `avatars/{uid}/thumb.webp`. On success we persist `avatarUrl` (cache-busted), `thumbUrl`, and `avatarUpdatedAt` to `users/{uid}` in Firestore, and update `FirebaseAuth.currentUser.photoURL` where supported.

## Constants Added

### App Dimensions (lib/shared/constants/app_dimensions.dart)

```dart
static const double avatarCropPreviewSize = 120.0;
static const double avatarCropOutputSize = 600.0;
static const double avatarCropThumbSize = 200.0;
static const double avatarCropMaxScale = 8.0;
static const double avatarCropPadding = 20.0;
static const double avatarCropHitTestSize = 20.0;
static const double avatarCropLineWidth = 2.0;
static const double avatarCropOverlayOpacity = 0.55;
static const double avatarCropToolbarHeight = 56.0;
static const double avatarCropHelpTextSize = 13.0;
static const double avatarCropHelpTextPadding = 16.0;
```

### App Strings (lib/shared/constants/app_strings.dart)

Added 15 bilingual string pairs for:

- Picker dialog (title, camera, gallery, cancel)
- Crop screen (title, save, help, failed)
- Upload messages (progress, success, error)
- Error messages (compression error, permission denied)

## Screen Integration

### 1. Complete Profile Screen

**File:** `lib/modules/auth/views/complete_profile_screen.dart`

- Added imports for all avatar upload components
- Added state fields: `_uploadedAvatarUrl`, `_imagePicker`, `_avatarUploader`
- Replaced `_handleEditPhoto()` with full upload flow:
  1. Show picker dialog
  2. Pick image with ImagePicker
  3. Navigate to crop screen
  4. Compress main avatar (600x600, quality 75)
  5. Create thumbnail (200x200, quality 70)
  6. Show progress dialog with percentage
  7. Upload to Firebase Storage
  8. Update local state and Firestore
  9. Clean up temp files
  10. Show success message
- Updated avatar display to use `CachedNetworkImage` with placeholder and error handling

### 2. Edit Profile Screen & Controller

**Files:**

- `lib/modules/profile/views/edit_profile_screen.dart`
- `lib/modules/profile/controllers/edit_profile_controller.dart`

**Controller Changes:**

- Added `RxnString avatarUrl` and `RxnString thumbUrl` reactive fields
- Uses `AvatarPhotoHandler` for the upload flow (`handleEditPhoto`)
- `_loadProfile()` prefers the typed `UserModel` values (`avatarUrl`, `thumbUrl`, `photoURL`) then falls back to Firestore map/FirebaseAuth

**View Changes:**

- Uses `Obx` with `CachedNetworkImage` for reactive loading/caching
- `Edit Photo` button calls `controller.handleEditPhoto()`
- Placeholder when no avatar; circular progress while loading

### 3. Profile Screen

**File:** `lib/modules/profile/views/profile_screen.dart`

- Renders via `CachedNetworkImage` and shows a full-screen overlay on tap using `modules/profile/widgets/full_image_overlay.dart`
- Reads `thumbUrl`/`avatarUrl` from the typed `currentUserModel` (reactive) and normalizes cache-busted URLs
- Loading and error states mirror other screens for consistency

## Dependencies Added

Updated `pubspec.yaml` with:

```yaml
image_picker: ^1.1.2
extended_image: ^10.0.1
croppy: ^1.4.1
flutter_image_compress: ^2.3.0
firebase_storage: ^13.0.2
cached_network_image: ^3.4.1
uuid: ^4.5.1
path_provider: ^2.1.5
path: ^1.9.0
```

Notes:

- In debug builds we set `croppy.croppyForceUseCassowaryDartImpl = true` in `main.dart` to avoid native FFI dependencies.
- Lockfile indicates Flutter SDK >= 3.35.0.

## User Flow

### Complete Profile Flow

1. User taps "Edit Photo" button
2. Dialog appears: "Camera" or "Gallery"
3. User picks image source
4. Camera/Gallery opens for image selection
5. Crop screen appears with circular overlay
6. User adjusts crop with pan/zoom gestures
7. User taps "Save" button
8. Progress dialog shows upload percentage (0-100%)
9. Avatar is compressed to WebP (600x600 main + 200x200 thumb)
10. Files uploaded to Firebase Storage
11. Firestore and Firebase Auth updated with new URL
12. Success message appears
13. Avatar immediately displays in profile

### Edit Profile Flow

Same as above, but triggered from edit profile screen

### View Avatar Flow

1. Profile screen loads
2. Fetches avatar URL from Firestore or Firebase Auth
3. CachedNetworkImage loads and caches avatar
4. Displays circular avatar or placeholder if none exists

## Technical Details

### Image Processing

- **Input:** Any image from camera or gallery
- **Crop:** 1:1 aspect ratio with circular preview
- **Output:** 600x600 WebP (quality 75) for main avatar
- **Thumbnail:** 200x200 WebP (quality 70) for thumbnail
- **Cleanup:** All temporary files removed after upload

### Firebase Storage Structure

```plaintext
avatars/
  {userId}/
    avatar.webp?v=1234567890    // Main avatar (600x600)
    thumb.webp?v=1234567890     // Thumbnail (200x200)
```

### Firestore Updates

- Document: `users/{userId}`
- Fields added/updated: `avatarUrl` (string), `thumbUrl` (string), `avatarUpdatedAt` (timestamp)

### Firebase Auth Updates

- User profile `photoURL` updated with main avatar URL (when available)

### Progress Tracking

- 0-80%: Main avatar upload
- 80-100%: Thumbnail upload
- Non-dismissible dialog during upload

### Error Handling

- Compression failure: Shows error snackbar
- Upload failure: Shows error snackbar, closes progress dialog
- Permission denied: Handled by image_picker package
- Network errors: Caught and displayed as error snackbar

### Caching

- `CachedNetworkImage` caches downloaded avatars locally
- Cache-busting query parameter ensures fresh image after upload; helper functions normalize URLs when `token?v=` is present
- Placeholder shown during initial load; error widget shows placeholder if image fails to load

## Code Quality

### Responsive Design

- All dimensions wrapped with `SizeUtils.h()`, `SizeUtils.w()`, `SizeUtils.r()`
- Works on all screen sizes and orientations

### Internationalization

- All user-facing strings in both English and French
- Language detection: `Get.locale?.languageCode == 'fr'`

### State Management

- GetX reactive programming (`RxnString`, `RxDouble`, `Obx`)
- Local state (`setState`) for complete profile screen
- Controller-based state for edit profile screen

### Code Reusability

- Shared widgets can be used in any screen
- Service layer encapsulates Firebase logic
- Utils provide reusable compression functionality

## Testing Recommendations

1. **Manual Testing:**

   - Test camera capture on physical device
   - Test gallery selection with various image formats
   - Test crop with different zoom levels
   - Test upload with slow network
   - Test error scenarios (no permission, no network)
   - Test avatar display in all three screens

2. **Edge Cases:**

   - Very large images (>10MB)
   - Very small images (<100px)
   - Portrait vs landscape orientation
   - Animated images (GIF/WebP)
   - Corrupted images

3. **Performance:**
   - Monitor memory usage during compression
   - Check upload times on slow networks
   - Verify cache efficiency with CachedNetworkImage

## Known Issues & Limitations

1. **Info-level lint warnings:**

   - `WillPopScope` deprecated (should migrate to `PopScope` in Flutter 3.12+)
   - `use_build_context_synchronously` warnings (minor async safety)
   - `withOpacity` deprecated (should use `.withValues()`)

2. **No avatar deletion feature:**
   - `deleteAvatar()` method exists but not exposed in UI
   - Could add "Remove Photo" option in future

## Future Enhancements

1. Add avatar removal functionality
2. Add image filters/adjustments before crop
3. Support multiple aspect ratios (not just 1:1)
4. Add option to zoom into specific area during crop
5. Add undo/redo in crop editor
6. Support video avatars or animated GIFs
7. Add avatar border/frame selection
8. Implement image quality detection and recommendations
9. Add batch upload for multiple profile photos
10. Add social media import (Facebook/Google profile photos)

## Files Modified/Created

### Created

- `lib/shared/utils/avatar_photo_handler.dart` — unified avatar flow (pick/crop/compress/upload/persist/refresh)
- `lib/modules/profile/widgets/full_image_overlay.dart` — tap-to-zoom viewer for full-resolution avatar
- `lib/shared/utils/avatar_utils.dart` — URL normalization and small helpers

### Modified

- `pubspec.yaml` — Added avatar/cropping/storage/caching dependencies
- `lib/shared/constants/app_dimensions.dart` — Added avatar-crop constants
- `lib/shared/constants/app_strings.dart` — Added bilingual strings for picker/crop/upload
- `lib/app/models/user.dart` — Added `avatarUrl`, `thumbUrl`, `avatarUpdatedAt`, `photoURL`
- `lib/app/controllers/auth_controller.dart` — Prefer typed model fields for profile getters
- `lib/modules/auth/views/complete_profile_screen.dart` — Avatar integration
- `lib/modules/profile/controllers/edit_profile_controller.dart` — Avatar integration
- `lib/modules/profile/views/edit_profile_screen.dart` — Avatar integration
- `lib/modules/profile/views/profile_screen.dart` — Cached display + fullscreen overlay

## Conclusion

The avatar upload feature is fully implemented and integrated into three screens:

1. **Complete Profile Screen** - First-time avatar setup
2. **Edit Profile Screen** - Avatar updates
3. **Profile Screen** - Avatar display

All components follow the app's established patterns for GetX state management, responsive design, internationalization, and Firebase integration. The implementation is production-ready with proper error handling, progress tracking, and efficient caching.
