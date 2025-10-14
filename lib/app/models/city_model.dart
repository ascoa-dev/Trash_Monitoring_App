import 'package:hive/hive.dart';

part 'city_model.g.dart';

@HiveType(typeId: 0)
class City {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String nameLower;

  @HiveField(2)
  final List<String> altNames;

  City({required this.name, required this.nameLower, required this.altNames});

  factory City.fromMap(Map<String, dynamic> map) {
    return City(
      name: map['name'] as String? ?? '',
      nameLower: map['nameLower'] as String? ?? '',
      altNames: ((map['altNames'] as List?) ?? []).map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'nameLower': nameLower,
        'altNames': altNames,
      };
}
