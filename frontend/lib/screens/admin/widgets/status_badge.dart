import 'package:flutter/material.dart';
import '../../../shared/widgets/status_badge.dart' as shared;

enum StatusType { status, role }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusType.status,
  });

  final String label;
  final StatusType type;

  @override
  Widget build(BuildContext context) {
    if (type == StatusType.status) {
      return shared.StatusBadge(label: label);
    }
    final style = _styleFor(label, type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: style.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: style.$2,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, Color) _styleFor(String raw, StatusType kind) {
    final value = raw.toLowerCase();
    if (kind == StatusType.role) {
      if (value.contains('admin')) return (const Color(0xFF0F172A), Colors.white);
      if (value.contains('recruteur') || value.contains('entreprise')) {
        return (const Color(0xFFF5F3FF), const Color(0xFF5B21B6));
      }
      return (const Color(0xFFEFF6FF), const Color(0xFF1E40AF));
    }

    return (const Color(0xFFF1F5F9), const Color(0xFF475569));
  }
}
