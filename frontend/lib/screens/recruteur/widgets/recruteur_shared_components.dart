import 'package:flutter/material.dart';

import 'matching_score_badge.dart';

class RecruteurStatCard extends StatelessWidget {
  const RecruteurStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trend,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? trend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFDBEAFE),
            child: Icon(icon, size: 18, color: const Color(0xFF1D4ED8)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          if (trend != null) Text(trend!, style: const TextStyle(fontSize: 12, color: Color(0xFF10B981))),
        ],
      ),
    );
  }
}

class OffreCard extends StatelessWidget {
  const OffreCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.views,
    required this.applications,
    required this.unread,
    this.onViewApplications,
    this.onEdit,
    this.onDuplicate,
    this.onClose,
  });

  final String title;
  final String subtitle;
  final String status;
  final int views;
  final int applications;
  final int unread;
  final VoidCallback? onViewApplications;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
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
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
              _pill(status),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _StatChip(label: '$views vues', icon: Icons.visibility_outlined),
              _StatChip(label: '$applications candidatures', icon: Icons.people_outline),
              _StatChip(label: '$unread non lues', icon: Icons.mark_email_unread_outlined),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionButton(icon: Icons.assignment_outlined, label: 'Candidatures', onPressed: onViewApplications),
              _ActionButton(icon: Icons.edit_outlined, label: 'Modifier', onPressed: onEdit),
              _ActionButton(icon: Icons.copy_outlined, label: 'Dupliquer', onPressed: onDuplicate),
              _ActionButton(icon: Icons.close_outlined, label: 'Clôturer', onPressed: onClose),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8))),
    );
  }
}

class CandidatureCard extends StatelessWidget {
  const CandidatureCard({
    super.key,
    required this.name,
    required this.jobTitle,
    required this.statusLabel,
    required this.score,
    this.onOpen,
  });

  final String name;
  final String jobTitle;
  final String statusLabel;
  final int score;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFDBEAFE),
        child: Text(name.isEmpty ? '?' : name[0], style: const TextStyle(color: Color(0xFF1D4ED8))),
      ),
      title: Text(name),
      subtitle: Text(jobTitle),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          MatchingScoreBadge(score: score),
          const SizedBox(height: 4),
          Text(statusLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ],
      ),
      onTap: onOpen,
    );
  }
}

class CandidatureKanbanCard extends StatelessWidget {
  const CandidatureKanbanCard({
    super.key,
    required this.name,
    required this.jobTitle,
    required this.score,
    this.onTap,
  });

  final String name;
  final String jobTitle;
  final int score;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(jobTitle, style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 6),
            MatchingScoreBadge(score: score),
          ],
        ),
      ),
    );
  }
}

class TalentCard extends StatelessWidget {
  const TalentCard({
    super.key,
    required this.name,
    required this.title,
    required this.score,
    required this.skills,
    this.onViewProfile,
    this.onContact,
    this.onSave,
  });

  final String name;
  final String title;
  final int score;
  final List<String> skills;
  final VoidCallback? onViewProfile;
  final VoidCallback? onContact;
  final VoidCallback? onSave;

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
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFDBEAFE),
                child: Text(name.isEmpty ? '?' : name[0], style: const TextStyle(color: Color(0xFF1D4ED8))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(title),
                  ],
                ),
              ),
              MatchingScoreBadge(score: score),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...skills.take(4).map((s) => Chip(label: Text(s), visualDensity: VisualDensity.compact)),
              if (skills.length > 4) Chip(label: Text('+${skills.length - 4}')),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(onPressed: onViewProfile, child: const Text('Voir profil')),
              OutlinedButton(onPressed: onContact, child: const Text('Contacter')),
              FilledButton(onPressed: onSave, child: const Text('Sauvegarder')),
            ],
          ),
        ],
      ),
    );
  }
}

class KanbanBoard extends StatelessWidget {
  const KanbanBoard({super.key, required this.columns});
  final List<KanbanColumn> columns;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: columns.map((col) {
          return Container(
            width: 270,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${col.title} (${col.count})', style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                ...col.children,
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class KanbanColumn {
  const KanbanColumn({required this.title, required this.count, required this.children});
  final String title;
  final int count;
  final List<Widget> children;
}

class CvViewer extends StatelessWidget {
  const CvViewer({super.key, required this.cvUrl});
  final String cvUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf_outlined),
          const SizedBox(width: 8),
          Expanded(child: Text(cvUrl, maxLines: 1, overflow: TextOverflow.ellipsis)),
          OutlinedButton(onPressed: () {}, child: const Text('Ouvrir')),
        ],
      ),
    );
  }
}

class OffreFormSteps extends StatelessWidget {
  const OffreFormSteps({super.key, required this.currentStep});
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const labels = ['Informations', 'Description', 'Prérequis', 'Publication'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(
        labels.length,
        (i) => ChoiceChip(
          label: Text('${i + 1}. ${labels[i]}'),
          selected: i == currentStep,
          onSelected: (_) {},
        ),
      ),
    );
  }
}

class TipsPanel extends StatelessWidget {
  const TipsPanel({super.key, required this.tips});
  final List<String> tips;

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
          const Text('Conseils', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...tips.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $t'),
              )),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.content, required this.time, required this.isMe});
  final String content;
  final String time;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1A56DB) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(content, style: TextStyle(color: isMe ? Colors.white : const Color(0xFF0F172A))),
            const SizedBox(height: 4),
            Text(time, style: TextStyle(fontSize: 11, color: isMe ? Colors.white70 : const Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }
}

class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.initials,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.selected,
    this.onTap,
  });

  final String initials;
  final String name;
  final String lastMessage;
  final String time;
  final bool unread;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      selected: selected,
      selectedTileColor: const Color(0xFFEEF2FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFDBEAFE),
        child: Text(initials, style: const TextStyle(color: Color(0xFF1D4ED8))),
      ),
      title: Text(name),
      subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(time, style: const TextStyle(fontSize: 11)),
          if (unread) const Text('●', style: TextStyle(color: Color(0xFF1D4ED8))),
        ],
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.time,
    required this.unread,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final String time;
  final bool unread;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE2E8F0),
        child: Icon(icon, size: 18),
      ),
      title: Row(
        children: [
          Expanded(child: Text(title)),
          if (unread) const Text('●', style: TextStyle(color: Color(0xFF1D4ED8))),
        ],
      ),
      subtitle: Text('$message\n$time'),
      isThreeLine: true,
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, this.onPressed});
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label));
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ],
    );
  }
}
