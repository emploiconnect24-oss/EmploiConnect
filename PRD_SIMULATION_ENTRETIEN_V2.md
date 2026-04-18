# PRD — EmploiConnect · Simulation d'Entretien Immersive V2
## Product Requirements Document v9.12
**Date : Avril 2026**

---

## Vision

```
Une simulation d'entretien RÉALISTE où :
→ Un recruteur virtuel animé pose des questions
→ Le candidat répond par la voix OU par texte
→ L'IA analyse le profil et adapte les questions
→ Un score + rapport détaillé à la fin
→ Expérience immersive comme un vrai entretien
```

---

## Architecture technique

```
STACK :
→ Flutter Web (interface + animations)
→ Web Speech API (micro gratuit dans Chrome)
→ Browser SpeechSynthesis (voix gratuite)
→ Node.js + Claude/OpenAI (IA questions/analyse)
→ Supabase (sauvegarde sessions)

COÛT SUPPLÉMENTAIRE : 0$ (APIs gratuites du navigateur)
```

---

## 1. Migration SQL

```sql
-- database/migrations/065_simulation_entretien_v2.sql

-- Sessions de simulation
CREATE TABLE IF NOT EXISTS simulation_sessions (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  candidat_id     UUID NOT NULL,
  poste_vise      TEXT NOT NULL,
  domaine         TEXT,
  niveau          TEXT DEFAULT 'junior',
  -- junior / senior / manager
  statut          TEXT DEFAULT 'en_cours',
  -- en_cours / termine / abandonne
  messages        JSONB DEFAULT '[]',
  -- [{role: 'recruteur'|'candidat', contenu, timestamp}]
  score_final     INTEGER,
  rapport_ia      JSONB,
  -- {points_forts, points_faibles, conseils, note_globale}
  duree_secondes  INTEGER,
  nb_questions    INTEGER DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  termine_le      TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_simulation_candidat
  ON simulation_sessions(candidat_id, created_at DESC);
```

---

## 2. Backend — Service Simulation IA

```javascript
// backend/src/services/simulationEntretien.service.js

const { _appellerIA, _getClesIA } =
  require('./ia.service');

// Questions de base par domaine
const QUESTIONS_BASE = {
  presentation: [
    'Pouvez-vous vous présenter brièvement ?',
    'Parlez-moi de votre parcours professionnel.',
  ],
  motivation: [
    'Pourquoi ce poste vous intéresse-t-il ?',
    'Pourquoi souhaitez-vous rejoindre notre équipe ?',
    'Quelles sont vos motivations principales ?',
  ],
  competences: [
    'Quelles sont vos principales compétences ?',
    'Décrivez un projet dont vous êtes fier.',
    'Comment gérez-vous les défis techniques ?',
  ],
  situation: [
    'Décrivez une situation difficile que vous avez surmontée.',
    'Comment gérez-vous le travail sous pression ?',
    'Parlez-moi d\'un échec et ce que vous en avez appris.',
  ],
  projection: [
    'Où vous voyez-vous dans 5 ans ?',
    'Quels sont vos objectifs de carrière ?',
    'Comment ce poste s\'inscrit dans votre projet professionnel ?',
  ],
  fin: [
    'Avez-vous des questions pour nous ?',
    'Y a-t-il quelque chose que vous souhaitez ajouter ?',
  ],
};

// Générer la première question (avec profil)
const genererPremierMessage = async (
    posteVise, profil) => {
  try {
    const cles = await _getClesIA();

    const prompt = `Tu es un recruteur professionnel
guinéen qui conduit un entretien d'embauche.
Tu dois accueillir chaleureusement le candidat.

Poste visé : ${posteVise}
Profil candidat :
- Nom : ${profil.nom}
- Titre : ${profil.titre_profil || 'Non précisé'}
- Expérience : ${profil.experience_annees || 0} ans
- Compétences : ${JSON.stringify(profil.competences || [])}

Génère un message d'accueil court et professionnel
(2-3 phrases maximum) puis pose la première question :
"Pouvez-vous vous présenter ?"

Ton : chaleureux, professionnel, encourageant.
NE PAS inclure de markdown, juste le texte.`;

    const reponse = await _appellerIA(
      prompt, cles, 'texte');

    return reponse || `Bonjour ${profil.nom} !
Bienvenue dans cet entretien pour le poste de
${posteVise}. Je suis ravi de vous rencontrer.
Pouvez-vous commencer par vous présenter ?`;

  } catch (_) {
    return `Bonjour ! Bienvenue dans votre simulation
d'entretien pour le poste de ${posteVise}.
Pouvez-vous vous présenter s'il vous plaît ?`;
  }
};

