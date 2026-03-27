import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../services/admin_service.dart';
import '../../widgets/responsive_container.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _admin = AdminService();
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await _admin.getStatistiques();
      setState(() {
        _stats = s;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            FilledButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      );
    }
    final s = _stats ?? <String, dynamic>{};
    final cards = <_StatCardData>[
      _StatCardData(
        label: 'Utilisateurs',
        value: _v(s['nombre_chercheurs']) + _v(s['nombre_entreprises']) + _v(s['nombre_admins']),
        trendLabel: '+12%',
        trendPositive: true,
        icon: Icons.people_rounded,
        color: const Color(0xFF1A56DB),
        bgColor: const Color(0xFFEFF6FF),
      ),
      _StatCardData(
        label: 'Offres actives',
        value: _v(s['nombre_offres_actives']),
        trendLabel: '+8%',
        trendPositive: true,
        icon: Icons.work_rounded,
        color: const Color(0xFF10B981),
        bgColor: const Color(0xFFECFDF5),
      ),
      _StatCardData(
        label: 'Entreprises',
        value: _v(s['nombre_entreprises']),
        trendLabel: '+5%',
        trendPositive: true,
        icon: Icons.business_rounded,
        color: const Color(0xFF8B5CF6),
        bgColor: const Color(0xFFF5F3FF),
      ),
      _StatCardData(
        label: 'Candidatures',
        value: _v(s['nombre_candidatures']),
        trendLabel: '+23%',
        trendPositive: true,
        icon: Icons.assignment_rounded,
        color: const Color(0xFFF59E0B),
        bgColor: const Color(0xFFFEF3C7),
      ),
      _StatCardData(
        label: 'En attente',
        value: _v(s['nombre_comptes_non_valides']) + _v(s['nombre_offres_en_attente']),
        trendLabel: '',
        trendPositive: false,
        icon: Icons.hourglass_empty_rounded,
        color: const Color(0xFFF59E0B),
        bgColor: const Color(0xFFFEF3C7),
      ),
      _StatCardData(
        label: 'Signalements',
        value: _v(s['nombre_signalements_en_attente']),
        trendLabel: 'URGENT',
        trendPositive: false,
        icon: Icons.shield_rounded,
        color: const Color(0xFFEF4444),
        bgColor: const Color(0xFFFEE2E2),
      ),
    ];

    return ResponsiveContainer(
      child: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WelcomeHeader(),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, c) {
                  final crossCount = c.maxWidth > 980 ? 3 : (c.maxWidth > 640 ? 2 : 1);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cards.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 2.2,
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
              LayoutBuilder(
                builder: (context, c) {
                  if (c.maxWidth < 980) {
                    return Column(
                      children: const [
                        _ActivityChartCard(),
                        SizedBox(height: 16),
                        _RecentActivityCard(),
                      ],
                    );
                  }
                  return const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 60, child: _ActivityChartCard()),
                      SizedBox(width: 16),
                      Expanded(flex: 40, child: _RecentActivityCard()),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              _PendingJobsCard(
                pendingCount: _v(s['nombre_offres_en_attente']),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _v(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class _WelcomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formatted = DateFormat('EEEE dd MMM yyyy', 'fr_FR').format(now);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour, Administrateur',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Voici un aperçu de la plateforme EmploiConnect aujourd\'hui.',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(
                formatted,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
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
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered ? data.color.withValues(alpha: 0.28) : const Color(0xFFE2E8F0),
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
                  Text(data.label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        tween: Tween<double>(begin: 0, end: data.value.toDouble()),
                        builder: (context, value, _) => Text(
                          NumberFormat.decimalPattern('fr_FR').format(value.round()),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
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
  const _ActivityChartCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activité (7 derniers jours)',
            style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aperçu rapide des inscriptions et candidatures.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const Spacer(),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            alignment: Alignment.center,
            child: const Text('Graphique à connecter (Section 13)', style: TextStyle(color: Color(0xFF64748B))),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Nouveau candidat inscrit', 'Mamadou Diallo · il y a 5 min'),
      ('Offre publiée', 'Orange Guinée · il y a 12 min'),
      ('Signalement reçu', 'Offre #247 · il y a 1 h'),
      ('Entreprise validée', 'MTN Guinée · il y a 2 h'),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activité récente',
            style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.fiber_manual_record, size: 10, color: Color(0xFF1A56DB)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(item.$2, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingJobsCard extends StatelessWidget {
  const _PendingJobsCard({required this.pendingCount});

  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    const jobs = [
      'Developpeur Mobile · Conakry · Orange Guinee',
      'Chef de projet · Kindia · ONG Plan Int.',
      'Comptable · Conakry · Ecobank',
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Offres en attente de validation ($pendingCount)',
                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const Spacer(),
              TextButton(onPressed: () {}, child: const Text('Voir tout')),
            ],
          ),
          const SizedBox(height: 8),
          ...jobs.map(
            (job) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(job)),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981)),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
