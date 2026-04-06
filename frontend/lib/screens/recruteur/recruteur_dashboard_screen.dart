import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/theme_extension.dart';
import '../../widgets/responsive_container.dart';

class RecruteurDashboardScreen extends StatelessWidget {
  const RecruteurDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    final today = DateTime.now();
    final dateText =
        '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}';

    final stats = const [
      _StatData('Offres actives', '12', '+2 ce mois', Icons.work_rounded, Color(0xFF1A56DB), Color(0xFFEFF6FF)),
      _StatData('Candidatures', '47', '+5 aujourd\'hui', Icons.people_rounded, Color(0xFF10B981), Color(0xFFECFDF5)),
      _StatData('Vues ce mois', '1 284', '+18%', Icons.visibility_rounded, Color(0xFF8B5CF6), Color(0xFFF5F3FF)),
      _StatData('Taux réponse', '89%', 'Excellent', Icons.star_rounded, Color(0xFFF59E0B), Color(0xFFFEF3C7)),
    ];

    return ResponsiveContainer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour, Mon entreprise',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: scheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vous avez 5 nouvelles candidatures aujourd\'hui.',
                      style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ext.cardBorder),
                  ),
                  child: Text(dateText, style: TextStyle(color: scheme.onSurfaceVariant)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hourglass_empty_rounded, color: Color(0xFFF59E0B), size: 16),
                  SizedBox(width: 8),
                  Text('8 candidatures en attente de réponse',
                      style: TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth >= 1100 ? 4 : (c.maxWidth >= 700 ? 2 : 1);
                return GridView.builder(
                  itemCount: stats.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    childAspectRatio: 2.25,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemBuilder: (_, i) => FadeInUp(
                    delay: Duration(milliseconds: i * 80),
                    duration: const Duration(milliseconds: 500),
                    child: _RecruteurStatCard(data: stats[i]),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            _SectionCard(
              title: 'Candidatures récentes (5 aujourd\'hui)',
              actionLabel: 'Voir tout',
              child: Column(
                children: const [
                  _RecentCandidateRow(name: 'Mamadou Barry', role: 'Dév. Flutter', score: 94),
                  _RecentCandidateRow(name: 'Aissatou Diallo', role: 'UX Designer', score: 87),
                  _RecentCandidateRow(name: 'Sekou Kouyaté', role: 'PM', score: 76),
                ],
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, c) {
                if (c.maxWidth < 980) {
                  return const Column(
                    children: [
                      _ViewsChartCard(),
                      SizedBox(height: 12),
                      _ActiveOffersCard(),
                    ],
                  );
                }
                return const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 55, child: _ViewsChartCard()),
                    SizedBox(width: 12),
                    Expanded(flex: 45, child: _ActiveOffersCard()),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Recommandations IA',
              subtitle: 'Profils correspondant à vos offres actives',
              actionLabel: 'Voir tous les talents',
              child: LayoutBuilder(
                builder: (context, c) {
                  final cols = c.maxWidth >= 1100 ? 4 : (c.maxWidth >= 700 ? 2 : 1);
                  return GridView.count(
                    crossAxisCount: cols,
                    childAspectRatio: 1.4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      _TalentMiniCard(name: 'Mamadou B.', score: 94),
                      _TalentMiniCard(name: 'Aissatou D.', score: 91),
                      _TalentMiniCard(name: 'Ibrahima B.', score: 88),
                      _TalentMiniCard(name: 'Mariam K.', score: 85),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    this.subtitle,
    this.actionLabel,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ext.cardBorder),
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
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                    ],
                  ],
                ),
              ),
              if (actionLabel != null)
                TextButton(
                  onPressed: () {},
                  child: Text(actionLabel!),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StatData {
  const _StatData(this.label, this.value, this.trend, this.icon, this.color, this.bg);
  final String label;
  final String value;
  final String trend;
  final IconData icon;
  final Color color;
  final Color bg;
}

class _RecruteurStatCard extends StatelessWidget {
  const _RecruteurStatCard({required this.data});
  final _StatData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ext.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: data.bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(data.icon, color: data.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(data.label, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(data.value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                Text(data.trend, style: TextStyle(fontSize: 12, color: data.color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentCandidateRow extends StatelessWidget {
  const _RecentCandidateRow({required this.name, required this.role, required this.score});
  final String name;
  final String role;
  final int score;

  @override
  Widget build(BuildContext context) {
    final ext = context.themeExt;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ext.sectionBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ext.cardBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFEFF6FF),
            child: Text(name[0], style: const TextStyle(color: Color(0xFF1A56DB), fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text('$name · $role', style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          _ScoreBadge(score: score),
          const SizedBox(width: 8),
          IconButton(onPressed: () {}, icon: const Icon(Icons.check_circle_outline, color: Color(0xFF10B981))),
          IconButton(onPressed: () {}, icon: const Icon(Icons.close_rounded, color: Color(0xFFEF4444))),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    Color c = const Color(0xFF10B981);
    if (score < 80) c = const Color(0xFF1A56DB);
    if (score < 60) c = const Color(0xFFF59E0B);
    if (score < 40) c = const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$score%', style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class _ViewsChartCard extends StatelessWidget {
  const _ViewsChartCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ext.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vues des offres (30 j.)', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: ext.sectionBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ext.cardBorder),
              ),
              alignment: Alignment.center,
              child: Text('Graphique vues (Section 15)', style: TextStyle(color: scheme.onSurfaceVariant)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveOffersCard extends StatelessWidget {
  const _ActiveOffersCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ext.cardBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mes offres actives', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 12),
          Text('• Développeur Flutter (23 cand.)'),
          SizedBox(height: 6),
          Text('• Chef de projet (12 cand.)'),
          SizedBox(height: 6),
          Text('• Data Analyst (8 cand.)'),
          Spacer(),
          Text('Gérer mes offres →', style: TextStyle(color: Color(0xFF1A56DB), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TalentMiniCard extends StatelessWidget {
  const _TalentMiniCard({required this.name, required this.score});
  final String name;
  final int score;

  @override
  Widget build(BuildContext context) {
    final ext = context.themeExt;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ext.sectionBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ext.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
              _ScoreBadge(score: score),
            ],
          ),
          const Spacer(),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1A56DB),
              foregroundColor: scheme.onPrimary,
              minimumSize: const Size(double.infinity, 36),
            ),
            child: const Text('Contacter'),
          ),
        ],
      ),
    );
  }
}