// Générer la prochaine question selon le contexte
const genererProchainMessage = async (
    historique, posteVise, profil, nbQuestions) => {
  try {
    const cles = await _getClesIA();

    const historiqueTexte = historique
      .slice(-6) // Garder les 6 derniers messages
      .map(m => `${m.role === 'recruteur'
        ? 'Recruteur' : 'Candidat'}: ${m.contenu}`)
      .join('\n');

    const estFin = nbQuestions >= 7;

    const prompt = `Tu es un recruteur professionnel
conduisant un entretien pour le poste de ${posteVise}.

Profil du candidat :
- Compétences : ${JSON.stringify(profil.competences || [])}
- Expérience : ${profil.experience_annees || 0} ans
- Domaine : ${profil.domaine_activite || 'Non précisé'}

Historique de l'entretien :
${historiqueTexte}

${estFin
  ? `C'est la dernière question. Remercie le candidat
     et conclus l'entretien de façon professionnelle.
     Dis-lui que les résultats seront disponibles
     dans quelques instants.`
  : `Pose la prochaine question pertinente basée sur
     ses réponses précédentes et son profil.
     Questions possibles : motivation, compétences,
     situations vécues, projets, objectifs.
     Une seule question courte et claire.`}

NE PAS inclure de markdown. Texte simple uniquement.
Maximum 3 phrases.`;

    const reponse = await _appellerIA(
      prompt, cles, 'texte');

    if (estFin) {
      return {
        message: reponse || 'Merci beaucoup pour cet entretien. Vos résultats seront disponibles dans quelques instants.',
        estFin: true,
      };
    }

    return {
      message: reponse || 'Très intéressant. Pouvez-vous me parler d\'un projet dont vous êtes particulièrement fier ?',
      estFin: false,
    };

  } catch (_) {
    return {
      message: 'Merci pour cette réponse. Pouvez-vous me parler de vos principales compétences ?',
      estFin: false,
    };
  }
};

// Générer le rapport final
const genererRapportFinal = async (
    historique, posteVise, profil) => {
  try {
    const cles = await _getClesIA();

    const historiqueTexte = historique
      .map(m => `${m.role === 'recruteur'
        ? 'Q' : 'R'}: ${m.contenu}`)
      .join('\n');

    const prompt = `Tu es un expert RH.
Analyse cet entretien et génère un rapport détaillé.

Poste visé : ${posteVise}
Profil : ${profil.titre_profil || 'Candidat'}

Entretien complet :
${historiqueTexte}

Génère un rapport JSON valide (sans markdown) :
{
  "score_global": <0-100>,
  "note_presentation": <0-10>,
  "note_motivation": <0-10>,
  "note_competences": <0-10>,
  "note_communication": <0-10>,
  "points_forts": ["point 1", "point 2", "point 3"],
  "points_ameliorer": ["point 1", "point 2"],
  "conseils": ["conseil 1", "conseil 2", "conseil 3"],
  "verdict": "<Excellent|Très bien|Bien|À améliorer>",
  "commentaire_global": "<2-3 phrases d'évaluation>"
}`;

    const reponse = await _appellerIA(
      prompt, cles, 'texte');

    if (!reponse) return null;

    const clean = reponse
      .replace(/```json/gi, '')
      .replace(/```/g, '')
      .trim();

    return JSON.parse(clean);

  } catch (e) {
    console.error('[simulation] Rapport:', e.message);
    return {
      score_global:        65,
      note_presentation:   7,
      note_motivation:     6,
      note_competences:    7,
      note_communication:  6,
      points_forts:        ['Communication claire'],
      points_ameliorer:    ['Donner plus d\'exemples concrets'],
      conseils:            ['Pratiquer davantage'],
      verdict:             'Bien',
      commentaire_global:  'Entretien correct dans l\'ensemble.',
    };
  }
};

module.exports = {
  genererPremierMessage,
  genererProchainMessage,
  genererRapportFinal,
};
```

---

## 3. Backend — Routes simulation

```javascript
// backend/src/routes/candidat/simulation.routes.js

const {
  genererPremierMessage,
  genererProchainMessage,
  genererRapportFinal,
} = require('../../services/simulationEntretien.service');

