import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_extension.dart';
import '../../models/admin_stats.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../widgets/responsive_container.dart';
import 'widgets/admin_page_shimmer.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _admin = AdminService();

  Future<void> _refreshAdmin() async {
    await context.read<AdminProvider>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        if (admin.isLoading && admin.dashboardResponse == null) {
          return ResponsiveContainer(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: const AdminDashboardShimmer(),
            ),
          );
        }
        if (admin.error != null && admin.dashboardResponse == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(admin.error!, textAlign: TextAlign.center),
                ),
                FilledButton(
                  onPressed: () => admin.loadDashboard(),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }
        final dash = admin.dashboardResponse ?? <String, dynamic>{};
    final st = AdminStats.fromDashboardBody(dash);
    final root = dash;
    final cards = <_StatCardData>[
      _StatCardData(
        label: 'Utilisateurs',
        value: _v(root['nombre_chercheurs']) + _v(root['nombre_entreprises']) + _v(root['nombre_admins']),
        trendLabel: '',
        trendPositive: true,
        icon: Icons.people_rounded,
        color: const Color(0xFF1A56DB),
        bgColor: const Color(0xFFEFF6FF),
      ),
      _StatCardData(
        label: 'Offres actives',
        value: _v(root['nombre_offres_actives']),
        trendLabel: '',
        trendPositive: true,
        icon: Icons.work_rounded,
        color: const Color(0xFF10B981),
        bgColor: const Color(0xFFECFDF5),
      ),
      _StatCardData(
        label: 'Entreprises',
        value: _v(root['nombre_entreprises']),
        trendLabel: '',
        trendPositive: true,
        icon: Icons.business_rounded,
        color: const Color(0xFF8B5CF6),
        bgColor: const Color(0xFFF5F3FF),
      ),
      _StatCardData(
        label: 'Candidatures',
        value: st.totalCandidatures,
        trendLabel: '',
        trendPositive: true,
        icon: Icons.assignment_rounded,
        color: const Color(0xFFF59E0B),
        bgColor: const Color(0xFFFEF3C7),
      ),
      _StatCardData(
        label: 'En attente',
        value: st.usersEnAttente + st.offresEnAttente,
        trendLabel: '',
        trendPositive: false,
        icon: Icons.hourglass_empty_rounded,
        color: const Color(0xFFF59E0B),
        bgColor: const Color(0xFFFEF3C7),
      ),
      _StatCardData(
        label: 'Signalements',
        value: st.signalementsEnAttente,
        trendLabel: st.signalementsEnAttente > 0 ? 'À traiter' : '',
        trendPositive: false,
        icon: Icons.shield_rounded,
        color: const Color(0xFFEF4444),
        bgColor: const Color(0xFFFEE2E2),
      ),
    ];

        return ResponsiveContainer(
      child: RefreshIndicator(
        onRefresh: () => admin.loadDashboard(),
        color: const Color(0xFF1A56DB),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WelcomeHeader(),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  final crossCount = w >= 900
                      ? 4
                      : w >= 600
                          ? 3
                          : w >= 380
                              ? 2
                              : 1;
                  final aspectRatio = w < 380
                      ? 1.25
                      : w < 600
                          ? 1.4
                          : w < 900
                              ? 1.65
                              : 1.9;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cards.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: aspectRatio,
                    ),
                    itemBuilder: (_, i) => FadeInUp(
                      delay: Duration(milliseconds: i * 80),
                      duration: const Duration(milliseconds: 500),
                      child: _StatCard(data: cards[i]),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              _ActivityChartCard(evolution: admin.evolution7d),
              const SizedBox(height: 20),
              _RecentActivityCard(activites: _activitesRecentes(dash)),
              const SizedBox(height: 24),
              _PendingJobsCard(
                pendingCount: st.offresEnAttente,
                offres: _offresEnAttenteList(dash),
                onValidate: _validerOffre,
                onReject: _refuserOffre,
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  int _v(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Données issues de `data.activite_recente` (table `activite_admin` côté API).
  List<Map<String, String>> _activitesRecentes(Map<String, dynamic> dash) {
    final data = dash['data'] as Map<String, dynamic>?;
    final raw = (data?['activite_recente'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        const <Map<String, dynamic>>[];
    final out = <Map<String, String>>[];
    for (final a in raw.take(8)) {
      final action = a['action']?.toString() ?? '';
      final type = a['type_objet']?.toString() ?? '';
      final adminRow = a['admin'];
      String who = 'Administrateur';
      if (adminRow is Map) {
        who = adminRow['nom']?.toString() ?? adminRow['email']?.toString() ?? who;
      }
      final iso = a['date_action']?.toString();
      final dt = iso != null ? DateTime.tryParse(iso) : null;
      final when = dt != null ? DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(dt.toLocal()) : '';
      final libelleApi = a['action_libelle']?.toString().trim() ?? '';
      final title =
          libelleApi.isNotEmpty ? libelleApi : _libelleActionAdmin(action);
      final detail = type.isNotEmpty ? 'Cible : $type' : 'Journal d’audit';
      out.add({
        'title': title,
        'subtitle': detail,
        'meta': '$who · $when',
        'kind': action.toLowerCase(),
      });
    }
    if (out.isEmpty) {
      out.add({
        'title': 'Aucune entrée pour l’instant',
        'subtitle':
            'Ce fil affiche les actions enregistrées dans le journal admin (validations, modération, paramètres, etc.).',
        'meta': 'Connectez-vous en tant qu’admin et effectuez une action pour alimenter la liste.',
        'kind': 'empty',
      });
    }
    return out;
  }

  String _libelleActionAdmin(String raw) {
    final a = raw.toLowerCase().trim();
    if (a.isEmpty) return 'Action administrateur';
    if (a.contains('valid')) return 'Validation / compte ou contenu';
    if (a.contains('refus') || a.contains('reject')) return 'Refus / rejet';
    if (a.contains('bloq') || a.contains('suspend')) return 'Blocage ou suspension';
    if (a.contains('suppr') || a.contains('delet')) return 'Suppression';
    if (a.contains('param') || a.contains('config')) return 'Modification des paramètres';
    if (a.contains('offre') || a.contains('job')) return 'Action sur une offre';
    if (a.contains('signalement')) return 'Traitement signalement';
    return raw.replaceAll('_', ' ');
  }

  List<Map<String, dynamic>> _offresEnAttenteList(Map<String, dynamic> dash) {
    final data = dash['data'] as Map<String, dynamic>?;
    final raw = data?['offres_en_attente'];
    if (raw is! List) return const [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> _validerOffre(String id) async {
    try {
      await _admin.patchOffreAdmin(id, action: 'valider');
      await _refreshAdmin();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offre validée')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _refuserOffre(String id) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Motif du refus'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Raison affichée côté modération'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Refuser')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final r = ctrl.text.trim();
    if (r.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Une raison est requise pour refuser une offre.')),
      );
      return;
    }
    try {
      await _admin.patchOffreAdmin(id, action: 'refuser', raisonRefus: r);
      await _refreshAdmin();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offre refusée')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

class _WelcomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    final now = DateTime.now();
    final formatted = DateFormat('EEEE dd MMM yyyy', 'fr_FR').format(now);
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final nom = auth.user?['nom']?.toString() ?? 'Administrateur';
        return LayoutBuilder(
          builder: (context, c) {
            final narrow = c.maxWidth < 560;
            final dateChip = Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ext.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      formatted,
                      style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
            final titleBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, $nom',
                  style: TextStyle(
                    fontSize: narrow ? 20 : 24,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Voici un aperçu de la plateforme EmploiConnect aujourd\'hui.',
                  style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                ),
              ],
            );
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleBlock,
                  const SizedBox(height: 12),
                  dateChip,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: titleBlock),
                const SizedBox(width: 12),
                dateChip,
              ],
            );
          },
        );
      },
    );
  }
}

