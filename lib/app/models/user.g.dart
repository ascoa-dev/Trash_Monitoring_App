// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 20;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      uid: fields[0] as String,
      email: fields[1] as String,
      firstName: fields[2] as String,
      lastName: fields[3] as String,
      phoneNumber: fields[4] as String,
      city: fields[5] as String,
      countryCode: fields[6] as String,
      avatarUrl: fields[7] as String?,
      thumbUrl: fields[8] as String?,
      avatarUpdatedAt: fields[9] as DateTime?,
      isProfileComplete: fields[10] as bool,
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime?,
      photoURL: fields[13] as String?,
      signUpMethod: fields[14] as String,
      cleanups: (fields[15] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.firstName)
      ..writeByte(3)
      ..write(obj.lastName)
      ..writeByte(4)
      ..write(obj.phoneNumber)
      ..writeByte(5)
      ..write(obj.city)
      ..writeByte(6)
      ..write(obj.countryCode)
      ..writeByte(7)
      ..write(obj.avatarUrl)
      ..writeByte(8)
      ..write(obj.thumbUrl)
      ..writeByte(9)
      ..write(obj.avatarUpdatedAt)
      ..writeByte(10)
      ..write(obj.isProfileComplete)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt)
      ..writeByte(13)
      ..write(obj.photoURL)
      ..writeByte(14)
      ..write(obj.signUpMethod)
      ..writeByte(15)
      ..write(obj.cleanups);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