// POST /api/candidat/simulation/demarrer
router.post('/demarrer', auth, async (req, res) => {
  try {
    const { poste_vise, domaine, niveau } = req.body;
    const candidatId = req.user.id;

    if (!poste_vise) {
      return res.status(400).json({
        success: false,
        message: 'Poste visé requis'
      });
    }

    // Récupérer le profil du candidat
    const { data: profil } = await supabase
      .from('chercheurs_emploi')
      .select(`
        titre_profil, competences,
        experience_annees, domaine_activite,
        utilisateur:utilisateurs(nom, email)
      `)
      .or(`utilisateur_id.eq.${candidatId},id.eq.${candidatId}`)
      .single();

    const profilComplet = {
      nom:               profil?.utilisateur?.nom || 'Candidat',
      titre_profil:      profil?.titre_profil || poste_vise,
      competences:       profil?.competences || [],
      experience_annees: profil?.experience_annees || 0,
      domaine_activite:  profil?.domaine_activite || domaine,
    };

    // Générer le message d'accueil
    const messageAccueil = await genererPremierMessage(
      poste_vise, profilComplet);

    // Créer la session
    const { data: session } = await supabase
      .from('simulation_sessions')
      .insert({
        candidat_id:  candidatId,
        poste_vise,
        domaine:      domaine || profilComplet.domaine_activite,
        niveau:       niveau || 'junior',
        statut:       'en_cours',
        messages:     [{
          role:      'recruteur',
          contenu:   messageAccueil,
          timestamp: new Date().toISOString(),
        }],
        nb_questions: 0,
      })
      .select()
      .single();

    return res.json({
      success:  true,
      data: {
        session_id:      session.id,
        message_accueil: messageAccueil,
        profil:          profilComplet,
      }
    });

  } catch (err) {
    res.status(500).json({
      success: false, message: err.message });
  }
});

// POST /api/candidat/simulation/:id/repondre
router.post('/:id/repondre', auth, async (req, res) => {
  try {
    const { reponse_candidat } = req.body;
    const sessionId = req.params.id;

    // Récupérer la session
    const { data: session } = await supabase
      .from('simulation_sessions')
      .select('*')
      .eq('id', sessionId)
      .single();

    if (!session || session.statut !== 'en_cours') {
      return res.status(400).json({
        success: false,
        message: 'Session invalide ou terminée'
      });
    }

    // Récupérer le profil
    const { data: profil } = await supabase
      .from('chercheurs_emploi')
      .select('titre_profil, competences, experience_annees, domaine_activite')
      .or(`utilisateur_id.eq.${req.user.id},id.eq.${req.user.id}`)
      .single();

    // Ajouter la réponse du candidat à l'historique
    const historique = [
      ...session.messages,
      {
        role:      'candidat',
        contenu:   reponse_candidat,
        timestamp: new Date().toISOString(),
      }
    ];

    const nbQuestions = session.nb_questions + 1;

    // Générer la prochaine question
    const { message, estFin } =
      await genererProchainMessage(
        historique,
        session.poste_vise,
        profil || {},
        nbQuestions);

    // Ajouter la réponse du recruteur
    const historiqueComplet = [
      ...historique,
      {
        role:      'recruteur',
        contenu:   message,
        timestamp: new Date().toISOString(),
      }
    ];

    let rapportFinal = null;
    let scoreGlobal  = null;

    if (estFin) {
      // Générer le rapport final
      rapportFinal = await genererRapportFinal(
        historiqueComplet,
        session.poste_vise,
        profil || {});
      scoreGlobal = rapportFinal?.score_global || null;
    }

    // Mettre à jour la session
    await supabase.from('simulation_sessions')
      .update({
        messages:     historiqueComplet,
        nb_questions: nbQuestions,
        statut:       estFin ? 'termine' : 'en_cours',
        score_final:  scoreGlobal,
        rapport_ia:   rapportFinal,
        termine_le:   estFin
          ? new Date().toISOString() : null,
      })
      .eq('id', sessionId);

    return res.json({
      success: true,
      data: {
        message_recruteur: message,
        est_fin:           estFin,
        rapport:           rapportFinal,
        score:             scoreGlobal,
        nb_questions:      nbQuestions,
      }
    });

  } catch (err) {
    res.status(500).json({
      success: false, message: err.message });
  }
});

// GET /api/candidat/simulation/historique
router.get('/historique', auth, async (req, res) => {
  try {
    const { data } = await supabase
      .from('simulation_sessions')
      .select(`
        id, poste_vise, statut, score_final,
        nb_questions, duree_secondes, created_at
      `)
      .eq('candidat_id', req.user.id)
      .order('created_at', { ascending: false })
      .limit(10);

    return res.json({
      success: true,
      data: data || []
    });
  } catch (err) {
    res.status(500).json({
      success: false, message: err.message });
  }
});
```

---

## 4. Flutter — Page Simulation Immersive

```dart
// frontend/lib/screens/candidat/simulation/
// simulation_entretien_page.dart

class SimulationEntretienPage extends StatefulWidget {
  const SimulationEntretienPage({super.key});
  @override
  State<SimulationEntretienPage> createState() =>
    _SimulationPageState();
}

