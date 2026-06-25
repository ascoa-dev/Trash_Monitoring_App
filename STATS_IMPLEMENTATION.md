# Stats Module Implementation Guide

## Overview

The Stats (Reports) module provides users with comprehensive analytics and visualizations of their cleanup activities, including waste category breakdowns, location-based mapping, and activity summaries.

## Module Structure

```plaintext
lib/modules/stats/
├── controllers/
│   └── stats_controller.dart          # State management and data aggregation
├── models/
│   └── stats_models.dart               # Data models for stats
├── views/
│   └── stats_screen.dart               # Main stats screen with map
└── widgets/
    ├── stats_header_widget.dart        # Header with Reports title
    ├── waste_chart_widget.dart         # Stacked bar chart for waste categories
    └── stats_filter_widget.dart        # Date and environment filters
```

## Features

### 1. Activity Summary Cards

**Location:** `stats_screen.dart` - `_ActivityCard` widget

Displays two key metrics:

- **Cleanups**: Total number of cleanups (padded to 2 digits)
- **Trash Collected**: Total weight in kilograms (decimal display)

**Design Specs:**

- Background: `AppColors.statsActivityCardBg` (#B4D17B - light green)
- Border radius: `AppDimensions.statsCardBorderRadius` (12px)
- Value font: `AppTextStyles.statsActivityValue` (Rubik, 57px, bold)
- Label font: `AppTextStyles.statsActivityLabel` (Rubik, 16px, italic)
- Unit offset: `AppDimensions.statsActivityUnitTopOffset` (36px from top)

### 2. Waste Category Chart

**Location:** `waste_chart_widget.dart`

A stacked bar chart showing items collected across 7 waste categories from `trash_template.json`:

1. Most Likely Items to Find
2. Fishing Gear
3. Tiny Trash (<2.5 cm)
4. Packaging Materials
5. Personal Hygiene
6. Items of Local Concern
7. Other Trash

**Environment Color Coding:**

- Freshwater: `AppColors.statsChartFreshwater` (#5FB3C6)
- Saltwater: `AppColors.statsChartSaltwater` (#357187)
- Land: `AppColors.statsChartLand` (#B4D17B)

**Chart Configuration:**

- Library: `fl_chart: ^0.69.0`
- Aspect ratio: `AppDimensions.statsChartAspectRatio` (1.0)
- Padding: `AppDimensions.statsChartPadding` (16px)
- Legend: Top-right overlay with semi-transparent background

**Dynamic Scaling:**

```dart
_getMaxY() {
  if (max <= 1) return 2;
  if (max <= 5) return 5;
  if (max <= 10) return 10;
  // ... up to (max / 10).ceil() * 10
}
```

### 3. Date and Environment Filters

**Location:** `stats_filter_widget.dart`

**Date Pickers:**

- **Two separate sliders** (stacked vertically)
- FROM picker (top): Teal bar on left → Green bar on right
- TO picker (bottom): Green bar on left → Teal bar on right
- Handle: 4px width × 44px height with 6px white padding on sides
- Dots: 4px circles inside colored bars
- Validation: Error messages for invalid date ranges

**Design Specs:**

- Slider track height: `AppDimensions.statsSliderTrackHeight` (16px)
- Slider handle: `AppDimensions.statsSliderHandleWidth` (4px)
- Teal color: `AppColors.statsFilterTeal` (#357187)
- Green color: `AppColors.statsFilterGreen` (#C7E0B0)
- Error style: `AppTextStyles.statsError` (Rubik, 12px, red)

**Environment Checkboxes:**

- Options: All, Inland, Freshwater, Saltwater
- Custom checkboxes: 18px × 18px with 2px border
- Check icon: 12px when selected

### 4. Location Map

**Location:** `stats_screen.dart` - `_buildMap()`

**Map Configuration:**

- Library: `google_maps_flutter: ^2.7.0`
- Initial center: Cameroon (6.5, 12.5) at zoom level 5
- Marker size: `AppDimensions.statsMarkerSize` (24px)
- Custom circle markers with 2px white borders
- Info window: Date + Group name / KG collected

**Marker Creation:**

```dart
Future<BitmapDescriptor> _createCircleMarker(Color color) async {
  // Creates 24x24 circle bitmap with:
  // - Filled circle with environment color
  // - 2px white border stroke
  // - Returns BitmapDescriptor for Google Maps
}
```

## State Management

### StatsController (GetX)

**File:** `stats_controller.dart`

**Key Observables:**

```dart
final isLoading = true.obs;
final error = ''.obs;
final cleanups = <CleanupModel>[].obs;
final fromDate = Rxn<DateTime>();
final toDate = Rxn<DateTime>();
final selectedEnvironments = <String>{'All'}.obs;
```

**Key Methods:**

- `fetchCleanups()`: Loads all cleanups from Firestore
- `getChartData()`: Aggregates waste category data by environment
- `getLocationData()`: Prepares cleanup locations for map markers
- `setFromDate(DateTime)` / `setToDate(DateTime)`: Updates date filters
- `toggleEnvironmentFilter(String)`: Manages environment selections
- `refresh()`: Reloads all data

**Data Aggregation Logic:**

```dart
Map<String, Map<String, int>> getChartData() {
  // 1. Filter cleanups by date range and environment
  // 2. Iterate through trash_template categories
  // 3. Count items per category per environment
  // 4. Return Map<category, Map<environment, count>>
}
```

## Shared Constants Usage

### Colors (`app_colors.dart`)

```dart
AppColors.statsChartFreshwater  // #5FB3C6
AppColors.statsChartSaltwater   // #357187
AppColors.statsChartLand        // #B4D17B
AppColors.statsFilterTeal       // #357187
AppColors.statsFilterGreen      // #C7E0B0
AppColors.statsActivityCardBg   // #B4D17B
```

### Dimensions (`app_dimensions.dart`)

```dart
AppDimensions.statsHeaderHeight              // 200.0
AppDimensions.statsCardBorderRadius          // 12.0
AppDimensions.statsMapHeight                 // 300.0
AppDimensions.statsMarkerSize                // 24.0
AppDimensions.statsSliderHandleWidth         // 4.0
AppDimensions.statsSliderHandleHeight        // 44.0
AppDimensions.statsActivityValueFontSize     // 57.0
AppDimensions.statsCheckboxSize              // 18.0
// ... (see app_dimensions.dart for full list)
```

### Strings (`app_strings.dart`)

```dart
AppStrings.statsPageTitle           // "Reports"
AppStrings.statsChartTitle          // "Items Collected by..."
AppStrings.statsMapTitle            // "Waste Collected by Location"
AppStrings.statsErrorFromDate       // "From date cannot be later..."
AppStrings.statsFilterDate          // "Date"
AppStrings.statsFilterEnvironment   // "Environment"
AppStrings.environmentFreshwater    // "Freshwater"
// ... (see app_strings.dart for full list)
```

### Text Styles (`app_text_styles.dart`)

```dart
AppTextStyles.statsTitle(context)           // 28px, bold, Rubik
AppTextStyles.statsChartTitle(context)      // 16px, semi-bold
AppTextStyles.statsActivityValue(context)   // 57px, bold
AppTextStyles.statsChartLegend(context)     // 10px for legend items
AppTextStyles.statsFilterDate(context)      // 14px for date labels
AppTextStyles.statsError(context)           // 12px, red
// ... (see app_text_styles.dart for full list)
```

## Data Flow

### 1. Initialization

```plaintext
StatsScreen.initState()
  ↓
StatsController.onInit()
  ↓
fetchCleanups() → Firestore query
  ↓
availableDates, fromDate, toDate calculated
  ↓
UI renders with initial data
```

### 2. Date Filter Change

```plaintext
User drags slider
  ↓
_handleFromChange() / _handleToChange()
  ↓
Validation (from <= to)
  ↓
controller.setFromDate() / setToDate()
  ↓
Obx triggers rebuild
  ↓
getChartData() / getLocationData() recalculate
  ↓
Chart and map update
```

### 3. Environment Filter Change

```plaintext
User taps checkbox
  ↓
toggleEnvironmentFilter(label)
  ↓
'All' logic: deselect others if 'All' selected
  ↓
selectedEnvironments.value updated
  ↓
Obx triggers rebuild
  ↓
Chart and map filter by environment
```

## Integration with Other Modules

### Cleanup Module

- Reads from same `cleanups` Firestore collection
- Uses `CleanupModel` and `CachedCleanupModel`
- Syncs through Hive offline cache (TypeId 4)

### Trash Template

- Reads category names from `trash_template.json`
- Ensures chart categories match template structure
- Critical: Must use exact category names for data matching

### Maps

- Uses `google_maps_flutter` package
- Geocoding data from cleanup locations
- Custom circle markers with environment colors

## Testing Considerations

### Unit Tests

```dart
test('getChartData filters by date range', () {
  // Setup cleanups with various dates
  // Set fromDate and toDate
  // Assert only cleanups in range are counted
});

test('environment filter "All" overrides others', () {
  // Setup selectedEnvironments
  // toggleEnvironmentFilter('All')
  // Assert only 'All' is selected
});
```

### Widget Tests

```dart
testWidgets('shows error message for invalid date range', (tester) async {
  // Build StatsFilterWidget
  // Drag FROM slider past TO slider
  // Assert error message appears
});
```

### Integration Tests

```dart
testWidgets('chart updates when date filter changes', (tester) async {
  // Navigate to stats screen
  // Wait for data load
  // Change date filter
  // Assert chart data changed
});
```

## Performance Optimization

### 1. AutomaticKeepAliveClientMixin

```dart
class _StatsScreenState extends State<StatsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
}
```

Preserves stats screen state when navigating away.

### 2. Cached Map Markers

```dart
final Map<String, BitmapDescriptor> _circleMarkers = {};

Future<void> _createCircleMarkers() async {
  // Create markers once during initState
  // Store in map for reuse
}
```

### 3. Chart Data Aggregation

- Filters cleanups before aggregation
- Caches available dates list
- Only recalculates on date/environment filter change

## Common Issues & Solutions

### Issue: Chart shows "Other Trash" only

**Solution:** Ensure category names in `getChartData()` exactly match trash_template.json:

```dart
static const List<String> allCategories = [
  'Most Likely Items to Find',  // Not "most likely items"
  'Fishing Gear',                // Not "fishing gear"
  // ... exact case and punctuation
];
```

### Issue: Date picker handle jumps erratically

**Solution:** Check handle area width calculation includes padding:

```dart
const totalHandleAreaWidth = paddingWidth + handleWidth + paddingWidth;
final trackWidth = width - totalHandleAreaWidth;
```

### Issue: Map markers not showing

**Solution:** Verify marker creation completes before building map:

```dart
Future<void> _createCircleMarkers() async {
  // ... create markers
  if (mounted) setState(() {}); // Trigger rebuild when ready
}
```

## Future Enhancements

### Planned Features

1. **Export Reports**: PDF/CSV export of stats data
2. **Time-based Charts**: Line charts showing trends over time
3. **Leaderboards**: Compare with other users/groups
4. **Achievements**: Badges for milestones
5. **Detailed Analytics**: Breakdown by city, group, or user

### Technical Debt

1. Add unit tests for `StatsController`
2. Implement caching for aggregated chart data
3. Optimize map marker clustering for many locations
4. Add accessibility labels for chart elements

## Related Documentation

- [Trash Template Integration](TRASH_TEMPLATE_INTEGRATION.md)
- [Cleanup Module Guide](CLEANUP_MODULE_GUIDE.md) _(to be created)_
- [Shared Components Guide](SHARED_COMPONENTS_GUIDE.md)
- [Developer Guide](DEVELOPER_GUIDE.md)

---

**Last Updated:** [Current Date]
**Module Version:** 1.0.0
**Flutter Version:** 3.x
**Dependencies:** fl_chart ^0.69.0, google_maps_flutter ^2.7.0, get ^4.6.5
