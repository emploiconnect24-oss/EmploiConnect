# PRD — EmploiConnect · Parcours Carrière v2 — Animations & IA
## Product Requirements Document v8.8
**Stack : Flutter + Node.js/Express + Supabase + Claude IA**
**Outil : Cursor / Kirsoft AI**
**Date : Avril 2026**

---

## Réponse à la question : Quelles IA utilise-t-on ?

```
PARCOURS CARRIÈRE utilise CLAUDE (Anthropic) pour :

1. Simulateur entretien :
   → Générer les questions d'entretien
   → Évaluer les réponses du candidat
   → Donner un feedback détaillé
   → Suggérer des améliorations

2. Calculateur salaire :
   → Analyser le marché guinéen
   → Estimer les fourchettes salariales
   → Donner des conseils de négociation

3. Illustrations contextuelles :
   → Choisir l'emoji/icône selon la question
   → Générer une description d'illustration
   → (Pas d'API image — utiliser des illustrations SVG
      générées selon le domaine/thème)

MÊME CLÉ que pour le matching et l'amélioration À propos.
Tout configuré dans Admin → Paramètres → IA.
```

---

## Table des Matières

1. [Fix scroll ressources trop collées en bas](#1-fix-scroll-ressources)
2. [Simulateur entretien — Illustrations + Animations](#2-simulateur-entretien--illustrations--animations)
3. [Animations confetti résultats](#3-animations-confetti-résultats)
4. [Lecteur vidéo intégré dans la plateforme](#4-lecteur-vidéo-intégré)
5. [Admin Parcours Carrière — Robustesse complète](#5-admin-parcours-carrière--robustesse-complète)
6. [Admin Paramètres IA — Parcours Carrière](#6-admin-paramètres-ia--parcours-carrière)

---

## 1. Fix scroll ressources

### Problème
```
Les ressources sont trop collées en bas de la page.
Il faut un meilleur espacement et un scroll fluide.
```

### Fix Flutter
```dart
// Dans parcours_carriere_page.dart
// Dans _buildTabRessources()

// AVANT ❌ — Liste trop collée
Widget _buildTabRessources() => Column(children: [
  _buildFiltres(),
  _buildOutilsIA(),
  Expanded(child: ListView(...)), // Collé
]);

// APRÈS ✅ — Scroll unifié + espacements
Widget _buildTabRessources() => CustomScrollView(
  physics: const AlwaysScrollableScrollPhysics(),
  slivers: [

    // Filtres catégories
    SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: _buildFiltresCategories())),

    // Outils IA
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: _buildOutilsIA())),

    // Titre section ressources
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(children: [
          Text('📚 Ressources disponibles',
            style: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A))),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1A56DB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(100)),
            child: Text('${_ressourcesFiltrees.length}',
              style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: const Color(0xFF1A56DB)))),
        ]))),

    // Liste ressources avec bon espacement
    _ressourcesFiltrees.isEmpty
        ? SliverFillRemaining(child: _buildEmpty())
        : SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _RessourceCard(
                  ressource: _ressourcesFiltrees[i],
                  onTap: () => _ouvrirRessource(
                    _ressourcesFiltrees[i])),
                childCount: _ressourcesFiltrees.length))),
  ]);
```

---

## 2. Simulateur entretien — Illustrations + Animations

### Logique des illustrations
```
Pas d'API de génération d'images (coûteux).
À la place : Claude choisit une illustration thématique
parmi une bibliothèque d'SVG/emojis selon le contexte.

Exemple :
Question sur le code    → 💻 + illustration code
Question sur le travail → 🤝 + illustration bureau
Question sur leadership → 👑 + illustration équipe
Question sur stress     → 🧘 + illustration zen
```

### Flutter — Phase simulation avec illustrations

```dart
// Dans simulateur_entretien_ia.dart
// Remplacer _buildSimulation() par la version animée

Widget _buildSimulation() {
  if (_questions.isEmpty) return const SizedBox();
  final q     = _questions[_questionActuelle];
  final total = _questions.length;
  final prog  = (_questionActuelle + 1) / total;
  final illus = _getIllustration(q['type'], q['theme']);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [

    // ── Barre de progression animée ─────────────────────
    TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: prog),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (_, v, __) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF8B5CF6).withOpacity(0.08),
              const Color(0xFF1A56DB).withOpacity(0.04),
            ]),
          borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(100)),
                child: Text(
                  'Q${_questionActuelle + 1}/$total',
                  style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w800,
                    color: Colors.white))),
              const SizedBox(width: 8),
              Text(q['type'] ?? '',
                style: GoogleFonts.inter(
                  fontSize: 11, color: const Color(0xFF8B5CF6),
                  fontWeight: FontWeight.w500)),
            ]),
            Text('${(v * 100).round()}% complété',
              style: GoogleFonts.inter(
                fontSize: 10, color: const Color(0xFF94A3B8))),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: v, minHeight: 8,
              backgroundColor:
                const Color(0xFF8B5CF6).withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation(
                Color(0xFF8B5CF6)))),
        ]))),
    const SizedBox(height: 14),

    // ── Illustration + Question animées ─────────────────
    AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, anim) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0), end: Offset.zero)
          .animate(CurvedAnimation(
            parent: anim, curve: Curves.easeOut)),
        child: FadeTransition(opacity: anim, child: child)),
      child: Container(
        key: ValueKey(_questionActuelle),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: illus['couleur'].withOpacity(0.3)),
          boxShadow: [BoxShadow(
            color: illus['couleur'].withOpacity(0.08),
            blurRadius: 12, offset: const Offset(0, 4))]),
        child: Column(children: [

          // Illustration thématique
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Grande illustration emoji
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: illus['couleur'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(
                illus['emoji'],
                style: const TextStyle(fontSize: 28)))),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(illus['titre'],
                style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: illus['couleur'])),
              const SizedBox(height: 6),
              Text(q['question'] as String? ?? '',
                style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A), height: 1.5)),
            ])),
          ]),

          // Conseil de réponse (si disponible)
          if ((q['conseil'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Text('💡', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  q['conseil'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF92400E)))),
              ])),
          ],
        ]))),
    const SizedBox(height: 14),

    // ── Zone réponse ────────────────────────────────────
    Text('✍️ Votre réponse :',
      style: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w700,
        color: const Color(0xFF374151))),
    const SizedBox(height: 8),
    TextFormField(
      controller: _reponseCtrl,
      maxLines: 5,
      decoration: InputDecoration(
        hintText:
          'Répondez clairement et avec des exemples concrets...',
        hintStyle: GoogleFonts.inter(
          fontSize: 13, color: const Color(0xFFCBD5E1)),
        filled: true, fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF8B5CF6), width: 2)))),
    const SizedBox(height: 14),

    // Boutons navigation
    Row(children: [
      if (_questionActuelle > 0)
        Expanded(child: OutlinedButton.icon(
          icon: const Icon(Icons.arrow_back_rounded, size: 14),
          label: const Text('Précédent'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            foregroundColor: const Color(0xFF64748B),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10))),
          onPressed: () => setState(() {
            _questionActuelle--;
            _reponseCtrl.text = _questionActuelle <
                _reponses.length
                    ? _reponses[_questionActuelle]['reponse']
                      as String? ?? '' : '';
          }))),

      if (_questionActuelle > 0) const SizedBox(width: 10),

      Expanded(child: ElevatedButton.icon(
        icon: _isEvaluating
            ? const SizedBox(width: 14, height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
            : Icon(
                _questionActuelle < total - 1
                    ? Icons.arrow_forward_rounded
                    : Icons.check_circle_rounded,
                size: 16),
        label: Text(
          _isEvaluating
              ? 'IA évalue...'
              : _questionActuelle < total - 1
                  ? 'Répondre & Continuer'
                  : '🏁 Terminer l\'entretien',
          style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B5CF6),
          foregroundColor: Colors.white, elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10))),
        onPressed: _isEvaluating ? null : _repondreEtContinuer)),
    ]),
  ]);
}

// Illustrations selon le type et thème de question
Map<String, dynamic> _getIllustration(
    String? type, String? theme) {
  final t = (theme ?? type ?? '').toLowerCase();

  if (t.contains('code') || t.contains('technique') ||
      t.contains('programm') || t.contains('flutter') ||
      t.contains('développ') || t.contains('informatique')) {
    return {
      'emoji':   '💻',
      'titre':   'Question Technique',
      'couleur': const Color(0xFF1A56DB),
    };
  }
  if (t.contains('team') || t.contains('équipe') ||
      t.contains('collège') || t.contains('leader')) {
    return {
      'emoji':   '🤝',
      'titre':   'Question sur le Travail d\'équipe',
      'couleur': const Color(0xFF10B981),
    };
  }
  if (t.contains('stress') || t.contains('pression') ||
      t.contains('difficulté') || t.contains('défi')) {
    return {
      'emoji':   '🧘',
      'titre':   'Question sur la Gestion du stress',
      'couleur': const Color(0xFFF59E0B),
    };
  }
  if (t.contains('motiv') || t.contains('objectif') ||
      t.contains('ambition') || t.contains('carrière')) {
    return {
      'emoji':   '🎯',
      'titre':   'Question de Motivation',
      'couleur': const Color(0xFF8B5CF6),
    };
  }
  if (t.contains('experience') || t.contains('projet') ||
      t.contains('réalisation') || t.contains('résultat')) {
    return {
      'emoji':   '🏆',
      'titre':   'Question sur l\'Expérience',
      'couleur': const Color(0xFFF59E0B),
    };
  }
  if (t.contains('comptab') || t.contains('finance') ||
      t.contains('budget') || t.contains('chiffre')) {
    return {
      'emoji':   '💰',
      'titre':   'Question Comptable/Financière',
      'couleur': const Color(0xFF10B981),
    };
  }
  if (t.contains('client') || t.contains('vente') ||
      t.contains('commercial') || t.contains('négoci')) {
    return {
      'emoji':   '🤝',
      'titre':   'Question Commerciale',
      'couleur': const Color(0xFF0EA5E9),
    };
  }
  if (t.contains('comportemental') || t.contains('situation')) {
    return {
      'emoji':   '🎭',
      'titre':   'Question Comportementale',
      'couleur': const Color(0xFF8B5CF6),
    };
  }
  // Défaut
  return {
    'emoji':   '💬',
    'titre':   'Question d\'Entretien',
    'couleur': const Color(0xFF8B5CF6),
  };
}
```

### Backend — Ajouter le thème dans les questions générées

```javascript
// Dans parcoursCarriere.controller.js
// Modifier le prompt pour inclure le thème

const prompt =
  `Tu es un recruteur expert en Guinée.
Génère exactement ${nb_questions} questions d'entretien.

Poste   : ${poste_vise}
Domaine : ${domaine}
Niveau  : ${niveau}

Réponds UNIQUEMENT avec ce JSON :
{
  "questions": [
    {
      "question": "...",
      "type":    "technique|comportemental|situation|motivation",
      "theme":   "<mot-clé du thème: code|equipe|stress|experience|finance|commercial>",
      "conseil": "<tip court pour bien répondre>"
    }
  ]
}`;
```

---

## 3. Animations confetti résultats

### Installer la dépendance

```yaml
# Dans frontend/pubspec.yaml
dependencies:
  confetti: ^0.7.0
```

### Flutter — Phase résultat avec confetti

```dart
// Dans simulateur_entretien_ia.dart
// Ajouter le controller confetti

import 'package:confetti/confetti.dart';

class _SimulateurState extends State<SimulateurEntretienIA>
    with TickerProviderStateMixin {

  late ConfettiController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(
      duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  // Dans _repondreEtContinuer(), quand on passe à 'resultat' :
  // if (scoreGlobal >= 60) _confettiCtrl.play();
  // setState(() => _phase = 'resultat');

  // ── Phase résultat avec confetti ────────────────────────
  Widget _buildResultat() {
    final scoreGlobal = _reponses.isEmpty ? 0
        : (_reponses.map((r) =>
            r['score'] as int? ?? 0).reduce((a, b) => a + b) /
            _reponses.length).round();

    final excellent = scoreGlobal >= 80;
    final bon       = scoreGlobal >= 60;

    return Stack(children: [

      // Confetti en haut au centre
      Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _confettiCtrl,
          blastDirectionality: BlastDirectionality.explosive,
          particleDrag: 0.05,
          emissionFrequency: 0.08,
          numberOfParticles: 20,
          gravity: 0.1,
          colors: const [
            Color(0xFF1A56DB), Color(0xFF10B981),
            Color(0xFF8B5CF6), Color(0xFFF59E0B),
            Color(0xFFEF4444),
          ])),

      // Contenu résultat
      SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

          // ── Carte score principal animée ───────────────
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: scoreGlobal / 100),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) {
              final pct    = (v * 100).round();
              final color  = excellent
                  ? const Color(0xFF10B981)
                  : bon ? const Color(0xFF8B5CF6)
                        : const Color(0xFFF59E0B);

              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: excellent
                        ? [const Color(0xFF10B981),
                           const Color(0xFF059669)]
                        : bon
                            ? [const Color(0xFF8B5CF6),
                               const Color(0xFF7C3AED)]
                            : [const Color(0xFFF59E0B),
                               const Color(0xFFD97706)]),
                  borderRadius: BorderRadius.circular(16)),
                child: Column(children: [

                  // Emoji résultat
                  Text(
                    excellent ? '🎉' : bon ? '👍' : '📈',
                    style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),

                  // Score animé
                  Text('$pct / 100',
                    style: GoogleFonts.poppins(
                      fontSize: 52, fontWeight: FontWeight.w900,
                      color: Colors.white)),

                  // Message
                  Text(
                    excellent
                        ? 'Excellent ! Vous êtes prêt !'
                        : bon
                            ? 'Bon résultat ! Continuez ainsi'
                            : 'Des axes d\'amélioration identifiés',
                    style: GoogleFonts.inter(
                      fontSize: 15, color: Colors.white,
                      fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center),
                  const SizedBox(height: 16),

                  // Mini barre progression
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: v, minHeight: 8,
                      backgroundColor:
                        Colors.white.withOpacity(0.25),
                      valueColor: const AlwaysStoppedAnimation(
                        Colors.white))),
                ]));
            }),
          const SizedBox(height: 20),

          // ── Analyse IA étape par étape ─────────────────
          _buildAnalyseDetaillee(scoreGlobal),
          const SizedBox(height: 20),

          // ── Détail par question ────────────────────────
          Text('📋 Détail question par question',
            style: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A))),
          const SizedBox(height: 12),

          ..._reponses.asMap().entries.map((entry) {
            final i   = entry.key;
            final r   = entry.value;
            final s   = r['score'] as int? ?? 0;
            final sc  = s >= 70
                ? const Color(0xFF10B981)
                : s >= 50
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFFF59E0B);
            final illus = _getIllustration(
              r['type'] as String?,
              r['theme'] as String?);

            return AnimatedContainer(
              duration: Duration(
                milliseconds: 400 + (i * 100)),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sc.withOpacity(0.3)),
                boxShadow: [BoxShadow(
                  color: sc.withOpacity(0.05),
                  blurRadius: 8, offset: const Offset(0, 2))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(children: [
                  Text(illus['emoji'],
                    style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    r['question'] as String? ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151)))),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: sc.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(100)),
                    child: Text('$s/100',
                      style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w800,
                        color: sc))),
                ]),
                const SizedBox(height: 10),

                // Points forts
                if ((r['points_forts'] as List?)?.isNotEmpty
                    == true) ...[
                  Text('✅ Points forts :',
                    style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: const Color(0xFF10B981))),
                  const SizedBox(height: 4),
                  ...(r['points_forts'] as List).map((p) =>
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 12, bottom: 2),
                      child: Text('• $p',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF374151))))),
                  const SizedBox(height: 8),
                ],

                // Axes d'amélioration
                if ((r['ameliorations'] as List?)?.isNotEmpty
                    == true) ...[
                  Text('📈 Axes d\'amélioration :',
                    style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: const Color(0xFFF59E0B))),
                  const SizedBox(height: 4),
                  ...(r['ameliorations'] as List).map((a) =>
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 12, bottom: 2),
                      child: Text('• $a',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF374151))))),
                  const SizedBox(height: 8),
                ],

                // Feedback principal
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(Icons.auto_awesome_rounded,
                      size: 12, color: Color(0xFF8B5CF6)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(
                      r['feedback'] as String? ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF374151),
                        height: 1.4))),
                  ])),
              ]));
          }),

          const SizedBox(height: 20),

          // Boutons
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 15),
              label: const Text('Recommencer'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: Color(0xFF8B5CF6)),
                foregroundColor: const Color(0xFF8B5CF6),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
              onPressed: () => setState(() {
                _phase           = 'config';
                _questions       = [];
                _reponses        = [];
                _questionActuelle = 0;
                _reponseCtrl.clear();
              }))),
          ]),
        ])),
    ]);
  }

  // ── Analyse IA étape par étape ───────────────────────────
  Widget _buildAnalyseDetaillee(int score) {
    final excellent = score >= 80;
    final bon       = score >= 60;
    final moyen     = score >= 40;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Row(children: [
          const Icon(Icons.auto_awesome_rounded,
            color: Color(0xFF8B5CF6), size: 18),
          const SizedBox(width: 8),
          Text('Analyse IA de votre entretien',
            style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A))),
        ]),
        const SizedBox(height: 14),

        // Étapes d'analyse
        _EtapeAnalyse(
          numero: '01',
          titre:  'Pertinence des réponses',
          desc:   excellent
              ? 'Vos réponses sont très pertinentes et bien structurées.'
              : bon
                  ? 'Vos réponses sont globalement pertinentes.'
                  : 'Certaines réponses manquent de précision.',
          icone:  excellent ? '✅' : bon ? '⚡' : '📝',
          couleur: excellent
              ? const Color(0xFF10B981)
              : bon ? const Color(0xFF1A56DB)
                    : const Color(0xFFF59E0B)),

        _EtapeAnalyse(
          numero: '02',
          titre:  'Maîtrise du domaine',
          desc:   excellent
              ? 'Excellente maîtrise technique du domaine demandé.'
              : bon
                  ? 'Bonne connaissance du domaine, quelques lacunes.'
                  : 'Des connaissances techniques à approfondir.',
          icone:  excellent ? '🎯' : bon ? '📊' : '📚',
          couleur: excellent
              ? const Color(0xFF10B981)
              : bon ? const Color(0xFF8B5CF6)
                    : const Color(0xFFF59E0B)),

        _EtapeAnalyse(
          numero: '03',
          titre:  'Communication et clarté',
          desc:   excellent
              ? 'Très bonne communication, idées bien structurées.'
              : bon
                  ? 'Communication correcte, peut être améliorée.'
                  : 'Travaillez la structure de vos réponses.',
          icone:  excellent ? '🗣️' : bon ? '💬' : '✏️',
          couleur: excellent
              ? const Color(0xFF10B981)
              : bon ? const Color(0xFF0EA5E9)
                    : const Color(0xFFF59E0B)),

        _EtapeAnalyse(
          numero: '04',
          titre:  'Recommandation finale',
          desc:   excellent
              ? '🎉 Vous êtes prêt pour cet entretien ! Présentez-vous avec confiance.'
              : bon
                  ? '👍 Continuez à pratiquer sur les points faibles identifiés.'
                  : '📈 Révisez les fondamentaux et reprenez la simulation.',
          icone:  excellent ? '🚀' : bon ? '💪' : '🎯',
          couleur: excellent
              ? const Color(0xFF10B981)
              : bon ? const Color(0xFF8B5CF6)
                    : const Color(0xFFEF4444),
          isLast: true),
      ]));
  }
}

// Widget étape analyse
class _EtapeAnalyse extends StatelessWidget {
  final String numero, titre, desc, icone;
  final Color couleur; final bool isLast;
  const _EtapeAnalyse({
    required this.numero, required this.titre,
    required this.desc, required this.icone,
    required this.couleur, this.isLast = false});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    Column(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: couleur.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: couleur.withOpacity(0.3))),
        child: Center(child: Text(icone,
          style: const TextStyle(fontSize: 14)))),
      if (!isLast) Container(
        width: 2, height: 30,
        color: const Color(0xFFE2E8F0)),
    ]),
    const SizedBox(width: 12),
    Expanded(child: Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(numero,
            style: GoogleFonts.inter(
              fontSize: 10, color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text(titre, style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A))),
        ]),
        const SizedBox(height: 3),
        Text(desc, style: GoogleFonts.inter(
          fontSize: 11, color: const Color(0xFF64748B),
          height: 1.4)),
      ]))),
  ]);
}
```

---

## 4. Lecteur vidéo intégré

### Dépendance à ajouter

```yaml
# Dans frontend/pubspec.yaml
dependencies:
  webview_flutter: ^4.4.2
  youtube_player_flutter: ^8.1.2  # Pour YouTube spécifiquement
```

### Flutter — Page détail ressource avec lecteur vidéo

```dart
// Dans parcours_ressource_detail_page.dart
// Remplacer le contenu par la version avec lecteur

import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ParcoursRessourceDetailPage extends StatefulWidget {
  final Map<String, dynamic> ressource;
  const ParcoursRessourceDetailPage({
    super.key, required this.ressource});
  @override
  State<ParcoursRessourceDetailPage> createState() =>
    _RessourceDetailState();
}

class _RessourceDetailState
    extends State<ParcoursRessourceDetailPage> {

  YoutubePlayerController? _ytCtrl;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
    _marquerVue();
  }

  void _initVideo() {
    final type = widget.ressource['type_ressource'] as String?;
    final url  = widget.ressource['url_externe']   as String?;

    if (type == 'video_youtube' && url != null) {
      // Extraire l'ID YouTube
      final videoId = YoutubePlayer.convertUrlToId(url);
      if (videoId != null) {
        _ytCtrl = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute:     false,
          ));
      }
    }
  }

  @override
  void dispose() {
    _ytCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r    = widget.ressource;
    final type = r['type_ressource'] as String? ?? '';
    final titre = r['titre']        as String? ?? '';
    final desc  = r['description']  as String? ?? '';
    final contenu = r['contenu']    as String? ?? '';
    final categorie = r['categorie'] as String? ?? '';
    final niveau    = r['niveau']    as String? ?? '';
    final duree     = r['duree_minutes'] as int?;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [

          // AppBar
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF1A56DB),
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(titre, style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: Colors.white),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded,
                  color: Colors.white),
                onPressed: () {}),
            ]),

          SliverToBoxAdapter(child: Column(children: [

            // ── Lecteur vidéo YouTube ────────────────────
            if (type == 'video_youtube' && _ytCtrl != null)
              YoutubePlayerBuilder(
                player: YoutubePlayer(
                  controller: _ytCtrl!,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: const Color(0xFF1A56DB),
                  progressColors: const ProgressBarColors(
                    playedColor:  Color(0xFF1A56DB),
                    handleColor:  Color(0xFF1A56DB))),
                builder: (ctx, player) => Column(children: [
                  // Lecteur pleine largeur
                  player,
                ])),

            // ── Vidéo interne (Supabase Storage) ─────────
            if (type == 'video_interne')
              Container(
                height: 220,
                color: Colors.black,
                child: Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  const Icon(Icons.play_circle_filled_rounded,
                    color: Colors.white, size: 56),
                  const SizedBox(height: 8),
                  Text('Cliquez pour regarder',
                    style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 13)),
                ]))),

            // ── Image de couverture si pas de vidéo ──────
            if (type != 'video_youtube' &&
                type != 'video_interne' &&
                r['image_couverture'] != null)
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      r['image_couverture'] as String),
                    fit: BoxFit.cover)),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0x80000000),
                      ])))),

            // ── Contenu principal ─────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                // Badges
                Wrap(spacing: 8, children: [
                  _BadgeInfo(_labelCategorie(categorie),
                    _couleurCategorie(categorie)),
                  _BadgeInfo(_labelNiveau(niveau),
                    const Color(0xFF64748B)),
                  if (duree != null)
                    _BadgeInfo('⏱️ $duree min',
                      const Color(0xFF0EA5E9)),
                ]),
                const SizedBox(height: 16),

                // Titre
                Text(titre, style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A))),
                const SizedBox(height: 8),

                // Description
                if (desc.isNotEmpty) ...[
                  Text(desc, style: GoogleFonts.inter(
                    fontSize: 14, color: const Color(0xFF64748B),
                    height: 1.6)),
                  const SizedBox(height: 16),
                ],

                // Contenu article
                if (contenu.isNotEmpty &&
                    type == 'article') ...[
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),
                  Text(contenu, style: GoogleFonts.inter(
                    fontSize: 14, color: const Color(0xFF374151),
                    height: 1.7)),
                ],

                // Lien PDF
                if (type == 'pdf' &&
                    r['fichier_url'] != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.picture_as_pdf_rounded, size: 18),
                      label: const Text('Ouvrir le PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                        textStyle: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                      onPressed: () async {
                        final url = Uri.parse(
                          r['fichier_url'] as String);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url,
                            mode: LaunchMode.externalApplication);
                        }
                      })),
                ],

                const SizedBox(height: 40),
              ])),
          ])),
        ]));
  }

  Future<void> _marquerVue() async {
    try {
      final token = // récupérer le token...
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/candidat/ressources/${widget.ressource['id']}/vue'),
        headers: {'Authorization': 'Bearer $token'});
    } catch (_) {}
  }

  String _labelCategorie(String c) => {
    'cv':              '📄 CV',
    'entretien':       '🎤 Entretien',
    'salaire':         '💰 Salaire',
    'reconversion':    '🔄 Reconversion',
    'entrepreneuriat': '🚀 Entrepreneuriat',
    'general':         '🗂️ Général',
  }[c] ?? c;

  Color _couleurCategorie(String c) => {
    'cv':              const Color(0xFF1A56DB),
    'entretien':       const Color(0xFF8B5CF6),
    'salaire':         const Color(0xFF10B981),
    'reconversion':    const Color(0xFFF59E0B),
    'entrepreneuriat': const Color(0xFFEF4444),
  }[c] ?? const Color(0xFF64748B);

  String _labelNiveau(String n) => {
    'debutant':     '🌱 Débutant',
    'intermediaire': '⭐ Intermédiaire',
    'avance':       '🏆 Avancé',
    'tous':         '👥 Tous niveaux',
  }[n] ?? n;
}

class _BadgeInfo extends StatelessWidget {
  final String label; final Color couleur;
  const _BadgeInfo(this.label, this.couleur);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: couleur.withOpacity(0.1),
      borderRadius: BorderRadius.circular(100),
      border: Border.all(
        color: couleur.withOpacity(0.3))),
    child: Text(label, style: GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w600,
      color: couleur)));
}
```

---

## 5. Admin Parcours Carrière — Robustesse complète

### Flutter — Dialog création ressource robuste

```dart
// Dans admin_ressources_parcours_screen.dart
// Dialog de création/édition complet

class _DialogRessource extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;
  const _DialogRessource({this.existing, required this.onSaved});
  @override
  State<_DialogRessource> createState() => _DialogRessourceState();
}

class _DialogRessourceState extends State<_DialogRessource> {

  final _titreCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _contenuCtrl = TextEditingController();
  final _urlCtrl   = TextEditingController();

  String _type       = 'article';
  String _categorie  = 'general';
  String _niveau     = 'tous';
  int?   _duree;
  bool   _isMisEnAvant = false;
  bool   _isPublie     = false;
  bool   _isSaving     = false;

  PlatformFile? _fichierPdf;
  PlatformFile? _imageCouverture;

  // Aperçu URL YouTube
  String? _ytVideoId;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titreCtrl.text   = e['titre']       as String? ?? '';
      _descCtrl.text    = e['description'] as String? ?? '';
      _contenuCtrl.text = e['contenu']     as String? ?? '';
      _urlCtrl.text     = e['url_externe'] as String? ?? '';
      _type       = e['type_ressource'] as String? ?? 'article';
      _categorie  = e['categorie']      as String? ?? 'general';
      _niveau     = e['niveau']         as String? ?? 'tous';
      _isMisEnAvant = e['est_mis_en_avant'] as bool? ?? false;
      _isPublie     = e['est_publie']       as bool? ?? false;
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16)),
    child: Container(
      width: 560,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF1A56DB),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(16))),
          child: Row(children: [
            const Icon(Icons.library_add_rounded,
              color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(
              widget.existing != null
                  ? 'Modifier la ressource'
                  : 'Nouvelle ressource',
              style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: Colors.white))),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
          ])),

        // Formulaire
        Flexible(child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

            // Type de ressource
            Text('Type de ressource *',
              style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: const Color(0xFF374151))),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _TypeBtn('article',
                '📝 Article', _type,
                (v) => setState(() => _type = v)),
              _TypeBtn('pdf',
                '📄 PDF', _type,
                (v) => setState(() => _type = v)),
              _TypeBtn('video_youtube',
                '▶️ YouTube', _type,
                (v) => setState(() => _type = v)),
              _TypeBtn('video_interne',
                '🎬 Vidéo upload', _type,
                (v) => setState(() => _type = v)),
            ]),
            const SizedBox(height: 16),

            // Titre
            _ChampForm(
              ctrl: _titreCtrl,
              label: 'Titre *',
              hint: 'Ex: Réussir son CV en Guinée'),
            const SizedBox(height: 12),

            // Description
            _ChampForm(
              ctrl: _descCtrl,
              label: 'Description courte',
              hint: 'Résumé en 1-2 phrases',
              maxLines: 2),
            const SizedBox(height: 12),

            // URL YouTube (si type youtube)
            if (_type == 'video_youtube') ...[
              _ChampForm(
                ctrl: _urlCtrl,
                label: 'URL YouTube *',
                hint: 'https://www.youtube.com/watch?v=...',
                onChanged: (v) {
                  final id = YoutubePlayer.convertUrlToId(v);
                  setState(() => _ytVideoId = id);
                }),
              // Aperçu miniature
              if (_ytVideoId != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    'https://img.youtube.com/vi/$_ytVideoId/mqdefault.jpg',
                    height: 120, width: double.infinity,
                    fit: BoxFit.cover)),
                const SizedBox(height: 4),
                Text('✅ Vidéo YouTube valide',
                  style: GoogleFonts.inter(
                    fontSize: 11, color: const Color(0xFF10B981),
                    fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 12),
            ],

            // Upload PDF
            if (_type == 'pdf') ...[
              GestureDetector(
                onTap: _choisirPDF,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _fichierPdf != null
                          ? const Color(0xFF10B981)
                          : const Color(0xFFE2E8F0),
                      width: _fichierPdf != null ? 2 : 1),
                    ),
                  child: Row(children: [
                    Icon(Icons.picture_as_pdf_rounded,
                      color: _fichierPdf != null
                          ? const Color(0xFF10B981)
                          : const Color(0xFF94A3B8)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      _fichierPdf?.name ?? 'Choisir un PDF...',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: _fichierPdf != null
                            ? const Color(0xFF10B981)
                            : const Color(0xFF94A3B8)))),
                    if (_fichierPdf != null)
                      const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF10B981)),
                  ]))),
              const SizedBox(height: 12),
            ],

            // Upload vidéo interne
            if (_type == 'video_interne') ...[
              GestureDetector(
                onTap: _choisirVideo,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0))),
                  child: Row(children: [
                    const Icon(Icons.video_file_outlined,
                      color: Color(0xFF8B5CF6)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      _fichierPdf?.name ?? 'Choisir une vidéo...',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF94A3B8)))),
                  ]))),
              const SizedBox(height: 12),
            ],

            // Contenu article
            if (_type == 'article') ...[
              _ChampForm(
                ctrl: _contenuCtrl,
                label: 'Contenu de l\'article',
                hint: 'Rédigez votre article ici...',
                maxLines: 8),
              const SizedBox(height: 12),
            ],

            // Catégorie + Niveau
            Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text('Catégorie *',
                  style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151))),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _categorie,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0)))),
                  items: const [
                    DropdownMenuItem(
                      value: 'general',
                      child: Text('🗂️ Général')),
                    DropdownMenuItem(
                      value: 'cv', child: Text('📄 CV')),
                    DropdownMenuItem(
                      value: 'entretien',
                      child: Text('🎤 Entretien')),
                    DropdownMenuItem(
                      value: 'salaire',
                      child: Text('💰 Salaire')),
                    DropdownMenuItem(
                      value: 'reconversion',
                      child: Text('🔄 Reconversion')),
                    DropdownMenuItem(
                      value: 'entrepreneuriat',
                      child: Text('🚀 Entrepreneuriat')),
                  ],
                  onChanged: (v) =>
                    setState(() => _categorie = v ?? _categorie)),
              ])),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text('Niveau',
                  style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151))),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _niveau,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0)))),
                  items: const [
                    DropdownMenuItem(
                      value: 'tous', child: Text('Tous')),
                    DropdownMenuItem(
                      value: 'debutant', child: Text('Débutant')),
                    DropdownMenuItem(
                      value: 'intermediaire',
                      child: Text('Intermédiaire')),
                    DropdownMenuItem(
                      value: 'avance', child: Text('Avancé')),
                  ],
                  onChanged: (v) =>
                    setState(() => _niveau = v ?? _niveau)),
              ])),
            ]),
            const SizedBox(height: 14),

            // Toggles
            _ToggleOption(
              titre: 'Mettre en avant',
              desc:  'Afficher en tête de liste',
              valeur: _isMisEnAvant,
              couleur: const Color(0xFFF59E0B),
              onChanged: (v) =>
                setState(() => _isMisEnAvant = v)),
            const SizedBox(height: 8),
            _ToggleOption(
              titre: 'Publier maintenant',
              desc:  'Visible pour les candidats + notification',
              valeur: _isPublie,
              couleur: const Color(0xFF10B981),
              onChanged: (v) =>
                setState(() => _isPublie = v)),
          ])),
        )),

        // Boutons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler',
                style: GoogleFonts.inter(
                  color: const Color(0xFF64748B))))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(
              icon: _isSaving
                  ? const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, size: 16),
              label: Text(
                _isSaving ? 'Enregistrement...' : 'Enregistrer',
                style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56DB),
                foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
              onPressed: _isSaving ? null : _sauvegarder)),
          ])),
      ]));

  Future<void> _choisirPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf']);
    if (result?.files.isNotEmpty == true) {
      setState(() => _fichierPdf = result!.files.first);
    }
  }

  Future<void> _choisirVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video);
    if (result?.files.isNotEmpty == true) {
      setState(() => _fichierPdf = result!.files.first);
    }
  }

  Future<void> _sauvegarder() async {
    if (_titreCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Le titre est obligatoire'),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final isEdit = widget.existing != null;
      final url = isEdit
          ? '${ApiConfig.baseUrl}/api/admin/ressources/${widget.existing!['id']}'
          : '${ApiConfig.baseUrl}/api/admin/ressources';

      final request = http.MultipartRequest(
        isEdit ? 'PATCH' : 'POST', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['titre']          = _titreCtrl.text.trim();
      request.fields['description']    = _descCtrl.text.trim();
      request.fields['contenu']        = _contenuCtrl.text.trim();
      request.fields['type_ressource'] = _type;
      request.fields['categorie']      = _categorie;
      request.fields['niveau']         = _niveau;
      request.fields['url_externe']    = _urlCtrl.text.trim();
      request.fields['est_mis_en_avant'] =
        _isMisEnAvant.toString();
      request.fields['est_publie']     = _isPublie.toString();

      if (_fichierPdf?.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'fichier', _fichierPdf!.bytes!,
          filename: _fichierPdf!.name));
      }

      final streamed = await request.send();
      final res      = await http.Response.fromStream(streamed);
      final body     = jsonDecode(res.body);

      if (body['success'] == true) {
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isPublie
              ? '✅ Ressource publiée ! Candidats notifiés.'
              : '✅ Ressource enregistrée'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }
}
```

---

## 6. Admin Paramètres IA — Parcours Carrière

```dart
// Dans admin_settings_screen.dart
// Ajouter dans la section IA existante :

// Toggle Simulateur entretien
_ToggleNotif(
  icon:      Icons.psychology_rounded,
  couleur:   const Color(0xFF8B5CF6),
  titre:     'Simulateur d\'entretien IA',
  sousTitre: 'Claude génère et évalue les entretiens',
  valeur:    (_params['ia_simulateur_actif'] ?? 'true') == 'true',
  onChanged: (v) {
    final val = v ? 'true' : 'false';
    setState(() => _params['ia_simulateur_actif'] = val);
    _saveParam('ia_simulateur_actif', val);
  }),
const SizedBox(height: 12),

// Toggle Calculateur salaire
_ToggleNotif(
  icon:      Icons.calculate_rounded,
  couleur:   const Color(0xFF10B981),
  titre:     'Calculateur de salaire IA',
  sousTitre: 'Claude estime les salaires guinéens',
  valeur:    (_params['ia_calculateur_actif'] ?? 'true') == 'true',
  onChanged: (v) {
    final val = v ? 'true' : 'false';
    setState(() => _params['ia_calculateur_actif'] = val);
    _saveParam('ia_calculateur_actif', val);
  }),
```

```sql
-- Supabase : ajouter les nouveaux paramètres
INSERT INTO parametres_plateforme (cle, valeur, type_valeur, description, categorie)
VALUES
  ('ia_simulateur_actif',   'true', 'boolean',
   'Activer le simulateur d entretien IA', 'ia'),
  ('ia_calculateur_actif',  'true', 'boolean',
   'Activer le calculateur de salaire IA', 'ia')
ON CONFLICT (cle) DO NOTHING;
```

---

## Dépendances à ajouter dans pubspec.yaml

```yaml
dependencies:
  # Confetti pour les célébrations
  confetti: ^0.7.0

  # Lecteur YouTube intégré
  youtube_player_flutter: ^8.1.2

  # WebView pour autres vidéos
  webview_flutter: ^4.4.2

  # Déjà présent (vérifier) :
  # file_picker, url_launcher, http, provider
```

```bash
# Installer les dépendances
cd frontend && flutter pub get
```

---

## Critères d'Acceptation

### ✅ Scroll ressources
- [ ] Plus de collage en bas — CustomScrollView fluide
- [ ] Espacement correct entre les sections

### ✅ Illustrations simulateur
- [ ] Chaque question a une illustration thématique
- [ ] Emoji + couleur selon le type (code, équipe, stress...)
- [ ] Transition animée entre les questions

### ✅ Confetti résultats
- [ ] Score >= 60% → confetti colorés
- [ ] Analyse IA étape par étape (4 étapes)
- [ ] Détail par question avec points forts + améliorations

### ✅ Lecteur vidéo intégré
- [ ] YouTube lisible DANS la plateforme
- [ ] Aperçu miniature dans l'admin avant publication
- [ ] PDF s'ouvre dans une nouvelle fenêtre

### ✅ Admin robuste
- [ ] Dialog création avec tous les types
- [ ] Aperçu YouTube avant publication
- [ ] Toggle publier/dépublier depuis la liste
- [ ] Notification automatique à la publication

### ✅ Admin Paramètres IA
- [ ] Toggle simulateur entretien
- [ ] Toggle calculateur salaire
- [ ] Tout géré depuis Admin → Paramètres → IA

---

*PRD EmploiConnect v8.8 — Parcours Carrière v2 Animations*
*Cursor / Kirsoft AI — Phase 21*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
