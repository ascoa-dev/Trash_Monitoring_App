import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ascoa_app/app/models/cleanup_model.dart';
import 'package:ascoa_app/shared/services/snackbar_service.dart';

class MyCleanupsController extends GetxController {
  final RxList<CleanupModel> allCleanups = <CleanupModel>[].obs;
  final RxList<CleanupModel> filteredCleanups = <CleanupModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final Rx<DateTime?> fromDate = Rx<DateTime?>(null);
  final Rx<DateTime?> toDate = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    loadCleanups();
  }

  Future<void> loadCleanups() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      isLoading.value = true;
      final snapshot =
          await FirebaseFirestore.instance
              .collection('cleanups')
              .where('userId', isEqualTo: user.uid)
              .get();

      final cleanups =
          snapshot.docs.map((doc) => CleanupModel.fromFirestore(doc)).toList()
            ..sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));

      allCleanups.value = cleanups;
      applyFilters();
    } catch (e) {
      debugPrint('[MyCleanups] Error loading cleanups: $e');
      SnackbarService.error('Error', 'Failed to load your cleanups');
    } finally {
      isLoading.value = false;
    }
  }

  void setSearchQuery(String value) {
    searchQuery.value = value;
    applyFilters();
  }

  void setFromDate(DateTime? value) {
    fromDate.value = value;
    applyFilters();
  }

  void setToDate(DateTime? value) {
    toDate.value = value;
    applyFilters();
  }

  void clearFilters() {
    searchQuery.value = '';
    fromDate.value = null;
    toDate.value = null;
    applyFilters();
  }

  void applyFilters() {
    final query = searchQuery.value.trim().toLowerCase();
    filteredCleanups.value =
        allCleanups.where((cleanup) {
          final cleanupDate = _parseDate(cleanup.date);
          if (fromDate.value != null && cleanupDate.isBefore(fromDate.value!)) {
            return false;
          }
          if (toDate.value != null && cleanupDate.isAfter(toDate.value!)) {
            return false;
          }
          if (query.isEmpty) return true;
          return cleanup.date.toLowerCase().contains(query) ||
              cleanup.location.toLowerCase().contains(query) ||
              cleanup.groupName.toLowerCase().contains(query);
        }).toList();
  }

  DateTime _parseDate(String date) {
    final parts = date.split('/');
    if (parts.length == 3) {
      return DateTime(
        int.tryParse(parts[2]) ?? 1970,
        int.tryParse(parts[1]) ?? 1,
        int.tryParse(parts[0]) ?? 1,
      );
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
