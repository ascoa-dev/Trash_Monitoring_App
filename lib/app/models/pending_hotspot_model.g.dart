// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_hotspot_model.dart';

class PendingHotspotModelAdapter extends TypeAdapter<PendingHotspotModel> {
  @override
  final int typeId = 5;

  @override
  PendingHotspotModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingHotspotModel(
      localId: fields[0] as String,
      userId: fields[1] as String,
      location: fields[2] as String,
      locationLatitude: fields[3] as double?,
      locationLongitude: fields[4] as double?,
      localPhotoPaths: (fields[5] as List).cast<String>(),
      createdAt: fields[6] as DateTime,
      savedAt: fields[7] as DateTime,
      isUploading: fields[8] as bool,
      uploadError: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PendingHotspotModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.localId)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.location)
      ..writeByte(3)
      ..write(obj.locationLatitude)
      ..writeByte(4)
      ..write(obj.locationLongitude)
      ..writeByte(5)
      ..write(obj.localPhotoPaths)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.savedAt)
      ..writeByte(8)
      ..write(obj.isUploading)
      ..writeByte(9)
      ..write(obj.uploadError);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingHotspotModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
