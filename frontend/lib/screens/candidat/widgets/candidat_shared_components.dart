import 'package:flutter/material.dart';

class CandidatStatCard extends StatelessWidget {
  const CandidatStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.color = const Color(0xFF1A56DB),
  });

  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class OffreQuickCard extends StatelessWidget {
  const OffreQuickCard({
    super.key,
    required this.title,
    required this.company,
    required this.score,
    this.onTap,
  });

  final String title;
  final String company;
  final int score;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(company, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text('$score%', style: const TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class OffreListCard extends StatelessWidget {
  const OffreListCard({
    super.key,
    required this.title,
    required this.company,
    required this.meta,
    required this.score,
    required this.saved,
    this.onApply,
    this.onSave,
    this.onDetails,
  });

  final String title;
  final String company;
  final String meta;
  final int score;
  final bool saved;
  final VoidCallback? onApply;
  final VoidCallback? onSave;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(company, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                  ],
                ),
              ),
              _scoreBadge(score),
            ],
          ),
          const SizedBox(height: 6),
          Text(meta, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(onPressed: onApply, child: const Text('Postuler')),
              OutlinedButton(onPressed: onDetails, child: const Text('Voir détails')),
              OutlinedButton.icon(
                onPressed: onSave,
                icon: Icon(saved ? Icons.bookmark : Icons.bookmark_outline, size: 16),
                label: Text(saved ? 'Sauvegardée' : 'Sauvegarder'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreBadge(int score) {
    final color = score >= 90 ? const Color(0xFF10B981) : const Color(0xFF1A56DB);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
      child: Text('$score% IA', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class CandidatureTimelineCard extends StatelessWidget {
  const CandidatureTimelineCard({
    super.key,
    required this.title,
    required this.company,
    required this.status,
    required this.step,
    this.footer,
    this.actions = const [],
  });

  final String title;
  final String company;
  final String status;
  final int step;
  final Widget? footer;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    const labels = ['Envoyée', 'En examen', 'Entretien', 'Réponse'];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(company, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(99)),
                child: Text(status, style: const TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(labels.length, (i) {
              final done = i <= step;
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? const Color(0xFF1A56DB) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(labels[i], style: const TextStyle(fontSize: 10)),
                  ],
                ),
              );
            }),
          ),
          if (footer != null) ...[
            const SizedBox(height: 8),
            footer!,
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ],
      ),
    );
  }
}

class ProfilCompletionBar extends StatelessWidget {
  const ProfilCompletionBar({super.key, required this.value});
  final int value;

  @override
  Widget build(BuildContext context) {
    final color = value >= 80
        ? const Color(0xFF10B981)
        : value >= 60
            ? const Color(0xFF1A56DB)
            : const Color(0xFFF59E0B);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Complétion du profil', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const Spacer(),
            Text('$value%', style: TextStyle(fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 8,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final trailingWidgets = trailing == null ? const <Widget>[] : <Widget>[trailing!];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
              ...trailingWidgets,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class CvSectionEditor extends StatelessWidget {
  const CvSectionEditor({
    super.key,
    required this.items,
    required this.onAdd,
    required this.onRemoveAt,
  });

  final List<String> items;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemoveAt;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...items.asMap().entries.map(
          (e) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(e.value),
            trailing: IconButton(
              onPressed: () => onRemoveAt(e.key),
              icon: const Icon(Icons.delete_outline, size: 18),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Ajouter'),
          ),
        ),
      ],
    );
  }
}

class SkillChipEditor extends StatelessWidget {
  const SkillChipEditor({
    super.key,
    required this.skills,
    required this.onDelete,
    this.onAdd,
  });

  final List<String> skills;
  final ValueChanged<String> onDelete;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...skills.map(
          (s) => Chip(
            label: Text(s),
            onDeleted: () => onDelete(s),
            deleteIcon: const Icon(Icons.close, size: 16),
          ),
        ),
        ActionChip(
          label: const Text('Ajouter'),
          avatar: const Icon(Icons.add, size: 16),
          onPressed: onAdd,
        ),
      ],
    );
  }
}

class AlerteCard extends StatelessWidget {
  const AlerteCard({
    super.key,
    required this.name,
    required this.summary,
    required this.frequency,
    required this.active,
    this.lastNotification,
    this.onToggle,
    this.onMenu,
  });

  final String name;
  final String summary;
  final String frequency;
  final bool active;
  final String? lastNotification;
  final ValueChanged<bool>? onToggle;
  final ValueChanged<String>? onMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_outlined, color: Color(0xFF1A56DB)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(summary, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                Text('Fréquence: $frequency', style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
                if (lastNotification != null)
                  Text(lastNotification!, style: const TextStyle(fontSize: 11, color: Color(0xFF10B981))),
              ],
            ),
          ),
          Switch(value: active, onChanged: onToggle),
          PopupMenuButton<String>(
            onSelected: onMenu,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'voir', child: Text('Voir les offres')),
              PopupMenuItem(value: 'modifier', child: Text('Modifier')),
              PopupMenuItem(value: 'supprimer', child: Text('Supprimer')),
            ],
          ),
        ],
      ),
    );
  }
}

class ConseilCard extends StatelessWidget {
  const ConseilCard({
    super.key,
    required this.title,
    required this.category,
    required this.summary,
    required this.readTime,
    this.onRead,
  });

  final String title;
  final String category;
  final String summary;
  final String readTime;
  final VoidCallback? onRead;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(99)),
            child: Text(category, style: const TextStyle(fontSize: 11, color: Color(0xFF1A56DB))),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(summary, maxLines: 2, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Row(
            children: [
              Text(readTime, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              const Spacer(),
              TextButton(onPressed: onRead, child: const Text('Lire')),
            ],
          ),
        ],
      ),
    );
  }
}

class IaScoreCard extends StatelessWidget {
  const IaScoreCard({
    super.key,
    required this.score,
    required this.tips,
  });

  final int score;
  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    return ProfileSection(
      title: 'Analyse IA du profil',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfilCompletionBar(value: score),
          const SizedBox(height: 10),
          ...tips.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF1A56DB)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.message,
    required this.time,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    this.unread = false,
    this.onTap,
  });

  final String message;
  final String time;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final bool unread;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: iconFg),
      ),
      title: Text(
        message,
        style: TextStyle(fontWeight: unread ? FontWeight.w700 : FontWeight.w500),
      ),
      subtitle: Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
    );
  }
}