class _SimulationPageState
    extends State<SimulationEntretienPage>
    with TickerProviderStateMixin {

  // Étapes
  static const _ETAPE_CONFIG  = 0;
  static const _ETAPE_ENTRETIEN = 1;
  static const _ETAPE_RAPPORT = 2;

  int _etape = _ETAPE_CONFIG;

  // Config
  final _posteCtrl = TextEditingController();
  String _niveauChoisi = 'junior';

  // Session
  String? _sessionId;
  String? _messageRecruteur;
  bool    _recruteurParle = false;
  bool    _candidatParle  = false;
  bool    _isLoading      = false;
  bool    _estFin         = false;
  int     _nbQuestions    = 0;

  // Rapport
  Map<String, dynamic>? _rapport;

  // Messages affichés
  final List<Map<String, dynamic>> _messages = [];

  // Contrôleur texte candidat
  final _reponseCtrl = TextEditingController();

  // Animation avatar
  late AnimationController _avatarCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  // Speech (Web)
  bool _micActif = false;
  String _texteReconnu = '';

  @override
  void initState() {
    super.initState();
    _avatarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300));
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.05)
      .animate(CurvedAnimation(
        parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _avatarCtrl.dispose();
    _pulseCtrl.dispose();
    _posteCtrl.dispose();
    _reponseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: switch (_etape) {
          _ETAPE_CONFIG    => _buildConfig(),
          _ETAPE_ENTRETIEN => _buildEntretien(),
          _ETAPE_RAPPORT   => _buildRapport(),
          _ => _buildConfig(),
        }));
  }

  // ── ÉTAPE 1 : Configuration ─────────────────────────
  Widget _buildConfig() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0D1B3E), Color(0xFF1A2F5E)])),
    child: Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

          // Icône
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A56DB),
                         Color(0xFF7C3AED)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                color: const Color(0xFF1A56DB)
                  .withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8))]),
            child: const Icon(
              Icons.record_voice_over_rounded,
              color: Colors.white, size: 40)),
          const SizedBox(height: 24),

          // Titre
          Text('Simulation d\'entretien IA',
            style: GoogleFonts.poppins(
              fontSize: 24, fontWeight: FontWeight.w900,
              color: Colors.white),
            textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Un recruteur virtuel vous posera des questions\n'
            'adaptées à votre profil. Répondez par voix\n'
            'ou par texte.',
            style: GoogleFonts.inter(
              fontSize: 14, color: Colors.white60,
              height: 1.5),
            textAlign: TextAlign.center),
          const SizedBox(height: 32),

          // Champ poste visé
          TextFormField(
            controller: _posteCtrl,
            style: GoogleFonts.inter(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Ex: Développeur Flutter, Comptable...',
              hintStyle: GoogleFonts.inter(
                color: Colors.white38),
              labelText: 'Poste visé *',
              labelStyle: GoogleFonts.inter(
                color: Colors.white60),
              prefixIcon: const Icon(
                Icons.work_outline_rounded,
                color: Color(0xFF1A56DB)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.2))),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.2))),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF1A56DB), width: 2)))),
          const SizedBox(height: 16),

          // Niveau
          Row(children: [
            Text('Niveau :',
              style: GoogleFonts.inter(
                color: Colors.white60, fontSize: 13)),
            const SizedBox(width: 12),
            ...['junior', 'senior', 'manager']
              .map((n) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () =>
                    setState(() => _niveauChoisi = n),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _niveauChoisi == n
                          ? const Color(0xFF1A56DB)
                          : Colors.white.withOpacity(0.08),
                      borderRadius:
                        BorderRadius.circular(100),
                      border: Border.all(
                        color: _niveauChoisi == n
                            ? const Color(0xFF1A56DB)
                            : Colors.white24)),
                    child: Text(
                      n[0].toUpperCase() + n.substring(1),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)))))),
          ]),
          const SizedBox(height: 32),

          // Infos
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12)),
            child: Column(children: [
              _InfoSimulation(Icons.mic_rounded,
                'Répondez par voix (micro)'),
              const SizedBox(height: 6),
              _InfoSimulation(Icons.keyboard_rounded,
                'Ou tapez votre réponse'),
              const SizedBox(height: 6),
              _InfoSimulation(Icons.psychology_rounded,
                'L\'IA analyse votre profil'),
              const SizedBox(height: 6),
              _InfoSimulation(Icons.timer_rounded,
                '7-10 questions • ~15 minutes'),
            ])),
          const SizedBox(height: 24),

          // Bouton démarrer
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _isLoading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white))
                  : const Icon(
                      Icons.play_arrow_rounded, size: 22),
              label: Text(
                _isLoading
                    ? 'Préparation...'
                    : 'Démarrer l\'entretien',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56DB),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius:
                    BorderRadius.circular(12))),
              onPressed: _isLoading ? null : _demarrer)),
        ]))));

  // ── ÉTAPE 2 : Entretien ─────────────────────────────
  Widget _buildEntretien() => Column(children: [

    // Header
    Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 12, left: 16, right: 16),
      color: const Color(0xFF0D1B3E),
      child: Row(children: [
        IconButton(
          icon: const Icon(
            Icons.close_rounded, color: Colors.white54),
          onPressed: () => _confirmerAbandon()),
        const Expanded(child: Center(
          child: Text('Entretien en cours',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600)))),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(100)),
          child: Text(
            'Q${_nbQuestions}/7',
            style: GoogleFonts.inter(
              fontSize: 12, color: Colors.white70,
              fontWeight: FontWeight.w600))),
      ])),

    // Zone principale
    Expanded(child: Row(children: [

      // ── Panneau gauche : Avatar ───────────────────
      Container(
        width: MediaQuery.of(context).size.width > 700
            ? 280 : 0,
        color: const Color(0xFF0D1B3E),
        child: MediaQuery.of(context).size.width > 700
            ? _buildAvatar() : null),

      // ── Panneau droit : Chat ──────────────────────
      Expanded(child: Container(
        color: const Color(0xFF0F172A),
        child: Column(children: [

          // Messages
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (ctx, i) {
              final msg = _messages[i];
              final estRecruteur =
                msg['role'] == 'recruteur';
              return _BulleMessage(
                message: msg['contenu'] as String,
                estRecruteur: estRecruteur);
            })),

          // Zone de réponse
          if (!_estFin) _buildZoneReponse(),
        ]))),
    ])),
  ]);

  // ── Avatar animé ─────────────────────────────────────
  Widget _buildAvatar() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    // Avatar
    AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Transform.scale(
        scale: _recruteurParle ? _pulseAnim.value : 1.0,
        child: child),
      child: Container(
        width: 160, height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A56DB), Color(0xFF7C3AED)]),
          boxShadow: [BoxShadow(
            color: const Color(0xFF1A56DB).withOpacity(
              _recruteurParle ? 0.6 : 0.2),
            blurRadius: _recruteurParle ? 30 : 15,
            spreadRadius: _recruteurParle ? 5 : 0)]),
        child: Stack(children: [
          // Visage
          Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            // Yeux
            Row(mainAxisAlignment:
                MainAxisAlignment.center,
              children: [
              Container(width: 14, height: 14,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle)),
              const SizedBox(width: 20),
              Container(width: 14, height: 14,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle)),
            ]),
            const SizedBox(height: 16),
            // Bouche animée
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _recruteurParle ? 40 : 30,
              height: _recruteurParle ? 20 : 8,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  _recruteurParle ? 10 : 4))),
          ])),
          // Badge actif
          if (_recruteurParle)
            Positioned(bottom: 8, right: 8,
              child: Container(
                width: 24, height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle),
                child: const Icon(
                  Icons.volume_up_rounded,
                  color: Colors.white, size: 14))),
        ]))),
    const SizedBox(height: 16),
    Text('Recruteur IA',
      style: GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w700,
        color: Colors.white)),
    Text('EmploiConnect',
      style: GoogleFonts.inter(
        fontSize: 12, color: Colors.white38)),
    const SizedBox(height: 12),
    // Indicateur état
    AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(
        horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _recruteurParle
            ? const Color(0xFF10B981).withOpacity(0.2)
            : _candidatParle
                ? const Color(0xFF1A56DB).withOpacity(0.2)
                : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: _recruteurParle
              ? const Color(0xFF10B981)
              : _candidatParle
                  ? const Color(0xFF1A56DB)
                  : Colors.white12)),
      child: Row(mainAxisSize: MainAxisSize.min,
        children: [
        Icon(
          _recruteurParle
              ? Icons.volume_up_rounded
              : _candidatParle
                  ? Icons.mic_rounded
                  : Icons.pause_rounded,
          color: _recruteurParle
              ? const Color(0xFF10B981)
              : _candidatParle
                  ? const Color(0xFF1A56DB)
                  : Colors.white38,
          size: 14),
        const SizedBox(width: 6),
        Text(
          _recruteurParle
              ? 'En train de parler...'
              : _candidatParle
                  ? 'En écoute...'
                  : 'En attente',
          style: GoogleFonts.inter(
            fontSize: 11, color: Colors.white60)),
      ])),
  ]);

  // ── Zone de réponse ───────────────────────────────────
  Widget _buildZoneReponse() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF0D1B3E),
      border: Border(
        top: BorderSide(color: Colors.white.withOpacity(0.08)))),
    child: Column(children: [
      // Champ texte
      Row(children: [
        Expanded(child: TextFormField(
          controller: _reponseCtrl,
          style: GoogleFonts.inter(
            color: Colors.white, fontSize: 14),
          maxLines: 3, minLines: 1,
          decoration: InputDecoration(
            hintText: 'Votre réponse...',
            hintStyle: GoogleFonts.inter(
              color: Colors.white30, fontSize: 13),
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.15))),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.15))),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF1A56DB)))),
          onFieldSubmitted: (_) => _envoyerReponse())),
        const SizedBox(width: 10),
        Column(children: [
          // Bouton micro
          GestureDetector(
            onTap: _toggleMic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48, height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _micActif
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF1A56DB)
                        .withOpacity(0.2),
                border: Border.all(
                  color: _micActif
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF1A56DB))),
              child: Icon(
                _micActif
                    ? Icons.mic_rounded
                    : Icons.mic_none_rounded,
                color: Colors.white, size: 22))),
          const SizedBox(height: 4),
          Text(_micActif ? 'Stop' : 'Micro',
            style: GoogleFonts.inter(
              fontSize: 9, color: Colors.white38)),
        ]),
      ]),
      const SizedBox(height: 10),
      // Texte reconnu
      if (_texteReconnu.isNotEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A56DB).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
          child: Text('🎤 $_texteReconnu',
            style: GoogleFonts.inter(
              fontSize: 12, color: Colors.white60))),
      const SizedBox(height: 8),
      // Bouton envoyer
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: _isLoading
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send_rounded, size: 18),
          label: Text(
            _isLoading ? 'Analyse...' : 'Envoyer',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(
              vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10))),
          onPressed: _isLoading ? null : _envoyerReponse)),
    ]));

  // ── ÉTAPE 3 : Rapport ───────────────────────────────
  Widget _buildRapport() {
    if (_rapport == null) {
      return const Center(child:
        CircularProgressIndicator(color: Color(0xFF1A56DB)));
    }

    final score = _rapport!['score_global'] as int? ?? 0;
    final verdict = _rapport!['verdict'] as String? ?? 'Bien';
    final couleur = score >= 80
        ? const Color(0xFF10B981)
        : score >= 60
            ? const Color(0xFF1A56DB)
            : score >= 40
                ? const Color(0xFFF59E0B)
                : const Color(0xFFEF4444);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 20),

        // Score circulaire
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: score / 100),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeOut,
          builder: (_, val, __) => Stack(
            alignment: Alignment.center,
            children: [
            SizedBox(width: 140, height: 140,
              child: CircularProgressIndicator(
                value: val, strokeWidth: 10,
                color: couleur,
                backgroundColor:
                  couleur.withOpacity(0.15))),
            Column(children: [
              Text('${(val * 100).round()}',
                style: GoogleFonts.poppins(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
              Text('/ 100',
                style: GoogleFonts.inter(
                  fontSize: 14, color: Colors.white38)),
            ]),
          ])),
        const SizedBox(height: 16),

        Text(verdict,
          style: GoogleFonts.poppins(
            fontSize: 22, fontWeight: FontWeight.w800,
            color: couleur)),
        const SizedBox(height: 8),
        Text(
          _rapport!['commentaire_global']
            as String? ?? '',
          style: GoogleFonts.inter(
            fontSize: 14, color: Colors.white60,
            height: 1.5),
          textAlign: TextAlign.center),
        const SizedBox(height: 24),

        // Notes par critère
        _CarteNotes(_rapport!),
        const SizedBox(height: 16),

        // Points forts
        _CarteListeRapport(
          titre: '✅ Points forts',
          items: List<String>.from(
            _rapport!['points_forts'] ?? []),
          couleur: const Color(0xFF10B981)),
        const SizedBox(height: 10),

        // Points à améliorer
        _CarteListeRapport(
          titre: '⚠️ Points à améliorer',
          items: List<String>.from(
            _rapport!['points_ameliorer'] ?? []),
          couleur: const Color(0xFFF59E0B)),
        const SizedBox(height: 10),

        // Conseils
        _CarteListeRapport(
          titre: '💡 Conseils pour progresser',
          items: List<String>.from(
            _rapport!['conseils'] ?? []),
          couleur: const Color(0xFF1A56DB)),
        const SizedBox(height: 24),

        // Boutons
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Recommencer'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: Color(0xFF1A56DB)),
              foregroundColor: const Color(0xFF1A56DB),
              padding: const EdgeInsets.symmetric(
                vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
            onPressed: () => setState(() {
              _etape = _ETAPE_CONFIG;
              _messages.clear();
              _rapport = null;
              _nbQuestions = 0;
              _estFin = false;
            }))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton.icon(
            icon: const Icon(Icons.home_rounded),
            label: const Text('Tableau de bord'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A56DB),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
            onPressed: () => context.go('/candidat'))),
        ]),
        const SizedBox(height: 32),
      ]));
  }

  // ── Actions ──────────────────────────────────────────

  Future<void> _demarrer() async {
    if (_posteCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrez le poste visé'),
          behavior: SnackBarBehavior.floating));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}'
          '/api/candidat/simulation/demarrer'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'poste_vise': _posteCtrl.text.trim(),
          'niveau':     _niveauChoisi,
        }));

      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        final data = body['data'];
        setState(() {
          _sessionId = data['session_id'] as String;
          _messageRecruteur =
            data['message_accueil'] as String;
          _messages.add({
            'role':    'recruteur',
            'contenu': _messageRecruteur,
          });
          _etape = _ETAPE_ENTRETIEN;
          _recruteurParle = true;
        });
        // Simuler voix du recruteur
        await _parlerRecruteur(_messageRecruteur!);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _envoyerReponse() async {
    final texte = _reponseCtrl.text.trim()
        .isNotEmpty
        ? _reponseCtrl.text.trim()
        : _texteReconnu.trim();

    if (texte.isEmpty) return;

    setState(() {
      _messages.add({
        'role': 'candidat', 'contenu': texte});
      _reponseCtrl.clear();
      _texteReconnu = '';
      _isLoading = true;
      _candidatParle = false;
    });

    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}'
          '/api/candidat/simulation/$_sessionId/repondre'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'reponse_candidat': texte}));

      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        final data = body['data'];
        final msgRecruteur =
          data['message_recruteur'] as String;
        final estFin = data['est_fin'] as bool? ?? false;

        setState(() {
          _messages.add({
            'role': 'recruteur', 'contenu': msgRecruteur});
          _nbQuestions = data['nb_questions'] as int? ?? 0;
          _recruteurParle = true;
          _estFin = estFin;
        });

        await _parlerRecruteur(msgRecruteur);

        if (estFin) {
          setState(() {
            _rapport = data['rapport']
                as Map<String, dynamic>?;
          });
          await Future.delayed(const Duration(seconds: 2));
          setState(() => _etape = _ETAPE_RAPPORT);
        }
      }
    } finally {
      if (mounted) setState(() {
        _isLoading = false;
        _recruteurParle = false;
      });
    }
  }

  // Synthèse vocale (navigateur)
  Future<void> _parlerRecruteur(String texte) async {
    setState(() => _recruteurParle = true);
    // Utiliser JavaScript interop pour Web Speech API
    // Durée estimée basée sur la longueur du texte
    final duree = Duration(
      milliseconds: (texte.length * 60).clamp(1000, 8000));
    await Future.delayed(duree);
    if (mounted) setState(() => _recruteurParle = false);
  }

  // Toggle microphone (Web Speech API)
  void _toggleMic() {
    setState(() {
      _micActif = !_micActif;
      _candidatParle = _micActif;
      if (!_micActif && _texteReconnu.isNotEmpty) {
        _reponseCtrl.text = _texteReconnu;
      }
    });
    // Note: Speech Recognition via js_interop
    // à implémenter selon la plateforme
  }

  void _confirmerAbandon() => showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Text('Abandonner l\'entretien ?',
        style: GoogleFonts.poppins(
          color: Colors.white, fontWeight: FontWeight.w700)),
      content: Text(
        'Votre progression sera perdue.',
        style: GoogleFonts.inter(color: Colors.white60)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Continuer',
            style: TextStyle(color: Color(0xFF1A56DB)))),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            setState(() => _etape = _ETAPE_CONFIG);
          },
          child: const Text('Abandonner',
            style: TextStyle(color: Color(0xFFEF4444)))),
      ]));
}

