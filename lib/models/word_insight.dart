import 'package:hive_flutter/hive_flutter.dart';

import 'morpheme_hint.dart';

class WordInsight {
  final String wordId;
  final String phonetic;
  final String partOfSpeech;
  final String definition;
  final String example;
  final String source;
  final bool hasInsight;
  final List<Map<String, dynamic>> morphemesRaw;

  const WordInsight({
    required this.wordId,
    this.phonetic = '',
    this.partOfSpeech = '',
    this.definition = '',
    this.example = '',
    this.source = '',
    this.hasInsight = false,
    this.morphemesRaw = const [],
  });

  factory WordInsight.empty(String wordId) => WordInsight(wordId: wordId);

  factory WordInsight.fromJson(Map<String, dynamic> json) {
    return WordInsight(
      wordId: json['wordId'] as String? ?? '',
      phonetic: json['phonetic'] as String? ?? '',
      partOfSpeech: json['partOfSpeech'] as String? ?? '',
      definition: json['definition'] as String? ?? '',
      example: json['example'] as String? ?? '',
      source: json['source'] as String? ?? '',
      hasInsight: json['hasInsight'] as bool? ?? false,
      morphemesRaw: (json['morphemes'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => item.map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wordId': wordId,
      'phonetic': phonetic,
      'partOfSpeech': partOfSpeech,
      'definition': definition,
      'example': example,
      'source': source,
      'hasInsight': hasInsight,
      'morphemes': morphemesRaw,
    };
  }

  List<MorphemeHint> get morphemes {
    return morphemesRaw.map(MorphemeHint.fromJson).toList()
      ..sort((a, b) => _kindRank(a.kind).compareTo(_kindRank(b.kind)));
  }

  static int _kindRank(String kind) {
    switch (kind) {
      case 'root':
        return 0;
      case 'prefix':
        return 1;
      case 'suffix':
        return 2;
      default:
        return 3;
    }
  }
}

class WordInsightAdapter extends TypeAdapter<WordInsight> {
  @override
  final int typeId = 2;

  @override
  WordInsight read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    final rawMorphemes = (fields[7] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (item) => item.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        )
        .toList();

    return WordInsight(
      wordId: fields[0] as String,
      phonetic: fields[1] as String? ?? '',
      partOfSpeech: fields[2] as String? ?? '',
      definition: fields[3] as String? ?? '',
      example: fields[4] as String? ?? '',
      source: fields[5] as String? ?? '',
      hasInsight: fields[6] as bool? ?? false,
      morphemesRaw: rawMorphemes,
    );
  }

  @override
  void write(BinaryWriter writer, WordInsight obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.wordId)
      ..writeByte(1)
      ..write(obj.phonetic)
      ..writeByte(2)
      ..write(obj.partOfSpeech)
      ..writeByte(3)
      ..write(obj.definition)
      ..writeByte(4)
      ..write(obj.example)
      ..writeByte(5)
      ..write(obj.source)
      ..writeByte(6)
      ..write(obj.hasInsight)
      ..writeByte(7)
      ..write(obj.morphemesRaw);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordInsightAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
