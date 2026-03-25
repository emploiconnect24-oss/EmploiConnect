import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../widgets/responsive_container.dart';
import '../../widgets/reveal_on_scroll.dart';

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
    if (_loading) return const Center(child: CircularProgressIndicator());
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
    final s = _stats!;

    final cards = <_KpiCardData>[
      _KpiCardData(
        title: 'Chercheurs',
        value: '${s['nombre_chercheurs'] ?? 0}',
        icon: Icons.person_search,
        tint: const Color(0xFF1F6FEB),
      ),
      _KpiCardData(
        title: 'Entreprises',
        value: '${s['nombre_entreprises'] ?? 0}',
        icon: Icons.apartment,
        tint: const Color(0xFFFF8A00),
      ),
      _KpiCardData(
        title: 'Offres actives',
        value: '${s['nombre_offres_actives'] ?? 0}',
        icon: Icons.campaign,
        tint: const Color(0xFF0F6D2B),
      ),
      _KpiCardData(
        title: 'Offres (total)',
        value: '${s['nombre_offres_total'] ?? 0}',
        icon: Icons.work_outline,
        tint: const Color(0xFF0B4DB5),
      ),
      _KpiCardData(
        title: 'Candidatures',
        value: '${s['nombre_candidatures'] ?? 0}',
        icon: Icons.assignment,
        tint: const Color(0xFF9A6700),
      ),
      _KpiCardData(
        title: 'Acceptées',
        value: '${s['nombre_candidatures_acceptees'] ?? 0}',
        icon: Icons.verified,
        tint: const Color(0xFF0F6D2B),
      ),
      _KpiCardData(
        title: 'CV',
        value: '${s['nombre_cv'] ?? 0}',
        icon: Icons.description,
        tint: const Color(0xFF374151),
      ),
      _KpiCardData(
        title: 'Signalements',
        subtitle: 'en attente',
        value: '${s['nombre_signalements_en_attente'] ?? 0}',
        icon: Icons.flag,
        tint: const Color(0xFF9B1C1C),
      ),
    ];

    return ResponsiveContainer(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Text(
              'Tableau de bord',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Vue d’ensemble de la plateforme.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            RevealOnScroll(
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  int cols = 2;
                  if (w >= 980) {
                    cols = 4;
                  } else if (w >= 700) {
                    cols = 3;
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cards.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.2,
                    ),
                    itemBuilder: (context, i) => _KpiCard(cards[i]),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            RevealOnScroll(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Astuce : utilisez l’onglet Utilisateurs pour valider/activer les comptes, '
                          'et l’onglet Signalements pour modérer les contenus.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }
}

class _KpiCardData {
  const _KpiCardData({
    required this.title,
    this.subtitle,
    required this.value,
    required this.icon,
    required this.tint,
  });

  final String title;
  final String? subtitle;
  final String value;
  final IconData icon;
  final Color tint;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard(this.data);

  final _KpiCardData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: data.tint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: data.tint.withValues(alpha: 0.18)),
              ),
              child: Icon(data.icon, color: data.tint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data.title,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  if (data.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle!,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    data.value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
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
