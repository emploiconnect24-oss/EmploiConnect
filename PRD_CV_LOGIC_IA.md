# PRD — EmploiConnect · Logique Analyse CV + Profil IA
## Product Requirements Document v8.2
**Stack : Flutter + Node.js/Express + Supabase + RapidAPI**
**Outil : Cursor / Kirsoft AI**
**Date : Avril 2026**

---

> ### ⚠️ INSTRUCTIONS POUR CURSOR
>
> Ce PRD améliore la logique post-analyse CV et ajoute
> l'amélioration IA du texte "À propos".
> Implémenter dans l'ordre exact des sections.

---

## Table des Matières

1. [Logique post-analyse CV — Que fait l'analyse ?](#1-logique-post-analyse-cv)
2. [Mise à jour profil après analyse](#2-mise-à-jour-profil-après-analyse)
3. [Fix champ compétences — séparation correcte](#3-fix-champ-compétences)
4. [Barre de complétion réactive](#4-barre-de-complétion-réactive)
5. [Amélioration IA du texte À propos](#5-amélioration-ia-du-texte-à-propos)

---

## 1. Logique post-analyse CV

### Pourquoi on analyse le CV ?

```
OBJECTIF DE L'ANALYSE :
Quand un candidat uploade son CV → l'IA lit le fichier
et extrait automatiquement :

1. Compétences    → améliorent le score de matching
2. Expériences    → enrichissent le profil
3. Formations     → complètent le profil
4. Langues        → ajoutées au profil

APRÈS L'ANALYSE → ces données sont sauvegardées
dans cv.competences_extrait (table cv en BDD)

ENSUITE → utilisées pour calculer le score
de compatibilité avec chaque offre d'emploi

RÉSULTAT → le candidat voit des scores %
sur les offres et des recommandations pertinentes
```

### Backend — Route /api/cv/analyser — Logique complète

```javascript
// Dans backend/src/routes/cv.routes.js
// Route POST /api/cv/analyser — version complète

router.post('/analyser', auth, async (req, res) => {
  try {
    console.log('\n[/cv/analyser] ═══ NOUVELLE DEMANDE ═══');

    // Récupérer le chercheur
    const { data: chercheur } = await supabase
      .from('chercheurs_emploi')
      .select('id, competences, titre_poste, about')
      .eq('utilisateur_id', req.user.id)
      .single();

    if (!chercheur) {
      return res.status(404).json({
        success: false,
        message: 'Profil candidat non trouvé'
      });
    }

    // Récupérer le CV
    const { data: cv } = await supabase
      .from('cv')
      .select('id, fichier_url, competences_extrait, type_fichier')
      .eq('chercheur_id', chercheur.id)
      .single();

    if (!cv?.fichier_url) {
      return res.status(404).json({
        success: false,
        message: 'Aucun CV trouvé. Uploadez d\'abord votre CV.'
      });
    }

    // CAS SPÉCIAL : CV créé depuis la plateforme
    if (cv.competences_extrait?.source === 'plateforme_cv_builder') {
      const comps = cv.competences_extrait.competences || [];
      const exps  = cv.competences_extrait.experience  || [];
      const fmts  = cv.competences_extrait.formation   || [];
      const langs = cv.competences_extrait.langues     || ['Français'];

      // Mettre à jour le profil avec ces données
      await _mettreAJourProfil(
        chercheur.id, req.user.id,
        comps, exps, fmts, langs
      );

      return res.json({
        success: true,
        message: `✅ ${comps.length} compétence(s) détectée(s) depuis votre CV plateforme`,
        data: {
          competences:    comps,
          experience:     exps,
          formation:      fmts,
          langues:        langs,
          nb_competences: comps.length,
          nb_experiences: exps.length,
          nb_formations:  fmts.length,
          profil_mis_a_jour: true,
        }
      });
    }

    // CAS NORMAL : Appeler l'API Resume Parser
    console.log('[/cv/analyser] Appel API Resume Parser...');
    const { analyserCV } = require('../services/ia.service');
    const resultat = await analyserCV(cv.fichier_url);

    const nbComps = resultat.competences?.length || 0;
    const nbExps  = resultat.experience?.length  || 0;
    const nbFmts  = resultat.formation?.length   || 0;

    // Sauvegarder dans cv.competences_extrait
    if (nbComps > 0 || nbExps > 0) {
      await supabase.from('cv').update({
        competences_extrait: {
          competences: resultat.competences || [],
          experience:  resultat.experience  || [],
          formation:   resultat.formation   || [],
          langues:     resultat.langues     || ['Français'],
          source:      'api_externe',
          analyse_le:  new Date().toISOString(),
        },
        date_analyse: new Date().toISOString(),
      }).eq('id', cv.id);

      // ← IMPORTANT : Mettre à jour le profil candidat
      await _mettreAJourProfil(
        chercheur.id, req.user.id,
        resultat.competences || [],
        resultat.experience  || [],
        resultat.formation   || [],
        resultat.langues     || ['Français']
      );
    }

    // Message selon résultat
    let message;
    let conseil = null;
    if (nbComps >= 8) {
      message = `✅ Excellent ! ${nbComps} compétences et ${nbExps} expériences extraites.`;
    } else if (nbComps >= 3) {
      message = `✅ ${nbComps} compétence(s) et ${nbExps} expérience(s) détectée(s). Profil mis à jour !`;
    } else if (nbComps > 0) {
      message = `⚠️ ${nbComps} compétence(s) détectée(s). Essayez d'enrichir votre CV.`;
      conseil = 'Ajoutez une section "Compétences" claire dans votre CV pour de meilleurs résultats.';
    } else {
      message = '❌ Aucune compétence détectée dans ce CV.';
      conseil = 'Utilisez le Créateur de CV intégré pour un meilleur résultat.';
    }

    return res.json({
      success: true,
      message,
      data: {
        competences:       resultat.competences || [],
        experience:        resultat.experience  || [],
        formation:         resultat.formation   || [],
        langues:           resultat.langues     || ['Français'],
        nb_competences:    nbComps,
        nb_experiences:    nbExps,
        nb_formations:     nbFmts,
        profil_mis_a_jour: nbComps > 0,
        conseil,
      }
    });

  } catch (err) {
    console.error('[/cv/analyser] ERREUR:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});

// ── Fonction helper : mettre à jour le profil ─────────────
async function _mettreAJourProfil(
  chercheurId, userId,
  competences, experience, formation, langues
) {
  try {
    console.log('[mettreAJourProfil] Mise à jour profil...');

    // 1. Mettre à jour les compétences dans chercheurs_emploi
    // NE PAS écraser — fusionner avec les compétences existantes
    const { data: profil } = await supabase
      .from('chercheurs_emploi')
      .select('competences, experiences, formations, langues')
      .eq('id', chercheurId)
      .single();

    // Fusionner les compétences (pas écraser)
    const compsExistantes = Array.isArray(profil?.competences)
      ? profil.competences
      : [];
    const nouvellesComps = [...new Set([
      ...compsExistantes,
      ...competences
    ])];

    // Fusionner les expériences
    const expsExistantes = Array.isArray(profil?.experiences)
      ? profil.experiences : [];
    const nouvellesExps = experience.length > 0
      ? experience : expsExistantes;

    // Fusionner les formations
    const fmtsExistantes = Array.isArray(profil?.formations)
      ? profil.formations : [];
    const nouvellesFmts = formation.length > 0
      ? formation : fmtsExistantes;

    // Fusionner les langues
    const langsExistantes = Array.isArray(profil?.langues)
      ? profil.langues : ['Français'];
    const nouvellesLangs = [...new Set([
      ...langsExistantes, ...langues
    ])];

    await supabase
      .from('chercheurs_emploi')
      .update({
        competences:  nouvellesComps,
        experiences:  nouvellesExps,
        formations:   nouvellesFmts,
        langues:      nouvellesLangs,
      })
      .eq('id', chercheurId);

    console.log('[mettreAJourProfil] ✅ Profil mis à jour');
    console.log('  Compétences:', nouvellesComps.length);
    console.log('  Expériences:', nouvellesExps.length);
    console.log('  Formations:', nouvellesFmts.length);

  } catch (err) {
    console.error('[mettreAJourProfil] Erreur:', err.message);
  }
}
```

---

## 2. Mise à jour profil après analyse

### Flutter — Afficher les données mises à jour après analyse

```dart
// Dans la page Mon Profil & CV
// Améliorer la méthode _analyserCV()

Future<void> _analyserCV() async {
  setState(() => _isAnalysing = true);
  try {
    final token = context.read<AuthProvider>().token ?? '';
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/cv/analyser'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 45));

    final body = jsonDecode(res.body);

    if (body['success'] == true) {
      final data       = body['data'] as Map<String, dynamic>? ?? {};
      final nbComps    = data['nb_competences'] as int? ?? 0;
      final nbExps     = data['nb_experiences'] as int? ?? 0;
      final nbFmts     = data['nb_formations']  as int? ?? 0;
      final comps      = List<String>.from(data['competences'] ?? []);
      final exps       = List<Map<String, dynamic>>.from(
        data['experience'] ?? []);
      final fmts       = List<Map<String, dynamic>>.from(
        data['formation'] ?? []);
      final profilMaj  = data['profil_mis_a_jour'] as bool? ?? false;
      final conseil    = data['conseil']           as String?;
      final message    = body['message']           as String? ?? '';

      if (mounted) {
        // Recharger le profil complet
        await _loadProfil();

        // Couleur selon résultat
        Color snackColor;
        if (nbComps >= 5) snackColor = const Color(0xFF10B981);
        else if (nbComps > 0) snackColor = const Color(0xFFF59E0B);
        else snackColor = const Color(0xFFEF4444);

        // SnackBar avec résumé
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
              if (profilMaj) ...[
                const SizedBox(height: 4),
                Text(
                  '→ $nbComps compétence(s) · '
                  '$nbExps expérience(s) · '
                  '$nbFmts formation(s) ajoutées au profil',
                  style: GoogleFonts.inter(
                    fontSize: 11, color: Colors.white70)),
              ],
              if (conseil != null) ...[
                const SizedBox(height: 4),
                Text(conseil, style: GoogleFonts.inter(
                  fontSize: 11, color: Colors.white70)),
              ],
            ],
          ),
          backgroundColor: snackColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          action: nbComps < 3 ? SnackBarAction(
            label: 'Créer CV',
            textColor: Colors.white,
            onPressed: () =>
              context.push('/dashboard-candidat/cv/creer')) : null,
        ));

        // Afficher dialog de résumé si beaucoup de données
        if (nbComps >= 3 && profilMaj) {
          _showResultatDialog(comps, exps, fmts);
        }
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
    setState(() => _isAnalysing = false);
  }
}

// Dialog qui affiche le résumé de l'analyse
void _showResultatDialog(
  List<String> comps,
  List<Map<String, dynamic>> exps,
  List<Map<String, dynamic>> fmts,
) {
  showDialog(context: context, builder: (_) => Dialog(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20)),
    child: Container(
      width: 480,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [
              Color(0xFF1A56DB), Color(0xFF7C3AED)]),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20))),
          child: Row(children: [
            const Icon(Icons.auto_awesome_rounded,
              color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Analyse IA terminée !',
                style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: Colors.white)),
              Text('Votre profil a été mis à jour',
                style: GoogleFonts.inter(
                  fontSize: 12, color: Colors.white70)),
            ])),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
          ])),

        // Contenu
        Flexible(child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Compétences
            if (comps.isNotEmpty) ...[
              _ResultatSection(
                icon: Icons.psychology_rounded,
                titre: '🔧 ${comps.length} Compétences extraites',
                couleur: const Color(0xFF1A56DB),
                child: Wrap(
                  spacing: 6, runSpacing: 6,
                  children: comps.take(15).map((c) =>
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: const Color(0xFFBFDBFE))),
                      child: Text(c, style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w500,
                        color: const Color(0xFF1E40AF))))).toList()),
              ),
              const SizedBox(height: 16),
            ],

            // Expériences
            if (exps.isNotEmpty) ...[
              _ResultatSection(
                icon: Icons.work_outline_rounded,
                titre: '💼 ${exps.length} Expérience(s)',
                couleur: const Color(0xFF10B981),
                child: Column(children: exps.take(3).map((e) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      const Icon(Icons.circle,
                        size: 6, color: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        '${e['titre'] ?? ''} — ${e['entreprise'] ?? ''}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF374151)))),
                    ]))).toList()),
              ),
              const SizedBox(height: 16),
            ],

            // Formations
            if (fmts.isNotEmpty) ...[
              _ResultatSection(
                icon: Icons.school_outlined,
                titre: '🎓 ${fmts.length} Formation(s)',
                couleur: const Color(0xFFF59E0B),
                child: Column(children: fmts.take(3).map((f) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      const Icon(Icons.circle,
                        size: 6, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        '${f['diplome'] ?? ''} — ${f['ecole'] ?? ''}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF374151)))),
                    ]))).toList()),
              ),
            ],
          ])),
        )),

        // Bouton fermer
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56DB),
                foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
              onPressed: () => Navigator.pop(context),
              child: Text('Voir mon profil mis à jour',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700))))),
      ])));
}

