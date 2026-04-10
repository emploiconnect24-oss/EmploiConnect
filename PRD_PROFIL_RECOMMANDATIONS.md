# PRD — EmploiConnect · Profil Candidat + Recommandations IA
## Product Requirements Document v8.3
**Stack : Flutter + Node.js/Express + Supabase**
**Outil : Cursor / Kirsoft AI**
**Date : Avril 2026**

---

> ### ⚠️ INSTRUCTIONS POUR CURSOR
> Implémenter dans l'ordre exact des sections.
> Chaque section = une fonctionnalité distincte.

---

## Table des Matières

1. [Post-analyse CV → Remplir champ À propos](#1-post-analyse-cv--remplir-champ-à-propos)
2. [Flux CV Plateforme → Profil automatique](#2-flux-cv-plateforme--profil-automatique)
3. [Ré-upload CV → Mise à jour profil automatique](#3-ré-upload-cv--mise-à-jour-profil-automatique)
4. [Modifier expériences/formations/compétences/langues](#4-modifier-expériencesformationscompétenceslangues)
5. [Design page Mon Profil & CV](#5-design-page-mon-profil--cv)
6. [Page Recommandations IA — Design grille 3 colonnes](#6-page-recommandations-ia--design-grille-3-colonnes)

---

## 1. Post-analyse CV → Remplir champ À propos

### Backend — Extraire le "profil/résumé" du CV analysé

```javascript
// Dans backend/src/services/ia.service.js
// Dans _extraireDonnees(), ajouter l'extraction du résumé profil

const _extraireDonnees = (data) => {
  // ... code existant ...

  // ← NOUVEAU : Extraire le résumé/profil du CV
  const resumeProfil =
    data.summary         ||
    data.profile         ||
    data.professional_summary ||
    data.about           ||
    data.personal_info?.summary ||
    data.personal_info?.profile ||
    data.objective       ||
    '';

  return {
    competences: compsFinal,
    experience,
    formation,
    langues: [...new Set(langues)],
    resume_profil: resumeProfil, // ← Retourner le résumé
    fallback: false,
  };
};
```

### Backend — Utiliser le résumé dans /api/cv/analyser

```javascript
// Dans backend/src/routes/cv.routes.js
// Route POST /api/cv/analyser
// Après avoir obtenu resultat de analyserCV() :

// Résumé profil : limiter à 500 caractères max
// et résumer avec l'IA si trop long
let resumeAPropos = resultat.resume_profil || '';

if (resumeAPropos.length > 500) {
  // Résumer automatiquement avec l'IA
  try {
    resumeAPropos = await _resumerTexte(resumeAPropos, 500);
  } catch (_) {
    resumeAPropos = resumeAPropos.substring(0, 500);
  }
}

// Mettre à jour le champ "about" du profil si vide
if (resumeAPropos && resumeAPropos.trim().length > 20) {
  const { data: profilActuel } = await supabase
    .from('chercheurs_emploi')
    .select('about')
    .eq('id', chercheur.id)
    .single();

  // Mettre à jour seulement si about est vide
  if (!profilActuel?.about?.trim()) {
    await supabase
      .from('chercheurs_emploi')
      .update({ about: resumeAPropos })
      .eq('id', chercheur.id);

    console.log('[analyser] À propos mis à jour depuis CV');
  }
}

// Retourner dans la réponse
return res.json({
  success: true,
  message,
  data: {
    competences:       resultat.competences || [],
    experience:        resultat.experience  || [],
    formation:         resultat.formation   || [],
    langues:           resultat.langues     || ['Français'],
    resume_profil:     resumeAPropos,        // ← Nouveau
    nb_competences:    nbComps,
    nb_experiences:    nbExps,
    profil_mis_a_jour: true,
    conseil,
  }
});

// ── Fonction helper : résumer un texte ─────────────────────
async function _resumerTexte(texte, maxChars = 500) {
  // Utiliser Claude API pour résumer
  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type':      'application/json',
      'x-api-key':         process.env.ANTHROPIC_API_KEY || '',
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model:      'claude-haiku-4-5-20251001',
      max_tokens: 200,
      messages: [{
        role:    'user',
        content:
          `Résume ce texte de profil professionnel en maximum ${maxChars} caractères. ` +
          `Garde l'essentiel du profil. Réponds UNIQUEMENT avec le résumé, sans explication :\n\n` +
          `"${texte}"`,
      }],
    }),
  });
  const data = await response.json();
  return data.content?.[0]?.text?.trim() || texte.substring(0, maxChars);
}
```

### Flutter — Mettre à jour le champ À propos après analyse

```dart
// Dans _reanalyserIA() ou après l'analyse
// Mettre à jour le champ À propos si des données arrivent

