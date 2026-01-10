// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_cleanup_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingCleanupModelAdapter extends TypeAdapter<PendingCleanupModel> {
  @override
  final int typeId = 3;

  @override
  PendingCleanupModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingCleanupModel(
      localId: fields[0] as String,
      userId: fields[1] as String,
      createdAt: fields[2] as DateTime,
      peopleCount: fields[3] as int,
      groupName: fields[4] as String,
      date: fields[5] as String,
      location: fields[6] as String,
      locationLatitude: fields[7] as double?,
      locationLongitude: fields[8] as double?,
      environment: fields[9] as String,
      trashItems: (fields[10] as Map).cast<String, int>(),
      itemWeights: (fields[11] as Map).cast<String, double>(),
      itemCategories: (fields[12] as Map).cast<String, String>(),
      localPhotoPaths: (fields[13] as List?)?.cast<String>(),
      savedAt: fields[14] as DateTime,
      isUploading: fields[15] as bool,
      uploadError: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PendingCleanupModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.localId)
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
      ..write(obj.trashItems)
      ..writeByte(11)
      ..write(obj.itemWeights)
      ..writeByte(12)
      ..write(obj.itemCategories)
      ..writeByte(13)
      ..write(obj.localPhotoPaths)
      ..writeByte(14)
      ..write(obj.savedAt)
      ..writeByte(15)
      ..write(obj.isUploading)
      ..writeByte(16)
      ..write(obj.uploadError);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingCleanupModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
