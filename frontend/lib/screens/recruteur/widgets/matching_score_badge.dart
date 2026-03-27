import 'package:flutter/material.dart';

class MatchingScoreBadge extends StatelessWidget {
  const MatchingScoreBadge({super.key, required this.score});
  final int score;

  Color get _color {
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 60) return const Color(0xFF1A56DB);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String get _label {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Bon match';
    if (score >= 40) return 'Moyen';
    return 'Faible';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 12, color: _color),
          const SizedBox(width: 4),
          Text(
            '$score% · $_label',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _color),
          ),
        ],
      ),
    );
  }
}