if (body['success'] == true) {
  final data        = body['data'] as Map<String, dynamic>? ?? {};
  final resumeProfil = data['resume_profil'] as String?;

  // Si un résumé profil a été extrait du CV
  if (resumeProfil != null && resumeProfil.isNotEmpty) {
    // Mettre à jour le champ À propos
    setState(() {
      // Ne remplacer que si le champ est vide
      if (_aboutCtrl.text.trim().isEmpty) {
        _aboutCtrl.text = resumeProfil;
      }
    });
  }

  // Recharger le profil complet
  await _loadProfil();
}
```

---

## 2. Flux CV Plateforme → Profil automatique

### Logique complète

```
Candidat crée CV depuis le wizard
        ↓
Remplit : nom, titre, compétences, expériences, formations
        ↓
Clique "Télécharger PDF"
        ↓
Backend génère le PDF
        ↓
AUTOMATIQUEMENT :
  → Sauvegarde les données dans cv.competences_extrait
    avec source = 'plateforme_cv_builder'
  → Met à jour chercheurs_emploi :
    * titre_poste = titre saisi
    * about = résumé saisi (max 500 chars)
    * competences = compétences saisies
    * experiences = expériences saisies
    * formations = formations saisies
    * langues = langues saisies
        ↓
Candidat voit son profil rempli automatiquement ✅
```

### Backend — Route generer-pdf : mettre à jour le profil

```javascript
// Dans backend/src/routes/candidat/cv.routes.js
// Route POST /api/candidat/cv/generer-pdf
// APRÈS avoir généré et uploadé le PDF, ajouter :

// ── Mettre à jour le profil avec les données du CV ────────
console.log('[generer-pdf] Mise à jour profil...');

// Préparer les données
const competencesTexte = Array.isArray(competences)
  ? competences.map(c => typeof c === 'string' ? c : c.nom || '')
  : [];

const experiencesFormattees = Array.isArray(experiences)
  ? experiences.map(e => ({
      titre:       e.titre      || '',
      entreprise:  e.entreprise || '',
      date_debut:  e.date_debut || '',
      date_fin:    e.date_fin   || null,
      en_poste:    e.en_poste   || false,
      description: e.description || '',
    }))
  : [];

const formationsFormattees = Array.isArray(formations)
  ? formations.map(f => ({
      diplome:  f.diplome  || '',
      ecole:    f.ecole    || '',
      annee:    f.annee    || '',
    }))
  : [];

const languesFinales = Array.isArray(langues) && langues.length > 0
  ? langues : ['Français'];

// Résumer le texte "résumé" si trop long
let aboutFinal = (resume || '').substring(0, 500);

// Mettre à jour chercheurs_emploi
await supabase
  .from('chercheurs_emploi')
  .update({
    titre_poste:  titre?.trim() || '',
    about:        aboutFinal,
    competences:  competencesTexte,
    experiences:  experiencesFormattees,
    formations:   formationsFormattees,
    langues:      languesFinales,
  })
  .eq('id', chercheurId);

// Sauvegarder dans cv.competences_extrait
await supabase.from('cv').upsert({
  chercheur_id:  chercheurId,
  fichier_url:   signData?.signedUrl || '',
  nom_fichier:   `CV_${nom.replace(/ /g, '_')}.pdf`,
  type_fichier:  'PDF',
  date_upload:   new Date().toISOString(),
  date_analyse:  new Date().toISOString(),
  competences_extrait: {
    competences: competencesTexte,
    experience:  experiencesFormattees,
    formation:   formationsFormattees,
    langues:     languesFinales,
    source:      'plateforme_cv_builder',
    resume:      aboutFinal,
    analyse_le:  new Date().toISOString(),
  },
}, { onConflict: 'chercheur_id' });

console.log('[generer-pdf] ✅ Profil mis à jour automatiquement');
console.log('  Compétences:', competencesTexte.length);
console.log('  Expériences:', experiencesFormattees.length);

return res.json({
  success: true,
  message: 'CV généré et profil mis à jour automatiquement !',
  data: {
    pdf_url:          signData?.signedUrl,
    nom_fichier:      `CV_${nom.replace(/ /g, '_')}.pdf`,
    profil_mis_a_jour: true,
  }
});
```

### Flutter — Message après téléchargement CV

```dart
// Dans le wizard créateur CV, après _genererPDF() :

if (body['success'] == true && body['data']['profil_mis_a_jour'] == true) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      const Icon(Icons.check_circle_rounded,
        color: Colors.white, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(
        '✅ CV téléchargé ! Votre profil a été mis à jour automatiquement.',
        style: GoogleFonts.inter(color: Colors.white))),
    ]),
    backgroundColor: const Color(0xFF10B981),
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10)),
    margin: const EdgeInsets.all(16),
  ));
}
```

---

## 3. Ré-upload CV → Mise à jour profil automatique

```javascript
// Dans backend/src/routes/cv.routes.js
// Route POST /api/cv/upload (upload d'un nouveau CV)
// Après l'upload réussi, lancer l'analyse IA en arrière-plan