// ── Widgets helpers ───────────────────────────────────────

class _BulleMessage extends StatelessWidget {
  final String message;
  final bool estRecruteur;
  const _BulleMessage({
    required this.message, required this.estRecruteur});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: estRecruteur
          ? MainAxisAlignment.start
          : MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
      if (estRecruteur) ...[
        Container(
          width: 32, height: 32,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A56DB),
                       Color(0xFF7C3AED)]),
            shape: BoxShape.circle),
          child: const Center(child: Text('🤖',
            style: TextStyle(fontSize: 14)))),
        const SizedBox(width: 8),
      ],
      Flexible(child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: estRecruteur
              ? const Color(0xFF1E293B)
              : const Color(0xFF1A56DB),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(
              estRecruteur ? 4 : 16),
            bottomRight: Radius.circular(
              estRecruteur ? 16 : 4))),
        child: Text(message,
          style: GoogleFonts.inter(
            fontSize: 14, color: Colors.white,
            height: 1.5)))),
      if (!estRecruteur) ...[
        const SizedBox(width: 8),
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF1A56DB)
              .withOpacity(0.3),
            shape: BoxShape.circle),
          child: const Center(child: Icon(
            Icons.person_rounded,
            color: Colors.white70, size: 18))),
      ],
    ]));
}

