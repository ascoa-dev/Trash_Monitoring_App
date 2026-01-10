import 'package:hive/hive.dart';
import 'package:ascoa_app/app/models/cleanup_model.dart';

part 'cached_cleanup_model.g.dart';

/// Cached version of CleanupModel for offline access in stats screen
@HiveType(typeId: 4)
class CachedCleanupModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final int peopleCount;

  @HiveField(4)
  final String groupName;

  @HiveField(5)
  final String date;

  @HiveField(6)
  final String location;

  @HiveField(7)
  final double? locationLatitude;

  @HiveField(8)
  final double? locationLongitude;

  @HiveField(9)
  final String environment;

  @HiveField(10)
  final Map<String, Map<String, dynamic>> categories;

  @HiveField(11)
  final double totalWeight;

  @HiveField(12)
  final List<String>? photoUrls;

  @HiveField(13)
  final DateTime cachedAt;

  CachedCleanupModel({
    required this.id,
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
    this.photoUrls,
    required this.cachedAt,
  });

  /// Convert from CleanupModel to CachedCleanupModel
  factory CachedCleanupModel.fromCleanupModel(CleanupModel cleanup) {
    // Convert categories to serializable format
    final categoriesMap = <String, Map<String, dynamic>>{};

    cleanup.categories.forEach((categoryName, items) {
      final categoryItems = <String, dynamic>{};
      items.forEach((itemName, cleanupItem) {
        categoryItems[itemName] = {
          'quantity': cleanupItem.quantity,
          'weightPerItem': cleanupItem.weightPerItem,
          'totalWeight': cleanupItem.totalWeight,
        };
      });
      categoriesMap[categoryName] = categoryItems;
    });

    return CachedCleanupModel(
      id: cleanup.id ?? '',
      userId: cleanup.userId,
      createdAt: cleanup.createdAt,
      peopleCount: cleanup.peopleCount,
      groupName: cleanup.groupName,
      date: cleanup.date,
      location: cleanup.location,
      locationLatitude: cleanup.locationLatitude,
      locationLongitude: cleanup.locationLongitude,
      environment: cleanup.environment,
      categories: categoriesMap,
      totalWeight: cleanup.totalWeight,
      photoUrls: cleanup.photoUrls,
      cachedAt: DateTime.now(),
    );
  }

  /// Convert to CleanupModel for use in app
  CleanupModel toCleanupModel() {
    // Convert categories back to CleanupItem format
    final categoriesMap = <String, Map<String, CleanupItem>>{};

    categories.forEach((categoryName, items) {
      final categoryItems = <String, CleanupItem>{};
      items.forEach((itemName, itemData) {
        final itemMap = itemData as Map<String, dynamic>;
        categoryItems[itemName] = CleanupItem(
          name: itemName,
          quantity: itemMap['quantity'] as int,
          weightPerItem: (itemMap['weightPerItem'] as num).toDouble(),
          totalWeight: (itemMap['totalWeight'] as num).toDouble(),
        );
      });
      categoriesMap[categoryName] = categoryItems;
    });

    return CleanupModel(
      id: id,
      userId: userId,
      createdAt: createdAt,
      peopleCount: peopleCount,
      groupName: groupName,
      date: date,
      location: location,
      locationLatitude: locationLatitude,
      locationLongitude: locationLongitude,
      environment: environment,
      categories: categoriesMap,
      totalWeight: totalWeight,
      photoUrls: photoUrls,
    );
  }
}
