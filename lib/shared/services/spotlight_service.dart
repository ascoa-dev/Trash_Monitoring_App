import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Reads the Firebase Storage `spotlight/` folder — the same folder admins
/// manage from the website. Returns the download URLs to show in the home
/// carousel. Returns an empty list on error or when the folder is empty.
class SpotlightService {
  static Future<List<String>> fetchImageUrls() async {
    try {
      final result = await FirebaseStorage.instance.ref('spotlight').listAll();
      final urls = await Future.wait(
        result.items.map((ref) => ref.getDownloadURL()),
      );
      return urls;
    } catch (e) {
      debugPrint('[Spotlight] Failed to list spotlight images: $e');
      return [];
    }
  }
}