// Lancer l'analyse automatiquement après upload
setImmediate(async () => {
  try {
    console.log('[uploadCV] Analyse automatique en arrière-plan...');
    const { analyserCV } = require('../services/ia.service');
    const resultat = await analyserCV(cvUrl);

    if ((resultat.competences?.length || 0) > 0) {
      // Sauvegarder les résultats
      await supabase.from('cv').update({
        competences_extrait: {
          competences: resultat.competences || [],
          experience:  resultat.experience  || [],
          formation:   resultat.formation   || [],
          langues:     resultat.langues     || ['Français'],
          resume_profil: resultat.resume_profil || '',
          source:      'api_externe',
          analyse_le:  new Date().toISOString(),
        },
        date_analyse: new Date().toISOString(),
      }).eq('id', cvId);

      // Mettre à jour le profil chercheur
      await _mettreAJourProfilDepuisAnalyse(
        chercheurId, req.user.id, resultat);

      console.log('[uploadCV] ✅ Analyse auto OK:',
        resultat.competences.length, 'compétences');
    }
  } catch (e) {
    console.warn('[uploadCV] Analyse auto non bloquante:', e.message);
  }
});

// Répondre immédiatement sans attendre l'analyse
return res.status(201).json({
  success: true,
  message: 'CV uploadé ! Analyse IA en cours...',
  data: { id: cvId, fichier_url: cvUrl, nom_fichier: nomOriginal }
});
```

---

## 4. Modifier expériences/formations/compétences/langues

### Flutter — Dialogs de modification

```dart
// Dans la page Mon Profil & CV
// Ajouter un bouton MODIFIER à côté de chaque item

// ── Item Expérience avec boutons modifier + supprimer ────

class _ExperienceItem extends StatelessWidget {
  final Map<String, dynamic> experience;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExperienceItem({
    required this.experience, required this.index,
    required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final titre  = experience['titre']      as String? ?? '';
    final ent    = experience['entreprise'] as String? ?? '';
    final debut  = experience['date_debut'] as String? ?? '';
    final fin    = experience['date_fin']   as String? ?? '';
    final enPoste = experience['en_poste']  as bool? ?? false;
    final desc   = experience['description'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.work_outline_rounded,
              color: Color(0xFF1A56DB), size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titre, style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A))),
            Text(ent, style: GoogleFonts.inter(
              fontSize: 12, color: const Color(0xFF1A56DB))),
          ])),
          // Bouton modifier
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6)),
              child: Row(children: [
                const Icon(Icons.edit_outlined,
                  size: 13, color: Color(0xFF1A56DB)),
                const SizedBox(width: 4),
                Text('Modifier', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A56DB))),
              ]))),
          const SizedBox(width: 6),
          // Bouton supprimer
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(6)),
              child: Row(children: [
                const Icon(Icons.delete_outline_rounded,
                  size: 13, color: Color(0xFFEF4444)),
                const SizedBox(width: 4),
                Text('Supprimer', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: const Color(0xFFEF4444))),
              ]))),
        ]),

        // Dates
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.calendar_today_outlined,
            size: 12, color: Color(0xFF94A3B8)),
          const SizedBox(width: 4),
          Text(
            enPoste
                ? '${_formatDate(debut)} → Aujourd\'hui'
                : '${_formatDate(debut)} → ${_formatDate(fin)}',
            style: GoogleFonts.inter(
              fontSize: 11, color: const Color(0xFF94A3B8))),
        ]),

        // Description
        if (desc.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(desc, style: GoogleFonts.inter(
            fontSize: 12, color: const Color(0xFF64748B),
            height: 1.4),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ]),
    );
  }

  String _formatDate(String? d) {
    if (d == null || d.isEmpty) return '—';
    try {
      final dt = DateTime.parse(d);
      return '${dt.month}/${dt.year}';
    } catch (_) { return d; }
  }
}

// ── Appeler les dialogs existants avec les données à modifier ─

void _modifierExperience(int index) {
  // Appeler le dialog avec les données existantes
  _showDialogExperience(context, _experiences[index], index: index);
}

void _showDialogExperience(
  BuildContext context,
  Map<String, dynamic>? existing, {int? index}
) {
  // ... code du dialog (déjà dans PRD_CANDIDAT_POLISH.md)
  // Ajouter le paramètre index pour savoir si c'est une modification
  final isEdit = index != null;

  // Dans onConfirm du dialog :
  // Si isEdit → remplacer l'item existant
  // Si !isEdit → ajouter à la liste

  // onConfirm:
  Navigator.pop(ctx);
  if (isEdit) {
    setState(() => _experiences[index!] = nouvelleDonnee);
  } else {
    setState(() => _experiences.add(nouvelleDonnee));
  }
  _sauvegarder(); // Sauvegarder immédiatement
}