class _ResultatSection extends StatelessWidget {
  final IconData icon; final String titre;
  final Color couleur; final Widget child;
  const _ResultatSection({required this.icon,
    required this.titre, required this.couleur, required this.child});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Icon(icon, size: 16, color: couleur),
      const SizedBox(width: 6),
      Text(titre, style: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w700,
        color: const Color(0xFF0F172A))),
    ]),
    const SizedBox(height: 8),
    child,
  ]);
}
```

---

## 3. Fix champ compétences — séparation correcte

### Problème : tout est mélangé dans le champ compétences

```javascript
// Dans backend/src/routes/candidat/profil.routes.js
// Route GET /api/candidat/profil — retourner les données séparées

router.get('/profil', auth, async (req, res) => {
  try {
    const { data: chercheur } = await supabase
      .from('chercheurs_emploi')
      .select(`
        id,
        titre_poste,
        about,
        competences,
        experiences,
        formations,
        langues,
        niveau_etude,
        disponibilite,
        profil_visible,
        utilisateur:utilisateur_id (
          id, nom, email, telephone, adresse, photo_url
        )
      `)
      .eq('utilisateur_id', req.user.id)
      .single();

    const { data: cv } = await supabase
      .from('cv')
      .select('id, fichier_url, nom_fichier, competences_extrait, date_analyse')
      .eq('chercheur_id', chercheur?.id)
      .single();

    // Extraire correctement chaque type de données
    // depuis cv.competences_extrait
    const cvData = cv?.competences_extrait || {};

    // Compétences = UNIQUEMENT les compétences (pas formations, pas langues)
    const competencesCV = Array.isArray(cvData.competences)
      ? cvData.competences : [];
    const competencesProfil = Array.isArray(chercheur?.competences)
      ? chercheur.competences : [];
    // Fusionner sans doublons
    const competences = [...new Set([
      ...competencesProfil,
      ...competencesCV
    ])];

    // Expériences = UNIQUEMENT les expériences
    const experiencesCV = Array.isArray(cvData.experience)
      ? cvData.experience : [];
    const experiencesProfil = Array.isArray(chercheur?.experiences)
      ? chercheur.experiences : [];
    const experiences = experiencesProfil.length > 0
      ? experiencesProfil : experiencesCV;

    // Formations = UNIQUEMENT les formations
    const formationsCV = Array.isArray(cvData.formation)
      ? cvData.formation : [];
    const formationsProfil = Array.isArray(chercheur?.formations)
      ? chercheur.formations : [];
    const formations = formationsProfil.length > 0
      ? formationsProfil : formationsCV;

    // Langues = UNIQUEMENT les langues
    const languesCV = Array.isArray(cvData.langues)
      ? cvData.langues : [];
    const languesProfil = Array.isArray(chercheur?.langues)
      ? chercheur.langues : [];
    const langues = [...new Set([
      ...languesProfil, ...languesCV,
      'Français' // Toujours inclure Français
    ])];

    // Calcul complétion (unifié)
    let pts = 0;
    const u = chercheur?.utilisateur;
    if (u?.photo_url)         pts += 15;
    if (u?.nom?.trim())       pts += 10;
    if (u?.telephone)         pts += 5;
    if (u?.adresse)           pts += 5;
    if (chercheur?.titre_poste?.trim()) pts += 10;
    if (chercheur?.about?.trim())       pts += 10;
    if (competences.length > 0)         pts += 10;
    if (cv?.fichier_url)                pts += 20;
    if (competencesCV.length > 0)       pts += 10;
    if (chercheur?.disponibilite)       pts += 5;
    const completion = Math.min(100, pts);

    return res.json({
      success: true,
      data: {
        // Infos utilisateur
        utilisateur: chercheur?.utilisateur,
        // Profil chercheur
        titre_poste:  chercheur?.titre_poste || '',
        about:        chercheur?.about || '',
        disponibilite: chercheur?.disponibilite || '',
        niveau_etude: chercheur?.niveau_etude || '',
        // ← Chaque section SÉPARÉE correctement
        competences,   // Seulement les compétences
        experiences,   // Seulement les expériences
        formations,    // Seulement les formations
        langues,       // Seulement les langues
        // CV
        cv: cv ? {
          id:           cv.id,
          fichier_url:  cv.fichier_url,
          nom_fichier:  cv.nom_fichier,
          date_analyse: cv.date_analyse,
          analyse:      cvData,
        } : null,
        // Complétion
        completion_profil: {
          pourcentage: completion,
        },
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});
```

### Flutter — Afficher chaque section séparément

```dart
// Dans la page Mon Profil & CV
// S'assurer que chaque section utilise la bonne liste

void _chargerDonnees(Map<String, dynamic> data) {
  setState(() {
    // ← Chaque variable reçoit SA liste correcte
    _competences = List<String>.from(data['competences'] ?? []);
    _experiences = List<Map<String, dynamic>>.from(
      data['experiences'] ?? []);
    _formations  = List<Map<String, dynamic>>.from(
      data['formations'] ?? []);
    _langues     = List<String>.from(data['langues'] ?? ['Français']);
    // NE JAMAIS mélanger ces listes
  });
}

// Dans le build :
// Section compétences → utiliser _competences UNIQUEMENT
// Section expériences → utiliser _experiences UNIQUEMENT
// Section formations  → utiliser _formations UNIQUEMENT
// Section langues     → utiliser _langues UNIQUEMENT
```

---

## 4. Barre de complétion réactive

```dart
// La barre doit se mettre à jour IMMÉDIATEMENT
// quand l'utilisateur modifie son profil

// Dans le provider CandidatProvider :
class CandidatProvider extends ChangeNotifier {
  int _completionPourcentage = 0;
  int get completionPourcentage => _completionPourcentage;

  // Recalculer localement sans attendre l'API
  void recalculerCompletion(Map<String, dynamic> profil) {
    int pts = 0;
    final u = profil['utilisateur'] as Map? ?? {};

    if ((u['photo_url'] as String?)?.isNotEmpty == true) pts += 15;
    if ((u['nom'] as String?)?.isNotEmpty == true)       pts += 10;
    if ((u['telephone'] as String?)?.isNotEmpty == true) pts += 5;
    if ((u['adresse'] as String?)?.isNotEmpty == true)   pts += 5;
    if ((profil['titre_poste'] as String?)?.isNotEmpty == true) pts += 10;
    if ((profil['about'] as String?)?.isNotEmpty == true)       pts += 10;

    final comps = profil['competences'] as List? ?? [];
    if (comps.isNotEmpty) pts += 10;

    final cv = profil['cv'] as Map?;
    if (cv?['fichier_url'] != null) pts += 20;

    final analyse = cv?['analyse'] as Map?;
    if ((analyse?['competences'] as List? ?? []).isNotEmpty) pts += 10;

    if ((profil['disponibilite'] as String?)?.isNotEmpty == true) pts += 5;

    _completionPourcentage = pts.clamp(0, 100);
    notifyListeners(); // ← Notifier immédiatement
  }
}

// Dans chaque page qui modifie le profil :
// Après chaque sauvegarde, appeler :
context.read<CandidatProvider>().recalculerCompletion(profilMisAJour);
```

---

## 5. Amélioration IA du texte À propos

### Backend — Route améliorer le texte

```javascript
// Dans backend/src/routes/candidat/profil.routes.js
// Route POST /api/candidat/ameliorer-apropos

router.post('/ameliorer-apropos', auth, async (req, res) => {
  try {
    const { texte_original, titre_poste, competences } = req.body;

    if (!texte_original?.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Texte original requis'
      });
    }

    // Utiliser l'API Claude via Anthropic
    // (ou n'importe quelle API IA disponible)
    const prompt =
      `Tu es un expert en rédaction de profils professionnels.\n` +
      `Améliore ce texte "À propos" pour un candidat à l'emploi.\n\n` +
      `Titre du poste : ${titre_poste || 'Non précisé'}\n` +
      `Compétences : ${(competences || []).join(', ')}\n\n` +
      `Texte original :\n"${texte_original}"\n\n` +
      `Consignes :\n` +
      `- Rendre le texte professionnel et percutant\n` +
      `- Maximum 150 mots\n` +
      `- Mettre en avant les compétences clés\n` +
      `- Ton dynamique et confiant\n` +
      `- Adapté au marché de l'emploi en Afrique (Guinée)\n` +
      `- Garder la langue française\n\n` +
      `Retourner UNIQUEMENT le texte amélioré, sans explication.`;

    // Appel à l'API Anthropic (Claude)
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type':            'application/json',
        'x-api-key':               process.env.ANTHROPIC_API_KEY || '',
        'anthropic-version':       '2023-06-01',
      },
      body: JSON.stringify({
        model:      'claude-haiku-4-5-20251001',
        max_tokens: 300,
        messages: [{
          role:    'user',
          content: prompt,
        }],
      }),
    });

    const data = await response.json();
    const texteAmeliore = data.content?.[0]?.text?.trim() || '';

    if (!texteAmeliore) {
      return res.status(500).json({
        success: false,
        message: 'Erreur lors de l\'amélioration du texte'
      });
    }

    return res.json({
      success: true,
      data: {
        texte_original,
        texte_ameliore: texteAmeliore,
      }
    });

  } catch (err) {
    console.error('[ameliorer-apropos]', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});
```

### Flutter — Bouton "Améliorer avec l'IA" dans le champ À propos

```dart
// Dans la section "À propos" de la page Mon Profil
// Ajouter un bouton IA à côté du champ texte

Widget _buildAProposSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [

    // Header section
    Row(children: [
      Text('À propos', style: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w700,
        color: const Color(0xFF0F172A))),
      const Spacer(),
      // ← Bouton améliorer avec IA
      GestureDetector(
        onTap: _ameliorerAPropos,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [
              Color(0xFF1A56DB), Color(0xFF7C3AED)]),
            borderRadius: BorderRadius.circular(100)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _isAmeliorant
                ? const SizedBox(width: 12, height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 12),
            const SizedBox(width: 5),
            Text(
              _isAmeliorant ? 'IA en cours...' : '✨ Améliorer avec l\'IA',
              style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: Colors.white)),
          ]))),
    ]),
    const SizedBox(height: 8),

    // Champ texte
    TextFormField(
      controller: _aboutCtrl,
      maxLines: 5, maxLength: 500,
      decoration: InputDecoration(
        hintText:
          'Décrivez votre profil professionnel, vos compétences '
          'et vos objectifs de carrière...',
        hintStyle: GoogleFonts.inter(
          fontSize: 13, color: const Color(0xFFCBD5E1)),
        filled: true, fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF1A56DB), width: 1.5)),
      ),
    ),
  ]);
}

