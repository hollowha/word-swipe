import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/word.dart';

class AssetService {
  static const _paths = {
    'A1': 'assets/words/a1_words.json',
    'A2': 'assets/words/a2_words.json',
    'B1': 'assets/words/b1_words.json',
    'B2': 'assets/words/b2_words.json',
    'C1': 'assets/words/c1_words.json',
    'C2': 'assets/words/c2_words.json',
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
}
