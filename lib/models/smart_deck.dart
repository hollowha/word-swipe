import 'word.dart';

class SmartDeckMetrics {
  final String targetLevel;
  final int dueReviewCount;
  final int learningCount;
  final int knowCount;
  final int newCount;
  final int totalCount;

  const SmartDeckMetrics({
    required this.targetLevel,
    required this.dueReviewCount,
    required this.learningCount,
    required this.knowCount,
    required this.newCount,
    required this.totalCount,
  });
}

class SmartDeck {
  final List<Word> words;
  final SmartDeckMetrics metrics;

  const SmartDeck({
    required this.words,
    required this.metrics,
  });
}
