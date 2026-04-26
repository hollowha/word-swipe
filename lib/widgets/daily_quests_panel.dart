import 'package:flutter/material.dart';

import '../models/game_progress.dart';
import '../theme.dart';

class DailyQuestsPanel extends StatelessWidget {
  final GameProgress progress;

  const DailyQuestsPanel({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final quests = progress.quests;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceSubtle,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E5E0)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/generated/daily-chest.png',
                width: 46,
                height: 46,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: quests
                    .map(
                      (quest) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _QuestRow(quest: quest),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestRow extends StatelessWidget {
  final DailyQuest quest;

  const _QuestRow({required this.quest});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          quest.completed ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: quest.completed ? AppTheme.know : AppTheme.inkMuted,
          size: 15,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            quest.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.inkSubtle,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '${quest.current.clamp(0, quest.target)}/${quest.target}',
          style: const TextStyle(
            color: AppTheme.inkMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
