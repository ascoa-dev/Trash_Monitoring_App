import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Session-cached "is the signed-in user an admin" check (doc at admins/{uid}).
/// Keyed by uid so a different account never sees a stale answer; [reset] is
/// also called on sign-out.
class AdminStatus {
  static String? _uid;
  static Future<bool>? _future;

  static Future<bool> isAdmin() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Future.value(false);
    if (_uid != uid || _future == null) {
      _uid = uid;
      _future = _fetch(uid);
    }
    return _future!;
  }

  static Future<bool> _fetch(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('admins').doc(uid).get();
      return doc.exists;
    } catch (_) {
      _future = null; // don't cache failures (e.g. offline)
      return false;
    }
  }

  static void reset() {
    _uid = null;
    _future = null;
  }
}
