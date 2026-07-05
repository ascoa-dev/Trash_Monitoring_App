import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:we_monitor/app/models/hotspot_model.dart';

class HotspotService {
  static Future<List<HotspotModel>> fetchUnresolved({int limit = 50}) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('plastic_hotspots')
          .where('status', isEqualTo: 'reported')
          .limit(limit)
          .get();
      final docs = snap.docs
          .map((doc) => HotspotModel.fromMap(doc.id, doc.data()))
          .toList();
      docs.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return docs;
    } catch (e) {
      debugPrint('[HotspotService] fetchUnresolved error: $e');
      return [];
    }
  }
}
