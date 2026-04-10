# PRD — EmploiConnect · Espace Candidat — Améliorations Complètes
## Product Requirements Document v8.0 — Candidat Space Polish
**Stack : Flutter + Node.js/Express + Supabase**
**Outil : Cursor / Kirsoft AI**
**Objectif : Vue d'ensemble + Profil CV + Créateur CV IA**
**Date : Mars 2026**

---

> ### ⚠️ INSTRUCTIONS POUR CURSOR
>
> Ce PRD améliore l'espace candidat en 5 sections.
> Implémenter dans l'ordre. Chaque section = une fonctionnalité.
> Palette : #1A56DB · #10B981 · #8B5CF6 · #F59E0B · #EF4444

---

## Table des Matières

1. [Vue d'ensemble — Offres recommandées (grille 3 colonnes)](#1-vue-densemble--offres-recommandées)
2. [Vue d'ensemble — Suivi candidatures animé](#2-vue-densemble--suivi-candidatures-animé)
3. [Topbar candidat — Photo profil + design](#3-topbar-candidat--photo-profil--design)
4. [Vue d'ensemble — Barre complétion profil animée](#4-vue-densemble--barre-complétion-profil-animée)
5. [Page Mon Profil & CV — Refonte complète](#5-page-mon-profil--cv--refonte-complète)
6. [Créateur de CV intégré — Fonctionnalité IA](#6-créateur-de-cv-intégré--fonctionnalité-ia)
7. [Backend — Routes Créateur CV](#7-backend--routes-créateur-cv)
8. [Critères d'Acceptation](#8-critères-dacceptation)

---

## 1. Vue d'ensemble — Offres recommandées

### Grille 3 colonnes avec score animé

```dart
// Dans dashboard_candidat_page.dart
// Remplacer la section offres recommandées

Widget _buildOffresRecommandees(List<Map<String, dynamic>> offres) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [

    // Header section
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [
              Color(0xFF1A56DB), Color(0xFF0EA5E9)]),
            borderRadius: BorderRadius.circular(100)),
          child: Row(children: [
            const Icon(Icons.auto_awesome_rounded,
              color: Colors.white, size: 12),
            const SizedBox(width: 4),
            Text('IA', style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: Colors.white)),
          ])),
        const SizedBox(width: 10),
        Text('Offres pour vous', style: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A))),
      ]),
      TextButton(
        onPressed: () =>
          context.push('/dashboard-candidat/recommandations'),
        child: Text('Voir tout →', style: GoogleFonts.inter(
          fontSize: 13, color: const Color(0xFF1A56DB)))),
    ]),
    const SizedBox(height: 12),

    if (offres.isEmpty)
      _buildEmptyOffres()
    else
      // Grille 3 colonnes sur desktop, 1 sur mobile
      LayoutBuilder(builder: (ctx, c) {
        final cols = c.maxWidth > 900 ? 3
                   : c.maxWidth > 600 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: offres.take(6).length,
          itemBuilder: (ctx, i) => _OffreRecommandeCard(
            offre: offres[i],
            index: i,
          ),
        );
      }),
  ]);
}

Widget _buildEmptyOffres() => Container(
  padding: const EdgeInsets.all(24),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: const Color(0xFFE2E8F0))),
  child: Column(children: [
    const Icon(Icons.work_outline_rounded,
      color: Color(0xFFE2E8F0), size: 48),
    const SizedBox(height: 10),
    Text('Complétez votre profil pour recevoir des recommandations',
      style: GoogleFonts.inter(
        fontSize: 13, color: const Color(0xFF94A3B8)),
      textAlign: TextAlign.center),
    const SizedBox(height: 12),
    ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A56DB),
        foregroundColor: Colors.white, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8))),
      onPressed: () => context.push('/dashboard-candidat/profil'),
      child: Text('Compléter mon profil',
        style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
  ]));
}
```

### Widget carte offre recommandée compacte

```dart
// lib/screens/candidat/widgets/offre_recommande_card.dart

class _OffreRecommandeCard extends StatefulWidget {
  final Map<String, dynamic> offre;
  final int index;
  const _OffreRecommandeCard({
    required this.offre, required this.index});
  @override
  State<_OffreRecommandeCard> createState() =>
    _OffreRecommandeCardState();
}

class _OffreRecommandeCardState
    extends State<_OffreRecommandeCard>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _scoreAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2), end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller, curve: Curves.easeOutBack));

    final score = widget.offre['score_compatibilite'] as int? ?? 0;
    _scoreAnimation = Tween<double>(begin: 0, end: score / 100)
      .animate(CurvedAnimation(
        parent: _controller, curve: Curves.easeOutCubic));

    // Délai selon l'index pour effet cascade
    Future.delayed(
      Duration(milliseconds: 100 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offre   = widget.offre;
    final titre   = offre['titre']       as String? ?? '';
    final ent     = offre['entreprise']  as Map?    ?? {};
    final nom     = ent['nom_entreprise'] as String? ?? '';
    final logo    = ent['logo_url']       as String?;
    final loc     = offre['localisation'] as String? ?? '';
    final contrat = offre['type_contrat'] as String? ?? '';
    final sMin    = offre['salaire_min']  as int?;
    final devise  = offre['devise']       as String? ?? 'GNF';
    final score   = offre['score_compatibilite'] as int? ?? 0;
    final vedette = offre['en_vedette']   as bool? ?? false;
    final saved   = offre['est_sauvegardee'] as bool? ?? false;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: score >= 70
                  ? const Color(0xFF10B981).withOpacity(0.3)
                  : const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(
              color: score >= 70
                  ? const Color(0xFF10B981).withOpacity(0.08)
                  : const Color(0x06000000),
              blurRadius: 12, offset: const Offset(0, 3))]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Zone score IA (haut) ──────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _scoreColor(score).withOpacity(0.06),
                    Colors.white,
                  ]),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                // Score animé
                AnimatedBuilder(
                  animation: _scoreAnimation,
                  builder: (_, __) => Row(children: [
                    // Arc de cercle animé
                    SizedBox(
                      width: 48, height: 48,
                      child: Stack(
                        alignment: Alignment.center, children: [
                        // Fond arc gris
                        CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 5,
                          color: const Color(0xFFF1F5F9)),
                        // Arc coloré animé
                        CircularProgressIndicator(
                          value: _scoreAnimation.value,
                          strokeWidth: 5,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation(
                            _scoreColor(score))),
                        // Chiffre au centre
                        Text(
                          score > 0 ? '$score%' : '—',
                          style: GoogleFonts.poppins(
                            fontSize: score > 0 ? 11 : 14,
                            fontWeight: FontWeight.w800,
                            color: _scoreColor(score))),
                      ])),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text(
                        score >= 80 ? 'Excellent !' :
                        score >= 60 ? 'Bon match' :
                        score >= 40 ? 'Moyen' :
                        score > 0  ? 'Faible' : 'Non calculé',
                        style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: _scoreColor(score))),
                      Text('Compatibilité IA',
                        style: GoogleFonts.inter(
                          fontSize: 9, color: const Color(0xFF94A3B8))),
                    ]),
                  ])),

                // Vedette + Bookmark
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end, children: [
                  if (vedette)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(100)),
                      child: Row(children: [
                        const Icon(Icons.star_rounded,
                          size: 10, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 2),
                        Text('Vedette', style: GoogleFonts.inter(
                          fontSize: 8, fontWeight: FontWeight.w700,
                          color: const Color(0xFF92400E))),
                      ])),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _toggleSave(),
                    child: Icon(
                      saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 20,
                      color: saved
                          ? const Color(0xFF1A56DB)
                          : const Color(0xFFCBD5E1))),
                ]),
              ])),

            // ── Infos offre ───────────────────────────
            Expanded(child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Logo + nom entreprise
                Row(children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6)),
                    child: logo != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(logo,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                _initLogo(nom)))
                        : _initLogo(nom),
                  ),
                  const SizedBox(width: 6),
                  Flexible(child: Text(nom, style: GoogleFonts.inter(
                    fontSize: 11, color: const Color(0xFF64748B)),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 6),

                // Titre
                Text(titre, style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A)),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),

                // Tags
                Wrap(spacing: 4, runSpacing: 4, children: [
                  if (loc.isNotEmpty)
                    _MiniTag(Icons.location_on_outlined, loc),
                  if (contrat.isNotEmpty)
                    _MiniTag(Icons.work_outline_rounded, contrat),
                  if (sMin != null)
                    _MiniTag(Icons.payments_outlined,
                      '${_fmtSalaire(sMin)} $devise'),
                ]),

                const Spacer(),

                // Bouton postuler
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A56DB),
                      foregroundColor: Colors.white, elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                      textStyle: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w700)),
                    onPressed: () => context.push(
                      '/dashboard-candidat/postuler/${offre['id']}'),
                    child: const Text('Postuler maintenant'))),
              ])),
            )),
          ]),
        ),
      ),
    );
  }

  Color _scoreColor(int s) {
    if (s >= 80) return const Color(0xFF10B981);
    if (s >= 60) return const Color(0xFF1A56DB);
    if (s >= 40) return const Color(0xFFF59E0B);
    if (s > 0)   return const Color(0xFFEF4444);
    return const Color(0xFF94A3B8);
  }

  Widget _initLogo(String nom) => Center(child: Text(
    nom.isNotEmpty ? nom[0].toUpperCase() : '?',
    style: GoogleFonts.poppins(
      fontSize: 12, fontWeight: FontWeight.w700,
      color: const Color(0xFF1A56DB))));

  String _fmtSalaire(int s) {
    if (s >= 1000000) return '${(s/1000000).toStringAsFixed(1)}M';
    if (s >= 1000) return '${(s/1000).toStringAsFixed(0)}K';
    return '$s';
  }

  void _toggleSave() async {
    // Appel API sauvegarder/retirer
    final token = context.read<AuthProvider>().token ?? '';
    final offre = widget.offre;
    final isSaved = offre['est_sauvegardee'] as bool? ?? false;
    final url = '${ApiConfig.baseUrl}/api/candidat/offres-sauvegardees/${offre['id']}';
    if (isSaved) {
      await http.delete(Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'});
    } else {
      await http.post(Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'});
    }
    if (mounted) setState(() {});
  }
}

class _MiniTag extends StatelessWidget {
  final IconData icon; final String text;
  const _MiniTag(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(100),
      border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 10, color: const Color(0xFF94A3B8)),
      const SizedBox(width: 3),
      Text(text, style: GoogleFonts.inter(
        fontSize: 10, color: const Color(0xFF64748B))),
    ]));
}
```

---

## 2. Vue d'ensemble — Suivi candidatures animé

```dart
// Section suivi candidatures — design animé avec icônes

class _SuiviCandidaturesWidget extends StatefulWidget {
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> candidaturesRecentes;
  const _SuiviCandidaturesWidget({
    required this.stats, required this.candidaturesRecentes});
  @override
  State<_SuiviCandidaturesWidget> createState() =>
    _SuiviCandidaturesWidgetState();
}

class _SuiviCandidaturesWidgetState
    extends State<_SuiviCandidaturesWidget>
    with TickerProviderStateMixin {

  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  final _etapes = [
    _Etape('En attente',  Icons.hourglass_empty_rounded, Color(0xFFF59E0B)),
    _Etape('En examen',   Icons.search_rounded,           Color(0xFF1A56DB)),
    _Etape('Entretien',   Icons.event_available_rounded,  Color(0xFF8B5CF6)),
    _Etape('Acceptées',   Icons.check_circle_rounded,     Color(0xFF10B981)),
    _Etape('Refusées',    Icons.cancel_rounded,           Color(0xFFEF4444)),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(5, (i) => AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600)));
    _animations = _controllers.map((c) =>
      Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: c, curve: Curves.elasticOut))).toList();

    // Lancer les animations en cascade
    for (int i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: 100 * i), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    final values = [
      stats['en_attente'] as int? ?? 0,
      stats['en_cours']   as int? ?? 0,
      stats['entretiens'] as int? ?? 0,
      stats['acceptees']  as int? ?? 0,
      stats['refusees']   as int? ?? 0,
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Suivi de mes candidatures', style: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A))),
        TextButton(
          onPressed: () =>
            context.push('/dashboard-candidat/candidatures'),
          child: Text('Tout voir →', style: GoogleFonts.inter(
            fontSize: 13, color: const Color(0xFF1A56DB)))),
      ]),
      const SizedBox(height: 12),

      // Grille des statuts animée
      LayoutBuilder(builder: (ctx, c) {
        final cols = c.maxWidth > 600 ? 5 : 3;
        return Wrap(
          spacing: 10, runSpacing: 10,
          children: List.generate(5, (i) {
            if (i >= _etapes.length) return const SizedBox.shrink();
            return SizedBox(
              width: (c.maxWidth - (cols - 1) * 10) / cols,
              child: ScaleTransition(
                scale: _animations[i],
                child: _StatutCard(
                  etape:  _etapes[i],
                  count:  values[i],
                  onTap: () =>
                    context.push('/dashboard-candidat/candidatures'),
                )),
            );
          }),
        );
      }),

      // Candidatures récentes
      if (widget.candidaturesRecentes.isNotEmpty) ...[
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            children: widget.candidaturesRecentes
              .take(3).toList().asMap().entries.map((e) {
              final i    = e.key;
              final cand = e.value;
              return _CandidatureRecenteItem(
                candidature: cand,
                showDivider: i < 2,
              );
            }).toList()),
        ),
      ],
    ]);
  }
}

class _StatutCard extends StatelessWidget {
  final _Etape etape;
  final int count;
  final VoidCallback onTap;
  const _StatutCard({required this.etape,
    required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: etape.color.withOpacity(0.3)),
        boxShadow: [BoxShadow(
          color: etape.color.withOpacity(0.06),
          blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(children: [
        // Icône avec fond coloré
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: etape.color.withOpacity(0.12),
            shape: BoxShape.circle),
          child: Icon(etape.icon, color: etape.color, size: 22)),
        const SizedBox(height: 8),
        // Compteur
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: count),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (_, val, __) => Text('$val',
            style: GoogleFonts.poppins(
              fontSize: 22, fontWeight: FontWeight.w900,
              color: etape.color)),
        ),
        // Label
        Text(etape.label, style: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w500,
          color: const Color(0xFF64748B)),
          textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _Etape {
  final String label; final IconData icon; final Color color;
  const _Etape(this.label, this.icon, this.color);
}

class _CandidatureRecenteItem extends StatelessWidget {
  final Map<String, dynamic> candidature;
  final bool showDivider;
  const _CandidatureRecenteItem({
    required this.candidature, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final offre  = candidature['offre'] as Map? ?? {};
    final ent    = offre['entreprise']  as Map? ?? {};
    final titre  = offre['titre']       as String? ?? '';
    final nomEnt = ent['nom_entreprise'] as String? ?? '';
    final logo   = ent['logo_url']       as String?;
    final statut = candidature['statut'] as String? ?? '';
    final date   = candidature['date_candidature'] as String?;

    Color sc; String sl; IconData si;
    switch (statut) {
      case 'acceptee':  sc = const Color(0xFF10B981); sl = 'Acceptée ✓'; si = Icons.check_circle_rounded; break;
      case 'entretien': sc = const Color(0xFF8B5CF6); sl = 'Entretien'; si = Icons.event_available_rounded; break;
      case 'en_cours':  sc = const Color(0xFF1A56DB); sl = 'En examen'; si = Icons.search_rounded; break;
      case 'refusee':   sc = const Color(0xFFEF4444); sl = 'Refusée'; si = Icons.cancel_rounded; break;
      default:          sc = const Color(0xFFF59E0B); sl = 'En attente'; si = Icons.hourglass_empty_rounded;
    }

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8)),
            child: logo != null
                ? ClipRRect(borderRadius: BorderRadius.circular(8),
                    child: Image.network(logo, fit: BoxFit.cover))
                : Center(child: Text(
                    nomEnt.isNotEmpty ? nomEnt[0] : '?',
                    style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A56DB)))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titre, style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A)),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(nomEnt, style: GoogleFonts.inter(
              fontSize: 11, color: const Color(0xFF64748B))),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: sc.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(si, size: 10, color: sc),
                const SizedBox(width: 3),
                Text(sl, style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: sc)),
              ])),
            if (date != null) ...[
              const SizedBox(height: 3),
              Text(_fmtDate(date), style: GoogleFonts.inter(
                fontSize: 10, color: const Color(0xFF94A3B8))),
            ],
          ]),
        ]),
      ),
      if (showDivider)
        const Divider(height: 1, indent: 16, endIndent: 16,
          color: Color(0xFFF1F5F9)),
    ]);
  }

  String _fmtDate(String d) {
    try {
      final dt = DateTime.parse(d).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inDays == 0) return 'Aujourd\'hui';
      if (diff.inDays == 1) return 'Hier';
      return 'Il y a ${diff.inDays}j';
    } catch (_) { return ''; }
  }
}
```

---

## 3. Topbar candidat — Photo profil + design

```dart
// frontend/lib/screens/candidat/candidat_topbar.dart

class CandidatTopbar extends StatelessWidget implements PreferredSizeWidget {
  const CandidatTopbar({super.key});
  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [BoxShadow(
          color: Color(0x06000000), blurRadius: 8,
          offset: Offset(0, 2))]),
      child: Row(children: [

        // Barre de recherche
        Expanded(child: GestureDetector(
          onTap: () => context.push('/dashboard-candidat/offres'),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Row(children: [
              const Icon(Icons.search_rounded,
                color: Color(0xFF94A3B8), size: 18),
              const SizedBox(width: 8),
              Text('Rechercher une offre...',
                style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFFCBD5E1))),
            ]),
          ))),
        const SizedBox(width: 12),

        // Bouton "Compléter le profil" si < 80%
        Consumer<CandidatProvider>(
          builder: (ctx, provider, _) {
            if (provider.completionPourcentage >= 80) {
              return const SizedBox.shrink();
            }
            return Container(
              margin: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () =>
                  context.push('/dashboard-candidat/profil'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      Color(0xFF1A56DB), Color(0xFF0EA5E9)]),
                    borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(Icons.bolt_rounded,
                      color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text('Profil ${provider.completionPourcentage}%',
                      style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                  ]))));
          }),

        // Notifications
        Consumer<CandidatProvider>(
          builder: (ctx, provider, _) => Stack(children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                color: Color(0xFF64748B), size: 22),
              onPressed: () =>
                context.push('/dashboard-candidat/notifications')),
            if (provider.nbNotifications > 0)
              Positioned(top: 6, right: 6, child: Container(
                width: 16, height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444), shape: BoxShape.circle),
                child: Center(child: Text(
                  '${provider.nbNotifications}',
                  style: GoogleFonts.inter(
                    fontSize: 9, fontWeight: FontWeight.w800,
                    color: Colors.white))))),
          ])),

        // ← PHOTO DE PROFIL (pas juste l'initiale)
        Consumer<AuthProvider>(
          builder: (ctx, auth, _) {
            final photo = auth.photoUrl; // Ajouter photoUrl dans AuthProvider
            final nom   = auth.userName ?? 'C';

            return GestureDetector(
              onTap: () => context.push('/dashboard-candidat/profil'),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF1A56DB).withOpacity(0.3),
                    width: 2)),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF1A56DB).withOpacity(0.1),
                  // ← Afficher la photo si disponible
                  backgroundImage: photo != null && photo.isNotEmpty
                      ? NetworkImage(photo) : null,
                  child: (photo == null || photo.isEmpty)
                      ? Text(nom[0].toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A56DB)))
                      : null,
                )));
          }),
      ]),
    );
  }
}
```

### Ajouter photoUrl dans AuthProvider

```dart
// Dans frontend/lib/providers/auth_provider.dart
// Ajouter la propriété photoUrl synchronisée depuis l'API

class AuthProvider extends ChangeNotifier {
  // ... propriétés existantes ...
  String? photoUrl; // ← Ajouter

  Future<void> loadProfile() async {
    // Charger le profil utilisateur depuis /api/users/me
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/me'),
        headers: {'Authorization': 'Bearer $token'});
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        photoUrl = body['data']['photo_url'] as String?;
        notifyListeners();
      }
    } catch (_) {}
  }

  // Appeler loadProfile() dans login() et au démarrage
}
```

---

## 4. Vue d'ensemble — Barre complétion profil animée

```dart
// Remplacer la barre de complétion existante par une version
// très animée et remarquable

class _CompletionProfilWidget extends StatefulWidget {
  final int pourcentage;
  final List<dynamic> manquants;
  const _CompletionProfilWidget({
    required this.pourcentage, required this.manquants});
  @override
  State<_CompletionProfilWidget> createState() =>
    _CompletionProfilWidgetState();
}

class _CompletionProfilWidgetState extends State<_CompletionProfilWidget>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  late Animation<double> _progressAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200));

    _progressAnim = Tween<double>(
      begin: 0, end: widget.pourcentage / 100,
    ).animate(CurvedAnimation(
      parent: _ctrl, curve: Curves.easeOutCubic));

    _pulseAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.03), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.03, end: 1.0), weight: 50),
    ]).animate(_ctrl);

    _ctrl.forward();
    // Répéter la pulsation
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) _ctrl.repeat(reverse: true, period:
            const Duration(milliseconds: 2000));
        });
      }
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final pct = widget.pourcentage;
    final isComplete = pct >= 100;

    return ScaleTransition(
      scale: _pulseAnim,
      child: GestureDetector(
        onTap: () => context.push('/dashboard-candidat/profil'),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isComplete
                  ? [const Color(0xFF059669), const Color(0xFF10B981)]
                  : pct >= 70
                      ? [const Color(0xFF1A56DB), const Color(0xFF0EA5E9)]
                      : [const Color(0xFF7C3AED), const Color(0xFF1A56DB)]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
              color: (isComplete
                  ? const Color(0xFF10B981)
                  : const Color(0xFF1A56DB)).withOpacity(0.3),
              blurRadius: 16, offset: const Offset(0, 6))]),
          child: Column(children: [

            // Ligne 1 : Icône + Titre + %
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle),
                child: Icon(
                  isComplete
                      ? Icons.verified_rounded
                      : Icons.person_outline_rounded,
                  color: Colors.white, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  isComplete
                      ? 'Profil complet ! 🎉'
                      : 'Complétez votre profil',
                  style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: Colors.white)),
                Text(
                  isComplete
                      ? 'Vous avez de meilleures chances d\'être contacté'
                      : '${widget.manquants.isNotEmpty ? (widget.manquants.first as Map)['label'] : ''} manquant',
                  style: GoogleFonts.inter(
                    fontSize: 11, color: Colors.white70)),
              ])),
              // % animé
              AnimatedBuilder(
                animation: _progressAnim,
                builder: (_, __) => Text(
                  '${((_progressAnim.value) * 100).toInt()}%',
                  style: GoogleFonts.poppins(
                    fontSize: 28, fontWeight: FontWeight.w900,
                    color: Colors.white))),
            ]),
            const SizedBox(height: 14),

            // Barre de progression animée
            AnimatedBuilder(
              animation: _progressAnim,
              builder: (_, __) => Column(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Stack(children: [
                    // Fond
                    Container(
                      height: 10, width: double.infinity,
                      color: Colors.white.withOpacity(0.25)),
                    // Remplissage animé
                    FractionallySizedBox(
                      widthFactor: _progressAnim.value,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: const [BoxShadow(
                            color: Colors.white38, blurRadius: 8)]))),
                    // Effet brillant qui se déplace
                    if (_progressAnim.value < 0.98)
                      Positioned(
                        left: MediaQuery.of(context).size.width *
                            _progressAnim.value * 0.7 - 20,
                        child: Container(
                          width: 20, height: 10,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.5),
                              Colors.transparent,
                            ])))),
                  ])),
              ])),

            // Bouton si pas complet
            if (!isComplete) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end, children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100)),
                  child: Row(children: [
                    Text('Compléter maintenant',
                      style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A56DB))),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded,
                      size: 14, color: Color(0xFF1A56DB)),
                  ])),
              ]),
            ],
          ]),
        ),
      ),
    );
  }
}
```

---

## 5. Page Mon Profil & CV — Refonte complète

### 5.1 Structure des sections avec dialogs d'ajout

```dart
// Pour chaque section (Expériences, Formations, Compétences, Langues)
// Utiliser un dialog d'ajout au lieu de duplication

// ── Section Expériences ─────────────────────────────────────

Widget _buildSectionExperiences() => _SectionCard(
  titre: '💼 Expériences professionnelles',
  onAjouter: () => _showDialogExperience(context, null),
  items: _experiences.map((exp) => _ExperienceItem(
    experience: exp,
    onEdit:   () => _showDialogExperience(context, exp),
    onDelete: () => _deleteExperience(exp['id']),
  )).toList(),
  emptyMessage: 'Ajoutez vos expériences professionnelles',
);

void _showDialogExperience(
  BuildContext context, Map<String, dynamic>? existing,
) {
  final titreCtrl = TextEditingController(
    text: existing?['titre'] ?? '');
  final entCtrl   = TextEditingController(
    text: existing?['entreprise'] ?? '');
  final descCtrl  = TextEditingController(
    text: existing?['description'] ?? '');
  DateTime? dateDebut  = existing?['date_debut'] != null
      ? DateTime.tryParse(existing!['date_debut']) : null;
  DateTime? dateFin    = existing?['date_fin'] != null
      ? DateTime.tryParse(existing!['date_fin']) : null;
  bool enPoste = existing?['en_poste'] ?? false;

  showDialog(context: context, builder: (_) =>
    StatefulBuilder(builder: (ctx, setS) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 520,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(mainAxisSize: MainAxisSize.min, children: [

          // Header
          _DialogHeader(
            icon: Icons.work_outline_rounded,
            title: existing == null
                ? 'Ajouter une expérience'
                : 'Modifier l\'expérience',
            color: const Color(0xFF1A56DB)),

          // Formulaire
          Flexible(child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              _FormField(titreCtrl, 'Titre du poste *',
                'Ex: Développeur Flutter Senior',
                Icons.work_outline_rounded),
              const SizedBox(height: 14),
              _FormField(entCtrl, 'Entreprise *',
                'Ex: Orange Guinée',
                Icons.business_outlined),
              const SizedBox(height: 14),

              // Dates
              Row(children: [
                Expanded(child: _DatePickerField(
                  label: 'Date de début *',
                  value: dateDebut,
                  onChanged: (d) => setS(() => dateDebut = d))),
                const SizedBox(width: 12),
                if (!enPoste)
                  Expanded(child: _DatePickerField(
                    label: 'Date de fin',
                    value: dateFin,
                    onChanged: (d) => setS(() => dateFin = d))),
                if (enPoste)
                  Expanded(child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10)),
                    child: Text('Poste actuel',
                      style: GoogleFonts.inter(
                        fontSize: 13, color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w600)))),
              ]),
              const SizedBox(height: 10),

              // Toggle en poste
              Row(children: [
                Switch(
                  value: enPoste,
                  onChanged: (v) => setS(() => enPoste = v),
                  activeColor: const Color(0xFF10B981)),
                const SizedBox(width: 8),
                Text('Je travaille actuellement ici',
                  style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF374151))),
              ]),
              const SizedBox(height: 14),

              // Description
              TextFormField(
                controller: descCtrl, maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description (optionnel)',
                  hintText: 'Décrivez vos missions et réalisations...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFFCBD5E1)),
                  filled: true, fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFFE2E8F0))),
                )),
            ]))),

          // Boutons
          _DialogActions(
            onCancel: () => Navigator.pop(ctx),
            onConfirm: () {
              if (titreCtrl.text.trim().isEmpty ||
                  entCtrl.text.trim().isEmpty || dateDebut == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Titre, entreprise et date de début requis'),
                    backgroundColor: Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating));
                return;
              }
              Navigator.pop(ctx);
              _saveExperience({
                'id':          existing?['id'],
                'titre':       titreCtrl.text.trim(),
                'entreprise':  entCtrl.text.trim(),
                'description': descCtrl.text.trim(),
                'date_debut':  dateDebut!.toIso8601String(),
                'date_fin':    enPoste ? null : dateFin?.toIso8601String(),
                'en_poste':    enPoste,
              });
            },
            labelConfirm: existing == null ? 'Ajouter' : 'Enregistrer'),
        ]))))));
}

// ── Section Compétences ─────────────────────────────────────

void _showDialogCompetence(BuildContext context) {
  final ctrl = TextEditingController();
  String _niveau = 'intermediaire';

  showDialog(context: context, builder: (_) =>
    StatefulBuilder(builder: (ctx, setS) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 420, padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _DialogHeader(
            icon: Icons.psychology_rounded,
            title: 'Ajouter une compétence',
            color: const Color(0xFF8B5CF6)),
          const SizedBox(height: 20),
          _FormField(ctrl, 'Compétence *',
            'Ex: Flutter, Python, Management...',
            Icons.star_outline_rounded),
          const SizedBox(height: 14),

          // Niveau
          Text('Niveau de maîtrise', style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w500,
            color: const Color(0xFF374151))),
          const SizedBox(height: 8),
          Row(children: [
            _NiveauBtn('Débutant',      'debutant',       _niveau, (v) => setS(() => _niveau = v)),
            _NiveauBtn('Intermédiaire', 'intermediaire',  _niveau, (v) => setS(() => _niveau = v)),
            _NiveauBtn('Expert',        'expert',         _niveau, (v) => setS(() => _niveau = v)),
          ]),
          const SizedBox(height: 20),
          _DialogActions(
            onCancel: () => Navigator.pop(ctx),
            onConfirm: () {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              _addCompetence(ctrl.text.trim(), _niveau);
            },
            labelConfirm: 'Ajouter'),
        ]))),
      )));
}

// ── Helpers widgets ─────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  final IconData icon; final String title; final Color color;
  const _DialogHeader({required this.icon, required this.title, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
    child: Row(children: [
      Icon(icon, color: Colors.white, size: 22),
      const SizedBox(width: 10),
      Expanded(child: Text(title, style: GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
      IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => Navigator.pop(context)),
    ]));
}

class _DialogActions extends StatelessWidget {
  final VoidCallback onCancel, onConfirm;
  final String labelConfirm;
  const _DialogActions({required this.onCancel, required this.onConfirm, required this.labelConfirm});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
    child: Row(children: [
      Expanded(child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        onPressed: onCancel,
        child: Text('Annuler', style: GoogleFonts.inter(color: const Color(0xFF64748B))))),
      const SizedBox(width: 12),
      Expanded(child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A56DB), foregroundColor: Colors.white, elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        onPressed: onConfirm,
        child: Text(labelConfirm, style: GoogleFonts.inter(fontWeight: FontWeight.w600)))),
    ]));
}

class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint; final IconData icon;
  const _FormField(this.ctrl, this.label, this.hint, this.icon);
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
      filled: true, fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1A56DB), width: 1.5))));
}

class _DatePickerField extends StatelessWidget {
  final String label; final DateTime? value;
  final void Function(DateTime?) onChanged;
  const _DatePickerField({required this.label, this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () async {
      final d = await showDatePicker(
        context: context,
        initialDate: value ?? DateTime.now(),
        firstDate: DateTime(1990), lastDate: DateTime.now());
      onChanged(d);
    },
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: value != null ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: value != null ? const Color(0xFF1A56DB) : const Color(0xFFE2E8F0))),
      child: Row(children: [
        Icon(Icons.calendar_today_outlined, size: 16,
          color: value != null ? const Color(0xFF1A56DB) : const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Flexible(child: Text(
          value != null
              ? '${value!.month}/${value!.year}'
              : label,
          style: GoogleFonts.inter(fontSize: 13,
            color: value != null ? const Color(0xFF1A56DB) : const Color(0xFFCBD5E1),
            fontWeight: value != null ? FontWeight.w600 : FontWeight.w400))),
      ])));
}

class _NiveauBtn extends StatelessWidget {
  final String label, value, selected;
  final void Function(String) onTap;
  const _NiveauBtn(this.label, this.value, this.selected, this.onTap);
  @override
  Widget build(BuildContext context) {
    final isSel = value == selected;
    return Expanded(child: GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF8B5CF6) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSel ? const Color(0xFF8B5CF6) : const Color(0xFFE2E8F0))),
        child: Text(label, style: GoogleFonts.inter(
          fontSize: 11, fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
          color: isSel ? Colors.white : const Color(0xFF64748B)),
          textAlign: TextAlign.center))));
  }
}
```

---

## 6. Créateur de CV intégré — Fonctionnalité IA

### 6.1 Page Créateur CV

```dart
// frontend/lib/screens/candidat/pages/createur_cv_page.dart

class CreateurCVPage extends StatefulWidget {
  const CreateurCVPage({super.key});
  @override
  State<CreateurCVPage> createState() => _CreateurCVPageState();
}

class _CreateurCVPageState extends State<CreateurCVPage> {
  int _etape = 0; // 0-4 : étapes du wizard

  // Données CV
  final _nomCtrl    = TextEditingController();
  final _titreCtrl  = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _telCtrl    = TextEditingController();
  final _villeCtrl  = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _resumeCtrl = TextEditingController();
  String? _photoPath;
  String? _photoUrl;

  List<Map<String, dynamic>> _experiences  = [];
  List<Map<String, dynamic>> _formations   = [];
  List<Map<String, dynamic>> _competences  = [];
  List<String>               _langues      = [];

  bool _isGenerating = false;
  bool _isDownloading = false;

  final _etapes = [
    _WizardEtape('Informations personnelles', Icons.person_outline_rounded, Color(0xFF1A56DB)),
    _WizardEtape('Résumé professionnel',      Icons.description_outlined,   Color(0xFF8B5CF6)),
    _WizardEtape('Expériences',               Icons.work_outline_rounded,   Color(0xFF10B981)),
    _WizardEtape('Formations',                Icons.school_outlined,        Color(0xFFF59E0B)),
    _WizardEtape('Compétences & Langues',     Icons.psychology_rounded,     Color(0xFFEF4444)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0, backgroundColor: Colors.white,
        title: Text('Créer mon CV professionnel',
          style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A))),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          // Bouton générer PDF
          if (_etape == 4)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                icon: _isDownloading
                    ? const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download_rounded, size: 16),
                label: Text(_isDownloading ? 'Génération...' : 'Télécharger PDF',
                  style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
                onPressed: _isDownloading ? null : _genererPDF)),
        ]),
      body: Column(children: [

        // ── Indicateur étapes ─────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            children: List.generate(_etapes.length, (i) {
              final isDone  = i < _etape;
              final isCurr  = i == _etape;
              final color   = _etapes[i].color;
              return Expanded(child: Row(children: [
                Column(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: isDone || isCurr
                          ? color : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      boxShadow: isCurr ? [BoxShadow(
                        color: color.withOpacity(0.3), blurRadius: 8)] : null),
                    child: Icon(
                      isDone ? Icons.check_rounded : _etapes[i].icon,
                      size: 16,
                      color: isDone || isCurr
                          ? Colors.white : const Color(0xFF94A3B8))),
                  const SizedBox(height: 4),
                  Text(_etapes[i].label.split(' ').first,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: isCurr
                          ? FontWeight.w700 : FontWeight.w400,
                      color: isCurr ? color : const Color(0xFF94A3B8))),
                ]),
                if (i < _etapes.length - 1)
                  Expanded(child: Container(
                    height: 2,
                    color: i < _etape
                        ? _etapes[i].color : const Color(0xFFE2E8F0))),
              ]));
            }),
          )),

        // ── Contenu étape ─────────────────────────────
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _buildEtapeContent(),
        )),

        // ── Navigation bas ────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          color: Colors.white,
          child: Row(children: [
            if (_etape > 0)
              Expanded(child: OutlinedButton.icon(
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Précédent'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
                onPressed: () => setState(() => _etape--)))
            else
              const Expanded(child: SizedBox()),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(
              icon: Icon(
                _etape < 4
                    ? Icons.arrow_forward_rounded
                    : Icons.preview_rounded,
                size: 16),
              label: Text(
                _etape < 4 ? 'Suivant' : 'Aperçu du CV',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _etapes[_etape].color,
                foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
              onPressed: _etape < 4
                  ? () => setState(() => _etape++)
                  : _apercu)),
          ])),
      ]),
    );
  }

  Widget _buildEtapeContent() {
    switch (_etape) {
      case 0: return _buildInfosPersonnelles();
      case 1: return _buildResume();
      case 2: return _buildExperiences();
      case 3: return _buildFormations();
      case 4: return _buildCompetencesLangues();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildInfosPersonnelles() => Column(children: [
    // Photo de profil
    Center(child: GestureDetector(
      onTap: _choisirPhoto,
      child: Stack(children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: const Color(0xFFEFF6FF),
          backgroundImage: _photoUrl != null
              ? NetworkImage(_photoUrl!) : null,
          child: _photoUrl == null ? Column(
            mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.add_a_photo_outlined,
              color: Color(0xFF1A56DB), size: 28),
            Text('Photo', style: GoogleFonts.inter(
              fontSize: 11, color: const Color(0xFF1A56DB))),
          ]) : null,
        ),
        Positioned(bottom: 0, right: 0, child: Container(
          width: 28, height: 28,
          decoration: const BoxDecoration(
            color: Color(0xFF1A56DB), shape: BoxShape.circle),
          child: const Icon(Icons.edit_rounded,
            color: Colors.white, size: 14))),
      ])),
    ),
    const SizedBox(height: 20),
    _FormField(_nomCtrl, 'Nom complet *', 'BARRY Youssouf',
      Icons.person_outline_rounded),
    const SizedBox(height: 14),
    _FormField(_titreCtrl, 'Titre professionnel *',
      'Développeur Flutter | Mobile & Web',
      Icons.work_outline_rounded),
    const SizedBox(height: 14),
    Row(children: [
      Expanded(child: _FormField(_emailCtrl, 'Email *',
        'email@exemple.com', Icons.email_outlined)),
      const SizedBox(width: 12),
      Expanded(child: _FormField(_telCtrl, 'Téléphone',
        '+224 620 00 00 00', Icons.phone_outlined)),
    ]),
    const SizedBox(height: 14),
    Row(children: [
      Expanded(child: _FormField(_villeCtrl, 'Ville',
        'Conakry, Guinée', Icons.location_on_outlined)),
      const SizedBox(width: 12),
      Expanded(child: _FormField(_linkedinCtrl, 'LinkedIn',
        'linkedin.com/in/...', Icons.link_rounded)),
    ]),
  ]);

  Widget _buildResume() => Column(children: [
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3))),
      child: Row(children: [
        const Icon(Icons.auto_awesome_rounded,
          color: Color(0xFF8B5CF6), size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(
          'Un résumé percutant augmente vos chances d\'être contacté. '
          'Décrivez votre profil en 3-5 phrases.',
          style: GoogleFonts.inter(
            fontSize: 12, color: const Color(0xFF6D28D9)))),
      ])),
    const SizedBox(height: 14),
    TextFormField(
      controller: _resumeCtrl, maxLines: 6, maxLength: 500,
      decoration: InputDecoration(
        hintText:
          'Développeur mobile passionné avec X ans d\'expérience en Flutter '
          'et Dart. Spécialisé dans la création d\'applications performantes '
          'et intuitives. À la recherche d\'opportunités...',
        hintStyle: GoogleFonts.inter(
          fontSize: 13, color: const Color(0xFFCBD5E1)),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      )),
  ]);

  // ... _buildExperiences(), _buildFormations(), _buildCompetencesLangues()
  // Utiliser les mêmes dialogs définis en Section 5.1

  Future<void> _genererPDF() async {
    setState(() => _isDownloading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/candidat/cv/generer-pdf'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nom':          _nomCtrl.text.trim(),
          'titre':        _titreCtrl.text.trim(),
          'email':        _emailCtrl.text.trim(),
          'telephone':    _telCtrl.text.trim(),
          'ville':        _villeCtrl.text.trim(),
          'linkedin':     _linkedinCtrl.text.trim(),
          'resume':       _resumeCtrl.text.trim(),
          'photo_url':    _photoUrl,
          'experiences':  _experiences,
          'formations':   _formations,
          'competences':  _competences,
          'langues':      _langues,
        }),
      );

      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final pdfUrl = body['data']['pdf_url'] as String;
        // Ouvrir le PDF
        await launchUrl(Uri.parse(pdfUrl),
          mode: LaunchMode.externalApplication);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_outline,
                color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'CV généré ! Vous pouvez maintenant l\'uploader pour l\'analyse IA.',
                style: GoogleFonts.inter(color: Colors.white))),
            ]),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Uploader',
              textColor: Colors.white,
              onPressed: () =>
                context.push('/dashboard-candidat/profil?tab=cv')),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating));
      }
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  Future<void> _apercu() async {
    // Afficher un aperçu du CV avant téléchargement
    context.push('/dashboard-candidat/cv/apercu', extra: {
      'nom': _nomCtrl.text, 'titre': _titreCtrl.text,
      // ... autres données
    });
  }

  Future<void> _choisirPhoto() async {
    final picker = ImagePicker();
    final file   = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    // Upload photo
    setState(() => _photoPath = file.path);
  }
}

class _WizardEtape {
  final String label; final IconData icon; final Color color;
  const _WizardEtape(this.label, this.icon, this.color);
}
```

### 6.2 Bouton "Créer mon CV" dans la page Mon Profil

```dart
// Dans la page Mon Profil & CV, ajouter en haut de la section CV :

// Banner "Créer mon CV" avec IA
Container(
  margin: const EdgeInsets.only(bottom: 16),
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF1A56DB), Color(0xFF7C3AED)]),
    borderRadius: BorderRadius.circular(14),
    boxShadow: const [BoxShadow(
      color: Color(0x301A56DB), blurRadius: 16,
      offset: Offset(0, 6))]),
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/dashboard-candidat/cv/creer'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded,
              color: Colors.white, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Créer mon CV avec l\'IA', style: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w800,
              color: Colors.white)),
            Text(
              'Remplissez vos infos → Téléchargez un CV pro → '
              'L\'IA analyse vos compétences',
              style: GoogleFonts.inter(
                fontSize: 11, color: Colors.white70, height: 1.4)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100)),
            child: Text('Créer', style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w800,
              color: const Color(0xFF1A56DB)))),
        ]))))),

// Conseil pour les CVs importés
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: const Color(0xFFFEF3C7),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color(0xFFFDE68A))),
  child: Row(children: [
    const Icon(Icons.lightbulb_outline_rounded,
      color: Color(0xFFF59E0B), size: 16),
    const SizedBox(width: 8),
    Expanded(child: Text(
      '💡 Pour que l\'IA analyse mieux votre CV : '
      'créez-le depuis la plateforme OU utilisez un CV '
      'en format texte clair (pas scanné).',
      style: GoogleFonts.inter(
        fontSize: 11, color: const Color(0xFF92400E),
        height: 1.4))),
  ])),
```

---

## 7. Backend — Routes Créateur CV

```javascript
// backend/src/routes/candidat/cv.routes.js
// Route pour générer le PDF du CV

router.post('/generer-pdf', auth, async (req, res) => {
  try {
    const {
      nom, titre, email, telephone, ville, linkedin,
      resume, photo_url, experiences, formations,
      competences, langues,
    } = req.body;

    if (!nom?.trim() || !titre?.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Nom et titre professionnels requis'
      });
    }

    // Récupérer le chercheur
    const { data: chercheur } = await supabase
      .from('chercheurs_emploi')
      .select('id')
      .eq('utilisateur_id', req.user.id)
      .single();

    if (!chercheur) {
      return res.status(404).json({
        success: false, message: 'Profil candidat non trouvé'
      });
    }

    // Sauvegarder les données CV dans la BDD
    // pour que l'IA puisse les analyser directement
    const competencesTexte = [
      ...(Array.isArray(competences) ? competences : []),
      ...(Array.isArray(experiences) ? experiences.map(e =>
        `${e.titre} chez ${e.entreprise}`) : []),
      ...(Array.isArray(formations) ? formations.map(f =>
        f.diplome) : []),
      ...(Array.isArray(langues) ? langues.map(l =>
        `Langue: ${l}`) : []),
    ].filter(Boolean);

    // Mettre à jour les données du chercheur
    await supabase.from('chercheurs_emploi').update({
      titre_poste: titre,
      about:       resume,
      competences: competencesTexte,
    }).eq('id', chercheur.id);

    await supabase.from('utilisateurs').update({
      nom,
      telephone: telephone || undefined,
      adresse:   ville || undefined,
    }).eq('id', req.user.id);

    // Générer le PDF avec une librairie (PDFKit)
    const PDFDocument = require('pdfkit');
    const chunks      = [];
    const doc         = new PDFDocument({ margin: 0, size: 'A4' });

    doc.on('data', chunk => chunks.push(chunk));
    doc.on('end', async () => {
      const pdfBuffer = Buffer.concat(chunks);

      // Uploader le PDF sur Supabase
      const bucket   = 'cv-files';
      const fileName = `cv-genere-${chercheur.id}-${Date.now()}.pdf`;

      const { error: upErr } = await supabase.storage
        .from(bucket)
        .upload(fileName, pdfBuffer, {
          contentType: 'application/pdf',
          upsert: false,
        });

      if (upErr) {
        return res.status(500).json({
          success: false,
          message: `Erreur upload: ${upErr.message}`
        });
      }

      // URL signée 7 jours
      const { data: signData } = await supabase.storage
        .from(bucket)
        .createSignedUrl(fileName, 7 * 24 * 3600);

      // Sauvegarder les compétences extraites pour l'IA
      await supabase.from('cv').upsert({
        chercheur_id:      chercheur.id,
        fichier_url:       signData?.signedUrl || '',
        nom_fichier:       `CV_${nom.replace(/ /g, '_')}.pdf`,
        type_fichier:      'PDF',
        date_upload:       new Date().toISOString(),
        competences_extrait: {
          competences:  competencesTexte.slice(0, 20),
          experience:   experiences || [],
          formation:    formations  || [],
          langues:      langues     || ['Français'],
          source:       'plateforme', // ← Généré depuis la plateforme
          analyse_le:   new Date().toISOString(),
        },
      }, { onConflict: 'chercheur_id' });

      return res.json({
        success: true,
        message: 'CV généré avec succès',
        data: {
          pdf_url:    signData?.signedUrl,
          nom_fichier: `CV_${nom.replace(/ /g, '_')}.pdf`,
        }
      });
    });

    // ── Génération du PDF ──────────────────────────
    const BLEU       = '#1A56DB';
    const BLEU_CLAIR = '#EFF6FF';
    const GRIS       = '#64748B';
    const NOIR       = '#0F172A';

    // En-tête colorée
    doc.rect(0, 0, 595, 130).fill(BLEU);

    // Photo si disponible (cercle)
    // doc.circle(80, 65, 45).clip()
    //    .image(photoBuffer, 35, 20, { width: 90, height: 90 });

    // Nom
    doc.fillColor('white')
      .font('Helvetica-Bold')
      .fontSize(24)
      .text(nom.toUpperCase(), 140, 35);

    // Titre
    doc.fillColor('rgba(255,255,255,0.85)')
      .font('Helvetica')
      .fontSize(14)
      .text(titre, 140, 65);

    // Contacts dans l'en-tête
    doc.fontSize(10)
      .text(`📧 ${email}  📞 ${telephone || ''}  📍 ${ville || ''}`, 140, 90);

    let y = 150;

    // Résumé
    if (resume?.trim()) {
      doc.fillColor(BLEU).font('Helvetica-Bold').fontSize(12)
        .text('PROFIL PROFESSIONNEL', 40, y);
      doc.moveTo(40, y+16).lineTo(555, y+16)
        .stroke(BLEU_CLAIR);
      y += 24;
      doc.fillColor(GRIS).font('Helvetica').fontSize(10)
        .text(resume, 40, y, { width: 515, lineGap: 4 });
      y += doc.heightOfString(resume, { width: 515 }) + 20;
    }

    // Expériences
    if (experiences?.length > 0) {
      doc.fillColor(BLEU).font('Helvetica-Bold').fontSize(12)
        .text('EXPÉRIENCES PROFESSIONNELLES', 40, y);
      doc.moveTo(40, y+16).lineTo(555, y+16).stroke(BLEU_CLAIR);
      y += 24;
      for (const exp of experiences) {
        doc.fillColor(NOIR).font('Helvetica-Bold').fontSize(11)
          .text(exp.titre || '', 40, y);
        doc.fillColor(BLEU).font('Helvetica').fontSize(10)
          .text(exp.entreprise || '', 40, y+14);
        const dates = `${exp.date_debut?.substring(0,7) || ''} → ${exp.en_poste ? 'Aujourd\'hui' : exp.date_fin?.substring(0,7) || ''}`;
        doc.fillColor(GRIS).fontSize(9).text(dates, 400, y,
          { align: 'right', width: 155 });
        if (exp.description) {
          y += 30;
          doc.fillColor(GRIS).font('Helvetica').fontSize(9)
            .text(exp.description, 40, y, { width: 515 });
          y += doc.heightOfString(exp.description, { width: 515 }) + 12;
        } else {
          y += 38;
        }
      }
      y += 10;
    }

    // Compétences
    if (competences?.length > 0) {
      doc.fillColor(BLEU).font('Helvetica-Bold').fontSize(12)
        .text('COMPÉTENCES', 40, y);
      doc.moveTo(40, y+16).lineTo(555, y+16).stroke(BLEU_CLAIR);
      y += 24;
      let x = 40;
      for (const comp of competences.slice(0, 12)) {
        const label = typeof comp === 'string'
          ? comp : comp.nom || '';
        const w = doc.widthOfString(label) + 20;
        if (x + w > 555) { x = 40; y += 22; }
        doc.roundedRect(x, y, w, 18, 4)
          .fill(BLEU_CLAIR);
        doc.fillColor(BLEU).font('Helvetica').fontSize(9)
          .text(label, x + 8, y + 4);
        x += w + 8;
      }
      y += 30;
    }

    doc.end();

  } catch (err) {
    console.error('[generer-pdf]', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});

// Enregistrer la route :
// router.use('/candidat/cv', require('./candidat/cv.routes'));
```

---

## 8. Critères d'Acceptation

### ✅ Vue d'ensemble — Offres recommandées
- [ ] Grille 3 colonnes sur desktop, 2 sur tablette, 1 sur mobile
- [ ] Score IA : arc de cercle animé (CircularProgressIndicator)
- [ ] Animation cascade : chaque carte apparaît avec délai (0, 100, 200ms...)
- [ ] Badge Excellent/Bon match/Moyen coloré selon le score
- [ ] Bouton "Postuler maintenant" sur chaque carte
- [ ] Bouton bookmark (sauvegarder/retirer) sur chaque carte

### ✅ Vue d'ensemble — Suivi candidatures
- [ ] 5 colonnes animées : En attente / En examen / Entretien / Acceptées / Refusées
- [ ] Compteurs animés (0 → valeur réelle) avec TweenAnimationBuilder
- [ ] Icônes colorées avec fond circulaire
- [ ] Animation ScaleTransition cascade
- [ ] Candidatures récentes en dessous avec logo entreprise

### ✅ Topbar candidat
- [ ] Photo de profil affichée (pas juste l'initiale)
- [ ] Indicateur "Profil X%" si < 80% (bouton gradient bleu)
- [ ] Badge rouge sur l'icône notifications
- [ ] photoUrl dans AuthProvider synchronisé

### ✅ Barre complétion profil
- [ ] Animation de progression au chargement
- [ ] Dégradé qui change selon le % (violet → bleu → vert)
- [ ] Effet brillant qui se déplace sur la barre
- [ ] Pulsation légère en boucle
- [ ] Bouton "Compléter maintenant" si pas à 100%

### ✅ Mon Profil — Sections avec dialogs
- [ ] Bouton "+" ouvre un dialog (pas de duplication)
- [ ] Dialog Expérience : titre, entreprise, dates, toggle "en poste"
- [ ] Dialog Formation : diplôme, école, année
- [ ] Dialog Compétence : nom + niveau (débutant/intermédiaire/expert)
- [ ] Dialog Langue : nom + niveau
- [ ] Chaque item a bouton modifier + supprimer

### ✅ Créateur de CV
- [ ] Wizard 5 étapes avec indicateur visuel
- [ ] Étape 1 : Infos personnelles + upload photo
- [ ] Étape 2 : Résumé professionnel
- [ ] Étape 3 : Expériences (avec dialogs)
- [ ] Étape 4 : Formations
- [ ] Étape 5 : Compétences + Langues
- [ ] Bouton "Télécharger PDF" → génère un PDF avec design coloré
- [ ] PDF généré sauvegardé automatiquement dans cv-files
- [ ] Compétences sauvegardées pour analyse IA immédiate
- [ ] Banner "Créer mon CV" visible sur la page Mon Profil
- [ ] Conseil affiché pour les CVs importés

---

*PRD EmploiConnect v8.0 — Espace Candidat Améliorations Complètes*
*Cursor / Kirsoft AI — Phase 13*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
