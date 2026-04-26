import 'word.dart';

enum SmartDeckReason { dueReview, currentLevel, challenge, warmUp }

extension SmartDeckReasonLabel on SmartDeckReason {
  String get label => switch (this) {
        SmartDeckReason.dueReview => 'Review due',
        SmartDeckReason.currentLevel => 'Right level',
        SmartDeckReason.challenge => 'New challenge',
        SmartDeckReason.warmUp => 'Warm-up',
      };
}

class SmartDeckItem {
  final Word word;
  final SmartDeckReason reason;

  const SmartDeckItem({
    required this.word,
    required this.reason,
  });
}

class SmartDeckMetrics {
  final String targetLevel;
  final String nextLevel;
  final String guidance;
  final int dueReviewCount;
  final int learningCount;
  final int knowCount;
  final int newCount;
  final int totalCount;

  const SmartDeckMetrics({
    required this.targetLevel,
    required this.nextLevel,
    required this.guidance,
    required this.dueReviewCount,
    required this.learningCount,
    required this.knowCount,
    required this.newCount,
    required this.totalCount,
  });
}

class SmartDeck {
  final List<SmartDeckItem> items;
  final SmartDeckMetrics metrics;

  const SmartDeck({
    required this.items,
    required this.metrics,
  });

  List<Word> get words => items.map((item) => item.word).toList();

  SmartDeckReason? reasonFor(String wordId) {
    for (final item in items) {
      if (item.word.id == wordId) return item.reason;
    }
    return null;
  }
}
