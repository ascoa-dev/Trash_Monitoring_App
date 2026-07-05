import 'package:cloud_firestore/cloud_firestore.dart';

class HotspotModel {
  final String id;
  final String userId;
  final String locationName;
  final double? latitude;
  final double? longitude;
  final List<String> photoUrls;
  final String? notes;
  final String status;
  final DateTime? createdAt;

  const HotspotModel({
    required this.id,
    required this.userId,
    required this.locationName,
    this.latitude,
    this.longitude,
    required this.photoUrls,
    this.notes,
    required this.status,
    this.createdAt,
  });

  factory HotspotModel.fromMap(String id, Map<String, dynamic> data) {
    final location = (data['location'] as Map<String, dynamic>?) ?? {};
    final Timestamp? ts = data['createdAt'] as Timestamp?;
    return HotspotModel(
      id: id,
      userId: (data['userId'] as String?) ?? '',
      locationName: (location['name'] as String?) ?? '',
      latitude: (location['latitude'] as num?)?.toDouble(),
      longitude: (location['longitude'] as num?)?.toDouble(),
      photoUrls: List<String>.from(data['photoUrls'] as List? ?? []),
      notes: data['notes'] as String?,
      status: (data['status'] as String?) ?? 'reported',
      createdAt: ts?.toDate(),
    );
  }
}
