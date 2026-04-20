import 'package:hive_flutter/hive_flutter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'word.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class Word extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String word;

  @HiveField(2)
  String cefrLevel;

  @HiveField(3)
  String partOfSpeech;

  @HiveField(4)
  String phonetic;

  @HiveField(5)
  String definition;

  @HiveField(6)
  String example;

  @HiveField(7)
  bool definitionLoaded;

  Word({
    required this.id,
    required this.word,
    required this.cefrLevel,
    this.partOfSpeech = '',
    this.phonetic = '',
    this.definition = '',
    this.example = '',
    this.definitionLoaded = false,
  });

  factory Word.fromJson(Map<String, dynamic> json) => _$WordFromJson(json);
  Map<String, dynamic> toJson() => _$WordToJson(this);

  Word copyWith({
    String? partOfSpeech,
    String? phonetic,
    String? definition,
    String? example,
    bool? definitionLoaded,
  }) {
    return Word(
      id: id,
      word: word,
      cefrLevel: cefrLevel,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      phonetic: phonetic ?? this.phonetic,
      definition: definition ?? this.definition,
      example: example ?? this.example,
      definitionLoaded: definitionLoaded ?? this.definitionLoaded,
    );
  }
}
