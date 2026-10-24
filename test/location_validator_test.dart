import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:we_monitor/shared/controllers/connectivity_controller.dart';
import 'package:we_monitor/shared/services/location_validator.dart';

class _OfflineConnectivity extends ConnectivityController {
  // Skip the plugin-backed listener; tests only need the flag.
  @override
  // ignore: must_call_super
  void onInit() {
    isOnline.value = false;
  }
}

void main() {
  setUp(() => Get.put<ConnectivityController>(_OfflineConnectivity()));
  tearDown(Get.reset);

  test('offline: point in Cameroon is accepted but unverified', () async {
    final result = await LocationValidator.check(const LatLng(4.0511, 9.7679));
    expect(result.isValid, isTrue);
    expect(result.location!.verified, isFalse);
    expect(result.location!.address, startsWith('Lat 4.05110'));
  });

  test('offline: preferred address is kept', () async {
    final result = await LocationValidator.check(
      const LatLng(4.0511, 9.7679),
      preferredAddress: 'Douala',
    );
    expect(result.location!.address, 'Douala');
  });

  test('offline: point outside the box is rejected, never moved', () async {
    final result = await LocationValidator.check(const LatLng(6.5244, 3.3792));
    expect(result.status, LocationCheckStatus.outsideCameroon);
    expect(result.location, isNull);
  });

  test('reverify keeps an unverified location while offline', () async {
    const loc = PickedLocation(
      latitude: 4.0511,
      longitude: 9.7679,
      address: 'Douala',
      verified: false,
    );
    expect(await LocationValidator.reverify(loc), same(loc));
  });
}
