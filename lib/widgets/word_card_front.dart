import 'package:flutter/material.dart';

import '../models/word.dart';
import 'word_card_face.dart';

class WordCardFront extends StatelessWidget {
  final Word word;

  const WordCardFront({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    return WordCardFace(word: word);
  }
}
