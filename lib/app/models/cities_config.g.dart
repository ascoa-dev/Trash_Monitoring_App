// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cities_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CitiesConfigAdapter extends TypeAdapter<CitiesConfig> {
  @override
  final int typeId = 1;

  @override
  CitiesConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CitiesConfig(
      allowCustomCities: fields[0] as bool,
      cities: (fields[1] as List).cast<City>(),
      fuzzyThreshold: fields[2] as int,
      maxSuggestions: fields[3] as int,
      updatedAt: fields[4] as DateTime?,
      customCitiesWarning: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CitiesConfig obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.allowCustomCities)
      ..writeByte(1)
      ..write(obj.cities)
      ..writeByte(2)
      ..write(obj.fuzzyThreshold)
      ..writeByte(3)
      ..write(obj.maxSuggestions)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.customCitiesWarning);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CitiesConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
