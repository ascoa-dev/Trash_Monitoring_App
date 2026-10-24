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

  // Resume state. Written after every step, so a retry continues where the
  // last attempt stopped instead of starting over.

  /// Firestore doc id, fixed on the first attempt (also the Storage folder).
  @HiveField(10)
  String? docId;

  /// Local photo path -> uploaded full / thumb URL.
  @HiveField(11)
  Map<String, String>? uploadedFull;

  @HiveField(12)
  Map<String, String>? uploadedThumb;

  /// Local photos that were gone from disk and had to be skipped.
  @HiveField(13)
  List<String>? missingPhotos;

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
    this.docId,
    this.uploadedFull,
    this.uploadedThumb,
    this.missingPhotos,
  });

  Map<String, dynamic> toFirestore({
    required List<String> photoUrls,
    List<String>? thumbUrls,
  }) {
    return {
      'userId': userId,
      'createdAt': createdAt,
      'location': {
        'name': location,
        'latitude': locationLatitude,
        'longitude': locationLongitude,
      },
      'photoUrls': photoUrls,
      'thumbUrls': thumbUrls ?? photoUrls,
      'status': 'reported',
    };
  }
}
