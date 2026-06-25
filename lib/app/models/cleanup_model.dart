import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for a cleanup record stored in Firestore
class CleanupModel {
  final String? id; // Firestore document ID
  final String userId; // User who created the cleanup
  final DateTime createdAt;

  // Basic Information
  final int peopleCount;
  final String groupName;
  final String date; // Format: dd/mm/yyyy
  final String location;
  final double? locationLatitude;
  final double? locationLongitude;

  // Trash Collected
  final String environment;
  final Map<String, Map<String, CleanupItem>>
  categories; // categoryName -> {itemName -> CleanupItem}
  final double totalWeight; // kg

  // Optional metadata
  final String? notes;
  final List<String>? photoUrls;

  CleanupModel({
    this.id,
    required this.userId,
    required this.createdAt,
    required this.peopleCount,
    required this.groupName,
    required this.date,
    required this.location,
    this.locationLatitude,
    this.locationLongitude,
    required this.environment,
    required this.categories,
    required this.totalWeight,
    this.notes,
    this.photoUrls,
  });

  /// Create from form controller data
  factory CleanupModel.fromFormData({
    required String userId,
    required int peopleCount,
    required String groupName,
    required String date,
    required String location,
    double? locationLatitude,
    double? locationLongitude,
    required String environment,
    required Map<String, int> trashItems, // itemName -> quantity
    required Map<String, double>
    itemWeights, // itemName -> weight per item (kg)
    required Map<String, String> itemCategories, // itemName -> categoryName
  }) {
    // Organize items by category
    final categories = <String, Map<String, CleanupItem>>{};
    double totalWeight = 0;

    trashItems.forEach((itemName, quantity) {
      final weightPerItem = itemWeights[itemName] ?? 0;
      final itemTotalWeight = weightPerItem * quantity;
      final categoryName = itemCategories[itemName] ?? 'Uncategorized';

      // Create CleanupItem
      final cleanupItem = CleanupItem(
        name: itemName,
        quantity: quantity,
        weightPerItem: weightPerItem,
        totalWeight: itemTotalWeight,
      );

      // Add to category
      if (!categories.containsKey(categoryName)) {
        categories[categoryName] = {};
      }
      categories[categoryName]![itemName] = cleanupItem;

      totalWeight += itemTotalWeight;
    });

    return CleanupModel(
      userId: userId,
      createdAt: DateTime.now(),
      peopleCount: peopleCount,
      groupName: groupName,
      date: date,
      location: location,
      locationLatitude: locationLatitude,
      locationLongitude: locationLongitude,
      environment: environment,
      categories: categories,
      totalWeight: totalWeight,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    // Convert categories to the desired structure
    final categoriesMap = <String, dynamic>{};

    categories.forEach((categoryName, items) {
      final categoryItems = <String, dynamic>{};
      items.forEach((itemName, cleanupItem) {
        categoryItems[itemName] = {
          'count': cleanupItem.quantity,
          'weightPerItem': cleanupItem.weightPerItem,
          'totalWeight': cleanupItem.totalWeight,
        };
      });
      categoriesMap[categoryName] = categoryItems;
    });

    return {
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'basicInfo': {
        'peopleCount': peopleCount,
        'groupName': groupName,
        'date': date,
        'location': location,
        'locationLatitude': locationLatitude,
        'locationLongitude': locationLongitude,
      },
      'trashCollected': {
        'environment': environment,
        'categories': categoriesMap,
        'totalWeight': totalWeight,
      },
      'metadata': {'notes': notes, 'photoUrls': photoUrls ?? []},
    };
  }

  /// Create from Firestore document
  factory CleanupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final basicInfo = data['basicInfo'] as Map<String, dynamic>;
    final trashCollected = data['trashCollected'] as Map<String, dynamic>;
    final categoriesData = trashCollected['categories'] as Map<String, dynamic>;
    final metadata = data['metadata'] as Map<String, dynamic>? ?? {};

    // Parse categories structure
    final categories = <String, Map<String, CleanupItem>>{};

    categoriesData.forEach((categoryName, categoryItems) {
      final items = <String, CleanupItem>{};
      final categoryItemsMap = categoryItems as Map<String, dynamic>;

      categoryItemsMap.forEach((itemName, itemData) {
        final itemMap = itemData as Map<String, dynamic>;
        items[itemName] = CleanupItem(
          name: itemName,
          quantity: itemMap['count'] as int,
          weightPerItem: (itemMap['weightPerItem'] as num).toDouble(),
          totalWeight: (itemMap['totalWeight'] as num).toDouble(),
        );
      });

      categories[categoryName] = items;
    });

    return CleanupModel(
      id: doc.id,
      userId: data['userId'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      peopleCount: basicInfo['peopleCount'] as int,
      groupName: basicInfo['groupName'] as String,
      date: basicInfo['date'] as String,
      location: basicInfo['location'] as String,
      locationLatitude: basicInfo['locationLatitude'] as double?,
      locationLongitude: basicInfo['locationLongitude'] as double?,
      environment: trashCollected['environment'] as String,
      categories: categories,
      totalWeight: (trashCollected['totalWeight'] as num).toDouble(),
      notes: metadata['notes'] as String?,
      photoUrls: (metadata['photoUrls'] as List<dynamic>?)?.cast<String>(),
    );
  }

  /// Create a copy with updated fields
  CleanupModel copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    int? peopleCount,
    String? groupName,
    String? date,
    String? location,
    double? locationLatitude,
    double? locationLongitude,
    String? environment,
    Map<String, Map<String, CleanupItem>>? categories,
    double? totalWeight,
    String? notes,
    List<String>? photoUrls,
  }) {
    return CleanupModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      peopleCount: peopleCount ?? this.peopleCount,
      groupName: groupName ?? this.groupName,
      date: date ?? this.date,
      location: location ?? this.location,
      locationLatitude: locationLatitude ?? this.locationLatitude,
      locationLongitude: locationLongitude ?? this.locationLongitude,
      environment: environment ?? this.environment,
      categories: categories ?? this.categories,
      totalWeight: totalWeight ?? this.totalWeight,
      notes: notes ?? this.notes,
      photoUrls: photoUrls ?? this.photoUrls,
    );
  }
}

/// Model for individual trash item in a cleanup
class CleanupItem {
  final String name;
  final int quantity;
  final double weightPerItem; // kg per single item
  final double totalWeight; // kg (quantity * weightPerItem)

  CleanupItem({
    required this.name,
    required this.quantity,
    required this.weightPerItem,
    required this.totalWeight,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'weightPerItem': weightPerItem,
      'totalWeight': totalWeight,
    };
  }

  factory CleanupItem.fromMap(Map<String, dynamic> map) {
    return CleanupItem(
      name: map['name'] as String,
      quantity: map['quantity'] as int,
      weightPerItem: (map['weightPerItem'] as num).toDouble(),
      totalWeight: (map['totalWeight'] as num).toDouble(),
    );
  }
}
