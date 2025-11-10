# Location Picker Implementation

## Overview

Implemented a robust location picker with **bidirectional sync** between a search field and Google Maps, similar to Uber/Zomato/Swiggy.

## Features Implemented

### 1. **Google Places Autocomplete Search**

- Real-time search with debouncing (500ms delay)
- Limits to 3 suggestions maximum
- Styled dropdown matching the custom date picker design
- Shows loading indicator during search

### 2. **Bidirectional Sync**

- **Search → Map**: Selecting a suggestion moves the map camera to that location
- **Map → Search**: Dragging the map updates the search field with reverse geocoded address
- Debounced map updates (800ms) to avoid excessive API calls

### 3. **USE MY LOCATION Button**

- Requests location permission
- Moves map to current GPS coordinates
- Updates search field with current address

### 4. **Visual Design**

- Search field uses the same FloatingLabelInputField pattern
- Dropdown styled with AppColors.background (matching date picker)
- Map height: 200px (responsive via SizeUtils)
- Search icon changes to loading spinner during search
- Location pin icon in dropdown suggestions

## Files Created/Modified

### Created Files

1. **`lib/shared/services/google_places_service.dart`**

   - Wrapper for Google Places API
   - `searchPlaces()`: Autocomplete with configurable max results
   - `getPlaceDetails()`: Get coordinates from place_id
   - Models: `PlaceSuggestion`, `PlaceDetails`

2. **`lib/shared/widgets/location_search_field.dart`**

   - Custom search field with dropdown
   - Debounced search (500ms)
   - Dropdown styled like date picker (AppColors.background, shadow, border radius)
   - Loading state with CircularProgressIndicator
   - Clears suggestions on blur

3. **`LOCATION_PICKER_IMPLEMENTATION.md`** (this file)

### Modified Files

1. **`pubspec.yaml`**

   - Added `geocoding: ^3.0.0` dependency

2. **`lib/modules/start_cleanup/views/basic_infomation_section.dart`**
   - Replaced `FloatingLabelInputField` with `LocationSearchField`
   - Integrated GoogleMap with height 200
   - Added state management for:
     - `currentPosition`: LatLng of selected location
     - `markers`: Set of markers to display
     - `_isUpdatingFromMap`: Flag to prevent circular updates
     - `_debounceTimer`: Debounce timer for map drag
   - Implemented sync methods:
     - `_onPlaceSelected()`: Search → Map
     - `_onMapDragEnd()`: Map → Search
     - `_updateMapLocation()`: Helper to update map position
   - Changed button icon from `location_pin` to `my_location`

## Setup Required

### 1. Google Cloud API Key

You need a Google Cloud API key with these APIs enabled:

- Maps SDK for Android
- Maps SDK for iOS
- Places API
- Geocoding API

### 2. Update API Key

**File**: `lib/shared/services/google_places_service.dart`

```dart
static const String _apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
```

Replace `'YOUR_GOOGLE_MAPS_API_KEY'` with your actual key.

### 3. Platform Configuration

The Google Maps API key is already configured in:

- Android: `android/app/src/main/AndroidManifest.xml`
- iOS: `ios/Runner/AppDelegate.swift` or `Info.plist`

## How It Works

### Search to Map Flow

1. User types in LocationSearchField
2. After 500ms debounce, calls Google Places Autocomplete API
3. Shows up to 3 suggestions in dropdown
4. User taps a suggestion
5. Calls Google Places Details API to get coordinates
6. Updates map camera to new position
7. Adds marker at location

### Map to Search Flow

1. User drags the map
2. `onCameraMove` updates marker position in real-time
3. When drag ends, `onCameraIdle` is called
4. After 800ms debounce, reverse geocodes coordinates
5. Updates search field text with address
6. Sets `_isUpdatingFromMap = true` to prevent circular update

### Use My Location Flow

1. User clicks "USE MY LOCATION" button
2. Requests GPS permission (currently mocked with Hyderabad coordinates)
3. Gets current coordinates
4. Updates map position
5. Reverse geocodes to get address
6. Updates search field

## State Management

### Key State Variables

- `currentPosition`: LatLng? - Current selected location
- `markers`: Set<`Marker`> - Markers displayed on map
- `_isUpdatingFromMap`: bool - Prevents circular updates
- `_debounceTimer`: Timer? - Debounces reverse geocoding

### Controllers

- `locationController`: TextEditingController - For search field text
- `mapController`: GoogleMapController? - For camera animations

## Styling

### Search Dropdown

- Background: `AppColors.background`
- Max height: 240px (~5 items like date picker)
- Border radius: 8px
- Box shadow: `Colors.black.withOpacity(0.1)`
- Item height: ~48px with icon, main text, secondary text
- Dividers between items

### Map

- Height: 200px (responsive)
- Border radius: 10px
- Markers update in real-time during drag
- Zoom level: 14
- Zoom controls disabled (user can still pinch to zoom)

## Error Handling

### Network Errors

- All API calls wrapped in try-catch
- Returns empty list on error (silently fails, shows no suggestions)
- Prints error to console (info level, not production logging)

### Edge Cases

- Empty search query → clears suggestions
- Controller disposed → returns empty list
- No placemarks found → keeps previous address
- Null checks for all optional values

## Performance Optimizations

1. **Debouncing**:
   - Search: 500ms delay
   - Map drag: 800ms delay
2. **Max Results**:
   - Limits to 3 suggestions (configurable)
3. **Lazy Loading**:
   - Only shows map when position exists
4. **State Flags**:
   - `_isUpdatingFromMap` prevents infinite loops

## Testing Checklist

- [ ] Search for location → map moves correctly
- [ ] Drag map → search field updates with address
- [ ] Click "USE MY LOCATION" → moves to current GPS
- [ ] Type fast → only sends one API request (debounced)
- [ ] Drag map fast → only reverse geocodes once (debounced)
- [ ] Dropdown styling matches date picker
- [ ] Suggestions limited to 3 items
- [ ] Loading indicator appears during search
- [ ] Suggestions clear when field loses focus
- [ ] Map height is 200px
- [ ] Map width matches search field width

## Known Limitations

1. **API Key**: Currently hardcoded as placeholder string
2. **GPS Location**: Currently mocked (Hyderabad coordinates)
3. **Error Messages**: Silently fails, no user-facing error messages
4. **Offline Support**: Requires internet for search and geocoding
5. **Country Filter**: Not implemented (searches globally)

## Future Enhancements

1. Add actual GPS permission handling with `geolocator` package
2. Add error snackbars for network failures
3. Add recent locations cache
4. Add country/region filter to Places API
5. Add map style (dark theme, custom colors)
6. Add "Detect Location" floating action button on map
7. Replace print statements with proper logging
8. Move API key to environment variables
9. Add unit tests for GooglePlacesService
10. Add integration tests for bidirectional sync

## Dependencies Added

```yaml
geocoding: ^3.0.0
```

## Dependencies Already Available

- `google_maps_flutter: ^2.7.0`
- `http: ^1.5.0`

## Compile Status

✅ **Clean compile** - No errors, only info-level warnings (print statements, deprecations in other files)

## Total Lines of Code

- GooglePlacesService: ~120 lines
- LocationSearchField: ~330 lines
- BasicInformationSection updates: ~150 lines modified/added
- **Total new code**: ~600 lines

## Development Time

Estimated: 2-3 hours for a developer familiar with Flutter and Google Maps API
