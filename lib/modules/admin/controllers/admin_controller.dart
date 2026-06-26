import 'dart:async';

import 'package:we_monitor/app/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AdminRecord {
  final String uid;
  final String email;
  final String displayName;
  final String addedBy;
  final DateTime? createdAt;

  AdminRecord({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.addedBy,
    this.createdAt,
  });

  factory AdminRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdAt = data['createdAt'];
    return AdminRecord(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      addedBy: data['addedBy'] as String? ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}

class AdminController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxBool isLoading = false.obs;
  final RxBool isSearching = false.obs;
  final RxBool isCurrentUserAdmin = false.obs;
  final RxString adminSearchQuery = ''.obs;
  final RxList<AdminRecord> admins = <AdminRecord>[].obs;
  final RxList<UserModel> userResults = <UserModel>[].obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _adminsSub;
  Timer? _searchDebounce;

  @override
  void onInit() {
    super.onInit();
    initialize();
  }

  @override
  void onClose() {
    _adminsSub?.cancel();
    _searchDebounce?.cancel();
    super.onClose();
  }

  Future<void> initialize() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final adminDoc = await _firestore.collection('admins').doc(user.uid).get();
    isCurrentUserAdmin.value = adminDoc.exists;
    if (adminDoc.exists) {
      _bindAdmins();
    }
  }

  /// Live admin list — a single ordered query is the authority. Adds/removes
  /// stream in automatically (no manual reload), and there is no append step
  /// that could double-list a row.
  void _bindAdmins() {
    isLoading.value = true;
    _adminsSub?.cancel();
    _adminsSub = _firestore
        .collection('admins')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .listen((snapshot) {
          admins.value = snapshot.docs.map(AdminRecord.fromDoc).toList();
          isLoading.value = false;
        });
  }

  List<AdminRecord> get filteredAdmins {
    final query = adminSearchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return admins;
    return admins.where((admin) {
      final haystack = '${admin.displayName} ${admin.email}'.toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  /// Debounced entry point for the user search field — call on every
  /// keystroke. Runs the actual query 350ms after typing stops.
  void onUserSearchChanged(String value) {
    _searchDebounce?.cancel();
    if (value.trim().isEmpty) {
      userResults.clear();
      isSearching.value = false;
      return;
    }
    isSearching.value = true;
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => searchUsers(value),
    );
  }

  Future<void> searchUsers(String value) async {
    if (!isCurrentUserAdmin.value) return;

    final query = value.trim().toLowerCase();
    if (query.isEmpty) {
      userResults.clear();
      return;
    }

    isSearching.value = true;
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .orderBy('email')
              .limit(100)
              .get();

      final users =
          snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), uidFromDoc: doc.id))
              .where((user) {
                final haystack =
                    '${user.email} ${user.firstName} ${user.lastName}'
                        .toLowerCase();
                return haystack.contains(query);
              })
              .toList();

      userResults.value = users;
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> addAdmin(UserModel user) async {
    if (!isCurrentUserAdmin.value) return;
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // The snapshots() listener refreshes the list — no manual reload.
    await _firestore.collection('admins').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': '${user.firstName} ${user.lastName}'.trim(),
      'addedBy': currentUser.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeAdmin(String uid) async {
    if (!isCurrentUserAdmin.value) return;
    await _firestore.collection('admins').doc(uid).delete();
  }
}