class _StatCardData {
  const _StatCardData({
    required this.label,
    required this.value,
    required this.trendLabel,
    required this.trendPositive,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  final String label;
  final int value;
  final String trendLabel;
  final bool trendPositive;
  final IconData icon;
  final Color color;
  final Color bgColor;
}

class _StatCard extends StatefulWidget {
  const _StatCard({required this.data});

  final _StatCardData data;

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final scheme = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered ? data.color.withValues(alpha: 0.28) : ext.cardBorder,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: data.color.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: data.bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(data.icon, color: data.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(data.label, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        tween: Tween<double>(begin: 0, end: data.value.toDouble()),
                        builder: (context, value, _) => Text(
                          NumberFormat.decimalPattern('fr_FR').format(value.round()),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      if (data.trendLabel.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: data.trendPositive
                                ? const Color(0xFFD1FAE5)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            data.trendLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: data.trendPositive
                                  ? const Color(0xFF065F46)
                                  : const Color(0xFF991B1B),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityChartCard extends StatelessWidget {
  const _ActivityChartCard({required this.evolution});

  final List<Map<String, dynamic>> evolution;

  static const double _chartHeight = 300;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    final spotsU = <FlSpot>[];
    final spotsO = <FlSpot>[];
    for (var i = 0; i < evolution.length; i++) {
      final e = evolution[i];
      final u = (e['utilisateurs'] is num) ? (e['utilisateurs'] as num).toDouble() : 0.0;
      final o = (e['offres'] is num) ? (e['offres'] as num).toDouble() : 0.0;
      spotsU.add(FlSpot(i.toDouble(), u));
      spotsO.add(FlSpot(i.toDouble(), o));
    }
    final maxY = [
      ...spotsU.map((s) => s.y),
      ...spotsO.map((s) => s.y),
      1.0,
    ].reduce((a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ext.cardBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.show_chart_rounded, color: Color(0xFF1A56DB), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activité sur 7 jours',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nouveaux comptes utilisateurs et nouvelles offres créées par jour (statistiques agrégées).',
                      style: GoogleFonts.inter(fontSize: 13, height: 1.35, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: _chartHeight,
            width: double.infinity,
            child: spotsU.isEmpty
                ? Center(
                    child: Text(
                      'Pas encore de données sur cette période.',
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY > 5 ? (maxY / 4).ceilToDouble() : 1,
                        getDrawingHorizontalLine: (_) => FlLine(color: ext.cardBorder, strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 26,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= evolution.length) return const SizedBox.shrink();
                              final d = evolution[i]['date']?.toString() ?? '';
                              final short = d.length >= 10 ? d.substring(5, 10) : d;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  short,
                                  style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (value, _) => Text(
                              value.toInt().toString(),
                              style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                            ),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                      maxY: maxY < 1 ? 4 : maxY * 1.1,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spotsU,
                          isCurved: true,
                          color: const Color(0xFF1A56DB),
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                        ),
                        LineChartBarData(
                          spots: spotsO,
                          isCurved: true,
                          color: const Color(0xFF10B981),
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 400),
                  ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: const [
              _LegendDot(color: Color(0xFF1A56DB), label: 'Nouveaux utilisateurs'),
              _LegendDot(color: Color(0xFF10B981), label: 'Nouvelles offres'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.activites});

  final List<Map<String, String>> activites;

  IconData _iconForKind(String? kind) {
    final k = kind ?? '';
    if (k == 'empty') return Icons.info_outline_rounded;
    if (k.contains('valid')) return Icons.verified_outlined;
    if (k.contains('refus') || k.contains('reject')) return Icons.cancel_outlined;
    if (k.contains('suppr') || k.contains('delet')) return Icons.delete_outline_rounded;
    if (k.contains('param') || k.contains('config')) return Icons.tune_rounded;
    if (k.contains('signalement')) return Icons.shield_outlined;
    if (k.contains('offre')) return Icons.work_outline_rounded;
    return Icons.history_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ext.cardBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E3A8A), Color(0xFF1A56DB)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.timeline_rounded, color: Colors.white.withValues(alpha: 0.95), size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Journal d’activité admin',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Dernières actions enregistrées (table activite_admin) : validations, modération, paramètres, etc.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < activites.length; i++) ...[
                  if (i > 0) const SizedBox(height: 4),
                  _RecentActivityTile(
                    icon: _iconForKind(activites[i]['kind']),
                    title: activites[i]['title'] ?? '',
                    subtitle: activites[i]['subtitle'] ?? '',
                    meta: activites[i]['meta'] ?? '',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityTile extends StatelessWidget {
  const _RecentActivityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.meta,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String meta;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF1A56DB)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Material(
              color: ext.sectionBg,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        meta,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingJobsCard extends StatelessWidget {
  const _PendingJobsCard({
    required this.pendingCount,
    required this.offres,
    required this.onValidate,
    required this.onReject,
  });

  final int pendingCount;
  final List<Map<String, dynamic>> offres;
  final Future<void> Function(String id) onValidate;
  final Future<void> Function(String id) onReject;

  String _entrepriseLine(Map<String, dynamic> o) {
    final e = o['entreprises'];
    String nom = '';
    if (e is Map) nom = e['nom_entreprise']?.toString() ?? '';
    if (e is List && e.isNotEmpty && e.first is Map) {
      nom = (e.first as Map)['nom_entreprise']?.toString() ?? nom;
    }
    final titre = o['titre']?.toString() ?? '—';
    final loc = o['localisation']?.toString() ?? '';
    final parts = [titre, if (loc.isNotEmpty) loc, if (nom.isNotEmpty) nom];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    final list = offres.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ext.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Offres en attente de validation ($pendingCount)',
            style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
          ),
          const SizedBox(height: 8),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Aucune offre en brouillon.', style: TextStyle(color: scheme.onSurfaceVariant)),
            )
          else
            ...list.map(
              (o) {
                final id = o['id']?.toString() ?? '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: ext.sectionBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ext.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(_entrepriseLine(o))),
                      IconButton(
                        tooltip: 'Valider',
                        onPressed: id.isEmpty ? null : () => onValidate(id),
                        icon: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981)),
                      ),
                      IconButton(
                        tooltip: 'Refuser',
                        onPressed: id.isEmpty ? null : () => onReject(id),
                        icon: const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
