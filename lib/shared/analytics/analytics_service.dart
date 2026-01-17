import 'dart:io' show Platform;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'analytics_events.dart';
import 'analytics_props.dart';
import 'analytics_user.dart';

// Export related files for convenience
export 'analytics_events.dart';
export 'analytics_props.dart';
export 'analytics_user.dart';

/// Central analytics service - single entry point for all tracking
///
/// Usage:
/// ```dart
/// Analytics.track(AnalyticsEvents.loginSuccess, {
///   AnalyticsProps.method: AuthMethods.email,
/// });
/// ```
class Analytics {
  Analytics._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  static bool _initialized = false;
  static String? _appVersion;
  static String? _platform;
  static String? _env;

  /// Get the FirebaseAnalytics observer for Navigator
  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Initialize analytics - call in main.dart after Firebase init
  static Future<void> init() async {
    if (_initialized) return;

    // Disable in debug mode
    final isDebug = kDebugMode;
    await _analytics.setAnalyticsCollectionEnabled(!isDebug);
    await _crashlytics.setCrashlyticsCollectionEnabled(!isDebug);

    if (!isDebug) {
      // Set up Flutter error handling for Crashlytics
      FlutterError.onError = (errorDetails) {
        _crashlytics.recordFlutterFatalError(errorDetails);
      };

      // Set up async error handling
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics.recordError(error, stack, fatal: true);
        return true;
      };
    }

    // Get app info
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
    } catch (_) {
      _appVersion = 'unknown';
    }

    _platform = kIsWeb ? 'web' : Platform.operatingSystem;
    _env = isDebug ? 'debug' : 'production';

    _initialized = true;

    // Track app opened
    track(AnalyticsEvents.appOpened);
  }

  /// Track an event with optional properties
  static Future<void> track(
    String eventName, [
    Map<String, Object>? properties,
  ]) async {
    if (kDebugMode) {
      debugPrint('[Analytics] $eventName: $properties');
    }

    try {
      // Merge global properties
      final enrichedProps = <String, Object>{
        ...?properties,
        AnalyticsProps.appVersion: _appVersion ?? 'unknown',
        AnalyticsProps.platform: _platform ?? 'unknown',
        AnalyticsProps.env: _env ?? 'unknown',
      };

      await _analytics.logEvent(name: eventName, parameters: enrichedProps);
    } catch (e) {
      // Never let analytics crash the app
      debugPrint('[Analytics] Error tracking $eventName: $e');
    }
  }

  /// Track screen view
  static Future<void> screenView(String screenName) async {
    if (kDebugMode) {
      debugPrint('[Analytics] Screen: $screenName');
      return;
    }

    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e) {
      debugPrint('[Analytics] Error tracking screen $screenName: $e');
    }
  }

  /// Log non-fatal error to Crashlytics
  static Future<void> error(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    if (kDebugMode) {
      debugPrint('[Analytics] Error ($reason): $error');
      if (stackTrace != null) {
        debugPrint('[Analytics] Stack: $stackTrace');
      }
      return;
    }

    try {
      await _crashlytics.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
    } catch (e) {
      debugPrint('[Analytics] Error logging error: $e');
    }
  }

  /// Log a custom key-value pair to Crashlytics for context
  static Future<void> setCustomKey(String key, Object value) async {
    if (kDebugMode) return;

    try {
      await _crashlytics.setCustomKey(key, value);
    } catch (e) {
      debugPrint('[Analytics] Error setting custom key: $e');
    }
  }

  /// Log message to Crashlytics (breadcrumb)
  static Future<void> log(String message) async {
    if (kDebugMode) {
      debugPrint('[Analytics] Log: $message');
      return;
    }

    try {
      await _crashlytics.log(message);
    } catch (e) {
      debugPrint('[Analytics] Error logging message: $e');
    }
  }

  // ========== Convenience Methods ==========

  /// Identify user after login
  static Future<void> identify(String userId) => AnalyticsUser.identify(userId);

  /// Clear user on logout
  static Future<void> clearIdentity() => AnalyticsUser.clearIdentity();

  /// Set user properties
  static Future<void> setUserProperties({
    bool? hasCompletedProfile,
    String? cleanupCountBucket,
    String? city,
    String? signupMethod,
  }) => AnalyticsUser.setUserProperties(
    hasCompletedProfile: hasCompletedProfile,
    cleanupCountBucket: cleanupCountBucket,
    city: city,
    signupMethod: signupMethod,
  );

  /// Get cleanup count bucket helper
  static String getCleanupBucket(int count) =>
      AnalyticsUser.getCleanupBucket(count);
}
