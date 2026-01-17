/// Centralized event name constants for Firebase Analytics
/// All event names follow snake_case convention
class AnalyticsEvents {
  AnalyticsEvents._();

  // ========== App Lifecycle ==========
  static const String appOpened = 'app_opened';
  static const String appBackgrounded = 'app_backgrounded';
  static const String appForegrounded = 'app_foregrounded';

  // ========== Auth Flow - Login ==========
  static const String loginScreenViewed = 'login_screen_viewed';
  static const String loginAttempted = 'login_attempted';
  static const String loginSuccess = 'login_success';
  static const String loginFailed = 'login_failed';

  // ========== Auth Flow - Signup ==========
  static const String signupScreenViewed = 'signup_screen_viewed';
  static const String signupStarted = 'signup_started';
  static const String signupSuccess = 'signup_success';
  static const String signupFailed = 'signup_failed';

  // ========== Auth Flow - Email Verification ==========
  static const String emailVerificationViewed = 'email_verification_viewed';
  static const String emailVerificationSent = 'email_verification_sent';
  static const String emailVerificationResent = 'email_verification_resent';
  static const String emailVerified = 'email_verified';

  // ========== Auth Flow - Forgot Password ==========
  static const String forgotPasswordViewed = 'forgot_password_viewed';
  static const String passwordResetRequested = 'password_reset_requested';
  static const String passwordResetSuccess = 'password_reset_success';
  static const String passwordResetFailed = 'password_reset_failed';

  // ========== Auth Flow - Change Password ==========
  static const String changePasswordSuccess = 'change_password_success';
  static const String changePasswordFailed = 'change_password_failed';

  // ========== Auth Flow - Complete Profile ==========
  static const String profileCompletionViewed = 'profile_completion_viewed';
  static const String profileCompletionStarted = 'profile_completion_started';
  static const String profileCompletionCompleted =
      'profile_completion_completed';
  static const String profileCompletionFailed = 'profile_completion_failed';
  static const String profilePhotoUploaded = 'profile_photo_uploaded';

  // ========== Main Navigation ==========
  static const String homeViewed = 'home_viewed';
  static const String statsViewed = 'stats_viewed';
  static const String newsViewed = 'news_viewed';
  static const String profileViewed = 'profile_viewed';

  // ========== Home Screen ==========
  static const String homeCarouselViewed = 'home_carousel_viewed';
  static const String homeCarouselItemClicked = 'home_carousel_item_clicked';
  static const String newsCarouselLoaded = 'news_carousel_loaded';
  static const String newsArticleClicked = 'news_article_clicked';
  static const String newsFetchFailed = 'news_fetch_failed';
  static const String cleanupCtaClicked = 'cleanup_cta_clicked';

  // ========== Cleanup Flow ==========
  static const String cleanupStarted = 'cleanup_started';
  static const String cleanupSectionCompleted = 'cleanup_section_completed';
  static const String cleanupPhotoAdded = 'cleanup_photo_added';
  static const String cleanupPhotoRemoved = 'cleanup_photo_removed';
  static const String cleanupSubmitted = 'cleanup_submitted';
  static const String cleanupSubmitFailed = 'cleanup_submit_failed';
  static const String cleanupSavedOffline = 'cleanup_saved_offline';
  static const String cleanupCancelled = 'cleanup_cancelled';

  // ========== Pending Cleanups ==========
  static const String pendingCleanupsViewed = 'pending_cleanups_viewed';
  static const String pendingCleanupSynced = 'pending_cleanup_synced';
  static const String pendingCleanupSyncFailed = 'pending_cleanup_sync_failed';

  // ========== Stats Screen ==========
  static const String statsLoaded = 'stats_loaded';
  static const String statsRefreshed = 'stats_refreshed';
  static const String statsChartViewed = 'stats_chart_viewed';
  static const String statsMapViewed = 'stats_map_viewed';
  static const String statsMarkerClicked = 'stats_marker_clicked';
  static const String statsFilterChanged = 'stats_filter_changed';
  static const String statsFilterApplied = 'stats_filter_applied';

  // ========== News Section ==========
  static const String newsSectionViewed = 'news_section_viewed';
  static const String newsComingSoonViewed = 'news_coming_soon_viewed';

  // ========== Profile Management ==========
  static const String editProfileViewed = 'edit_profile_viewed';
  static const String editProfileSaved = 'edit_profile_saved';
  static const String editProfileFailed = 'edit_profile_failed';
  static const String avatarChanged = 'avatar_changed';

  // ========== Password Management ==========
  static const String changePasswordViewed = 'change_password_viewed';
  static const String changePasswordSuccessEvent = 'change_password_success';
  static const String changePasswordFailedEvent = 'change_password_failed';

  // ========== Logout ==========
  static const String logoutClicked = 'logout_clicked';
  static const String logoutSuccess = 'logout_success';

  // ========== Errors (Non-Fatal) ==========
  static const String apiError = 'api_error';
  static const String networkError = 'network_error';
  static const String locationError = 'location_error';
  static const String uploadError = 'upload_error';
}
