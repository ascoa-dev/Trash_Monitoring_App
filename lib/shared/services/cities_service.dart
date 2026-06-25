import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:ascoa_app/app/models/cities_config.dart';

class CitiesService extends GetxService {
  static const _boxName = 'config_cities';
  static const _key = 'cities_config';

  final Rxn<CitiesConfig> _config = Rxn<CitiesConfig>();

  CitiesConfig? get config => _config.value;

  /// Initialize service: load from cache, then fetch from Firestore
  Future<CitiesService> init() async {
    // Try to load from Hive first for instant access
    await loadFromLocal();

    // Attempt to fetch from Firestore and update cache
    await fetchAndCache();

    return this;
  }

  /// Fetch latest cities config from Firestore and cache locally
  Future<CitiesConfig?> fetchAndCache() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('config')
              .doc('cities')
              .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final parsed = CitiesConfig.fromMap(data);
        _config.value = parsed;

        final box = await Hive.openBox<CitiesConfig>(_boxName);
        await box.put(_key, parsed);

        return parsed;
      }
    } catch (e) {
      debugPrint('Failed to fetch cities config from Firestore: $e');
    }
    return null;
  }

  /// Load cached config from Hive
  Future<CitiesConfig?> loadFromLocal() async {
    try {
      final box = await Hive.openBox<CitiesConfig>(_boxName);
      final stored = box.get(_key);
      if (stored != null) {
        _config.value = stored;
        return stored;
      }
    } catch (e) {
      debugPrint('Failed to load cities config from Hive: $e');
    }
    return null;
  }

  /// Always get the freshest data when app boots
  Future<CitiesConfig?> initializeOnAppStart() async {
    final config = await fetchAndCache();
    if (config != null) return config;
    return loadFromLocal();
  }
}
