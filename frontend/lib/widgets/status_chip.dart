import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.value,
  });

  final String value;

  @override
  Widget build(BuildContext context) {
    final v = value.toLowerCase();
    Color fg = Colors.blueGrey.shade800;
    Color bg = Colors.blueGrey.shade100;

    if (v == 'acceptee' || v == 'active' || v == 'traite' || v == 'valide' || v == 'actif') {
      fg = const Color(0xFF0F6D2B);
      bg = const Color(0xFFDDF5E4);
    } else if (v == 'en_attente' || v == 'en_cours') {
      fg = const Color(0xFF9A6700);
      bg = const Color(0xFFFFF1CC);
    } else if (v == 'refusee' || v == 'annulee' || v == 'rejete' || v == 'suspendue' || v == 'fermee' || v == 'non_valide' || v == 'inactif') {
      fg = const Color(0xFF9B1C1C);
      bg = const Color(0xFFFDE2E2);
    } else if (v == 'brouillon') {
      fg = const Color(0xFF374151);
      bg = const Color(0xFFE5E7EB);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

