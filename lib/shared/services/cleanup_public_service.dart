import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:we_monitor/app/models/cleanup_model.dart';

class CleanupPublicService {
  static Future<List<CleanupModel>> fetchPublic({int limit = 50}) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('cleanups')
          .limit(limit)
          .get();
      final docs = snap.docs
          .map((doc) => CleanupModel.fromFirestore(doc))
          .where((cleanup) => !cleanup.flagged)
          .toList();
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return docs;
    } catch (e) {
      debugPrint('[CleanupPublicService] fetchPublic error: $e');
      return [];
    }
  }
}
