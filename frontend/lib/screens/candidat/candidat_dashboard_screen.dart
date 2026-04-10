import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_extension.dart';
import '../../providers/auth_provider.dart';
import '../../providers/candidat_provider.dart';
import '../../widgets/responsive_container.dart';
import 'widgets/dashboard_completion_polish.dart';
import 'widgets/dashboard_suivi_candidatures.dart';
import 'widgets/offre_recommande_card.dart';

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
    final completionBloc = overview['completion_profil'];
    final manquants = completionBloc is Map
        ? (completionBloc['manquants'] as List<dynamic>? ?? const [])
        : const <dynamic>[];
    final statsBloc = overview['stats'];
    final statsMap = statsBloc is Map<String, dynamic>
        ? statsBloc
        : <String, dynamic>{};

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
            child: DashboardCompletionPolish(
              pourcentage: profileCompletion,
              manquants: manquants,
              onTap: widget.onGoProfil,
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
          _buildOffresRecommandeesSection(context, recommended),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: recentCands.isEmpty && (statsMap['total_candidatures'] as num? ?? 0) == 0
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suivi de mes candidatures',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Aucune candidature pour le moment. Postulez aux offres qui vous correspondent.',
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                      ),
                    ],
                  )
                : DashboardSuiviCandidatures(
                    stats: statsMap,
                    candidaturesRecentes: recentCands,
                    onVoirTout: widget.onGoCandidatures,
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

  Widget _buildOffresRecommandeesSection(
    BuildContext context,
    List<Map<String, dynamic>> offres,
  ) {
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
                      ),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'IA',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Offres pour vous',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: widget.onGoRecommandations,
                child: Text(
                  'Voir tout →',
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1A56DB)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (offres.isEmpty)
            _buildEmptyOffresProfil(context)
          else
            LayoutBuilder(
              builder: (ctx, c) {
                final cols = c.maxWidth > 900 ? 3 : (c.maxWidth > 600 ? 2 : 1);
                final slice = offres.take(6).toList();
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: slice.length,
                  itemBuilder: (ctx, i) => OffreRecommandeCard(
                    offre: slice[i],
                    index: i,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyOffresProfil(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.work_outline_rounded, color: Color(0xFFE2E8F0), size: 48),
          const SizedBox(height: 10),
          Text(
            'Complétez votre profil pour recevoir de meilleures recommandations',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A56DB),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: widget.onGoProfil,
            child: Text('Compléter mon profil', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
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

