// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swipe_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SwipeRecordAdapter extends TypeAdapter<SwipeRecord> {
  @override
  final int typeId = 1;

  @override
  SwipeRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SwipeRecord(
      wordId: fields[0] as String,
      rightCount: fields[1] as int? ?? 0,
      leftCount: fields[2] as int? ?? 0,
      lastSwipedAt: fields[3] as DateTime?,
      lastDirection: fields[4] as String? ?? '',
      srsStep: fields[5] as int? ?? 0,
      dueAt: fields[6] as DateTime?,
      newMarkedAt: fields[7] as DateTime?,
      consecutiveKnowCount: fields[8] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, SwipeRecord obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.wordId)
      ..writeByte(1)
      ..write(obj.rightCount)
      ..writeByte(2)
      ..write(obj.leftCount)
      ..writeByte(3)
      ..write(obj.lastSwipedAt)
      ..writeByte(4)
      ..write(obj.lastDirection)
      ..writeByte(5)
      ..write(obj.srsStep)
      ..writeByte(6)
      ..write(obj.dueAt)
      ..writeByte(7)
      ..write(obj.newMarkedAt)
      ..writeByte(8)
      ..write(obj.consecutiveKnowCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwipeRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
