# Trash Template Integration Guide

## Overview

The Trash Collected section is fully wired to use the Firebase configuration document (`/app-templates/trash_template`). This document explains how the integration works.

## Architecture

### 1. Data Flow

```plaintext
Firebase (app-templates/trash_template)
    ↓
CleanupFormController.fetchTrashTemplate()
    ↓
Parses categoryOrder and categories
    ↓
Stores weights for calculation
    ↓
TrashCollectedSection displays categories in order
    ↓
User selects items and quantities
    ↓
Data saved to controller.trashItems
```

### 2. Key Components

#### Firebase Document Structure

Location: `app-templates/trash_template`

```json
{
  "version": 1,
  "lastUpdated": "2025-11-05",
  "units": "kg_per_item",
  "categoryOrder": ["Most Likely Items to Find", "Fishing Gear", ...],
  "categories": {
    "mostLikelyItems": {
      "name": "Most Likely Items to Find",
      "items": {
        "Grocery bags (plastic)": 0.006,
        "Brasseries bottles (glass)": 0.22,
        ...
      }
    },
    "fishingGear": { ... }
  }
}
```

#### Controller (cleanup_form_controller.dart)

**Data Storage:**

```dart
List<String> categoryOrder = [];           // Display order
Map<String, TrashCategory> categories = {}; // Categories & items
Map<String, int> trashItems = {};          // User selections (itemName -> count)
bool isLoadingTemplate = false;            // Loading state
```

**Key Methods:**

- `fetchTrashTemplate()` - Fetches and parses the template from Firebase
- `getOrderedCategories()` - Returns categories in the correct order
- `validateSection('Trash Collected')` - Validates user selections

**TrashCategory Model:**

```dart
class TrashCategory {
  final String name;                    // Display name
  final Map<String, double> items;      // itemName -> weight (kg)
}
```

### 3. UI Integration (TrashCollectedSection)

#### Display Flow

1. **Loading State** - Shows spinner while template loads
2. **Empty State** - Shows message if no categories available
3. **Category Headers** - Collapsible headers in `categoryOrder` sequence
4. **Item Controls** - Each item has +/- buttons to set quantity

#### User Actions

```dart
_onItemCountChanged(String itemName, int count)
  ↓
Updates controller.trashItems[itemName] = count
  ↓
Clears field errors
  ↓
Controller notifies listeners (UI rebuilds)
```

### 4. Data During Form Submission

When submitting the cleanup form, the app has access to:

**Weights (for calculation):**

```dart
final weight = categories[categoryKey]!.items[itemName]!;
final quantity = trashItems[itemName]!;
final totalWeight = weight * quantity;  // kg
```

**User Selections:**

```dart
trashItems = {
  "Grocery bags (plastic)": 5,
  "Brasseries bottles (glass)": 3,
  ...
}
```

**Environment:**

```dart
selectedEnvironments.first  // Single selected environment
```

### 5. Workflow for Creating Firestore Document

When user submits the form:

```dart
// 1. Validate all sections
bool isValid = controller.validateSection('Trash Collected');

// 2. Access weights for calculations
for (var entry in controller.trashItems.entries) {
  final itemName = entry.key;
  final quantity = entry.value;

  // Find the category key containing this item
  final categoryKey = controller.categories.entries
    .firstWhere((e) => e.value.items.containsKey(itemName))
    .key;

  final weight = controller.categories[categoryKey]!.items[itemName]!;
  final totalWeight = weight * quantity;

  print('$itemName x $quantity = ${totalWeight}kg');
}

// 3. Create Firestore document
final cleanupData = {
  'basicInfo': { ... },
  'trashCollected': {
    'environment': controller.selectedEnvironments.first,
    'items': controller.trashItems,  // itemName -> count
    'weights': { ... },              // itemName -> kg (calculated)
    'totalWeight': totalWeight,      // sum of all weights
  },
  'timestamp': FieldValue.serverTimestamp(),
};

await FirebaseFirestore.instance
  .collection('cleanups')
  .doc(cleanupId)
  .set(cleanupData);
```

## Configuration & Maintenance

### Adding New Items

1. Update Firebase document: `/app-templates/trash_template`
2. Add to appropriate category's `items` object
3. Assign weight in kg (empty item weight)
4. App will automatically load on next startup

### Reordering Categories

1. Modify `categoryOrder` array in Firebase document
2. App will display in new order on next startup

### Updating Weights

1. Update values in `items` objects
2. Existing cleanups keep their recorded weights
3. Future cleanups use new weights

## Testing the Integration

### Manual Testing

1. Open Cleanup Screen
2. Navigate to "Trash Collected" section
3. Verify categories load and display in correct order
4. Verify items appear under each category
5. Test +/- buttons to increment/decrement
6. Verify data persists when closing/reopening section

### Debug Logging

Add logging in `fetchTrashTemplate()` to track:

```dart
debugPrint('[TrashTemplate] Loaded ${categories.length} categories');
debugPrint('[TrashTemplate] Category order: $categoryOrder');
debugPrint('[TrashTemplate] ${category.name} has ${category.items.length} items');
```

## Current Status

✅ **Implemented:**

- Firebase template loading from `/app-templates/trash_template`
- Category ordering via `categoryOrder` array
- Weight storage in category items
- UI display with collapsible categories
- +/- controls for quantity selection
- Data persistence in controller
- Loading and empty states

⚠️ **TODO:**

- Add calculation logic for total weight during submission
- Add confirmation preview showing selected items and weights
- Add option to save cleanup record to Firestore
- Add error handling for Firebase connection issues

## API Reference

### CleanupFormController

```dart
// Properties
List<String> categoryOrder              // Display order
Map<String, TrashCategory> categories   // All categories & items
Map<String, int> trashItems             // User selections
bool isLoadingTemplate                  // Loading indicator

// Methods
Future<void> fetchTrashTemplate()       // Load from Firebase
List<MapEntry<String, TrashCategory>> getOrderedCategories()
bool validateSection(String title)      // Validate selections
void clearFieldError(String field)      // Clear validation error
```

### TrashCategory Model

```dart
class TrashCategory {
  final String name;                    // Display name
  final Map<String, double> items;      // itemName -> weight (kg)
}
```

## Example: Complete Submission Flow

```dart
// In NewCleanupScreen or submission handler:

// 1. Validate Trash Collected section
if (!controller.validateSection('Trash Collected')) {
  return; // Show errors
}

// 2. Get selected items with weights
final trashData = <String, dynamic>{};
double totalWeight = 0;

controller.trashItems.forEach((itemName, quantity) {
  // Find weight from categories
  final category = controller.categories.values.firstWhere(
    (cat) => cat.items.containsKey(itemName)
  );
  final weightPerItem = category.items[itemName]!;
  final itemTotal = weightPerItem * quantity;

  trashData[itemName] = {
    'quantity': quantity,
    'weightPerItem': weightPerItem,
    'totalWeight': itemTotal,
  };

  totalWeight += itemTotal;
});

// 3. Create cleanup record
final cleanupRecord = {
  'date': controller.date,
  'location': controller.location,
  'environment': controller.selectedEnvironments.first,
  'peopleCount': controller.peopleCount,
  'groupName': controller.groupName,
  'trash': {
    'items': trashData,
    'totalWeight': totalWeight,
    'unit': 'kg',
  },
  'timestamp': FieldValue.serverTimestamp(),
};

// 4. Save to Firestore
await FirebaseFirestore.instance
  .collection('cleanups')
  .add(cleanupRecord);
```
