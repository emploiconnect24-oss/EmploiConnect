import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/recruteur_provider.dart';
import '../../../shared/widgets/status_badge.dart';

/// Vue d’ensemble recruteur (PRD v5.3) — données via [RecruteurProvider].
class DashboardOverviewPage extends StatelessWidget {
  const DashboardOverviewPage({super.key, this.onShellNavigate});

  final void Function(String route)? onShellNavigate;

  void _go(BuildContext context, String route) {
    final cb = onShellNavigate;
    if (cb != null) {
      cb(route);
    }
  }

  static int _n(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }

  static String _nomCand(Map<String, dynamic> c) {
    final ch = c['chercheur'];
    if (ch is Map) {
      final u = ch['utilisateur'];
      if (u is Map) return u['nom']?.toString() ?? 'Candidat';
    }
    final legacy = c['candidat'];
    if (legacy is Map) return legacy['nom']?.toString() ?? 'Candidat';
    return 'Candidat';
  }

  static String? _photoCand(Map<String, dynamic> c) {
    final ch = c['chercheur'];
    if (ch is Map) {
      final u = ch['utilisateur'];
      if (u is Map) return u['photo_url']?.toString();
    }
    return null;
  }

  static int? _score(Map<String, dynamic> c) {
    final s = c['score_compatibilite'];
    if (s == null) return null;
    if (s is num) return s.round();
    return int.tryParse(s.toString());
  }

  static String _formatDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final d = DateTime.parse(raw.toString()).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  static Color _scoreColor(int score) {
    if (score >= 70) return const Color(0xFF10B981);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecruteurProvider>();
    final data = provider.dashboardData ?? {};
    final stats = data['stats'] as Map<String, dynamic>? ?? {};
    final offres = List<Map<String, dynamic>>.from(data['offres_actives'] ?? const []);
    final cands = List<Map<String, dynamic>>.from(data['candidatures_recentes'] ?? const []);
    final urgentes = List<Map<String, dynamic>>.from(data['candidatures_urgentes'] ?? const []);
    final evolution = List<Map<String, dynamic>>.from(data['evolution_semaine'] ?? const []);
    final entreprise = data['entreprise'] as Map<String, dynamic>? ?? {};

    final token = context.read<AuthProvider>().token ?? '';

    return RefreshIndicator(
      color: const Color(0xFF1A56DB),
      onRefresh: () async {
        if (token.isEmpty) return;
        await context.read<RecruteurProvider>().loadAll(token);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              entreprise: entreprise,
              urgentes: urgentes,
              onNewOffer: () => _go(context, '/dashboard-recruteur/offres/nouvelle'),
            ),
            const SizedBox(height: 20),
            _StatCards(stats: stats),
            const SizedBox(height: 24),
            if (urgentes.isNotEmpty) ...[
              _UrgentBanner(
                count: urgentes.length,
                onTap: () => _go(context, '/dashboard-recruteur/candidatures'),
              ),
              const SizedBox(height: 16),
            ],
            LayoutBuilder(
              builder: (ctx, c) {
                if (c.maxWidth > 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 60, child: _EvolutionChart(evolution: evolution)),
                      const SizedBox(width: 16),
                      Expanded(flex: 40, child: _RepartitionCard(stats: stats)),
                    ],
                  );
                }
                return Column(
                  children: [
                    _EvolutionChart(evolution: evolution),
                    const SizedBox(height: 16),
                    _RepartitionCard(stats: stats),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            _Section(
              titre: 'Candidatures récentes',
              lienLabel: 'Voir tout →',
              onLien: () => _go(context, '/dashboard-recruteur/candidatures'),
              child: _CandidaturesList(cands: cands),
            ),
            const SizedBox(height: 24),
            _Section(
              titre: 'Mes offres actives',
              lienLabel: 'Gérer →',
              onLien: () => _go(context, '/dashboard-recruteur/offres'),
              child: _OffresList(
                offres: offres,
                onTapOffre: (_) => _go(context, '/dashboard-recruteur/candidatures'),
                onPublishFirst: () => _go(context, '/dashboard-recruteur/offres/nouvelle'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.entreprise,
    required this.urgentes,
    required this.onNewOffer,
  });

  final Map<String, dynamic> entreprise;
  final List<Map<String, dynamic>> urgentes;
  final VoidCallback onNewOffer;

  @override
  Widget build(BuildContext context) {
    final nom = entreprise['nom']?.toString() ?? 'Mon entreprise';
    final h = DateTime.now().hour;
    final salut = h < 12 ? 'Bonjour' : (h < 18 ? 'Bon après-midi' : 'Bonsoir');
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$salut 👋',
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
              ),
              Text(
                nom,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              if (urgentes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle),
                      ),
                      Expanded(
                        child: Text(
                          '${urgentes.length} candidature(s) en attente depuis plus de 7 jours',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFFF59E0B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 18),
          label: Text('Nouvelle offre', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: onNewOffer,
        ),
      ],
    );
  }
}

class _StatCards extends StatelessWidget {
  const _StatCards({required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final att = DashboardOverviewPage._n(stats['offres_en_attente_valid']);
    final cards = [
      _StatInfo(
        label: 'Offres actives',
        value: '${DashboardOverviewPage._n(stats['offres_actives'])}',
        subLabel: att > 0 ? '+$att en attente validation' : 'Publiées et visibles',
        icon: Icons.work_rounded,
        color: const Color(0xFF1A56DB),
        bg: const Color(0xFFEFF6FF),
      ),
      _StatInfo(
        label: 'Candidatures',
        value: '${DashboardOverviewPage._n(stats['total_candidatures'])}',
        subLabel: '${DashboardOverviewPage._n(stats['candidatures_en_attente'])} en attente',
        icon: Icons.people_rounded,
        color: const Color(0xFF10B981),
        bg: const Color(0xFFECFDF5),
      ),
      _StatInfo(
        label: 'Vues ce mois',
        value: '${DashboardOverviewPage._n(stats['vues_ce_mois'])}',
        subLabel: 'Visiteurs (fenêtre 30 j / agrégé)',
        icon: Icons.visibility_rounded,
        color: const Color(0xFF8B5CF6),
        bg: const Color(0xFFF5F3FF),
      ),
      _StatInfo(
        label: 'Taux de réponse',
        value: '${DashboardOverviewPage._n(stats['taux_reponse'])}%',
        subLabel: DashboardOverviewPage._n(stats['taux_reponse']) >= 50 ? 'Bon taux' : 'À améliorer',
        icon: Icons.reply_rounded,
        color: const Color(0xFFF59E0B),
        bg: const Color(0xFFFEF3C7),
      ),
    ];

    return LayoutBuilder(
      builder: (ctx, c) {
        final cols = c.maxWidth < 600 ? 2 : 4;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: c.maxWidth < 600 ? 1.4 : 1.8,
          children: cards.map((s) => _StatCard(info: s)).toList(),
        );
      },
    );
  }
}

class _StatInfo {
  const _StatInfo({
    required this.label,
    required this.value,
    required this.subLabel,
    required this.icon,
    required this.color,
    required this.bg,
  });
  final String label;
  final String value;
  final String subLabel;
  final IconData icon;
  final Color color;
  final Color bg;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.info});
  final _StatInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: info.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(info.icon, color: info.color, size: 22),
          const Spacer(),
          Text(info.value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
          Text(info.label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(info.subLabel, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _UrgentBanner extends StatelessWidget {
  const _UrgentBanner({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFDBA74)),
        ),
        child: Row(
          children: [
            const Icon(Icons.hourglass_empty_rounded, color: Color(0xFFF97316), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count candidature(s) attendent votre réponse depuis plus de 7 jours. '
                'Répondez rapidement pour améliorer votre taux !',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF9A3412),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF9A3412)),
          ],
        ),
      ),
    );
  }
}