class _InfoSimulation extends StatelessWidget {
  final IconData icone;
  final String texte;
  const _InfoSimulation(this.icone, this.texte);
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icone, color: const Color(0xFF1A56DB), size: 16),
    const SizedBox(width: 10),
    Text(texte, style: GoogleFonts.inter(
      fontSize: 12, color: Colors.white54)),
  ]);
}

class _CarteNotes extends StatelessWidget {
  final Map<String, dynamic> rapport;
  const _CarteNotes(this.rapport);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Text('Notes détaillées',
        style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: Colors.white)),
      const SizedBox(height: 12),
      _NoteLigne('Présentation',
        rapport['note_presentation'] as int? ?? 0),
      _NoteLigne('Motivation',
        rapport['note_motivation'] as int? ?? 0),
      _NoteLigne('Compétences',
        rapport['note_competences'] as int? ?? 0),
      _NoteLigne('Communication',
        rapport['note_communication'] as int? ?? 0),
    ]));
}

class _NoteLigne extends StatelessWidget {
  final String label;
  final int note;
  const _NoteLigne(this.label, this.note);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      SizedBox(width: 110, child: Text(label,
        style: GoogleFonts.inter(
          fontSize: 12, color: Colors.white60))),
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: note / 10,
          backgroundColor: Colors.white12,
          color: note >= 8
              ? const Color(0xFF10B981)
              : note >= 6
                  ? const Color(0xFF1A56DB)
                  : const Color(0xFFF59E0B),
          minHeight: 6))),
      const SizedBox(width: 8),
      Text('$note/10',
        style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: Colors.white70)),
    ]));
}