// Même logique pour formations, compétences, langues
```

---

## 5. Design page Mon Profil & CV

### Structure améliorée

```dart
// Dans profil_cv_page.dart
// Améliorer le design global

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF8FAFC),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator(
            color: Color(0xFF1A56DB)))
        : RefreshIndicator(
            onRefresh: _loadProfil,
            color: const Color(0xFF1A56DB),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(children: [

                // ── Complétion globale ──────────────────
                _buildCompletionCard(),
                const SizedBox(height: 16),

                // ── Photo & Identité ────────────────────
                _buildPhotoIdentiteCard(),
                const SizedBox(height: 16),

                // ── À propos ────────────────────────────
                _buildAProposCard(),
                const SizedBox(height: 16),

                // ── CV Upload + Analyse ─────────────────
                _buildCVCard(),
                const SizedBox(height: 16),

                // ── Expériences ─────────────────────────
                _buildSectionCard(
                  titre: 'Expériences professionnelles',
                  icon: Icons.work_outline_rounded,
                  couleur: const Color(0xFF1A56DB),
                  items: _experiences,
                  onAjouter: () =>
                    _showDialogExperience(context, null),
                  itemBuilder: (exp, i) => _ExperienceItem(
                    experience: exp, index: i,
                    onEdit:   () => _modifierExperience(i),
                    onDelete: () => _supprimerExperience(i)),
                ),
                const SizedBox(height: 16),

                // ── Formations ──────────────────────────
                _buildSectionCard(
                  titre: 'Formations',
                  icon: Icons.school_outlined,
                  couleur: const Color(0xFFF59E0B),
                  items: _formations,
                  onAjouter: () =>
                    _showDialogFormation(context, null),
                  itemBuilder: (fmt, i) => _FormationItem(
                    formation: fmt, index: i,
                    onEdit:   () => _modifierFormation(i),
                    onDelete: () => _supprimerFormation(i)),
                ),
                const SizedBox(height: 16),

                // ── Compétences ─────────────────────────
                _buildCompetencesCard(),
                const SizedBox(height: 16),

                // ── Langues ─────────────────────────────
                _buildLanguesCard(),
                const SizedBox(height: 16),

                // ── Bouton sauvegarder ──────────────────
                _buildBoutonSauvegarder(),
              ])),
          ));
}

// ── Card Complétion ──────────────────────────────────────────
Widget _buildCompletionCard() {
  final pct = _completionPourcentage;
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: pct >= 80
            ? [const Color(0xFF059669), const Color(0xFF10B981)]
            : pct >= 50
                ? [const Color(0xFF1A56DB), const Color(0xFF0EA5E9)]
                : [const Color(0xFF7C3AED), const Color(0xFF1A56DB)]),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(
        color: (pct >= 80
            ? const Color(0xFF10B981)
            : const Color(0xFF1A56DB)).withOpacity(0.25),
        blurRadius: 12, offset: const Offset(0, 4))]),
    child: Row(children: [
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Complétion du profil', style: GoogleFonts.inter(
          fontSize: 12, color: Colors.white70)),
        const SizedBox(height: 4),
        Text('$pct%', style: GoogleFonts.poppins(
          fontSize: 32, fontWeight: FontWeight.w900,
          color: Colors.white)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: pct / 100, minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation(Colors.white))),
      ])),
      const SizedBox(width: 16),
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle),
        child: Icon(
          pct >= 100
              ? Icons.verified_rounded
              : Icons.person_outline_rounded,
          color: Colors.white, size: 28)),
    ]),
  );
}

