# PRD — EmploiConnect · IA Matching Avancé + Alertes Intelligentes
## Product Requirements Document v9.11
**Date : Avril 2026**

---

## Vision

```
3 fonctionnalités majeures :

1. AVERTISSEMENT INTELLIGENT à la postulation
   → Score de compatibilité visible avant de postuler
   → Conseils IA si score faible
   → Encouragements si score fort

2. ALERTES EMAIL AUTOMATIQUES
   → Candidat reçoit un email si une offre compatible
   → Entreprise reçoit un email si un profil compatible
   → Emails riches avec aperçu + bouton action

3. EMAILS PRO AVEC APERÇU
   → L'offre s'affiche dans l'email (candidat)
   → Le profil s'affiche dans l'email (recruteur)
   → Bouton "Postuler" depuis l'email
```

---

## 1. Migration SQL

```sql
-- database/migrations/064_matching_alertes.sql

-- Table alertes matching envoyées
-- (pour éviter le spam)
CREATE TABLE IF NOT EXISTS alertes_matching_envoyees (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  candidat_id   UUID,
  offre_id      UUID,
  entreprise_id UUID,
  type_alerte   TEXT NOT NULL,
  -- types : offre_compatible, profil_compatible
  score         INTEGER,
  envoye_le     TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour éviter les doublons d'alertes
CREATE UNIQUE INDEX IF NOT EXISTS idx_alerte_unique
  ON alertes_matching_envoyees(
    candidat_id, offre_id, type_alerte
  ) WHERE candidat_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_alerte_entreprise
  ON alertes_matching_envoyees(
    entreprise_id, candidat_id, offre_id, type_alerte
  ) WHERE entreprise_id IS NOT NULL;

-- Colonne score_matching sur candidatures si absente
ALTER TABLE candidatures
  ADD COLUMN IF NOT EXISTS score_matching INTEGER,
  ADD COLUMN IF NOT EXISTS analyse_ia     JSONB,
  ADD COLUMN IF NOT EXISTS conseils_ia    TEXT;
```

---

## 2. Backend — Service Matching Avancé

```javascript
// backend/src/services/matchingAvance.service.js

const { _appellerIA, _getClesIA } =
  require('./ia.service');
const { envoyerEmail } = require('./mail.service');

// ── Analyser la compatibilité profil ↔ offre ────────────
const analyserCompatibilite = async (
    candidatId, offreId) => {
  try {
    const cles = await _getClesIA();

    // Récupérer les données du candidat
    const { data: candidat } = await supabase
      .from('chercheurs_emploi')
      .select(`
        competences, niveau_etudes, experience_annees,
        langues, domaine_activite, titre_profil,
        utilisateur:utilisateurs(nom, email)
      `)
      .eq('utilisateur_id', candidatId)
      .single();

    // Récupérer l'offre
    const { data: offre } = await supabase
      .from('offres_emploi')
      .select(`
        titre, description, competences_requises,
        niveau_etudes_requis, experience_requise,
        type_contrat, localisation, salaire_min,
        salaire_max, entreprise:entreprises(nom)
      `)
      .eq('id', offreId)
      .single();

    if (!candidat || !offre) return null;

    const prompt = `Tu es un expert en recrutement.
Analyse la compatibilité entre ce candidat et cette offre.

PROFIL CANDIDAT :
- Titre : ${candidat.titre_profil || 'Non précisé'}
- Compétences : ${JSON.stringify(candidat.competences || [])}
- Niveau études : ${candidat.niveau_etudes || 'Non précisé'}
- Expérience : ${candidat.experience_annees || 0} ans
- Domaine : ${candidat.domaine_activite || 'Non précisé'}
- Langues : ${JSON.stringify(candidat.langues || [])}

OFFRE D'EMPLOI :
- Titre : ${offre.titre}
- Entreprise : ${offre.entreprise?.nom}
- Compétences requises : ${JSON.stringify(offre.competences_requises || [])}
- Niveau études requis : ${offre.niveau_etudes_requis || 'Non précisé'}
- Expérience requise : ${offre.experience_requise || 0} ans
- Type contrat : ${offre.type_contrat}
- Localisation : ${offre.localisation}

