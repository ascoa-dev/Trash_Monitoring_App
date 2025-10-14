import 'package:fuzzy/fuzzy.dart';
import 'package:ascoa_app/app/models/city_model.dart';
import 'package:ascoa_app/app/models/cities_config.dart';

/// City search utility with fuzzy matching support
class CitySearch {
  final CitiesConfig config;
  late Fuzzy<City> _fuzzy;

  CitySearch(this.config) {
    _fuzzy = Fuzzy<City>(
      config.cities,
      options: FuzzyOptions(
        keys: [
          WeightedKey(
            name: 'name',
            getter: (City city) => city.name,
            weight: 0.8,
          ),
          WeightedKey(
            name: 'nameLower',
            getter: (City city) => city.nameLower,
            weight: 1.0,
          ),
          WeightedKey(
            name: 'altNames',
            getter: (City city) => city.altNames.join(' '),
            weight: 0.8,
          ),
          // Add tokenized version for better matching across spaces
          WeightedKey(
            name: 'nameTokenized',
            getter: (City city) => city.name.replaceAll(' ', '').toLowerCase(),
            weight: 0.95,
          ),
        ],
        // More permissive threshold for better fuzzy matching
        // 0.0 = exact match only, 1.0 = very loose matching
        // 0.7 allows "abele" to match "ab leila" (without spaces)
        threshold: config.fuzzyThreshold / 1.0,
        distance: 100,
        isCaseSensitive: false,
        shouldSort: true,
        // Tokenize to help match across word boundaries
        tokenize: true,
      ),
    );
  }

  /// Search cities with fuzzy matching
  List<City> search(String query) {
    if (query.isEmpty) return config.cities;

    final results = _fuzzy.search(query);
    return results.map((r) => r.item).take(config.maxSuggestions).toList();
  }

  /// Get all cities (for initial display)
  List<City> getAllCities() => config.cities;

  /// Check if custom cities are allowed
  bool get allowCustomCities => config.allowCustomCities;

  /// Get max suggestions limit
  int get maxSuggestions => config.maxSuggestions;

  /// Get fuzzy threshold
  int get fuzzyThreshold => config.fuzzyThreshold;
}
