import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:we_monitor/app/routes/app_routes.dart';
import 'package:we_monitor/shared/analytics/analytics_service.dart';
import 'package:we_monitor/shared/utils/deep_link.dart';

/// Routes incoming app links without ever resetting the navigation stack
/// (except password reset, which owns the whole flow).
///
/// Links that arrive before the app is ready (cold start, or signed-out /
/// still on the auth gate) are kept as [_pending] and opened once the main
/// screen is mounted. app_links 6.x delivers the initial link on
/// `uriLinkStream` too, so only the stream is used.
class DeepLinkService {
  DeepLinkService._();

  static DeepLink? _pending;
  static bool _appReady = false;
  // A count, not a flag: offAllNamed(home) can dispose the old MainScreen
  // after the new one has mounted.
  static int _homeMounts = 0;
  static StreamSubscription<Uri>? _sub;

  /// Call before runApp: only subscribes and stores, never navigates.
  static void init() {
    _sub ??= AppLinks().uriLinkStream.listen(
      _handle,
      onError: (Object e) => debugPrint('[DeepLink] stream error: $e'),
    );
  }

  /// Call once GetMaterialApp is mounted (first frame).
  static void markAppReady() {
    _appReady = true;
    final p = _pending;
    if (p is ResetPasswordLink) {
      _pending = null;
      _open(p);
    }
  }

  /// MainScreen calls these in initState (post-frame) / dispose.
  static void homeMounted() {
    _homeMounts++;
    final p = _pending;
    if (p != null) {
      _pending = null;
      _open(p);
    }
  }

  static void homeDisposed() => _homeMounts--;

  static void _handle(Uri uri) {
    debugPrint('[DeepLink] received: $uri');
    final link = parseDeepLink(uri);
    if (link is UnknownLink) return;
    final canOpenNow = _appReady && (link is ResetPasswordLink || _homeMounts > 0);
    if (canOpenNow) {
      _open(link);
    } else {
      _pending = link;
    }
  }

  static void _open(DeepLink link) {
    switch (link) {
      case ResetPasswordLink(:final oobCode):
        Get.offAllNamed(
          AppRoutes.resetPassword,
          arguments: {'oobCode': oobCode},
        );
      case CleanupLink(:final id):
        _openShared('cleanup', id);
      case HotspotLink(:final id):
        _openShared('hotspot', id);
      case UnknownLink():
        break;
    }
  }

  static void _openShared(String type, String id) {
    Analytics.track(AnalyticsEvents.deepLinkOpened, {'type': type});
    Get.toNamed(AppRoutes.sharedLink, arguments: {'type': type, 'id': id});
  }
}
