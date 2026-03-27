import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ContractBadge extends StatelessWidget {
  const ContractBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final normalized = label.toLowerCase();

    Color bg = const Color(0xFFE0F2FE);
    Color fg = const Color(0xFF0369A1);
    if (normalized == 'cdi') {
      bg = const Color(0xFFD1FAE5);
      fg = const Color(0xFF065F46);
    } else if (normalized == 'cdd') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFF92400E);
    } else if (normalized == 'stage') {
      bg = const Color(0xFFDBEAFE);
      fg = const Color(0xFF1D4ED8);
    } else if (normalized == 'freelance') {
      bg = const Color(0xFFEDE9FE);
      fg = const Color(0xFF6D28D9);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

