import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 20)
class UserModel {
  @HiveField(0)
  final String uid;
  @HiveField(1)
  final String email;
  @HiveField(2)
  final String firstName;
  @HiveField(3)
  final String lastName;
  @HiveField(4)
  final String phoneNumber;
  @HiveField(5)
  final String city;
  @HiveField(6)
  final String countryCode;
  @HiveField(7)
  final String? avatarUrl;
  @HiveField(8)
  final String? thumbUrl;
  @HiveField(9)
  final DateTime? avatarUpdatedAt;
  @HiveField(10)
  final bool isProfileComplete;
  @HiveField(11)
  final DateTime createdAt;
  @HiveField(12)
  final DateTime? updatedAt;
  @HiveField(13)
  final String? photoURL;
  @HiveField(14)
  final String signUpMethod;
  @HiveField(15)
  final List<String> cleanups; // Array of cleanup document IDs

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.city,
    required this.countryCode,
    this.avatarUrl,
    this.thumbUrl,
    this.avatarUpdatedAt,
    required this.isProfileComplete,
    required this.createdAt,
    this.updatedAt,
    this.photoURL,
    required this.signUpMethod,
    this.cleanups = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'avatarUrl': avatarUrl,
      'thumbUrl': thumbUrl,
      'avatarUpdatedAt': avatarUpdatedAt?.toIso8601String(),
      'phoneNumber': phoneNumber,
      'city': city,
      'countryCode': countryCode,
      'isProfileComplete': isProfileComplete,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'photoURL': photoURL,
      'signUpMethod': signUpMethod,
      'cleanups': cleanups,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, {String? uidFromDoc}) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value) ??
            DateTime.fromMillisecondsSinceEpoch(0);
      }
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final uid = uidFromDoc ?? (map['uid'] as String?) ?? '';
    final email = (map['email'] as String?) ?? '';
    final firstName = (map['firstName'] as String?) ?? '';
    final lastName = (map['lastName'] as String?) ?? '';
    final phoneNumber = (map['phoneNumber'] as String?) ?? '';
    final city = (map['city'] as String?) ?? '';
    final countryCode = (map['countryCode'] as String?) ?? '';
    final avatarUrl = (map['avatarUrl'] as String?);
    final thumbUrl = (map['thumbUrl'] as String?);
    final avatarUpdatedAt =
        map['avatarUpdatedAt'] != null
            ? parseDate(map['avatarUpdatedAt'])
            : null;
    final isProfileComplete =
        (map['isProfileComplete'] is bool)
            ? map['isProfileComplete'] as bool
            : false;
    final createdAt = parseDate(map['createdAt']);
    final updatedAt =
        map['updatedAt'] != null ? parseDate(map['updatedAt']) : null;
    final signUpMethod = (map['signUpMethod'] as String?) ?? '';
    final photoURL = (map['photoURL'] as String?);
    final cleanups = (map['cleanups'] as List<dynamic>?)?.cast<String>() ?? [];

    return UserModel(
      uid: uid,
      email: email,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      city: city,
      countryCode: countryCode,
      avatarUrl: avatarUrl,
      thumbUrl: thumbUrl,
      avatarUpdatedAt: avatarUpdatedAt,
      isProfileComplete: isProfileComplete,
      createdAt: createdAt,
      updatedAt: updatedAt,
      photoURL: photoURL,
      signUpMethod: signUpMethod,
      cleanups: cleanups,
    );
  }
}
