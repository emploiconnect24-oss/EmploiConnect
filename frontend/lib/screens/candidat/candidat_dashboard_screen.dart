import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_extension.dart';
import '../../providers/auth_provider.dart';
import '../../providers/candidat_provider.dart';
import '../../widgets/responsive_container.dart';
import 'candidat_offer_detail_screen.dart';

class CandidatDashboardScreen extends StatefulWidget {
  const CandidatDashboardScreen({
    super.key,
    this.onGoOffres,
    this.onGoProfil,
    this.onGoRecommandations,
    this.onGoCandidatures,
    this.onGoAlertes,
  });

  final VoidCallback? onGoOffres;
  final VoidCallback? onGoProfil;
  final VoidCallback? onGoRecommandations;
  final VoidCallback? onGoCandidatures;
  final VoidCallback? onGoAlertes;

  @override
  State<CandidatDashboardScreen> createState() =>
      _CandidatDashboardScreenState();
}

class _CandidatDashboardScreenState extends State<CandidatDashboardScreen> {
  static String _firstNameFromNom(String? nom) {
    final n = (nom ?? '').trim();
    if (n.isEmpty) return 'Candidat';
    return n.split(RegExp(r'\s+')).first;
  }

  static String _shortDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return '';
    }
  }

  static List<Map<String, dynamic>> _asMapList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cStats = context.watch<CandidatProvider>();
    final overview = cStats.overview;
    final displayNom = (overview['candidat'] is Map
            ? (overview['candidat'] as Map)['nom']
            : null)
        ?.toString()
        .trim();
    final profileNom = (cStats.profile['nom'] ?? '').toString().trim();
    final authName = (context.watch<AuthProvider>().user?['nom'] ?? 'Candidat')
        .toString();
    final firstName = _firstNameFromNom(
      displayNom?.isNotEmpty == true
          ? displayNom
          : (profileNom.isNotEmpty ? profileNom : authName),
    );
    final recommended = _asMapList(overview['offres_recommandees']);
    final recentCands = _asMapList(overview['candidatures_recentes']);
    final alertesCount = (overview['nouvelles_offres_alerte'] as num?)?.toInt() ?? 0;
    final candidatures = cStats.badge('candidatures');
    final recommandations = cStats.badge('recommandations');
    final sauvegardes = cStats.badge('sauvegardes');
    final vuesProfil = cStats.kpis['vues_profil'] is num
        ? (cStats.kpis['vues_profil'] as num).toInt()
        : 0;
    final profileCompletion = cStats.profileCompletionPercent;

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Bonjour'
        : hour < 18
        ? 'Bon après-midi'
        : 'Bonsoir';
    final fromApi = (overview['citation_motivation'] ?? '').toString().trim();
    const quotesFallback = [
      'Le succès appartient à ceux qui commencent.',
      'Chaque candidature est un pas vers votre réussite.',
      'Votre prochaine opportunité est à portée de main.',
      'Les grandes choses commencent par une petite action.',
    ];
    final quote = fromApi.isNotEmpty
        ? fromApi
        : quotesFallback[DateTime.now().day % quotesFallback.length];

    final bottomInset = MediaQuery.of(context).size.width <= 900 ? 80.0 : 24.0;
    return ResponsiveContainer(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: ListView(
        padding: EdgeInsets.only(bottom: bottomInset),
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final compact = c.maxWidth < 700;
              return compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting, $firstName ! 👋',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('Voici vos opportunités du jour.'),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: widget.onGoOffres,
                            icon: const Icon(Icons.search_rounded, size: 16),
                            label: const Text('Explorer les offres'),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$greeting, $firstName ! 👋',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text('Voici vos opportunités du jour.'),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: widget.onGoOffres,
                          icon: const Icon(Icons.search_rounded, size: 16),
                          label: const Text('Explorer les offres'),
                        ),
                      ],
                    );
            },
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, (1 - t) * -10),
                child: child,
              ),
            ),
            child: _completionAlert(
              profileCompletion,
              onGoProfil: widget.onGoProfil,
            ),
          ),
          const SizedBox(height: 16),
          _statsGrid(
            candidatures: candidatures,
            recommandations: recommandations,
            sauvegardes: sauvegardes,
            vuesProfil: vuesProfil,
          ),
          const SizedBox(height: 18),
          _sectionCard(
            title: 'Offres recommandées pour vous',
            actionLabel: 'Voir tout',
            onAction: widget.onGoRecommandations,
            child: LayoutBuilder(
              builder: (context, c) {
                final col = c.maxWidth >= 980 ? 2 : 1;
                if (recommended.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Aucune offre publiée pour le moment.',
                    ),
                  );
                }
                return GridView.builder(
                  itemCount: recommended.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: col,
                    childAspectRatio: 3.2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (_, i) {
                    final o = recommended[i];
                    final offreId = (o['id'] ?? '').toString();
                    final ent = o['entreprises'];
                    final company = ent is Map
                        ? (ent['nom_entreprise'] ?? 'Entreprise').toString()
                        : (o['entreprise_nom'] ??
                                o['entreprise']?['nom_entreprise'] ??
                                'Entreprise')
                            .toString();
                    final rawScore = o['_score'] ?? o['score_compatibilite'];
                    int? score;
                    if (rawScore is num) {
                      final r = rawScore.round();
                      score = r > 0 ? r : null;
                    } else if (rawScore != null) {
                      final p = int.tryParse(rawScore.toString());
                      score = (p != null && p > 0) ? p : null;
                    }
                    return _OfferQuickCard(
                      offreId: offreId,
                      title: (o['titre'] ?? 'Offre').toString(),
                      company: company,
                      locationType:
                          '${(o['localisation'] ?? 'N/A').toString()} · ${(o['type_contrat'] ?? 'N/A').toString()}',
                      score: score,
                      onPostuler: offreId.isEmpty
                          ? null
                          : () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      CandidatOfferDetailScreen(offreId: offreId),
                                ),
                              );
                            },
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            title: 'Suivi de mes candidatures',
            actionLabel: 'Voir tout',
            onAction: widget.onGoCandidatures,
            child: recentCands.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Aucune candidature pour le moment. Postulez aux offres qui vous correspondent.',
                    ),
                  )
                : Column(
                    children: recentCands.map((c) {
                      final offre = c['offre'];
                      final titre = offre is Map
                          ? (offre['titre'] ?? 'Offre').toString()
                          : 'Offre';
                      final ent = offre is Map ? offre['entreprise'] : null;
                      final company = ent is Map
                          ? (ent['nom_entreprise'] ?? 'Entreprise').toString()
                          : 'Entreprise';
                      final label = (c['statut_label'] ?? '').toString();
                      final d = _shortDate(c['date_candidature']?.toString());
                      final suffix = d.isEmpty ? '' : ' · $d';
                      return _TrackRow(
                        text: '$company · $titre → $label$suffix',
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.rotate(angle: (1 - t) * -0.02, child: child),
            ),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF1A56DB)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.format_quote_rounded,
                    color: Colors.white54,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      quote,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            title: alertesCount > 0
                ? 'Vos alertes emploi ($alertesCount active${alertesCount > 1 ? 's' : ''})'
                : 'Alertes emploi',
            actionLabel: 'Gérer mes alertes',
            onAction: widget.onGoAlertes ?? widget.onGoOffres,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                alertesCount > 0
                    ? 'Vous avez $alertesCount alerte${alertesCount > 1 ? 's' : ''} configurée${alertesCount > 1 ? 's' : ''}. Parcourez les offres récentes ou affinez vos critères.'
                    : 'Créez une alerte pour recevoir les offres qui vous intéressent.',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _completionAlert(int completion, {VoidCallback? onGoProfil}) {
    final isDark = context.isDark;
    final bg = const Color(0xFF1A56DB).withValues(alpha: isDark ? 0.15 : 0.08);
    final border = const Color(
      0xFF1A56DB,
    ).withValues(alpha: isDark ? 0.30 : 0.20);
    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxWidth < 760;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          color: Color(0xFF1A56DB),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Complétez votre profil pour obtenir de meilleures offres.',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: completion / 100,
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$completion%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onGoProfil,
                        child: const Text('Compléter'),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      color: Color(0xFF1A56DB),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Complétez votre profil pour obtenir de meilleures offres.',
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 120,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$completion%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: completion / 100,
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: onGoProfil,
                      child: const Text('Compléter'),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _statsGrid({
    required int candidatures,
    required int recommandations,
    required int sauvegardes,
    required int vuesProfil,
  }) {
    final stats = [
      ('Candidatures', '$candidatures', 'suivies', Icons.assignment_rounded),
      (
        'Recommandations',
        '$recommandations',
        'offres disponibles',
        Icons.auto_awesome_rounded,
      ),
      (
        'Sauvegardées',
        '$sauvegardes',
        'offres favorites',
        Icons.bookmark_rounded,
      ),
      ('Vues profil', '$vuesProfil', 'ce mois', Icons.visibility_rounded),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 900 ? 4 : 2;
        return GridView.builder(
          itemCount: stats.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
          ),
          itemBuilder: (_, i) => TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(milliseconds: 380 + (i * 80)),
            curve: Curves.easeOut,
            builder: (context, t, child) => Opacity(
              opacity: t.clamp(0, 1),
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 16),
                child: child,
              ),
            ),
            child: _StatCard(
              label: stats[i].$1,
              value: stats[i].$2,
              subtitle: stats[i].$3,
              icon: stats[i].$4,
            ),
          ),
        );
      },
    );
  }

  Widget _sectionCard({
    required String title,
    String? actionLabel,
    VoidCallback? onAction,
    required Widget child,
  }) {
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (actionLabel != null)
                TextButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
          if (child is! SizedBox) const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
  });
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final target = int.tryParse(value) ?? 0;
    final scheme = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ext.cardBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEFF6FF),
            child: Icon(icon, color: const Color(0xFF1A56DB)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: target.toDouble()),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOut,
                  builder: (context, v, _) => Text(
                    v.round().toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(label, style: const TextStyle(fontSize: 12)),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferQuickCard extends StatelessWidget {
  const _OfferQuickCard({
    required this.offreId,
    required this.title,
    required this.company,
    required this.locationType,
    required this.score,
    this.onPostuler,
  });
  final String offreId;
  final String title;
  final String company;
  final String locationType;
  final int? score;
  final VoidCallback? onPostuler;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ext.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(
            company,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
          Text(
            locationType,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Builder(
                  builder: (context) {
                    final s = score;
                    return Text(
                      (s != null && s > 0) ? 'Score IA : $s%' : 'Score IA : —',
                    );
                  },
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: onPostuler,
                child: const Text('Postuler'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Text('● ', style: TextStyle(color: Color(0xFF1A56DB))),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
