import 'package:flutter/material.dart';

enum StudyMode {
  smartSwipe,
  flashcards,
  learnQuiz,
  typeAnswer,
  match,
  test,
}

extension StudyModeInfo on StudyMode {
  String get routeName => switch (this) {
        StudyMode.smartSwipe => 'smart-swipe',
        StudyMode.flashcards => 'flashcards',
        StudyMode.learnQuiz => 'learn-quiz',
        StudyMode.typeAnswer => 'type-answer',
        StudyMode.match => 'match',
        StudyMode.test => 'test',
      };

  String get label => switch (this) {
        StudyMode.smartSwipe => 'Smart Swipe',
        StudyMode.flashcards => 'Flashcards',
        StudyMode.learnQuiz => 'Learn Quiz',
        StudyMode.typeAnswer => 'Type Answer',
        StudyMode.match => 'Match',
        StudyMode.test => 'Test',
      };

  String get description => switch (this) {
        StudyMode.smartSwipe => 'Fast KNOW / NEW sorting with spaced review.',
        StudyMode.flashcards => 'Flip cards, listen, then mark your recall.',
        StudyMode.learnQuiz => 'Pick the word that matches the meaning.',
        StudyMode.typeAnswer => 'Recall and type the exact word.',
        StudyMode.match => 'Pair words with meanings against the clock.',
        StudyMode.test => 'Take a scored mixed review session.',
      };

  IconData get icon => switch (this) {
        StudyMode.smartSwipe => Icons.swipe_rounded,
        StudyMode.flashcards => Icons.style_rounded,
        StudyMode.learnQuiz => Icons.psychology_alt_rounded,
        StudyMode.typeAnswer => Icons.keyboard_rounded,
        StudyMode.match => Icons.grid_view_rounded,
        StudyMode.test => Icons.assignment_turned_in_rounded,
      };

  static StudyMode fromRouteName(String value) {
    return StudyMode.values.firstWhere(
      (mode) => mode.routeName == value,
      orElse: () => StudyMode.flashcards,
    );
  }
}