// ── Card Photo & Identité ────────────────────────────────────
Widget _buildPhotoIdentiteCard() {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Column(children: [
      // Header
      _SectionHeader(
        icon: Icons.person_outline_rounded,
        titre: 'Photo & Identité',
        couleur: const Color(0xFF1A56DB)),
      const SizedBox(height: 16),

      // Photo + champs
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Photo
        GestureDetector(
          onTap: _uploadPhoto,
          child: Stack(children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFFEFF6FF),
              backgroundImage: _photoUrl != null
                  ? NetworkImage(_photoUrl!) : null,
              child: _photoUrl == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      const Icon(Icons.add_a_photo_outlined,
                        color: Color(0xFF1A56DB), size: 20),
                      Text('Photo', style: GoogleFonts.inter(
                        fontSize: 9, color: const Color(0xFF1A56DB))),
                    ]) : null,
            ),
            if (_isUploading)
              Positioned.fill(child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black38, shape: BoxShape.circle),
                child: const Center(child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white)))),
            Positioned(bottom: 0, right: 0, child: Container(
              width: 22, height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFF1A56DB), shape: BoxShape.circle),
              child: const Icon(Icons.edit_rounded,
                color: Colors.white, size: 12))),
          ])),
        const SizedBox(width: 16),

        // Champs
        Expanded(child: Column(children: [
          _InputChamp(_nomCtrl, 'Nom complet *',
            Icons.person_outline_rounded),
          const SizedBox(height: 10),
          _InputChamp(_telCtrl, 'Téléphone',
            Icons.phone_outlined),
          const SizedBox(height: 10),
          _InputChamp(_villeCtrl, 'Ville / Adresse',
            Icons.location_on_outlined),
          const SizedBox(height: 10),
          _InputChamp(_titrePosteCtrl, 'Titre professionnel',
            Icons.work_outline_rounded),
        ])),
      ]),
    ]),
  );
}

// ── Widget helper : header de section ───────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon; final String titre; final Color couleur;
  final VoidCallback? onAjouter;
  const _SectionHeader({required this.icon, required this.titre,
    required this.couleur, this.onAjouter});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: couleur, size: 16)),
    const SizedBox(width: 10),
    Expanded(child: Text(titre, style: GoogleFonts.inter(
      fontSize: 15, fontWeight: FontWeight.w700,
      color: const Color(0xFF0F172A)))),
    if (onAjouter != null)
      GestureDetector(
        onTap: onAjouter,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: couleur,
            borderRadius: BorderRadius.circular(100)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.add_rounded,
              color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text('Ajouter', style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: Colors.white)),
          ]))),
  ]);
}
```

---

## 6. Page Recommandations IA — Design grille 3 colonnes

### Explication du score "30/100"

```
Score IA = score de complétion du profil pour le matching

Il est calculé ainsi :
- CV uploadé et analysé    → +20 pts
- Compétences renseignées  → +20 pts
- Titre professionnel      → +15 pts
- À propos rempli          → +15 pts
- Expériences              → +15 pts
- Formations               → +10 pts
- Photo                    → +5 pts

Total = /100

30/100 signifie que le profil est peu rempli
→ L'IA a peu d'infos pour faire de bonnes recommandations
→ Plus le score est élevé → meilleures recommandations
```

### Flutter — Page Recommandations IA redesignée

```dart
// frontend/lib/screens/candidat/pages/recommandations_ia_page.dart

class RecommandationsIAPage extends StatefulWidget {
  const RecommandationsIAPage({super.key});
  @override
  State<RecommandationsIAPage> createState() =>
    _RecommandationsIAPageState();
}

