/// Centralized property key constants for Firebase Analytics
class AnalyticsProps {
  AnalyticsProps._();

  // Common
  static const String method = 'method';
  static const String reason = 'reason';
  static const String source = 'source';
  static const String success = 'success';
  static const String errorCode = 'error_code';

  // Auth
  static const String authMethod = 'auth_method';
  static const String signupMethod = 'signup_method';

  // Content
  static const String articleId = 'article_id';
  static const String articleTitle = 'article_title';
  static const String articleUrl = 'article_url';
  static const String position = 'position';
  static const String index = 'index';

  // Cleanup
  static const String section = 'section';
  static const String photosCount = 'photos_count';
  static const String trashKg = 'trash_kg';
  static const String environment = 'environment';
  static const String cleanupId = 'cleanup_id';
  static const String isOffline = 'is_offline';

  // Stats
  static const String cleanupsCount = 'cleanups_count';
  static const String chartType = 'chart_type';
  static const String markersCount = 'markers_count';
  static const String filterType = 'filter_type';
  static const String filterValue = 'filter_value';

  // Profile
  static const String fieldsChanged = 'fields_changed';
  static const String step = 'step';

  // Session (auto-attached)
  static const String appVersion = 'app_version';
  static const String platform = 'platform';
  static const String env = 'env';
  static const String userLoggedIn = 'user_logged_in';
}

/// Auth method values
class AuthMethods {
  AuthMethods._();

  static const String email = 'email';
  static const String google = 'google';
  static const String facebook = 'facebook';
}

/// Cleanup section values
class CleanupSections {
  CleanupSections._();

  static const String basicInfo = 'basic_info';
  static const String trashCollected = 'trash_collected';
  static const String photos = 'photos';
  static const String photosVideos = 'photos_videos';
}

/// Filter type values
class FilterTypes {
  FilterTypes._();

  static const String date = 'date';
  static const String environment = 'environment';
}
