import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String city;
  final String countryCode;
  final String? avatarUrl;
  final String? thumbUrl;
  final DateTime? avatarUpdatedAt;
  final bool isProfileComplete;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? photoURL;
  final String signUpMethod;
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
