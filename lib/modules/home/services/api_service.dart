import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ascoa_app/app/models/post.dart';
import 'package:ascoa_app/app/models/media.dart';

class ApiService {
  ApiService._();

  static const String _base = 'https://ascoa-cm.org';

  /// Fetch posts with minimal fields to reduce payload.
  static Future<List<Post>> fetchPosts({int perPage = 10}) async {
    final Uri uri = Uri.parse(
      '$_base/wp-json/wp/v2/posts?per_page=$perPage&_fields=id,title,link,featured_media',
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load posts: ${res.statusCode}');
    }
    final List<dynamic> raw = json.decode(res.body) as List<dynamic>;
    return raw.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Fetch media details for a given media id
  static Future<MediaModel> fetchMedia(int id) async {
    final Uri uri = Uri.parse('$_base/wp-json/wp/v2/media/$id');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load media $id: ${res.statusCode}');
    }
    final Map<String, dynamic> raw =
        json.decode(res.body) as Map<String, dynamic>;
    return MediaModel.fromJson(raw);
  }
}
