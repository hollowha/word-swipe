import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/word.dart';
import 'models/swipe_record.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(WordAdapter());
  Hive.registerAdapter(SwipeRecordAdapter());

  await Future.wait([
    Hive.openBox<Word>('words'),
    Hive.openBox<SwipeRecord>('swipe_records'),
    Hive.openBox<dynamic>('meta'),
  ]);

  runApp(const ProviderScope(child: WordSwipeApp()));
}
