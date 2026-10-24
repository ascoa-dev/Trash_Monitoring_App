/// Pure-Dart parsing/building of app.ascoa-cm.org deep links.
const String deepLinkHost = 'app.ascoa-cm.org';

/// Public download page, for share messages.
const String appDownloadUrl = 'https://$deepLinkHost/get';

String cleanupShareUrl(String id) => 'https://$deepLinkHost/cleanup/$id';
String hotspotShareUrl(String id) => 'https://$deepLinkHost/hotspot/$id';

sealed class DeepLink {
  const DeepLink();
}

class ResetPasswordLink extends DeepLink {
  final String oobCode;
  const ResetPasswordLink(this.oobCode);
}

class CleanupLink extends DeepLink {
  final String id;
  const CleanupLink(this.id);
}

class HotspotLink extends DeepLink {
  final String id;
  const HotspotLink(this.id);
}

class UnknownLink extends DeepLink {
  const UnknownLink();
}

final RegExp _idPattern = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

DeepLink parseDeepLink(Uri uri) {
  if (uri.host != deepLinkHost) return const UnknownLink();

  final mode = uri.queryParameters['mode'];
  final oobCode = uri.queryParameters['oobCode']?.trim();
  if (mode == 'resetPassword' && oobCode != null && oobCode.isNotEmpty) {
    return ResetPasswordLink(oobCode);
  }

  // Trailing slash yields an empty last segment; drop it.
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.length == 2 && _idPattern.hasMatch(segments[1])) {
    if (segments[0] == 'cleanup') return CleanupLink(segments[1]);
    if (segments[0] == 'hotspot') return HotspotLink(segments[1]);
  }
  return const UnknownLink();
}
