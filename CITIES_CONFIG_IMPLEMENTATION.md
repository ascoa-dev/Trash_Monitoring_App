# Cities Configuration - Firestore + Hive Implementation

## Overview

This implementation fetches the `config/cities` document from Firestore at app startup, caches it locally using Hive for offline access, and provides a city selector widget for use in profile screens.

## Architecture

### Models (`lib/app/models/`)

- **`city_model.dart`**: Represents a single city with:
  - `name`: Display name of the city
  - `nameLower`: Lowercase version for case-insensitive searching
  - `altNames`: List of alternative names/spellings
- **`cities_config.dart`**: Top-level config containing:
  - `allowCustomCities`: Whether users can type custom city names
  - `cities`: List of City objects
  - `fuzzyThreshold`: Threshold for fuzzy matching (0-100)
  - `maxSuggestions`: Maximum number of suggestions to show
  - `updatedAt`: Timestamp of last update
  - `customCitiesWarning`: Warning message shown when no cities match (user typing custom city)

Both models include:

- Hive `@HiveType` and `@HiveField` annotations
- `fromMap()` factory for Firestore deserialization
- `toMap()` method for serialization
- Auto-generated TypeAdapters via `build_runner`

### Service Layer (`lib/shared/services/`)

**`cities_service.dart`**:

- Extends `GetxService` for app-wide singleton
- Loads cached config from Hive on initialization
- Fetches latest config from Firestore `config/cities` document
- Updates cache when remote fetch succeeds
- Provides reactive `Rxn<CitiesConfig>` for state management
- Graceful error handling with fallback to cached data

### Controller Layer (`lib/shared/controllers/`)

**`cities_controller.dart`**:

- Wraps CitiesService for easy GetX access
- Exposes convenience methods:
  - `config`: Get current CitiesConfig
  - `allowCustomCities`: Check if custom cities allowed
  - `customCitiesWarning`: Get the warning message for custom cities (defaults to standard message if not set)
  - `cityNames()`: Get list of city names for display

### Widget Layer (`lib/shared/widgets/`)

**`city_selector_field.dart`**:

- Autocomplete text field with dropdown overlay using Material Design 3 styling
- Filters cities as user types using fuzzy search
- Shows filtered suggestions when focused (or all cities if input is empty)
- Supports custom city input (when `allowCustomCities` is enabled in config)
- Matches existing `FloatingLabelInputField` style with floating label chip
- Uses `CompositedTransformTarget`/`Follower` for precise overlay positioning
- No gap between input and dropdown for seamless visual experience
- All dimensions use `AppDimensions` constants for consistency
- All colors use `AppColors` constants
- All text styling uses `AppTextStyles` and `AppTypography`
- All strings use `AppStrings` constants
- Responsive sizing via `SizeUtils`

**Constants used:**

- `AppDimensions.citySelectorMaxWidth` (300px)
- `AppDimensions.citySelectorMaxHeight` (240px)
- `AppDimensions.citySelectorMinHeight` (56px)
- `AppDimensions.citySelectorBorderRadius` (4px)
- `AppDimensions.citySelectorItemHeight` (48px)
- `AppDimensions.citySelectorTextSize` (18px)
- Material Design 3 shadow constants
- `AppColors.shadowMedium`, `AppColors.shadowLight`
- `AppStrings.citySelectorNoCitiesFound`

