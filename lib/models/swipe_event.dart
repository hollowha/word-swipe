import 'package:hive_flutter/hive_flutter.dart';

class SwipeEvent {
  final String id;
  final String wordId;
  final String direction;
  final DateTime swipedAt;
  final String inputSource;

  const SwipeEvent({
    required this.id,
    required this.wordId,
    required this.direction,
    required this.swipedAt,
    required this.inputSource,
  });
}

class SwipeEventAdapter extends TypeAdapter<SwipeEvent> {
  @override
  final int typeId = 3;

  @override
  SwipeEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return SwipeEvent(
      id: fields[0] as String,
      wordId: fields[1] as String,
      direction: fields[2] as String,
      swipedAt: fields[3] as DateTime,
      inputSource: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SwipeEvent obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.wordId)
      ..writeByte(2)
      ..write(obj.direction)
      ..writeByte(3)
      ..write(obj.swipedAt)
      ..writeByte(4)
      ..write(obj.inputSource);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwipeEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
