import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:we_monitor/shared/controllers/connectivity_controller.dart';
import 'package:we_monitor/shared/services/google_places_service.dart';

/// A location the user explicitly chose. This is the single source of truth
/// for cleanup / hotspot coordinates — map camera movement never produces one.
class PickedLocation {
  final double latitude;
  final double longitude;
  final String address;

  /// True when Google confirmed the point is in Cameroon. False when only the
  /// offline bounding-box check passed (re-verify before submitting online).
  final bool verified;

  const PickedLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.verified,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  static String coordsLabel(LatLng p) =>
      'Lat ${p.latitude.toStringAsFixed(5)}, Lng ${p.longitude.toStringAsFixed(5)}';
}

enum LocationCheckStatus { valid, outsideCameroon }

class LocationCheck {
  final LocationCheckStatus status;
  final PickedLocation? location;

  const LocationCheck._(this.status, this.location);

  bool get isValid => status == LocationCheckStatus.valid;
}

/// Validates that a point is inside Cameroon.
///
/// Online: Google reverse geocoding is the source of truth. If Google is
/// unreachable, fall back to the bounding box and mark the result unverified.
/// Offline: bounding box only (unverified).
class LocationValidator {
  static const LatLng defaultCenter = LatLng(3.8480, 11.5021); // Yaoundé
  static final LatLngBounds cameroonBounds = LatLngBounds(
    southwest: const LatLng(1.65, 8.49),
    northeast: const LatLng(13.08, 16.19),
  );

  static bool inCameroonBbox(LatLng p) {
    return p.latitude >= 1.72767263428 &&
        p.latitude <= 12.8593962671 &&
        p.longitude >= 8.48881554529 &&
        p.longitude <= 16.0128524106;
  }

  /// [preferredAddress] keeps a label the user picked (e.g. a search result)
  /// instead of replacing it with the reverse-geocoded address.
  static Future<LocationCheck> check(
    LatLng p, {
    String? preferredAddress,
  }) async {
    final isOnline = Get.find<ConnectivityController>().isOnline.value;
    final geo =
        isOnline
            ? await GooglePlacesService.reverseGeocode(p.latitude, p.longitude)
            : null;

    if (geo == null) {
      // Offline or service failure: bounding box is the only check available.
      if (!inCameroonBbox(p)) {
        return const LocationCheck._(LocationCheckStatus.outsideCameroon, null);
      }
      return LocationCheck._(
        LocationCheckStatus.valid,
        PickedLocation(
          latitude: p.latitude,
          longitude: p.longitude,
          address: _nonEmpty(preferredAddress) ?? PickedLocation.coordsLabel(p),
          verified: false,
        ),
      );
    }

    if (!geo.isCameroon) {
      return const LocationCheck._(LocationCheckStatus.outsideCameroon, null);
    }
    return LocationCheck._(
      LocationCheckStatus.valid,
      PickedLocation(
        latitude: p.latitude,
        longitude: p.longitude,
        address:
            _nonEmpty(preferredAddress) ??
            _nonEmpty(geo.formattedAddress) ??
            PickedLocation.coordsLabel(p),
        verified: true,
      ),
    );
  }

  /// Re-checks an unverified location once a connection is available.
  /// Returns the (possibly upgraded) location, or null if it is outside
  /// Cameroon.
  static Future<PickedLocation?> reverify(PickedLocation loc) async {
    if (loc.verified) return loc;
    if (!Get.find<ConnectivityController>().isOnline.value) return loc;
    final isCoordsLabel = loc.address == PickedLocation.coordsLabel(loc.latLng);
    final result = await check(
      loc.latLng,
      preferredAddress: isCoordsLabel ? null : loc.address,
    );
    return result.location;
  }

  static String? _nonEmpty(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s;
}
