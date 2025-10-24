// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'water_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WaterRecordAdapter extends TypeAdapter<WaterRecord> {
  @override
  final int typeId = 0;

  @override
  WaterRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WaterRecord(
      date: fields[0] as DateTime,
      amountInMl: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, WaterRecord obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.amountInMl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaterRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
