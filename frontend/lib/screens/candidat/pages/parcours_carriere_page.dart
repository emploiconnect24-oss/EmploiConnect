import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/candidat_parcours_service.dart';
import '../widgets/calculateur_salaire.dart';
import '../widgets/simulateur_entretien_ia.dart';
import 'parcours_ressource_detail_page.dart';

/// Parcours Carrière candidat : ressources + simulateur + calculateur (PRD §4).
class ParcoursCarrierePage extends StatefulWidget {
  const ParcoursCarrierePage({super.key, this.onOpenCvCreate});

  final VoidCallback? onOpenCvCreate;

  @override
  State<ParcoursCarrierePage> createState() => _ParcoursCarrierePageState();
}

class _ParcoursCarrierePageState extends State<ParcoursCarrierePage> with SingleTickerProviderStateMixin {
  final _svc = CandidatParcoursService();
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _ressources = [];
  int _nbVuesUser = 0;
  bool _isLoading = true;
  String? _error;
  String _categorieActive = 'tous';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final body = await _svc.listRessources();
      if (!mounted) return;
      final meta = body['meta'] as Map<String, dynamic>?;
      setState(() {
        _ressources = List<Map<String, dynamic>>.from(body['data'] as List? ?? []);
        _nbVuesUser = (meta?['nb_vues_utilisateur'] as int?) ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _ressourcesFiltrees => _categorieActive == 'tous'
      ? _ressources
      : _ressources.where((r) => r['categorie']?.toString() == _categorieActive).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A56DB), Color(0xFF7C3AED)],
            ),
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
                        Text(
                          'Parcours Carrière',
                          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        Text(
                          'Développez vos compétences avec l’IA',
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 13),
                        const SizedBox(width: 5),
                        Text(
                          'Propulsé par IA',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatHero('${_ressources.length}', 'Ressources', Icons.library_books_outlined),
                  const SizedBox(width: 16),
                  const _StatHero('3', 'Outils IA', Icons.psychology_rounded),
                  const SizedBox(width: 16),
                  _StatHero('$_nbVuesUser', 'Vues', Icons.visibility_outlined),
                ],
              ),
            ],
          ),
        ),
        Material(
          color: Colors.white,
          child: TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400),
            labelColor: const Color(0xFF1A56DB),
            unselectedLabelColor: const Color(0xFF94A3B8),
            indicatorColor: const Color(0xFF1A56DB),
            tabs: const [
              Tab(text: 'Ressources'),
              Tab(text: 'Simulateur IA'),
              Tab(text: 'Calculateur'),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildTabRessources(),
              const SimulateurEntretienIA(),
              const CalculateurSalaire(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabRessources() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1A56DB)));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filtreCategorie('tous', 'Tout'),
                    _filtreCategorie('cv', 'CV'),
                    _filtreCategorie('entretien', 'Entretien'),
                    _filtreCategorie('salaire', 'Salaire'),
                    _filtreCategorie('reconversion', 'Reconversion'),
                    _filtreCategorie('entrepreneuriat', 'Entrepreneuriat'),
                    _filtreCategorie('general', 'Général'),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: Divider(height: 1)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: _buildOutilsIA(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Text(
                    'Ressources disponibles',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A56DB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '${_ressourcesFiltrees.length}',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1A56DB)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_ressourcesFiltrees.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: _buildEmpty())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final r = _ressourcesFiltrees[i];
                    return _RessourceCard(
                      ressource: r,
                      onTap: () async {
                        await Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => ParcoursRessourceDetailPage(
                              id: r['id']?.toString() ?? '',
                              preview: r,
                            ),
                          ),
                        );
                        await _load();
                      },
                    );
                  },
                  childCount: _ressourcesFiltrees.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOutilsIA() {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      color: const Color(0xFFF8FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Outils IA',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _OutilIACard(
                  icon: Icons.psychology_rounded,
                  titre: 'Simulateur d’entretien',
                  desc: 'Préparez-vous avec l’IA',
                  couleur: const Color(0xFF8B5CF6),
                  onTap: () => _tabCtrl.animateTo(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OutilIACard(
                  icon: Icons.calculate_rounded,
                  titre: 'Calculateur salaire',
                  desc: 'Estimez une fourchette',
                  couleur: const Color(0xFF10B981),
                  onTap: () => _tabCtrl.animateTo(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OutilIACard(
                  icon: Icons.description_outlined,
                  titre: 'Générateur CV',
                  desc: 'Créer / enrichir',
                  couleur: const Color(0xFF1A56DB),
                  onTap: widget.onOpenCvCreate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _filtreCategorie(String val, String label) {
    final isSel = _categorieActive == val;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
        onPressed: () => setState(() => _categorieActive = val),
        backgroundColor: isSel ? const Color(0xFF1A56DB) : const Color(0xFFF8FAFC),
        labelStyle: TextStyle(color: isSel ? Colors.white : const Color(0xFF64748B)),
        side: BorderSide(color: isSel ? const Color(0xFF1A56DB) : const Color(0xFFE2E8F0)),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_books_outlined, color: Color(0xFFE2E8F0), size: 56),
            const SizedBox(height: 16),
            Text('Aucune ressource disponible', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('De nouveaux guides arrivent bientôt.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}

class _StatHero extends StatelessWidget {
  const _StatHero(this.valeur, this.label, this.icon);

  final String valeur;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    valeur,
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutilIACard extends StatelessWidget {
  const _OutilIACard({
    required this.icon,
    required this.titre,
    required this.desc,
    required this.couleur,
    this.onTap,
  });

  final IconData icon;
  final String titre;
  final String desc;
  final Color couleur;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: couleur, size: 22),
              const SizedBox(height: 8),
              Text(titre, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(desc, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B))),
            ],
          ),
        ),
      ),
    );
  }
}

class _RessourceCard extends StatelessWidget {
  const _RessourceCard({required this.ressource, required this.onTap});

  final Map<String, dynamic> ressource;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final titre = ressource['titre']?.toString() ?? 'Sans titre';
    final desc = ressource['description']?.toString() ?? '';
    final cat = ressource['categorie']?.toString() ?? '';
    final vue = ressource['deja_vue'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ressource['image_couverture'] != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  ressource['image_couverture'].toString(),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.article_rounded, color: Color(0xFF1A56DB)),
                ),
              )
            : const Icon(Icons.article_rounded, color: Color(0xFF1A56DB), size: 36),
        title: Text(titre, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        subtitle: Text(
          desc.isEmpty ? cat : desc,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
        ),
        trailing: vue ? const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 20) : null,
        onTap: onTap,
      ),
    );
  }
}
