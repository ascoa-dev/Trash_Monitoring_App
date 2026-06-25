import 'package:hive/hive.dart';
import 'city_model.dart';

part 'cities_config.g.dart';

@HiveType(typeId: 1)
class CitiesConfig {
  @HiveField(0)
  final bool allowCustomCities;

  @HiveField(1)
  final List<City> cities;

  @HiveField(2)
  final int fuzzyThreshold;

  @HiveField(3)
  final int maxSuggestions;

  @HiveField(4)
  final DateTime? updatedAt;

  @HiveField(5)
  final String? customCitiesWarning;

  CitiesConfig({
    required this.allowCustomCities,
    required this.cities,
    required this.fuzzyThreshold,
    required this.maxSuggestions,
    this.updatedAt,
    this.customCitiesWarning,
  });

  factory CitiesConfig.fromMap(Map<String, dynamic> map) {
    return CitiesConfig(
      allowCustomCities: map['allowCustomCities'] as bool? ?? false,
      cities:
          ((map['cities'] as List?) ?? [])
              .map((e) => City.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList(),
      fuzzyThreshold: (map['fuzzyThreshold'] as num?)?.toInt() ?? 80,
      maxSuggestions: (map['maxSuggestions'] as num?)?.toInt() ?? 5,
      updatedAt:
          map['updatedAt'] == null
              ? null
              : DateTime.tryParse(map['updatedAt'].toString()),
      customCitiesWarning: map['customCitiesWarning'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'allowCustomCities': allowCustomCities,
    'cities': cities.map((c) => c.toMap()).toList(),
    'fuzzyThreshold': fuzzyThreshold,
    'maxSuggestions': maxSuggestions,
    'updatedAt': updatedAt?.toIso8601String(),
    'customCitiesWarning': customCitiesWarning,
  };
}