class _RecommandationsIAPageState extends State<RecommandationsIAPage> {
  List<Map<String, dynamic>> _offres = [];
  bool _isLoading = true;
  int  _scoreIA   = 0;
  List<String> _conseils = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/candidat/recommandations'),
        headers: {'Authorization': 'Bearer $token'});
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        setState(() {
          _offres   = List<Map<String, dynamic>>.from(
            body['data']['offres'] ?? []);
          _scoreIA  = body['data']['score_profil'] as int? ?? 0;
          _conseils = List<String>.from(
            body['data']['conseils'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [

      // ── Header avec score IA ────────────────────────────
      _buildHeader(),

      // ── Conseils d'amélioration ─────────────────────────
      if (_conseils.isNotEmpty)
        _buildConseils(),

      // ── Grille des offres ───────────────────────────────
      Expanded(child: _isLoading
          ? const Center(child: CircularProgressIndicator(
              color: Color(0xFF1A56DB)))
          : _offres.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFF1A56DB),
                  child: _buildGrilleOffres())),
    ]);
  }

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
    color: Colors.white,
    child: Column(children: [
      Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [
                  Color(0xFF1A56DB), Color(0xFF7C3AED)]),
                borderRadius: BorderRadius.circular(100)),
              child: Row(children: [
                const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 11),
                const SizedBox(width: 4),
                Text('IA', style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: Colors.white)),
              ])),
            const SizedBox(width: 8),
            Text('Recommandations IA', style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A))),
          ]),
          const SizedBox(height: 4),
          Text(
            'L\'IA analyse votre profil pour vous proposer '
            'les offres les plus adaptées',
            style: GoogleFonts.inter(
              fontSize: 12, color: const Color(0xFF64748B))),
        ])),
      ]),
      const SizedBox(height: 14),

      // Score IA profil
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _scoreIA >= 70
                ? [const Color(0xFFECFDF5), const Color(0xFFF0FDF4)]
                : _scoreIA >= 40
                    ? [const Color(0xFFEFF6FF), const Color(0xFFF0F9FF)]
                    : [const Color(0xFFFEF3C7), const Color(0xFFFFFBEB)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _scoreIA >= 70
                ? const Color(0xFF10B981).withOpacity(0.3)
                : _scoreIA >= 40
                    ? const Color(0xFF1A56DB).withOpacity(0.3)
                    : const Color(0xFFF59E0B).withOpacity(0.3))),
        child: Row(children: [
          // Cercle score
          SizedBox(width: 56, height: 56,
            child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(
              value: 1.0, strokeWidth: 6,
              color: const Color(0xFFE2E8F0)),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _scoreIA / 100),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => CircularProgressIndicator(
                value: v, strokeWidth: 6,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(
                  _scoreIA >= 70
                      ? const Color(0xFF10B981)
                      : _scoreIA >= 40
                          ? const Color(0xFF1A56DB)
                          : const Color(0xFFF59E0B)))),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: _scoreIA),
              duration: const Duration(milliseconds: 1000),
              builder: (_, v, __) => Text('$v',
                style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A)))),
          ])),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Score de votre profil IA',
              style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A))),
            const SizedBox(height: 3),
            Text(
              _scoreIA >= 70
                  ? '✅ Excellent ! Votre profil attire les recruteurs'
                  : _scoreIA >= 40
                      ? '📈 Bon profil. Ajoutez des compétences pour améliorer'
                      : '⚠️ Profil incomplet. Complétez pour de meilleures offres',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: _scoreIA >= 70
                    ? const Color(0xFF065F46)
                    : _scoreIA >= 40
                        ? const Color(0xFF1E40AF)
                        : const Color(0xFF92400E),
                height: 1.4)),
            const SizedBox(height: 6),
            // Mini barre progression
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: _scoreIA / 100, minHeight: 5,
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation(
                  _scoreIA >= 70
                      ? const Color(0xFF10B981)
                      : _scoreIA >= 40
                          ? const Color(0xFF1A56DB)
                          : const Color(0xFFF59E0B)))),
          ])),
        ]),
      ),
    ]));

  Widget _buildConseils() => Container(
    margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.lightbulb_outline_rounded,
          color: Color(0xFFF59E0B), size: 16),
        const SizedBox(width: 6),
        Text('Améliorer vos suggestions',
          style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A))),
      ]),
      const SizedBox(height: 10),
      ..._conseils.map((conseil) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.1),
              shape: BoxShape.circle),
            child: const Icon(Icons.arrow_forward_rounded,
              size: 11, color: Color(0xFFF59E0B))),
          const SizedBox(width: 8),
          Expanded(child: Text(conseil,
            style: GoogleFonts.inter(
              fontSize: 12, color: const Color(0xFF374151)))),
        ]))),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: () => context.push('/dashboard-candidat/profil'),
        child: Text(
          '→ Compléter mon profil maintenant',
          style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: const Color(0xFF1A56DB),
            decoration: TextDecoration.underline))),
    ]));

  Widget _buildGrilleOffres() => SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
    child: Column(children: [
      // Titre section
      Row(children: [
        Text('${_offres.length} offre(s) recommandée(s)',
          style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B))),
      ]),
      const SizedBox(height: 12),

      // Grille 3 colonnes sur desktop, 2 sur tablette, 1 sur mobile
      LayoutBuilder(builder: (ctx, c) {
        final cols = c.maxWidth > 900 ? 3
                   : c.maxWidth > 600 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:  cols,
            crossAxisSpacing: 12,
            mainAxisSpacing:  12,
            childAspectRatio: 0.82, // ← Compact
          ),
          itemCount: _offres.length,
          itemBuilder: (ctx, i) => _OffreIACard(
            offre: _offres[i], index: i),
        );
      }),
    ]));

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF), shape: BoxShape.circle),
          child: const Icon(Icons.auto_awesome_rounded,
            color: Color(0xFF1A56DB), size: 40)),
        const SizedBox(height: 16),
        Text('Aucune recommandation disponible',
          style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A))),
        const SizedBox(height: 8),
        Text(
          'Complétez votre profil et uploadez votre CV\n'
          'pour recevoir des recommandations personnalisées.',
          style: GoogleFonts.inter(
            fontSize: 13, color: const Color(0xFF64748B),
            height: 1.5),
          textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.person_outline_rounded, size: 16),
          label: const Text('Compléter mon profil'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10))),
          onPressed: () =>
            context.push('/dashboard-candidat/profil')),
      ])));
}

// ── Carte offre IA compacte ──────────────────────────────────
class _OffreIACard extends StatefulWidget {
  final Map<String, dynamic> offre;
  final int index;
  const _OffreIACard({required this.offre, required this.index});
  @override
  State<_OffreIACard> createState() => _OffreIACardState();
}