class _EvolutionChart extends StatelessWidget {
  const _EvolutionChart({required this.evolution});
  final List<Map<String, dynamic>> evolution;

  @override
  Widget build(BuildContext context) {
    final maxVal = evolution.isEmpty
        ? 1
        : evolution.map((e) => DashboardOverviewPage._n(e['count'])).reduce((a, b) => a > b ? a : b);
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final total = evolution.fold<int>(0, (s, e) => s + DashboardOverviewPage._n(e['count']));

    return Container(
      padding: const EdgeInsets.all(20),
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
              Text(
                'Candidatures — 7 derniers jours',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
              ),
              const Spacer(),
              Text('Total: $total', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 20),
          if (evolution.isEmpty)
            Center(child: Text('Aucune donnée', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))))
          else
            // Empêche les RenderFlex overflow quand l’espace vertical est serré.
            SizedBox(
              height: 132,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: evolution.map((e) {
                  final count = DashboardOverviewPage._n(e['count']);
                  final pct = maxVal > 0 ? count / maxVal : 0.0;
                  final isToday = e['date']?.toString() == todayStr;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (count > 0)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '$count',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A56DB),
                                ),
                              ),
                            ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            height: (86 * pct).clamp(4.0, 86.0),
                            decoration: BoxDecoration(
                              color: isToday ? const Color(0xFF1A56DB) : const Color(0xFF1A56DB).withValues(alpha: 0.25),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              e['jour']?.toString() ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: isToday ? const Color(0xFF1A56DB) : const Color(0xFF94A3B8),
                                fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _RepartitionCard extends StatelessWidget {
  const _RepartitionCard({required this.stats});
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final total = DashboardOverviewPage._n(stats['total_candidatures']);
    final att = DashboardOverviewPage._n(stats['candidatures_en_attente']);
    final acc = DashboardOverviewPage._n(stats['candidatures_acceptees']);
    final ref = DashboardOverviewPage._n(stats['candidatures_refusees']);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Répartition candidatures',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 16),
          if (total == 0)
            Center(
              child: Column(
                children: [
                  const Icon(Icons.people_outline, color: Color(0xFFE2E8F0), size: 40),
                  const SizedBox(height: 8),
                  Text('Aucune candidature', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13)),
                ],
              ),
            )
          else ...[
            _RepartRow(label: 'En attente', count: att, color: const Color(0xFF1A56DB), total: total),
            const SizedBox(height: 12),
            _RepartRow(label: 'Acceptées', count: acc, color: const Color(0xFF10B981), total: total),
            const SizedBox(height: 12),
            _RepartRow(label: 'Refusées', count: ref, color: const Color(0xFFEF4444), total: total),
          ],
        ],
      ),
    );
  }
}

