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
      frequencyRank: fields[8] as int? ?? 0,
      usefulnessScore: (fields[9] as num?)?.toDouble() ?? 0.0,
      sourceTags: (fields[10] as List?)?.cast<String>(),
      lemma: fields[11] as String? ?? '',
      isCore: fields[12] as bool? ?? false,
      qualityFlags: (fields[13] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Word obj) {
    writer
      ..writeByte(14)
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
      ..write(obj.definitionLoaded)
      ..writeByte(8)
      ..write(obj.frequencyRank)
      ..writeByte(9)
      ..write(obj.usefulnessScore)
      ..writeByte(10)
      ..write(obj.sourceTags)
      ..writeByte(11)
      ..write(obj.lemma)
      ..writeByte(12)
      ..write(obj.isCore)
      ..writeByte(13)
      ..write(obj.qualityFlags);
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
      frequencyRank: (json['frequencyRank'] as num?)?.toInt() ?? 0,
      usefulnessScore: (json['usefulnessScore'] as num?)?.toDouble() ?? 0,
      sourceTags: (json['sourceTags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      lemma: json['lemma'] as String? ?? '',
      isCore: json['isCore'] as bool? ?? false,
      qualityFlags: (json['qualityFlags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
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
      'frequencyRank': instance.frequencyRank,
      'usefulnessScore': instance.usefulnessScore,
      'sourceTags': instance.sourceTags,
      'lemma': instance.lemma,
      'isCore': instance.isCore,
      'qualityFlags': instance.qualityFlags,
    };
