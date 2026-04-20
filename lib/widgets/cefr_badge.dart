import 'package:flutter/material.dart';
import '../theme.dart';

class CefrBadge extends StatelessWidget {
  final String level;
  final bool small;

  const CefrBadge({super.key, required this.level, this.small = false});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.cefrColor(level);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 7 : 9,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        level,
        style: TextStyle(
          color: color,
          fontSize: small ? 10 : 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

Color cefrColor(String level) => AppTheme.cefrColor(level);
