import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme_extension.dart';

/// Blocs UI de la page Mon Profil — alignés sur le PRD §5 (`_buildCompletionCard`, sections, items).

class ProfilCompletionCard extends StatelessWidget {
  const ProfilCompletionCard({
    super.key,
    required this.completion,
    required this.isAutoSaving,
    this.lastAutoSavedAt,
    required this.isSaving,
    required this.onSave,
  });

  final int completion;
  final bool isAutoSaving;
  final DateTime? lastAutoSavedAt;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final pct = completion.clamp(0, 100);
    final grad = pct >= 80
        ? const [Color(0xFF059669), Color(0xFF10B981)]
        : pct >= 50
        ? const [Color(0xFF1A56DB), Color(0xFF0EA5E9)]
        : const [Color(0xFF7C3AED), Color(0xFF1A56DB)];
    final shadowC = pct >= 80
        ? const Color(0xFF10B981)
        : const Color(0xFF1A56DB);

    final savedLine = isAutoSaving
        ? 'Autosave en cours...'
        : lastAutoSavedAt == null
        ? ''
        : 'Sauvegardé à ${lastAutoSavedAt!.hour.toString().padLeft(2, '0')}:${lastAutoSavedAt!.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: grad),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: shadowC.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complétion du profil',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  '$pct%',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  savedLine,
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1A56DB),
                ),
                onPressed: isSaving ? null : onSave,
                icon: isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(isSaving ? '…' : 'Enregistrer'),
              ),
              const SizedBox(height: 10),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  pct >= 100
                      ? Icons.verified_rounded
                      : Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProfilSectionCard extends StatelessWidget {
  const ProfilSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.onAdd,
    this.icon,
    this.accent = const Color(0xFF1A56DB),
  });

  final String title;
  final Widget child;
  final VoidCallback? onAdd;
  final IconData? icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.themeExt.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: accent, size: 17),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (onAdd != null)
                IconButton(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_circle_outline),
                ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class ProfilEditableRow extends StatelessWidget {
  const ProfilEditableRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.onDelete,
    this.onEdit,
  });

  final String title;
  final String subtitle;
  final String body;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.themeExt.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (subtitle.isNotEmpty) Text(subtitle),
                if (body.isNotEmpty)
                  Text(body, style: const TextStyle(color: Color(0xFF64748B))),
              ],
            ),
          ),
          if (onEdit != null)
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Modifier'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1A56DB),
                visualDensity: VisualDensity.compact,
              ),
            ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            color: const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }
}