class _RepartRow extends StatelessWidget {
  const _RepartRow({
    required this.label,
    required this.count,
    required this.color,
    required this.total,
  });
  final String label;
  final int count;
  final Color color;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155))),
            Text(
              total > 0 ? '$count (${(count / total * 100).toStringAsFixed(0)}%)' : '$count',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: total > 0 ? count / total : 0,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.titre,
    required this.lienLabel,
    required this.onLien,
    required this.child,
  });
  final String titre;
  final String lienLabel;
  final VoidCallback onLien;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(titre, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
            TextButton(
              onPressed: onLien,
              child: Text(lienLabel, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1A56DB))),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _CandidaturesList extends StatelessWidget {
  const _CandidaturesList({required this.cands});
  final List<Map<String, dynamic>> cands;

  @override
  Widget build(BuildContext context) {
    if (cands.isEmpty) {
      return _EmptyCard(icon: Icons.people_outline, message: 'Aucune candidature reçue pour le moment');
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: cands.map((c) {
          final nom = DashboardOverviewPage._nomCand(c);
          final photo = DashboardOverviewPage._photoCand(c);
          final offre = (c['offre'] is Map) ? (c['offre'] as Map)['titre']?.toString() ?? 'Offre' : 'Offre';
          final score = DashboardOverviewPage._score(c);
          final statut = c['statut']?.toString() ?? 'en_attente';
          final date = DashboardOverviewPage._formatDate(c['date_candidature']);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF1A56DB),
                  backgroundImage: photo != null && photo.isNotEmpty ? NetworkImage(photo) : null,
                  child: photo == null || photo.isEmpty
                      ? Text(
                          nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nom, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                      Text(offre, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (score != null && score > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: DashboardOverviewPage._scoreColor(score).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: DashboardOverviewPage._scoreColor(score).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, size: 10, color: Color(0xFF1A56DB)),
                        const SizedBox(width: 3),
                        Text(
                          '$score%',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: DashboardOverviewPage._scoreColor(score)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                StatusBadge(label: statut),
                const SizedBox(width: 8),
                Text(date, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _OffresList extends StatelessWidget {
  const _OffresList({
    required this.offres,
    required this.onTapOffre,
    required this.onPublishFirst,
  });
  final List<Map<String, dynamic>> offres;
  final void Function(String id) onTapOffre;
  final VoidCallback onPublishFirst;

  @override
  Widget build(BuildContext context) {
    if (offres.isEmpty) {
      return _EmptyCard(
        icon: Icons.work_outline,
        message: 'Aucune offre active. Publiez votre première offre !',
        actionLabel: 'Publier une offre',
        onAction: onPublishFirst,
      );
    }
    return Column(
      children: offres.map((o) {
        final id = o['id']?.toString() ?? '';
        final titre = o['titre']?.toString() ?? 'Offre';
        final nbVues = DashboardOverviewPage._n(o['nb_vues']);
        final nbCands = DashboardOverviewPage._n(o['nb_candidatures']);
        final nbNonLus = DashboardOverviewPage._n(o['nb_non_lues']);
        final statut = o['statut']?.toString() ?? '';
        String dateLimite = '';
        if (o['date_limite'] != null) {
          try {
            final dl = DateTime.parse(o['date_limite'].toString()).toLocal();
            final diff = dl.difference(DateTime.now()).inDays;
            dateLimite = diff > 0 ? 'Expire dans $diff j' : 'Expirée';
          } catch (_) {}
        }
        return GestureDetector(
          onTap: () => onTapOffre(id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: nbNonLus > 0 ? const Color(0xFF1A56DB).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
              ),
              boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: nbNonLus > 0 ? const Color(0xFF1A56DB) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              titre,
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          StatusBadge(label: statut),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _OffreStat(icon: Icons.visibility_outlined, text: '$nbVues vues'),
                          const SizedBox(width: 14),
                          _OffreStat(icon: Icons.people_outline, text: '$nbCands candidats'),
                          if (nbNonLus > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                '$nbNonLus nouvelles',
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF10B981)),
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (dateLimite.isNotEmpty)
                            Text(
                              dateLimite,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: dateLimite.contains('Expir') ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _OffreStat extends StatelessWidget {
  const _OffreStat({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(text, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message, this.actionLabel, this.onAction});
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: const Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          Text(message, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8)), textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56DB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: onAction,
              child: Text(actionLabel!, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }
}
