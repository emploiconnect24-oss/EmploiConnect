import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  const StatusBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        config.label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: config.text,
        ),
      ),
    );
  }

  _BadgeConfig _getConfig(String statut) {
    switch (statut.toLowerCase().trim()) {
      case 'publiee':
      case 'publiée':
      case 'active':
        return _BadgeConfig(
          label: 'Publiée',
          bg: const Color(0xFFD1FAE5),
          text: const Color(0xFF065F46),
        );
      case 'en_attente':
        return _BadgeConfig(
          label: 'En attente',
          bg: const Color(0xFFFEF3C7),
          text: const Color(0xFF92400E),
        );
      case 'brouillon':
        return _BadgeConfig(
          label: 'Brouillon',
          bg: const Color(0xFFF1F5F9),
          text: const Color(0xFF64748B),
        );
      case 'refusee':
      case 'refusée':
      case 'suspendue':
        return _BadgeConfig(
          label: 'Refusée',
          bg: const Color(0xFFFEE2E2),
          text: const Color(0xFF991B1B),
        );
      case 'expiree':
      case 'expirée':
      case 'fermee':
        return _BadgeConfig(
          label: 'Expirée',
          bg: const Color(0xFFF1F5F9),
          text: const Color(0xFF94A3B8),
        );
      case 'en_cours':
        return _BadgeConfig(
          label: 'En examen',
          bg: const Color(0xFFFEF3C7),
          text: const Color(0xFF92400E),
        );
      case 'entretien':
        return _BadgeConfig(
          label: 'Entretien',
          bg: const Color(0xFFF5F3FF),
          text: const Color(0xFF5B21B6),
        );
      case 'acceptee':
      case 'acceptée':
        return _BadgeConfig(
          label: 'Acceptée',
          bg: const Color(0xFFD1FAE5),
          text: const Color(0xFF065F46),
        );
      case 'refusee_candidature':
        return _BadgeConfig(
          label: 'Refusée',
          bg: const Color(0xFFFEE2E2),
          text: const Color(0xFF991B1B),
        );
      case 'actif':
        return _BadgeConfig(
          label: 'Actif',
          bg: const Color(0xFFD1FAE5),
          text: const Color(0xFF065F46),
        );
      case 'bloque':
      case 'bloqué':
        return _BadgeConfig(
          label: 'Bloqué',
          bg: const Color(0xFFFEE2E2),
          text: const Color(0xFF991B1B),
        );
      case 'suspendu':
        return _BadgeConfig(
          label: 'Suspendu',
          bg: const Color(0xFFFEE2E2),
          text: const Color(0xFF991B1B),
        );
      default:
        return _BadgeConfig(
          label: statut.isNotEmpty ? statut[0].toUpperCase() + statut.substring(1) : 'Inconnu',
          bg: const Color(0xFFF1F5F9),
          text: const Color(0xFF64748B),
        );
    }
  }
}

class _BadgeConfig {
  final String label;
  final Color bg;
  final Color text;
  const _BadgeConfig({
    required this.label,
    required this.bg,
    required this.text,
  });
}