## Initialization Flow (`lib/main.dart`)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(...);

  // Initialize Hive and register adapters
  await Hive.initFlutter();
  Hive.registerAdapter(CityAdapter());
  Hive.registerAdapter(CitiesConfigAdapter());

  // Initialize and register CitiesService
  final citiesService = await CitiesService().init();
  Get.put<CitiesService>(citiesService, permanent: true);
  Get.put(CitiesController());

  runApp(const MyApp());
}
```

### Startup Behavior

1. App starts → Hive initialized
2. TypeAdapters registered
3. CitiesService.init() called:
   - Opens Hive box `config_cities`
   - Loads cached config (if exists) → immediate UI access
   - Attempts Firestore fetch in background
   - On success: updates cache and reactive state
   - On failure: keeps cached data, logs error

## Usage in Screens

### Complete Profile Screen (`lib/modules/auth/views/complete_profile_screen.dart`)

Replaced `FloatingLabelInputField` with `CitySelectorField`:

```dart
CitySelectorField(
  controller: formControllers.cityController,
  label: cityLabel,
  hint: AppStrings.cityHint,
  supportText: validationController.cityError.value,
  isError: validationController.cityError.value != null,
  onChanged: validationController.validateCity,
)
```

### Edit Profile Screen (`lib/modules/profile/views/edit_profile_screen.dart`)

Same replacement for consistent UX:

```dart
CitySelectorField(
  controller: forms.cityController,
  label: cityLabel,
  hint: AppStrings.cityHint,
  supportText: validation.cityError.value,
  isError: validation.cityError.value != null,
  onChanged: validation.validateCity,
)
```

## Firestore Document Structure

Expected document at `config/cities`:

```json
{
  "allowCustomCities": true,
  "cities": [
    {
      "name": "Mumbai",
      "nameLower": "mumbai",
      "altNames": ["Bombay", "बॉम्बे"]
    },
    {
      "name": "Delhi",
      "nameLower": "delhi",
      "altNames": ["New Delhi", "दिल्ली"]
    }
  ],
  "fuzzyThreshold": 80,
  "maxSuggestions": 5,
  "customCitiesWarning": "This city is not officially recognized. Please double-check.",
  "updatedAt": "2025-10-14T10:30:00Z"
}
```

## Code Generation

TypeAdapters are generated via `build_runner`:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Generated files:

- `lib/app/models/city_model.g.dart`
- `lib/app/models/cities_config.g.dart`

## Benefits

1. **Offline-first**: Cached data available immediately, even without network
2. **Fresh data**: Background fetch ensures up-to-date city list
3. **Fast UX**: Autocomplete with local filtering (no API calls per keystroke)
4. **Flexible**: Supports custom cities when enabled in Firestore
5. **Type-safe**: Full Dart models with null safety
6. **Maintainable**: Single source of truth in Firestore, easy to update
7. **Responsive**: Uses SizeUtils for consistent scaling
8. **Fuzzy search**: Tokenized fuzzy matching allows "abele" to match "ab leila"
9. **Smart warnings**: Custom warning messages for unrecognized cities (configurable via Firestore)

## Features

### Fuzzy Search

- Uses the `fuzzy` package with weighted keys for intelligent matching
- Searches across: `name`, `nameLower`, `altNames`, and tokenized version (spaces removed)
- Threshold set to 0.7 for permissive matching that works with typos and partial matches
- Example: typing "abele" will match "ab leila" thanks to tokenization

### Custom City Warnings

- When `allowCustomCities` is `true` and user types a city not in the list
- Shows `customCitiesWarning` message from Firestore config
- Displays in yellow/error color to catch user attention
- Default fallback: "This city is not officially recognized. Please double-check."

### Smart Refocus Behavior

- When input is empty: shows all cities
- When input has text: shows filtered suggestions based on current text
- No gap between input field and dropdown for seamless visual experience

## Future Enhancements

1. ~~**Fuzzy search**: Use `fuzzyThreshold` for typo-tolerant matching~~ ✅ Implemented
2. ~~**Alternative names**: Search through `altNames` for better discovery~~ ✅ Implemented
3. **Periodic sync**: Auto-refresh config every N hours
4. **Force refresh**: Pull-to-refresh or manual sync button
5. **Analytics**: Track which cities are most commonly selected
6. **Localization**: Return city names based on user locale

## Files Modified/Created

### Created

- `lib/app/models/city_model.dart`
- `lib/app/models/cities_config.dart`
- `lib/app/models/city_model.g.dart` (generated)
- `lib/app/models/cities_config.g.dart` (generated)
- `lib/shared/services/cities_service.dart`
- `lib/shared/controllers/cities_controller.dart`
- `lib/shared/widgets/city_selector_field.dart`

### Modified

- `pubspec.yaml` (added `hive_flutter: ^1.1.0`)
- `lib/main.dart` (Hive init, adapter registration, service init)
- `lib/modules/auth/views/complete_profile_screen.dart` (replaced city input)
- `lib/modules/profile/views/edit_profile_screen.dart` (replaced city input)

## Testing

Run analyzer to verify no issues:

```bash
flutter analyze
```

Result: ✅ No issues found!

## Notes

- TypeAdapters use typeId 0 (City) and 1 (CitiesConfig)
- If adding more Hive models, use typeId >= 2
- Service is registered as `permanent: true` in GetX (never disposed)
- Controller is registered normally (can be disposed if needed)
- Overlay positioning works correctly with keyboard and scrolling
