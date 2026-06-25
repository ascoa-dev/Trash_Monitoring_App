import 'package:firebase_analytics/firebase_analytics.dart';

/// User identification and property management for analytics
class AnalyticsUser {
  AnalyticsUser._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Identify user after login (Firebase uses Firebase Auth UID automatically)
  static Future<void> identify(String userId) async {
    await _analytics.setUserId(id: userId);
  }

  /// Clear user identity on logout
  static Future<void> clearIdentity() async {
    await _analytics.setUserId(id: null);
  }

  /// Set safe user properties (no PII)
  static Future<void> setUserProperties({
    bool? hasCompletedProfile,
    String? cleanupCountBucket,
    String? city,
    String? signupMethod,
  }) async {
    if (hasCompletedProfile != null) {
      await _analytics.setUserProperty(
        name: 'has_completed_profile',
        value: hasCompletedProfile.toString(),
      );
    }
    if (cleanupCountBucket != null) {
      await _analytics.setUserProperty(
        name: 'cleanup_count_bucket',
        value: cleanupCountBucket,
      );
    }
    if (city != null) {
      await _analytics.setUserProperty(name: 'city', value: city);
    }
    if (signupMethod != null) {
      await _analytics.setUserProperty(
        name: 'signup_method',
        value: signupMethod,
      );
    }
  }

  /// Get cleanup count bucket for user property
  static String getCleanupBucket(int count) {
    if (count == 0) return '0';
    if (count <= 5) return '1-5';
    if (count <= 10) return '6-10';
    if (count <= 25) return '11-25';
    if (count <= 50) return '26-50';
    return '50+';
  }
}