bool _isAmeliorant = false;

Future<void> _ameliorerAPropos() async {
  if (_aboutCtrl.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Écrivez d\'abord quelques mots sur vous'),
      behavior: SnackBarBehavior.floating));
    return;
  }

  setState(() => _isAmeliorant = true);

  try {
    final token = context.read<AuthProvider>().token ?? '';
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/candidat/ameliorer-apropos'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'texte_original': _aboutCtrl.text.trim(),
        'titre_poste':    _titrePosteCtrl.text.trim(),
        'competences':    _competences,
      }),
    ).timeout(const Duration(seconds: 30));

    final body = jsonDecode(res.body);

    if (body['success'] == true) {
      final texteAmeliore = body['data']['texte_ameliore'] as String;

      // Afficher dialog de comparaison
      if (mounted) {
        _showComparaisonDialog(
          original:  _aboutCtrl.text.trim(),
          ameliore:  texteAmeliore,
          onAccepter: () {
            setState(() => _aboutCtrl.text = texteAmeliore);
            Navigator.pop(context);
          },
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur IA: $e'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating));
    }
  } finally {
    setState(() => _isAmeliorant = false);
  }
}

void _showComparaisonDialog({
  required String original,
  required String ameliore,
  required VoidCallback onAccepter,
}) {
  showDialog(context: context, builder: (_) => Dialog(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20)),
    child: Container(
      width: 500,
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        // Header
        Row(children: [
          const Icon(Icons.auto_awesome_rounded,
            color: Color(0xFF7C3AED), size: 22),
          const SizedBox(width: 10),
          Text('Amélioration IA', style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A))),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => Navigator.pop(context)),
        ]),
        const SizedBox(height: 16),

        // Texte amélioré
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withOpacity(0.3))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.auto_awesome_rounded,
                size: 13, color: Color(0xFF7C3AED)),
              const SizedBox(width: 6),
              Text('Version améliorée par l\'IA :',
                style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: const Color(0xFF6D28D9))),
            ]),
            const SizedBox(height: 8),
            Text(ameliore, style: GoogleFonts.inter(
              fontSize: 13, color: const Color(0xFF374151),
              height: 1.5)),
          ])),
        const SizedBox(height: 20),

        // Boutons
        Row(children: [
          Expanded(child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context),
            child: Text('Garder l\'original',
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B))))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton.icon(
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Utiliser ce texte'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white, elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
              textStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w700)),
            onPressed: onAccepter)),
        ]),
      ])));
}
```

---

## Critères d'Acceptation

### ✅ Logique post-analyse
- [ ] Après analyse → compétences sauvegardées dans `cv.competences_extrait`
- [ ] Après analyse → profil `chercheurs_emploi` mis à jour (fusion, pas écrasement)
- [ ] Dialog de résumé affiché avec compétences, expériences, formations
- [ ] Message SnackBar avec nombre de compétences/expériences ajoutées

### ✅ Séparation des données
- [ ] Section Compétences → UNIQUEMENT les compétences
- [ ] Section Expériences → UNIQUEMENT les expériences
- [ ] Section Formations → UNIQUEMENT les formations
- [ ] Section Langues → UNIQUEMENT les langues
- [ ] Aucun mélange entre les sections

### ✅ Barre complétion réactive
- [ ] Se met à jour immédiatement après modification du profil
- [ ] Même valeur dans sidebar, vue d'ensemble, page profil
- [ ] Recalcul local sans attendre l'API

### ✅ Amélioration IA À propos
- [ ] Bouton "✨ Améliorer avec l'IA" visible dans la section À propos
- [ ] Dialog de comparaison : texte original vs texte amélioré
- [ ] Bouton "Utiliser ce texte" remplace le texte
- [ ] Bouton "Garder l'original" ferme sans modification
- [ ] Indicateur de chargement pendant l'appel IA

---

*PRD EmploiConnect v8.2 — Logique CV + IA À propos*
*Cursor / Kirsoft AI — Phase 15*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
