import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/word.dart';
import '../models/word_insight.dart';

class AssetService {
  static const _paths = {
    'A1': 'assets/words/a1_words.json',
    'A2': 'assets/words/a2_words.json',
    'B1': 'assets/words/b1_words.json',
    'B2': 'assets/words/b2_words.json',
    'C1': 'assets/words/c1_words.json',
    'C2': 'assets/words/c2_words.json',
  };
  static const wordSeedVersion = '2026-04-21-v2';
  static const insightSeedVersion = '2026-04-21-v2';
  static const _insightPaths = {
    'A1': 'assets/insights/a1_insights.json',
    'A2': 'assets/insights/a2_insights.json',
    'B1': 'assets/insights/b1_insights.json',
    'B2': 'assets/insights/b2_insights.json',
    'C1': 'assets/insights/c1_insights.json',
    'C2': 'assets/insights/c2_insights.json',
  };

  Future<List<Word>> loadLevel(String level) async {
    final path = _paths[level]!;
    final jsonString = await rootBundle.loadString(path);
    final list = json.decode(jsonString) as List<dynamic>;
    return list.map((e) => Word.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Word>> loadAll() async {
    final results = await Future.wait(_paths.keys.map(loadLevel));
    return results.expand((l) => l).toList();
  }

  Future<List<WordInsight>> loadInsightLevel(String level) async {
    final path = _insightPaths[level]!;
    final jsonString = await rootBundle.loadString(path);
    final list = json.decode(jsonString) as List<dynamic>;
    return list
        .map((e) => WordInsight.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<WordInsight>> loadAllInsights() async {
    final results = await Future.wait(_insightPaths.keys.map(loadInsightLevel));
    return results.expand((l) => l).toList();
  }
}
