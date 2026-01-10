class Cleanup {
  final String id;
  final int numberOfPeople;
  final String groupName;
  final DateTime date;
  final String location;
  final double? latitude;
  final double? longitude;
  final String photoUrl;
  final String? videoUrl;
  final String environmentType;
  final double trashCollectedKg;
  final Map<String, Map<String, int>> categories;
  // e.g. { "Most Likely to Find": {"Grocery bags": 12, "Glass bottles": 5}, ... }

  Cleanup({
    required this.id,
    required this.numberOfPeople,
    required this.groupName,
    required this.date,
    required this.location,
    this.latitude,
    this.longitude,
    required this.photoUrl,
    this.videoUrl,
    required this.environmentType,
    required this.trashCollectedKg,
    required this.categories,
  });

  factory Cleanup.fromJson(Map<String, dynamic> json) => Cleanup(
    id: json['id'],
    numberOfPeople: json['numberOfPeople'],
    groupName: json['groupName'],
    date: DateTime.parse(json['date']),
    location: json['location'],
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    photoUrl: json['photoUrl'],
    videoUrl: json['videoUrl'],
    environmentType: json['environmentType'],
    trashCollectedKg: (json['trashCollectedKg'] as num?)?.toDouble() ?? 0.0,
    categories: (json['categories'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, Map<String, int>.from(value as Map)),
    ),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'numberOfPeople': numberOfPeople,
    'groupName': groupName,
    'date': date.toIso8601String(),
    'location': location,
    'latitude': latitude,
    'longitude': longitude,
    'photoUrl': photoUrl,
    'videoUrl': videoUrl,
    'environmentType': environmentType,
    'trashCollectedKg': trashCollectedKg,
    'categories': categories,
  };
}