Réponds UNIQUEMENT en JSON valide :
{
  "score": <nombre entre 0 et 100>,
  "niveau": "<excellent|bon|moyen|faible>",
  "points_forts": ["...", "..."],
  "points_faibles": ["...", "..."],
  "conseils": ["conseil 1", "conseil 2", "conseil 3"],
  "message_court": "<une phrase encourageante ou honnête>",
  "recommande_parcours": <true|false>
}`;

    const reponse = await _appellerIA(
      prompt, cles, 'matching');

    if (!reponse) return null;

    // Parser le JSON
    const clean = reponse
      .replace(/```json/g, '')
      .replace(/```/g, '')
      .trim();

    const analyse = JSON.parse(clean);

    // Sauvegarder dans la candidature si elle existe
    await supabase.from('candidatures')
      .update({
        score_matching: analyse.score,
        analyse_ia:     analyse,
        conseils_ia:    JSON.stringify(analyse.conseils),
      })
      .eq('offre_id', offreId)
      .eq('candidat_id', candidatId);

    return { analyse, candidat, offre };

  } catch (e) {
    console.error('[matching] Erreur:', e.message);
    return null;
  }
};

// ── Envoyer alerte email à un candidat ──────────────────
const envoyerAlerteOffreCandidat = async (
    candidat, offre, score) => {
  try {
    const appUrl = process.env.PUBLIC_APP_URL
      || 'http://localhost:3001';

    const couleurScore = score >= 80
      ? '#10B981' : score >= 60
      ? '#F59E0B' : '#EF4444';

    const labelScore = score >= 80
      ? '🎯 Excellent match !'
      : score >= 60
      ? '👍 Bonne compatibilité'
      : '⚠️ Compatibilité moyenne';

    await envoyerEmail({
      to:      candidat.email,
      subject: `🎯 Offre compatible avec votre profil : ${offre.titre}`,
      html: `
<div style="font-family:sans-serif;max-width:620px;margin:0 auto;">

  <!-- Header -->
  <div style="background:linear-gradient(135deg,#1A56DB,#7C3AED);
              padding:28px 32px;border-radius:12px 12px 0 0;
              text-align:center;">
    <h1 style="color:white;margin:0;font-size:24px;">
      EmploiConnect
    </h1>
    <p style="color:rgba(255,255,255,0.8);margin:6px 0 0;
              font-size:13px;">
      🇬🇳 La plateforme N°1 de l'emploi en Guinée
    </p>
  </div>

  <!-- Body -->
  <div style="background:white;padding:28px 32px;
              border:1px solid #E2E8F0;border-top:none;">

    <p style="color:#374151;font-size:15px;margin:0 0 16px;">
      Bonjour <strong>${candidat.nom}</strong> 👋
    </p>

    <p style="color:#374151;font-size:14px;line-height:1.7;
              margin:0 0 20px;">
      Notre IA a trouvé une offre qui correspond
      à votre profil. Découvrez-la !
    </p>

    <!-- Score badge -->
    <div style="text-align:center;margin:0 0 24px;">
      <div style="display:inline-block;
                  background:${couleurScore}20;
                  border:2px solid ${couleurScore};
                  border-radius:100px;
                  padding:8px 20px;">
        <span style="color:${couleurScore};
                     font-weight:800;font-size:16px;">
          ${labelScore} — ${score}% de compatibilité
        </span>
      </div>
    </div>

    <!-- Carte offre -->
    <div style="background:#F8FAFC;border-radius:12px;
                border:1px solid #E2E8F0;
                padding:20px;margin:0 0 24px;">

      <h2 style="color:#0F172A;margin:0 0 6px;
                 font-size:18px;">
        ${offre.titre}
      </h2>
      <p style="color:#1A56DB;margin:0 0 12px;
                font-size:14px;font-weight:600;">
        🏢 ${offre.entreprise?.nom || 'Entreprise'}
      </p>

      <div style="display:flex;gap:8px;flex-wrap:wrap;
                  margin:0 0 12px;">
        <span style="background:#EFF6FF;color:#1A56DB;
                     padding:4px 10px;border-radius:100px;
                     font-size:12px;font-weight:600;">
          📍 ${offre.localisation}
        </span>
        <span style="background:#F0FDF4;color:#10B981;
                     padding:4px 10px;border-radius:100px;
                     font-size:12px;font-weight:600;">
          📄 ${offre.type_contrat}
        </span>
        ${offre.salaire_min ? `
        <span style="background:#FFF7ED;color:#F59E0B;
                     padding:4px 10px;border-radius:100px;
                     font-size:12px;font-weight:600;">
          💰 ${offre.salaire_min.toLocaleString()} GNF+
        </span>` : ''}
      </div>

      <p style="color:#64748B;font-size:13px;
                line-height:1.6;margin:0;">
        ${(offre.description || '').substring(0, 200)}...
      </p>
    </div>

    <!-- CTA -->
    <div style="text-align:center;margin:0 0 20px;">
      <a href="${appUrl}/offres/${offre.id}"
         style="background:#1A56DB;color:white;
                padding:14px 32px;text-decoration:none;
                border-radius:8px;font-weight:700;
                font-size:15px;display:inline-block;">
        Voir l'offre et postuler →
      </a>
    </div>

    <p style="color:#94A3B8;font-size:12px;
              text-align:center;margin:0;">
      Cette recommandation est basée sur votre profil.
      Plus votre profil est complet, meilleures sont
      les recommandations.
    </p>
  </div>

  <!-- Footer -->
  <div style="background:#F8FAFC;padding:16px;
              text-align:center;font-size:11px;
              color:#94A3B8;
              border-radius:0 0 12px 12px;">
    © 2025 EmploiConnect · Conakry, Guinée<br>
    <a href="${appUrl}/preferences"
       style="color:#94A3B8;">
      Gérer mes alertes
    </a>
  </div>
</div>`,
    });

    // Marquer l'alerte comme envoyée
    await supabase.from('alertes_matching_envoyees').insert({
      candidat_id: candidat.id,
      offre_id:    offre.id,
      type_alerte: 'offre_compatible',
      score,
    });

    console.log('[alerte] ✅ Email offre envoyé à:',
      candidat.email);

  } catch (e) {
    console.error('[alerte] Erreur:', e.message);
  }
};

// ── Envoyer alerte profil à une entreprise ───────────────
const envoyerAlerteProfilEntreprise = async (
    entreprise, candidat, offre, score) => {
  try {
    const appUrl = process.env.PUBLIC_APP_URL
      || 'http://localhost:3001';

    await envoyerEmail({
      to:      entreprise.email,
      subject: `👤 Profil compatible détecté : ${offre.titre}`,
      html: `
<div style="font-family:sans-serif;max-width:620px;margin:0 auto;">

  <!-- Header -->
  <div style="background:linear-gradient(135deg,#0D1B3E,#1A56DB);
              padding:28px 32px;border-radius:12px 12px 0 0;
              text-align:center;">
    <h1 style="color:white;margin:0;font-size:24px;">
      EmploiConnect
    </h1>
    <p style="color:rgba(255,255,255,0.7);margin:6px 0 0;
              font-size:13px;">
      Espace Recruteur
    </p>
  </div>

  <!-- Body -->
  <div style="background:white;padding:28px 32px;
              border:1px solid #E2E8F0;border-top:none;">

    <p style="color:#374151;font-size:15px;margin:0 0 16px;">
      Bonjour <strong>${entreprise.nom}</strong> 👋
    </p>

    <p style="color:#374151;font-size:14px;
              line-height:1.7;margin:0 0 20px;">
      Notre IA a identifié un profil correspondant
      à votre offre <strong>${offre.titre}</strong>.
    </p>

    <!-- Score -->
    <div style="text-align:center;margin:0 0 24px;">
      <div style="display:inline-block;
                  background:#10B98120;
                  border:2px solid #10B981;
                  border-radius:100px;
                  padding:8px 20px;">
        <span style="color:#10B981;font-weight:800;
                     font-size:16px;">
          🎯 ${score}% de compatibilité
        </span>
      </div>
    </div>

    <!-- Carte candidat (anonymisée) -->
    <div style="background:#F8FAFC;border-radius:12px;
                border:1px solid #E2E8F0;
                padding:20px;margin:0 0 24px;">

      <div style="display:flex;align-items:center;
                  gap:14px;margin:0 0 14px;">
        <div style="width:48px;height:48px;
                    background:linear-gradient(
                      135deg,#1A56DB,#7C3AED);
                    border-radius:50%;display:flex;
                    align-items:center;
                    justify-content:center;
                    font-size:20px;color:white;
                    font-weight:900;">
          ${candidat.nom[0]}
        </div>
        <div>
          <h3 style="margin:0;color:#0F172A;
                     font-size:16px;">
            ${candidat.titre_profil || 'Candidat'}
          </h3>
          <p style="margin:2px 0 0;color:#64748B;
                    font-size:13px;">
            ${candidat.experience_annees || 0} ans
            d'expérience •
            ${candidat.niveau_etudes || 'Non précisé'}
          </p>
        </div>
      </div>

      <!-- Compétences -->
      ${candidat.competences?.length > 0 ? `
      <div style="margin:0 0 12px;">
        <p style="color:#374151;font-size:12px;
                  font-weight:700;margin:0 0 6px;">
          Compétences clés :
        </p>
        <div>
          ${(candidat.competences || []).slice(0, 5)
            .map(c => `
            <span style="background:#EFF6FF;color:#1A56DB;
                         padding:3px 8px;border-radius:4px;
                         font-size:11px;font-weight:600;
                         margin-right:4px;margin-bottom:4px;
                         display:inline-block;">
              ${c}
            </span>`).join('')}
        </div>
      </div>` : ''}

      <p style="color:#94A3B8;font-size:11px;
                margin:8px 0 0;font-style:italic;">
        * Identité complète disponible sur la plateforme
      </p>
    </div>

    <!-- CTA -->
    <div style="text-align:center;margin:0 0 20px;">
      <a href="${appUrl}/recruteur/candidatures?offre=${offre.id}"
         style="background:#1A56DB;color:white;
                padding:14px 32px;text-decoration:none;
                border-radius:8px;font-weight:700;
                font-size:15px;display:inline-block;">
        Voir le profil complet →
      </a>
    </div>
  </div>

  <!-- Footer -->
  <div style="background:#F8FAFC;padding:16px;
              text-align:center;font-size:11px;
              color:#94A3B8;
              border-radius:0 0 12px 12px;">
    © 2025 EmploiConnect · Conakry, Guinée
  </div>
</div>`,
    });

    await supabase.from('alertes_matching_envoyees').insert({
      entreprise_id: entreprise.id,
      candidat_id:   candidat.id,
      offre_id:      offre.id,
      type_alerte:   'profil_compatible',
      score,
    });

    console.log('[alerte] ✅ Email profil envoyé à:',
      entreprise.email);

  } catch (e) {
    console.error('[alerte] Erreur:', e.message);
  }
};

// ── Vérifier et envoyer les alertes pour une nouvelle offre
const traiterAlertesNouvelleOffre = async (offreId) => {
  try {
    console.log('[matching] Traitement alertes offre:',
      offreId);

    // Récupérer l'offre
    const { data: offre } = await supabase
      .from('offres_emploi')
      .select(`*, entreprise:entreprises(nom, email)`)
      .eq('id', offreId)
      .single();

    if (!offre) return;

    // Récupérer tous les candidats actifs
    const { data: candidats } = await supabase
      .from('chercheurs_emploi')
      .select(`
        utilisateur_id, competences,
        niveau_etudes, experience_annees,
        titre_profil, domaine_activite,
        utilisateur:utilisateurs(id, nom, email, est_actif)
      `)
      .limit(50); // Traiter par batch

    const cles = await _getClesIA();
    let nbAlertes = 0;

    for (const candidat of (candidats || [])) {
      try {
        if (!candidat.utilisateur?.est_actif) continue;
        if (!candidat.utilisateur?.email) continue;

        // Vérifier si alerte déjà envoyée
        const { data: dejaEnvoyee } = await supabase
          .from('alertes_matching_envoyees')
          .select('id')
          .eq('candidat_id', candidat.utilisateur_id)
          .eq('offre_id', offreId)
          .single();

        if (dejaEnvoyee) continue;

        // Calculer le score rapidement
        const score = await _calculerScoreRapide(
          candidat, offre, cles);

        // Envoyer seulement si score >= 70
        if (score >= 70) {
          await envoyerAlerteOffreCandidat(
            {
              id:    candidat.utilisateur_id,
              nom:   candidat.utilisateur.nom,
              email: candidat.utilisateur.email,
            },
            offre,
            score);
          nbAlertes++;

          // Pause entre les envois (anti-spam)
          await new Promise(r => setTimeout(r, 1000));
        }

      } catch (e) {
        console.warn('[matching] Candidat erreur:', e.message);
      }
    }

    console.log(`[matching] ✅ ${nbAlertes} alertes envoyées`
      + ` pour offre: ${offre.titre}`);

  } catch (e) {
    console.error('[matching] traiterAlertes:', e.message);
  }
};

// ── Score rapide (sans appel IA complet) ────────────────
const _calculerScoreRapide = async (candidat, offre, cles) => {
  try {
    const competencesCandidats = new Set(
      (candidat.competences || [])
        .map(c => c.toLowerCase()));
    const competencesOffre = new Set(
      (offre.competences_requises || [])
        .map(c => c.toLowerCase()));

    // Score basé sur les compétences
    let scoreComp = 0;
    if (competencesOffre.size > 0) {
      let match = 0;
      competencesOffre.forEach(c => {
        if (competencesCandidats.has(c)) match++;
      });
      scoreComp = (match / competencesOffre.size) * 60;
    } else {
      scoreComp = 40; // Pas de compétences requises
    }

    // Score expérience
    const expReq = parseInt(
      offre.experience_requise || '0');
    const expCandidat = candidat.experience_annees || 0;
    const scoreExp = expCandidat >= expReq
        ? 25 : Math.max(0,
          25 - (expReq - expCandidat) * 5);

    // Score domaine
    const scoreDomaine =
      candidat.domaine_activite &&
      offre.description?.toLowerCase()
        .includes(
          candidat.domaine_activite.toLowerCase())
        ? 15 : 5;

    return Math.min(100,
      Math.round(scoreComp + scoreExp + scoreDomaine));

  } catch (_) {
    return 0;
  }
};

module.exports = {
  analyserCompatibilite,
  envoyerAlerteOffreCandidat,
  envoyerAlerteProfilEntreprise,
  traiterAlertesNouvelleOffre,
  _calculerScoreRapide,
};
```

---

## 3. Backend — Intégrer dans la route de candidature

```javascript
// backend/src/routes/candidat/candidatures.js

const {
  analyserCompatibilite
} = require('../../services/matchingAvance.service');

// GET /api/candidat/offres/:offreId/analyse
// Appelé AVANT de postuler pour afficher le score
router.get('/offres/:offreId/analyse',
  auth, async (req, res) => {
  try {
    const { offreId } = req.params;
    const candidatId  = req.user.id;

    const resultat = await analyserCompatibilite(
      candidatId, offreId);

    if (!resultat) {
      return res.json({
        success: true,
        data: {
          score:   null,
          message: 'Analyse non disponible',
        }
      });
    }

    return res.json({
      success: true,
      data: {
        score:              resultat.analyse.score,
        niveau:             resultat.analyse.niveau,
        message_court:      resultat.analyse.message_court,
        points_forts:       resultat.analyse.points_forts,
        points_faibles:     resultat.analyse.points_faibles,
        conseils:           resultat.analyse.conseils,
        recommande_parcours: resultat.analyse.recommande_parcours,
      }
    });

  } catch (err) {
    res.status(500).json({
      success: false, message: err.message });
  }
});

// Dans la route POST de publication d'offre
// Déclencher les alertes après publication
router.post('/offres', auth, async (req, res) => {
  // ... création de l'offre existante ...

  // Après création réussie :
  if (data?.id) {
    // Traiter les alertes en arrière-plan
    setImmediate(async () => {
      try {
        const {
          traiterAlertesNouvelleOffre
        } = require('../../services/matchingAvance.service');
        await traiterAlertesNouvelleOffre(data.id);
      } catch (_) {}
    });
  }
});
```

---

## 4. Flutter — Dialog avertissement avant postulation

```dart
// frontend/lib/widgets/dialog_analyse_postulation.dart

class DialogAnalysePostulation extends StatefulWidget {
  final String offreId;
  final String offreTitre;
  final VoidCallback onConfirmerPostulation;

  const DialogAnalysePostulation({
    super.key,
    required this.offreId,
    required this.offreTitre,
    required this.onConfirmerPostulation,
  });

  @override
  State<DialogAnalysePostulation> createState() =>
    _DialogAnalyseState();
}

class _DialogAnalyseState
    extends State<DialogAnalysePostulation> {

  Map<String, dynamic>? _analyse;
  bool _isLoading = true;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _chargerAnalyse();
  }

  Future<void> _chargerAnalyse() async {
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/candidat'
          '/offres/${widget.offreId}/analyse'),
        headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _analyse = body['data'];
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = _analyse?['score'] as int?;
    final niveau = _analyse?['niveau'] as String? ?? '';

    Color couleurScore = const Color(0xFF64748B);
    String emojiScore = '🤔';
    String labelScore = 'Analyse en cours';

    if (score != null) {
      if (score >= 80) {
        couleurScore = const Color(0xFF10B981);
        emojiScore = '🎯';
        labelScore = 'Excellent match !';
      } else if (score >= 60) {
        couleurScore = const Color(0xFFF59E0B);
        emojiScore = '👍';
        labelScore = 'Bonne compatibilité';
      } else if (score >= 40) {
        couleurScore = const Color(0xFFF97316);
        emojiScore = '⚠️';
        labelScore = 'Compatibilité moyenne';
      } else {
        couleurScore = const Color(0xFFEF4444);
        emojiScore = '❗';
        labelScore = 'Faible compatibilité';
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 460,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(children: [

          // Header coloré
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  couleurScore.withOpacity(0.8),
                  couleurScore,
                ]),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20))),
            child: Row(children: [
              Text(emojiScore,
                style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text('Analyse IA',
                  style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.white70)),
                Text(labelScore,
                  style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w800,
                    color: Colors.white)),
                if (score != null)
                  Text('${score}% de compatibilité',
                    style: GoogleFonts.inter(
                      fontSize: 13, color: Colors.white70)),
              ])),
              IconButton(
                icon: const Icon(Icons.close_rounded,
                  color: Colors.white70),
                onPressed: () => Navigator.pop(context)),
            ])),

          // Contenu scrollable
          Expanded(child: _isLoading
              ? const Center(child:
                  CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                      CrossAxisAlignment.start,
                    children: [

                    // Offre concernée
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius:
                          BorderRadius.circular(8)),
                      child: Row(children: [
                        const Icon(Icons.work_outline_rounded,
                          color: Color(0xFF1A56DB), size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          widget.offreTitre,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700))),
                      ])),
                    const SizedBox(height: 16),

                    // Message IA
                    if (_analyse?['message_court'] != null)
                      Text(
                        _analyse!['message_court'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF374151),
                          height: 1.5)),

                    // Points forts
                    if ((_analyse?['points_forts']
                          as List?)?.isNotEmpty == true) ...[
                      const SizedBox(height: 16),
                      _TitreSection('✅ Points forts',
                        const Color(0xFF10B981)),
                      const SizedBox(height: 6),
                      ...(_analyse!['points_forts'] as List)
                          .map((p) => _ItemListe(
                            p as String,
                            const Color(0xFF10B981))),
                    ],

                    // Points faibles
                    if ((_analyse?['points_faibles']
                          as List?)?.isNotEmpty == true) ...[
                      const SizedBox(height: 14),
                      _TitreSection('⚠️ Points à améliorer',
                        const Color(0xFFF59E0B)),
                      const SizedBox(height: 6),
                      ...(_analyse!['points_faibles'] as List)
                          .map((p) => _ItemListe(
                            p as String,
                            const Color(0xFFF59E0B))),
                    ],

                    // Conseils IA
                    if ((_analyse?['conseils']
                          as List?)?.isNotEmpty == true) ...[
                      const SizedBox(height: 14),
                      _TitreSection('💡 Conseils IA',
                        const Color(0xFF1A56DB)),
                      const SizedBox(height: 6),
                      ...(_analyse!['conseils'] as List)
                          .map((c) => _ItemListe(
                            c as String,
                            const Color(0xFF1A56DB))),
                    ],

                    // Recommandation Parcours Carrière
                    if (_analyse?['recommande_parcours']
                          == true) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius:
                            BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF8B5CF6)
                              .withOpacity(0.3))),
                        child: Row(children: [
                          const Icon(
                            Icons.school_outlined,
                            color: Color(0xFF8B5CF6),
                            size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Column(
                            crossAxisAlignment:
                              CrossAxisAlignment.start,
                            children: [
                            Text('Parcours Carrière recommandé',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF7C3AED))),
                            Text(
                              'Développez vos compétences '
                              'pour des meilleures chances.',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF7C3AED))),
                          ])),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              context.go('/parcours');
                            },
                            child: Text('Voir',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF7C3AED)))),
                        ])),
                    ],
                  ]))),

          // Boutons action
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xFFE2E8F0)))),
            child: Row(children: [
              // Bouton annuler
              Expanded(child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B))))),
              const SizedBox(width: 10),

              // Bouton postuler
              Expanded(flex: 2, child: ElevatedButton.icon(
                icon: _isPosting
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white))
                    : const Icon(
                        Icons.send_rounded, size: 16),
                label: Text(
                  _isPosting
                      ? 'Envoi...'
                      : score != null && score < 40
                          ? 'Postuler quand même'
                          : 'Postuler maintenant',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: score != null && score < 40
                      ? const Color(0xFFF97316)
                      : const Color(0xFF1A56DB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
                onPressed: _isPosting ? null : () async {
                  setState(() => _isPosting = true);
                  Navigator.pop(context);
                  widget.onConfirmerPostulation();
                })),
            ])),
        ])));
  }
}

Widget _TitreSection(String titre, Color couleur) =>
  Text(titre, style: GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w700,
    color: couleur));

Widget _ItemListe(String texte, Color couleur) =>
  Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      Icon(Icons.arrow_right_rounded,
        color: couleur, size: 16),
      const SizedBox(width: 4),
      Expanded(child: Text(texte,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: const Color(0xFF374151),
          height: 1.4))),
    ]));
```

---

## 5. Intégrer le dialog dans le bouton Postuler

```dart
// Dans offre_detail_page.dart ou home_offres_section.dart
// Remplacer l'appel direct à postuler par :

Future<void> _postulerAvecAnalyse(
    String offreId, String offreTitre) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => DialogAnalysePostulation(
      offreId:  offreId,
      offreTitre: offreTitre,
      onConfirmerPostulation: () async {
        // Appel à la vraie route de postulation
        await _soumettrePostulation(offreId);
      }));
}

// Remplacer tous les boutons "Postuler" par :
ElevatedButton.icon(
  icon: const Icon(Icons.send_rounded, size: 14),
  label: const Text('Postuler'),
  onPressed: () => _postulerAvecAnalyse(
    offre['id'] as String,
    offre['titre'] as String)),
```

---

## Critères d'Acceptation

- [ ] Migration SQL 064
- [ ] Service matchingAvance.service.js créé
- [ ] Route GET /api/candidat/offres/:id/analyse
- [ ] Dialog analyse s'affiche avant postulation
- [ ] Score coloré (vert/jaune/orange/rouge)
- [ ] Points forts, faibles, conseils visibles
- [ ] Lien Parcours Carrière si recommandé
- [ ] Email alerte candidat (score >= 70)
- [ ] Email alerte entreprise (profil compatible)
- [ ] Email riche avec aperçu de l'offre/profil
- [ ] Anti-spam (une alerte par offre par candidat)
- [ ] Alertes déclenchées à la publication d'offre

---

*PRD EmploiConnect v9.11 — IA Matching Avancé*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