class _OffreIACardState extends State<_OffreIACard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fade, _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 500));
    _fade  = Tween<double>(begin: 0, end: 1)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween<double>(begin: 20, end: 0)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(
      Duration(milliseconds: 80 * widget.index),
      () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final offre   = widget.offre;
    final titre   = offre['titre']       as String? ?? '';
    final ent     = offre['entreprise']  as Map?    ?? {};
    final nomEnt  = ent['nom_entreprise'] as String? ?? '';
    final logo    = ent['logo_url']       as String?;
    final loc     = offre['localisation'] as String? ?? '';
    final contrat = offre['type_contrat'] as String? ?? '';
    final score   = offre['score_compatibilite'] as int? ?? 0;

    Color sc = score >= 80
        ? const Color(0xFF10B981)
        : score >= 60
            ? const Color(0xFF1A56DB)
            : score >= 40
                ? const Color(0xFFF59E0B)
                : const Color(0xFF94A3B8);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: _fade.value,
        child: Transform.translate(
          offset: Offset(0, _slide.value),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: score >= 70
                    ? sc.withOpacity(0.3)
                    : const Color(0xFFE2E8F0)),
              boxShadow: [BoxShadow(
                color: score >= 70
                    ? sc.withOpacity(0.08)
                    : const Color(0x05000000),
                blurRadius: 10, offset: const Offset(0, 3))]),
            child: Column(children: [

              // Haut : score + logo
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                decoration: BoxDecoration(
                  color: sc.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                  // Score animé
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: score / 100),
                    duration: const Duration(milliseconds: 800),
                    builder: (_, v, __) => Row(children: [
                      SizedBox(width: 36, height: 36,
                        child: Stack(alignment: Alignment.center, children: [
                        CircularProgressIndicator(
                          value: 1.0, strokeWidth: 4,
                          color: const Color(0xFFE2E8F0)),
                        CircularProgressIndicator(
                          value: v, strokeWidth: 4,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation(sc)),
                        Text(score > 0 ? '$score%' : '—',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: sc)),
                      ])),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text(
                          score >= 80 ? 'Excellent' :
                          score >= 60 ? 'Bon' :
                          score >= 40 ? 'Moyen' : '—',
                          style: GoogleFonts.inter(
                            fontSize: 10, fontWeight: FontWeight.w700,
                            color: sc)),
                        Text('Match IA', style: GoogleFonts.inter(
                          fontSize: 8, color: const Color(0xFF94A3B8))),
                      ]),
                    ])),

                  // Logo entreprise
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6)),
                    child: logo != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(logo,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                _initLogo(nomEnt)))
                        : _initLogo(nomEnt)),
                ])),

              // Infos
              Expanded(child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(nomEnt, style: GoogleFonts.inter(
                    fontSize: 10, color: const Color(0xFF64748B)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(titre, style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A)),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Wrap(spacing: 4, runSpacing: 4, children: [
                    if (loc.isNotEmpty)
                      _MiniChip(Icons.location_on_outlined, loc),
                    if (contrat.isNotEmpty)
                      _MiniChip(Icons.work_outline_rounded, contrat),
                  ]),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A56DB),
                        foregroundColor: Colors.white, elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                        textStyle: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w700)),
                      onPressed: () => context.push(
                        '/dashboard-candidat/postuler/${offre['id']}'),
                      child: const Text('Postuler'))),
                ])),
              )),
            ]),
          ))));
  }

  Widget _initLogo(String nom) => Center(child: Text(
    nom.isNotEmpty ? nom[0].toUpperCase() : '?',
    style: GoogleFonts.poppins(
      fontSize: 13, fontWeight: FontWeight.w700,
      color: const Color(0xFF1A56DB))));
}

class _MiniChip extends StatelessWidget {
  final IconData icon; final String text;
  const _MiniChip(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(100),
      border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 9, color: const Color(0xFF94A3B8)),
      const SizedBox(width: 3),
      Text(text, style: GoogleFonts.inter(
        fontSize: 9, color: const Color(0xFF64748B))),
    ]));
}
```

### Backend — Route recommandations avec score profil et conseils

```javascript
// Dans backend/src/routes/candidat.routes.js
// Route GET /api/candidat/recommandations

