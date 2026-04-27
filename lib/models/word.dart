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

  @HiveField(8, defaultValue: 0)
  int frequencyRank;

  @HiveField(9, defaultValue: 0.0)
  double usefulnessScore;

  @HiveField(10, defaultValue: <String>[])
  List<String> sourceTags;

  @HiveField(11, defaultValue: '')
  String lemma;

  @HiveField(12, defaultValue: false)
  bool isCore;

  @HiveField(13, defaultValue: <String>[])
  List<String> qualityFlags;

  Word({
    required this.id,
    required this.word,
    required this.cefrLevel,
    this.partOfSpeech = '',
    this.phonetic = '',
    this.definition = '',
    this.example = '',
    this.definitionLoaded = false,
    this.frequencyRank = 0,
    this.usefulnessScore = 0,
    List<String>? sourceTags,
    this.lemma = '',
    this.isCore = false,
    List<String>? qualityFlags,
  })  : sourceTags = sourceTags ?? const [],
        qualityFlags = qualityFlags ?? const [];

  factory Word.fromJson(Map<String, dynamic> json) => _$WordFromJson(json);
  Map<String, dynamic> toJson() => _$WordToJson(this);

  Word copyWith({
    String? partOfSpeech,
    String? phonetic,
    String? definition,
    String? example,
    bool? definitionLoaded,
    int? frequencyRank,
    double? usefulnessScore,
    List<String>? sourceTags,
    String? lemma,
    bool? isCore,
    List<String>? qualityFlags,
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
      frequencyRank: frequencyRank ?? this.frequencyRank,
      usefulnessScore: usefulnessScore ?? this.usefulnessScore,
      sourceTags: sourceTags ?? this.sourceTags,
      lemma: lemma ?? this.lemma,
      isCore: isCore ?? this.isCore,
      qualityFlags: qualityFlags ?? this.qualityFlags,
    );
  }
}
