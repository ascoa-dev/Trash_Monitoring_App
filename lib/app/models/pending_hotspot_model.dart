import 'package:hive/hive.dart';

part 'pending_hotspot_model.g.dart';

@HiveType(typeId: 5)
class PendingHotspotModel extends HiveObject {
  @HiveField(0)
  final String localId;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String location;

  @HiveField(3)
  final double? locationLatitude;

  @HiveField(4)
  final double? locationLongitude;

  @HiveField(5)
  final List<String> localPhotoPaths;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime savedAt;

  @HiveField(8)
  bool isUploading;

  @HiveField(9)
  String? uploadError;

  PendingHotspotModel({
    required this.localId,
    required this.userId,
    required this.location,
    this.locationLatitude,
    this.locationLongitude,
    required this.localPhotoPaths,
    required this.createdAt,
    required this.savedAt,
    this.isUploading = false,
    this.uploadError,
  });

  Map<String, dynamic> toFirestore({required List<String> photoUrls}) {
    return {
      'userId': userId,
      'createdAt': createdAt,
      'location': {
        'name': location,
        'latitude': locationLatitude,
        'longitude': locationLongitude,
      },
      'photoUrls': photoUrls,
      'status': 'reported',
    };
  }
}
