class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String city;
  final bool isProfileComplete;
  final DateTime createdAt;
  final String signUpMethod;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.city,
    required this.isProfileComplete,
    required this.createdAt,
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
      'isProfileComplete': isProfileComplete,
      'createdAt': createdAt.toIso8601String(),
      'signUpMethod': signUpMethod,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      email: map['email'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      phoneNumber: map['phoneNumber'],
      city: map['city'],
      isProfileComplete: map['isProfileComplete'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      signUpMethod: map['signUpMethod'],
    );
  }
}
