# Photo Upload Implementation

This document describes the photo upload feature implementation for the cleanup form.

## Overview

The photo upload feature allows users to:

- Select up to 5 photos (configurable)
- Preview selected photos in a responsive grid
- Track upload progress with a circular progress indicator
- Cancel uploads in progress
- Remove photos before or after upload
- Automatically compress images before uploading to optimize storage

## Components

### 1. MediaUploadController

**Location:** `lib/modules/start_cleanup/controllers/media_upload_controller.dart`

Manages the state of photo uploads including:

- Photo selection and storage
- Compression using `flutter_image_compress`
- Upload to Firebase Storage
- Progress tracking
- Error handling

**Key Configuration (MediaUploadConfig class):**

```dart
static const int maxPhotos = 5;  // Maximum number of photos allowed
static const int imageQuality = 75;  // JPEG quality (0-100)
static const int maxWidth = 1920;  // Maximum width in pixels
static const int maxHeight = 1920;  // Maximum height in pixels
```

To change the maximum number of photos, modify `maxPhotos` in the `MediaUploadConfig` class.

### 2. PhotosSection Widget

**Location:** `lib/modules/start_cleanup/views/photos_section.dart`

UI component that displays:

- Upload button
- Photo grid with responsive layout
- Upload progress overlays
- Action buttons (cancel/delete)

**Grid Layout Logic:**

- 1-3 photos: displays in a single row
- 4-5 photos: displays in a 2-column grid

### 3. CircularUploadProgress Widget

**Location:** `lib/shared/widgets/circular_upload_progress.dart`

A static circular progress indicator showing upload progress from 0% to 100%.
Unlike the animated `CircularInfiniteLoader`, this widget does not rotate.

## Firebase Storage Structure

Photos are stored in Firebase Storage with the following structure:

```
cleanups/
  └── {cleanupDocId}/
      ├── {uuid1}.jpg
      ├── {uuid2}.jpg
      └── ...
```

The download URLs are stored in the Firestore `cleanups` collection document under the `photoUrls` array field.

## Upload Flow

1. **User selects photos** → Photos added to controller with `pending` status
   - Image picker is limited to images only (no videos)
   - Manual fallback ensures max photo limit is enforced
2. **Immediate upload starts** → Each photo begins uploading as soon as selected
   - Cleanup document ID is pre-generated for storage path
3. **Compression** → Each photo is compressed using `flutter_image_compress`
   - Status changes to `compressing`
   - Progress: 0.1 - 0.3
4. **Upload** → Compressed photos uploaded to Firebase Storage in parallel
   - Status changes to `uploading`
   - Progress: 0.3 - 1.0
5. **Complete** → Download URLs stored in controller
   - Status changes to `completed`
   - Progress: 1.0
6. **Form submission** → URLs are retrieved and added to cleanup document
   - No additional upload needed - photos already uploaded

## Error Handling

- **Compression failure**: Photo status set to `error`, user can retry by removing and re-adding
- **Upload failure**: Same as compression failure
- **User cancellation**: Upload task cancelled, photo removed from queue
- **Network issues**: Firebase SDK handles retries automatically

## Usage in CleanupFormController

The `CleanupFormController` integrates the `MediaUploadController` and pre-generates a cleanup document ID:

```dart
// Pre-generated cleanup document ID for photo uploads
String? _cleanupDocId;
String get cleanupDocId {
  _cleanupDocId ??= FirebaseFirestore.instance.collection('cleanups').doc().id;
  return _cleanupDocId!;
}

// Photos upload immediately after selection in PhotosSection
// When submitting cleanup, just get the URLs:
Future<String?> submitCleanup(String userId) async {
  // ... validation ...

  // Photos already uploaded - just get URLs
  final photoUrls = mediaUploadController.uploadedPhotoUrls;

  // Use the pre-generated cleanup doc ID
  final cleanupRef = firestore.collection('cleanups').doc(cleanupDocId);

  // Include in cleanup model
  final cleanup = CleanupModel.fromFormData(...)
      .copyWith(photoUrls: photoUrls.isNotEmpty ? photoUrls : null);

  // ... save to Firestore ...
}
```

## Customization

### Change Maximum Photos

Edit `MediaUploadConfig.maxPhotos` in `media_upload_controller.dart`:

```dart
class MediaUploadConfig {
  static const int maxPhotos = 10; // Change from 5 to 10
  // ...
}
```

### Change Compression Settings

Edit compression parameters in `MediaUploadConfig`:

```dart
static const int imageQuality = 85; // Higher quality
static const int maxWidth = 2400;   // Larger size
static const int maxHeight = 2400;
```

### Change Grid Layout

Modify `_getGridCrossAxisCount()` in `photos_section.dart`:

```dart
int _getGridCrossAxisCount(int photoCount) {
  // Custom logic here
  return 3; // Always 3 columns
}
```

## Dependencies

Required packages (already in pubspec.yaml):

- `image_picker` - Select images from gallery
- `flutter_image_compress` - Compress images
- `firebase_storage` - Upload to Firebase Storage
- `uuid` - Generate unique file names
- `path_provider` - Access temporary directory for compression

## Future Enhancements

Potential improvements:

- Video upload support
- Image cropping before upload
- Photo reordering in grid
- Multiple photo selection improvements
- Upload queue with retry logic
- Offline support with background sync
