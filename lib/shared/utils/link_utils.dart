import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [urlString] in an external browser. Used for Terms / Privacy links.
Future<void> openExternalUrl(String urlString) async {
  try {
    await launchUrl(
      Uri.parse(urlString),
      mode: LaunchMode.externalApplication,
    );
  } catch (e) {
    debugPrint('Failed to open URL $urlString: $e');
  }
}
