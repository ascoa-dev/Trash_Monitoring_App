import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Service to interact with Google Places API
/// Handles autocomplete search and place details
class GooglePlacesService {
  // TODO: Replace with your actual Google Maps API key
  // This should ideally come from environment variables or secure config
  static const String _apiKey = 'AIzaSyD3Of3mq_589PvECQl_yHyQ_coI2bWUCD0';

  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  /// Search for place suggestions based on user input
  /// Returns up to [maxResults] suggestions (default 3)
  /// Restricted to Cameroon only (country code: CM)
  static Future<List<PlaceSuggestion>> searchPlaces(
    String query, {
    int maxResults = 3,
  }) async {
    if (query.isEmpty) return [];

    try {
      // Add components=country:cm to restrict results to Cameroon
      final url = Uri.parse(
        '$_baseUrl/autocomplete/json?input=$query&components=country:cm&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          return predictions
              .take(maxResults)
              .map((p) => PlaceSuggestion.fromJson(p))
              .toList();
        }
      }
    } catch (e) {
      // Log error in production, return empty list
      debugPrint('Error searching places: $e');
    }

    return [];
  }

  /// Get detailed information about a place using place_id
  /// Returns coordinates (LatLng) and formatted address
  static Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/details/json?place_id=$placeId&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final result = data['result'];
          final location = result['geometry']['location'];

          return PlaceDetails(
            placeId: placeId,
            formattedAddress: result['formatted_address'] ?? '',
            latLng: LatLng(location['lat'], location['lng']),
          );
        }
      }
    } catch (e) {
      debugPrint('Error getting place details: $e');
    }

    return null;
  }
}

/// Model for place suggestion from autocomplete
class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final structuredFormatting = json['structured_formatting'];

    return PlaceSuggestion(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: structuredFormatting['main_text'] ?? '',
      secondaryText: structuredFormatting['secondary_text'] ?? '',
    );
  }
}

/// Model for detailed place information
class PlaceDetails {
  final String placeId;
  final String formattedAddress;
  final LatLng latLng;

  PlaceDetails({
    required this.placeId,
    required this.formattedAddress,
    required this.latLng,
  });
}
