import 'dart:convert';

/// A photo kept in a draft: durable local copy + download URL once uploaded.
class DraftPhoto {
  final String path;
  final String? url;
  final String? thumbUrl; // missing in drafts saved before thumbnails

  const DraftPhoto({required this.path, this.url, this.thumbUrl});

  Map<String, dynamic> toJson() => {
    'path': path,
    'url': url,
    'thumbUrl': thumbUrl,
  };

  factory DraftPhoto.fromJson(Map<String, dynamic> json) => DraftPhoto(
    path: json['path'] as String,
    url: json['url'] as String?,
    thumbUrl: json['thumbUrl'] as String?,
  );
}

/// Pure-Dart snapshot of the New Cleanup / Report Hotspot forms.
/// Hotspot drafts only use the location, docId and photos fields.
class FormDraft {
  static const String kindCleanup = 'cleanup';
  static const String kindHotspot = 'hotspot';

  final String kind;
  final String docId;
  final DateTime savedAt;

  final int peopleCount;
  final String groupName;
  final String date;
  final String location;
  final double? locationLatitude;
  final double? locationLongitude;
  final bool locationVerified;
  final Set<String> selectedEnvironments;
  final Map<String, int> trashItems;
  final bool basicInfoCompleted;
  final bool trashCollectedCompleted;
  final bool photosCompleted;
  final String? expandedSection;
  final List<DraftPhoto> photos;

  const FormDraft({
    required this.kind,
    required this.docId,
    required this.savedAt,
    this.peopleCount = 0,
    this.groupName = '',
    this.date = '',
    this.location = '',
    this.locationLatitude,
    this.locationLongitude,
    this.locationVerified = false,
    this.selectedEnvironments = const {},
    this.trashItems = const {},
    this.basicInfoCompleted = false,
    this.trashCollectedCompleted = false,
    this.photosCompleted = false,
    this.expandedSection,
    this.photos = const [],
  });

  /// True once the user entered anything worth restoring.
  bool get hasContent =>
      peopleCount > 0 ||
      groupName.trim().isNotEmpty ||
      date.trim().isNotEmpty ||
      locationLatitude != null ||
      selectedEnvironments.isNotEmpty ||
      trashItems.values.any((c) => c > 0) ||
      photos.isNotEmpty;

  int get itemCount => trashItems.values.fold(0, (sum, c) => sum + c);

  Map<String, dynamic> toJson() => {
    'kind': kind,
    'docId': docId,
    'savedAt': savedAt.toIso8601String(),
    'peopleCount': peopleCount,
    'groupName': groupName,
    'date': date,
    'location': location,
    'locationLatitude': locationLatitude,
    'locationLongitude': locationLongitude,
    'locationVerified': locationVerified,
    'selectedEnvironments': selectedEnvironments.toList(),
    'trashItems': trashItems,
    'basicInfoCompleted': basicInfoCompleted,
    'trashCollectedCompleted': trashCollectedCompleted,
    'photosCompleted': photosCompleted,
    'expandedSection': expandedSection,
    'photos': photos.map((p) => p.toJson()).toList(),
  };

  factory FormDraft.fromJson(Map<String, dynamic> json) => FormDraft(
    kind: json['kind'] as String,
    docId: json['docId'] as String,
    savedAt: DateTime.parse(json['savedAt'] as String),
    peopleCount: (json['peopleCount'] as num?)?.toInt() ?? 0,
    groupName: json['groupName'] as String? ?? '',
    date: json['date'] as String? ?? '',
    location: json['location'] as String? ?? '',
    locationLatitude: (json['locationLatitude'] as num?)?.toDouble(),
    locationLongitude: (json['locationLongitude'] as num?)?.toDouble(),
    locationVerified: json['locationVerified'] as bool? ?? false,
    selectedEnvironments:
        ((json['selectedEnvironments'] as List?) ?? const [])
            .cast<String>()
            .toSet(),
    trashItems: ((json['trashItems'] as Map?) ?? const {}).map(
      (k, v) => MapEntry(k as String, (v as num).toInt()),
    ),
    basicInfoCompleted: json['basicInfoCompleted'] as bool? ?? false,
    trashCollectedCompleted: json['trashCollectedCompleted'] as bool? ?? false,
    photosCompleted: json['photosCompleted'] as bool? ?? false,
    expandedSection: json['expandedSection'] as String?,
    photos:
        ((json['photos'] as List?) ?? const [])
            .map((p) => DraftPhoto.fromJson(Map<String, dynamic>.from(p)))
            .toList(),
  );

  String encode() => jsonEncode(toJson());

  factory FormDraft.decode(String source) =>
      FormDraft.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
