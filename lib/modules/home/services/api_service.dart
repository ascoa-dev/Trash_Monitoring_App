import 'package:ascoa_app/app/models/post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';

class ApiService {
  ApiService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetch posts with minimal fields to reduce payload.
  static Future<List<Post>> fetchPosts({int perPage = 10}) async {
    final snap =
        await _db
            .collection("posts")
            .orderBy('updatedAt', descending: true)
            .limit(perPage)
            .get();

    return Future.wait(
      snap.docs.map((doc) async {
        final data = doc.data();
        final adaptedJson = {
          'id': data['id'],
          'link': data['link'],
          'featured_media': 0, // no longer used
          'title': {'rendered': data['title']},
        };

        final post = Post.fromJson(adaptedJson);

        // 🔑 Generate Firebase Storage download URL from path
        final imagePath = data['imagePath'] as String?;
        debugPrint('[Post Image Path] $imagePath');
        if (imagePath != null && imagePath.isNotEmpty) {
          post.imageUrl =
              await FirebaseStorage.instance
                  .ref()
                  .child(imagePath)
                  .getDownloadURL();
          debugPrint('[Post Image URL] ${post.imageUrl}');
        }
        return post;
      }).toList(),
    );
  }
}
