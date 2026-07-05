import 'package:cloud_firestore/cloud_firestore.dart';

typedef UserProfileMini = ({String firstName, String lastName, String? avatarUrl});

class UserProfileService {
  static final Map<String, Future<UserProfileMini?>> _cache = {};

  static Future<UserProfileMini?> fetch(String userId) {
    return _cache.putIfAbsent(userId, () => _fetchFromFirestore(userId));
  }

  static Future<UserProfileMini?> _fetchFromFirestore(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      return (
        firstName: (data['firstName'] as String?) ?? '',
        lastName: (data['lastName'] as String?) ?? '',
        avatarUrl: data['avatarUrl'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