class _CarteListeRapport extends StatelessWidget {
  final String titre;
  final List<String> items;
  final Color couleur;
  const _CarteListeRapport({
    required this.titre, required this.items,
    required this.couleur});
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: couleur.withOpacity(0.25))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text(titre,
          style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: couleur)),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Icon(Icons.arrow_right_rounded,
              color: couleur, size: 16),
            const SizedBox(width: 4),
            Expanded(child: Text(item,
              style: GoogleFonts.inter(
                fontSize: 12, color: Colors.white70,
                height: 1.4))),
          ]))),
      ]));
  }
}
```

---

## 5. Speech API — Intégration Web

```dart
// frontend/lib/utils/speech_service.dart
// Utilise js_interop pour Web Speech API

import 'dart:js_interop';

@JS('startSpeechRecognition')
external void startSpeechRecognitionJS(
  JSFunction callback);

@JS('stopSpeechRecognition')
external void stopSpeechRecognitionJS();

@JS('speakText')
external void speakTextJS(JSString text, JSString lang);

class SpeechService {
  // Démarrer la reconnaissance vocale
  static void demarrerMicro(
      Function(String) onResult) {
    startSpeechRecognitionJS(
      (JSString result) {
        onResult(result.toDart);
      }.toJS);
  }

  // Arrêter le micro
  static void arreterMicro() {
    stopSpeechRecognitionJS();
  }

