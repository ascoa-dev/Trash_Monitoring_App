import 'package:get/get.dart';
import '../services/cities_service.dart';
import '../../app/models/cities_config.dart';
import '../../app/models/city_model.dart';
import '../utils/city_search.dart';

class CitiesController extends GetxController {
  final CitiesService _service = Get.find<CitiesService>();

  CitySearch? _search;
  final isReady = false.obs;
  final suggestions = <City>[].obs;

  CitiesConfig? get config => _service.config;

  bool get allowCustomCities => _search?.allowCustomCities ?? false;

  String get customCitiesWarning =>
      config?.customCitiesWarning ??
      'This city is not officially recognized. Please double-check.';

  List<String> cityNames() => config?.cities.map((c) => c.name).toList() ?? [];

  @override
  void onInit() {
    super.onInit();
    _initializeSearch();
  }

  void _initializeSearch() {
    final currentConfig = _service.config;
    if (currentConfig != null) {
      _search = CitySearch(currentConfig);
      isReady.value = true;
    }
  }

  /// Search cities with fuzzy matching
  void searchCities(String query) {
    if (!isReady.value || _search == null) return;
    suggestions.assignAll(_search!.search(query));
  }

  /// Get all cities for initial display
  List<City> getAllCities() {
    return _search?.getAllCities() ?? [];
  }

  /// Get city suggestions as strings
  List<String> getCitySuggestions(String query) {
    if (!isReady.value || _search == null) return [];
    return _search!.search(query).map((c) => c.name).toList();
  }

  /// Check if a city name exists in the configured cities list
  bool isCityValid(String cityName) {
    if (!isReady.value || _search == null) return true; // Allow if not ready
    final trimmed = cityName.trim();
    if (trimmed.isEmpty) return false;
    
    // Check exact match (case-insensitive)
    final cityNamesLower = cityNames().map((c) => c.toLowerCase()).toList();
    return cityNamesLower.contains(trimmed.toLowerCase());
  }
}
