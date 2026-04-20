import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/word.dart';
import '../providers/swipe_providers.dart';
import '../theme.dart';
import 'cefr_badge.dart';

class WordCardBack extends ConsumerWidget {
  final Word word;

  const WordCardBack({super.key, required this.word});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defAsync = ref.watch(definitionProvider(word.id));

    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(28),
      child: defAsync.when(
        loading: () => const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, __) => _Content(word: word),
        data: (w) => _Content(word: w),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final Word word;
  const _Content({required this.word});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: word + badge
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                word.word,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                  letterSpacing: -1.0,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            CefrBadge(level: word.cefrLevel),
          ],
        ),

        // Phonetic + part of speech
        if (word.phonetic.isNotEmpty || word.partOfSpeech.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              if (word.phonetic.isNotEmpty)
                Text(word.phonetic, style: AppTheme.phoneticStyle),
              if (word.phonetic.isNotEmpty && word.partOfSpeech.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 3,
                  height: 3,
                  decoration: const BoxDecoration(
                    color: AppTheme.inkMuted,
                    shape: BoxShape.circle,
                  ),
                ),
              if (word.partOfSpeech.isNotEmpty)
                Text(
                  word.partOfSpeech,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.inkSubtle,
                    letterSpacing: 0.2,
                  ),
                ),
            ],
          ),
        ],

        const SizedBox(height: 20),
        const Divider(color: Color(0xFFEEEEEC), thickness: 1, height: 1),
        const SizedBox(height: 20),

        // Definition section
        if (word.definition.isNotEmpty) ...[
          Text('MEANING', style: AppTheme.labelSmall),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.definition,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.ink,
                      height: 1.6,
                    ),
                  ),
                  if (word.example.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('EXAMPLE', style: AppTheme.labelSmall),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          left: BorderSide(
                            color: AppTheme.cefrColor(word.cefrLevel),
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        '"${word.example}"',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.inkSubtle,
                          height: 1.6,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ] else
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 32, color: AppTheme.inkMuted),
                  const SizedBox(height: 8),
                  const Text(
                    'Definition unavailable',
                    style: TextStyle(color: AppTheme.inkMuted, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

        // Bottom hint
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app_rounded, size: 13, color: AppTheme.inkMuted),
            const SizedBox(width: 5),
            Text('Tap to flip back', style: AppTheme.labelSmall),
          ],
        ),
      ],
    );
  }
}
