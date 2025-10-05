import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String city;
  final String countryCode;
  final bool isProfileComplete;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String signUpMethod;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.city,
    required this.countryCode,
    required this.isProfileComplete,
    required this.createdAt,
    this.updatedAt,
    required this.signUpMethod,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'city': city,
      'countryCode': countryCode,
      'isProfileComplete': isProfileComplete,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'signUpMethod': signUpMethod,
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
    final isProfileComplete =
        (map['isProfileComplete'] is bool)
            ? map['isProfileComplete'] as bool
            : false;
    final createdAt = parseDate(map['createdAt']);
    final updatedAt =
        map['updatedAt'] != null ? parseDate(map['updatedAt']) : null;
    final signUpMethod = (map['signUpMethod'] as String?) ?? '';

    return UserModel(
      uid: uid,
      email: email,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      city: city,
      countryCode: countryCode,
      isProfileComplete: isProfileComplete,
      createdAt: createdAt,
      updatedAt: updatedAt,
      signUpMethod: signUpMethod,
    );
  }
}
