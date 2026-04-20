// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WordAdapter extends TypeAdapter<Word> {
  @override
  final int typeId = 0;

  @override
  Word read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Word(
      id: fields[0] as String,
      word: fields[1] as String,
      cefrLevel: fields[2] as String,
      partOfSpeech: fields[3] as String,
      phonetic: fields[4] as String,
      definition: fields[5] as String,
      example: fields[6] as String,
      definitionLoaded: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Word obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.word)
      ..writeByte(2)
      ..write(obj.cefrLevel)
      ..writeByte(3)
      ..write(obj.partOfSpeech)
      ..writeByte(4)
      ..write(obj.phonetic)
      ..writeByte(5)
      ..write(obj.definition)
      ..writeByte(6)
      ..write(obj.example)
      ..writeByte(7)
      ..write(obj.definitionLoaded);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Word _$WordFromJson(Map<String, dynamic> json) => Word(
      id: json['id'] as String,
      word: json['word'] as String,
      cefrLevel: json['cefrLevel'] as String,
      partOfSpeech: json['partOfSpeech'] as String? ?? '',
      phonetic: json['phonetic'] as String? ?? '',
      definition: json['definition'] as String? ?? '',
      example: json['example'] as String? ?? '',
      definitionLoaded: json['definitionLoaded'] as bool? ?? false,
    );

Map<String, dynamic> _$WordToJson(Word instance) => <String, dynamic>{
      'id': instance.id,
      'word': instance.word,
      'cefrLevel': instance.cefrLevel,
      'partOfSpeech': instance.partOfSpeech,
      'phonetic': instance.phonetic,
      'definition': instance.definition,
      'example': instance.example,
      'definitionLoaded': instance.definitionLoaded,
    };