  // Faire parler le recruteur
  static void parler(String texte) {
    speakTextJS(texte.toJS, 'fr-FR'.toJS);
  }
}
```

```javascript
// Dans web/index.html — ajouter avant </body>

<script>
// Synthèse vocale
window.speakText = function(text, lang) {
  if ('speechSynthesis' in window) {
    window.speechSynthesis.cancel();
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = lang || 'fr-FR';
    utterance.rate = 0.9;
    utterance.pitch = 1.0;
    utterance.volume = 1.0;
    // Choisir une voix française si disponible
    const voices = window.speechSynthesis.getVoices();
    const voixFr = voices.find(v =>
      v.lang.startsWith('fr'));
    if (voixFr) utterance.voice = voixFr;
    window.speechSynthesis.speak(utterance);
  }
};

// Reconnaissance vocale
let recognition = null;
window.startSpeechRecognition = function(callback) {
  if (!('webkitSpeechRecognition' in window)
      && !('SpeechRecognition' in window)) {
    console.warn('Speech Recognition non supporté');
    return;
  }
  const SR = window.SpeechRecognition
    || window.webkitSpeechRecognition;
  recognition = new SR();
  recognition.lang = 'fr-FR';
  recognition.continuous = false;
  recognition.interimResults = true;

  recognition.onresult = function(event) {
    const transcript = Array.from(event.results)
      .map(r => r[0].transcript)
      .join('');
    callback(transcript);
  };
  recognition.onerror = function(e) {
    console.warn('Speech error:', e.error);
  };
  recognition.start();
};

window.stopSpeechRecognition = function() {
  if (recognition) recognition.stop();
};
</script>
```

---

## Critères d'Acceptation

- [ ] Migration SQL 065
- [ ] Service simulation IA créé
- [ ] Routes backend simulation
- [ ] Page config avec poste + niveau
- [ ] Interface chat immersive fond sombre
- [ ] Avatar animé (bouche bouge quand parle)
- [ ] Indicateur "En train de parler" / "En écoute"
- [ ] Réponse par texte fonctionne
- [ ] Réponse par micro fonctionne (Chrome)
- [ ] Recruteur parle (voix navigateur)
- [ ] 7-8 questions adaptées au profil
- [ ] Rapport final avec score circulaire
- [ ] Notes par critère avec barres animées
- [ ] Points forts / faibles / conseils
- [ ] Bouton "Recommencer" et "Tableau de bord"
- [ ] Historique des simulations

---

*PRD EmploiConnect v9.12 — Simulation Entretien V2*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
