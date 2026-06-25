import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Controller to monitor network connectivity status
class ConnectivityController extends GetxController {
  final RxBool isOnline = true.obs;
  final Connectivity _connectivity = Connectivity();

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  /// Check initial connectivity status
  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      // Default to online if check fails
      isOnline.value = true;
    }
  }

  /// Update connection status based on connectivity result
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // Consider online if any connection type is available
    isOnline.value = results.any((result) => result != ConnectivityResult.none);
  }

  /// Manual check for connectivity (useful before important operations)
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final online = results.any((result) => result != ConnectivityResult.none);
      isOnline.value = online;
      return online;
    } catch (e) {
      return false;
    }
  }
}
