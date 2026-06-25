// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_cleanup_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedCleanupModelAdapter extends TypeAdapter<CachedCleanupModel> {
  @override
  final int typeId = 4;

  @override
  CachedCleanupModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedCleanupModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      createdAt: fields[2] as DateTime,
      peopleCount: fields[3] as int,
      groupName: fields[4] as String,
      date: fields[5] as String,
      location: fields[6] as String,
      locationLatitude: fields[7] as double?,
      locationLongitude: fields[8] as double?,
      environment: fields[9] as String,
      categories: (fields[10] as Map).map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as Map).cast<String, dynamic>())),
      totalWeight: fields[11] as double,
      photoUrls: (fields[12] as List?)?.cast<String>(),
      cachedAt: fields[13] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CachedCleanupModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.peopleCount)
      ..writeByte(4)
      ..write(obj.groupName)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.location)
      ..writeByte(7)
      ..write(obj.locationLatitude)
      ..writeByte(8)
      ..write(obj.locationLongitude)
      ..writeByte(9)
      ..write(obj.environment)
      ..writeByte(10)
      ..write(obj.categories)
      ..writeByte(11)
      ..write(obj.totalWeight)
      ..writeByte(12)
      ..write(obj.photoUrls)
      ..writeByte(13)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedCleanupModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