router.get('/recommandations', auth, async (req, res) => {
  try {
    const { data: chercheur } = await supabase
      .from('chercheurs_emploi')
      .select('id, competences, titre_poste, about, disponibilite')
      .eq('utilisateur_id', req.user.id)
      .single();

    const { data: user } = await supabase
      .from('utilisateurs')
      .select('photo_url, nom, adresse')
      .eq('id', req.user.id)
      .single();

    const { data: cv } = await supabase
      .from('cv')
      .select('fichier_url, competences_extrait')
      .eq('chercheur_id', chercheur?.id)
      .single();

    // Calculer le score profil
    let score = 0;
    if (user?.photo_url)                          score += 5;
    if (user?.nom)                                score += 5;
    if (user?.adresse)                            score += 5;
    if (chercheur?.titre_poste)                   score += 15;
    if (chercheur?.about)                         score += 15;
    if (chercheur?.disponibilite)                 score += 5;
    const comps = Array.isArray(chercheur?.competences)
      ? chercheur.competences : [];
    if (comps.length > 0) score += 20;
    if (cv?.fichier_url)  score += 15;
    const compsCV = cv?.competences_extrait?.competences || [];
    if (compsCV.length > 0) score += 15;

    // Conseils selon ce qui manque
    const conseils = [];
    if (comps.length === 0 && compsCV.length === 0)
      conseils.push('Ajoutez vos compétences techniques à votre profil');
    if (!chercheur?.titre_poste)
      conseils.push('Renseignez votre titre professionnel');
    if (!chercheur?.about)
      conseils.push('Complétez votre section "À propos"');
    if (!cv?.fichier_url)
      conseils.push('Uploadez votre CV pour une meilleure analyse IA');
    if (!chercheur?.disponibilite)
      conseils.push('Mettez à jour votre disponibilité');
    if (!user?.adresse)
      conseils.push('Ajoutez votre localisation');

    // Récupérer les offres avec scores
    const { data: offres } = await supabase
      .from('offres_emploi')
      .select(`
        id, titre, localisation, type_contrat,
        salaire_min, salaire_max, devise,
        en_vedette, competences_requises,
        entreprise:entreprise_id (nom_entreprise, logo_url)
      `)
      .eq('statut', 'publiee')
      .order('date_publication', { ascending: false })
      .limit(12);

    // Calculer le score de matching pour chaque offre
    const offresAvecScores = await Promise.all(
      (offres || []).map(async (offre) => {
        // Chercher dans le cache
        const { data: cache } = await supabase
          .from('offres_scores_cache')
          .select('score')
          .eq('chercheur_id', chercheur?.id)
          .eq('offre_id', offre.id)
          .single();

        if (cache) {
          return { ...offre, score_compatibilite: cache.score };
        }

        // Calculer le score
        const { calculerMatchingScore } = require('../services/ia.service');
        const scoreOffre = await calculerMatchingScore(
          { competences: [...comps, ...compsCV],
            titre_poste: chercheur?.titre_poste },
          offre
        );

        // Sauvegarder dans le cache
        if (chercheur?.id) {
          await supabase.from('offres_scores_cache').upsert({
            chercheur_id: chercheur.id,
            offre_id:     offre.id,
            score:        scoreOffre,
            calcule_le:   new Date().toISOString(),
          }, { onConflict: 'chercheur_id,offre_id' });
        }

        return { ...offre, score_compatibilite: scoreOffre };
      })
    );

    // Trier par score décroissant
    offresAvecScores.sort((a, b) =>
      (b.score_compatibilite || 0) - (a.score_compatibilite || 0));

    return res.json({
      success: true,
      data: {
        offres:        offresAvecScores,
        score_profil:  Math.min(100, score),
        conseils:      conseils.slice(0, 4), // Max 4 conseils
      }
    });
  } catch (err) {
    console.error('[recommandations]', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});
```

---

## Critères d'Acceptation

### ✅ Post-analyse → À propos
- [ ] Après analyse CV → champ À propos rempli si vide
- [ ] Texte limité à 500 caractères
- [ ] IA résume si trop long

### ✅ Flux CV plateforme
- [ ] Après téléchargement PDF → profil mis à jour automatiquement
- [ ] Message de confirmation affiché

### ✅ Ré-upload CV
- [ ] Après upload → analyse automatique en arrière-plan
- [ ] Profil mis à jour sans action supplémentaire

### ✅ Modifier sections profil
- [ ] Bouton "Modifier" visible sur chaque expérience/formation
- [ ] Dialog pré-rempli avec les données existantes
- [ ] Sauvegarde immédiate après modification

### ✅ Design profil
- [ ] Card complétion avec gradient coloré
- [ ] Card photo & identité avec champs bien disposés
- [ ] Headers de sections avec icônes colorées

### ✅ Page Recommandations IA
- [ ] Grille 3 colonnes (desktop) / 2 (tablette) / 1 (mobile)
- [ ] Score profil avec cercle animé + explication
- [ ] Section conseils avec actions cliquables
- [ ] Cartes compactes avec score IA animé

---

*PRD EmploiConnect v8.3 — Profil Candidat + Recommandations IA*
*Cursor / Kirsoft AI — Phase 16*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
