/// Each item type (e.g. "Plastic Bags", "Bottle Caps") under a category
class CleanupItem {
  final String name;
  final int count;

  CleanupItem({required this.name, required this.count});

  Map<String, dynamic> toJson() => {'name': name, 'count': count};

  factory CleanupItem.fromJson(Map<String, dynamic> json) =>
      CleanupItem(name: json['name'], count: json['count'] ?? 0);
}

/// A category grouping items, e.g. "Fishing Gear", "Most Likely to Find"
class CleanupCategory {
  final String categoryName;
  final List<CleanupItem> items;

  CleanupCategory({required this.categoryName, required this.items});

  Map<String, dynamic> toJson() => {
    'categoryName': categoryName,
    'items': items.map((e) => e.toJson()).toList(),
  };

  factory CleanupCategory.fromJson(
    Map<String, dynamic> json,
  ) => CleanupCategory(
    categoryName: json['categoryName'],
    items: (json['items'] as List).map((e) => CleanupItem.fromJson(e)).toList(),
  );
}
