import 'swipe_record.dart';

enum ProgressBucket {
  all,
  unseen,
  newWord,
  learning,
  know,
  due,
  mastered,
}

extension ProgressBucketInfo on ProgressBucket {
  String get label => switch (this) {
        ProgressBucket.all => 'All',
        ProgressBucket.unseen => 'Unseen',
        ProgressBucket.newWord => 'New',
        ProgressBucket.learning => 'Learning',
        ProgressBucket.know => 'Know',
        ProgressBucket.due => 'Due',
        ProgressBucket.mastered => 'Mastered',
      };
}

ProgressBucket progressBucketFor(SwipeRecord? record, DateTime now) {
  if (record == null || !record.isSeen) return ProgressBucket.unseen;
  if (record.isMastered) return ProgressBucket.mastered;
  if (record.isDue(now)) return ProgressBucket.due;
  if (record.leftCount > 0 && record.rightCount == 0 && record.srsStep == 0) {
    return ProgressBucket.newWord;
  }
  if (record.isLearning) return ProgressBucket.learning;
  if (record.isFamiliar) return ProgressBucket.know;
  return ProgressBucket.learning;
}
