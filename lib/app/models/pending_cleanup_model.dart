import 'package:hive/hive.dart';
import 'package:ascoa_app/app/models/cleanup_model.dart';

part 'pending_cleanup_model.g.dart';

@HiveType(typeId: 3)
class PendingCleanupModel extends HiveObject {
  @HiveField(0)
  final String localId;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final int peopleCount;

  @HiveField(4)
  final String groupName;

  @HiveField(5)
  final String date;

  @HiveField(6)
  final String location;

  @HiveField(7)
  final double? locationLatitude;

  @HiveField(8)
  final double? locationLongitude;

  @HiveField(9)
  final String environment;

  @HiveField(10)
  final Map<String, int> trashItems;

  @HiveField(11)
  final Map<String, double> itemWeights;

  @HiveField(12)
  final Map<String, String> itemCategories;

  @HiveField(13)
  final List<String>? localPhotoPaths;

  @HiveField(14)
  final DateTime savedAt;

  @HiveField(15)
  bool isUploading;

  @HiveField(16)
  String? uploadError;

  PendingCleanupModel({
    required this.localId,
    required this.userId,
    required this.createdAt,
    required this.peopleCount,
    required this.groupName,
    required this.date,
    required this.location,
    this.locationLatitude,
    this.locationLongitude,
    required this.environment,
    required this.trashItems,
    required this.itemWeights,
    required this.itemCategories,
    this.localPhotoPaths,
    required this.savedAt,
    this.isUploading = false,
    this.uploadError,
  });

  factory PendingCleanupModel.fromFormData({
    required String localId,
    required String userId,
    required int peopleCount,
    required String groupName,
    required String date,
    required String location,
    double? locationLatitude,
    double? locationLongitude,
    required String environment,
    required Map<String, int> trashItems,
    required Map<String, double> itemWeights,
    required Map<String, String> itemCategories,
    List<String>? localPhotoPaths,
  }) {
    return PendingCleanupModel(
      localId: localId,
      userId: userId,
      createdAt: DateTime.now(),
      peopleCount: peopleCount,
      groupName: groupName,
      date: date,
      location: location,
      locationLatitude: locationLatitude,
      locationLongitude: locationLongitude,
      environment: environment,
      trashItems: trashItems,
      itemWeights: itemWeights,
      itemCategories: itemCategories,
      localPhotoPaths: localPhotoPaths,
      savedAt: DateTime.now(),
    );
  }

  CleanupModel toCleanupModel({List<String>? uploadedPhotoUrls}) {
    return CleanupModel.fromFormData(
      userId: userId,
      peopleCount: peopleCount,
      groupName: groupName,
      date: date,
      location: location,
      locationLatitude: locationLatitude,
      locationLongitude: locationLongitude,
      environment: environment,
      trashItems: trashItems,
      itemWeights: itemWeights,
      itemCategories: itemCategories,
    ).copyWith(photoUrls: uploadedPhotoUrls);
  }
}
