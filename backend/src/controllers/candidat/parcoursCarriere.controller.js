import { supabase } from '../../config/supabase.js';
import { _appellerIA, _getClesIA } from '../../services/ia.service.js';

/** Paramètre booléen plateforme (défaut true si absent ou valeur ambiguë). */
async function isParamActif(cle, defaultTrue = true) {
  const { data, error } = await supabase.from('parametres_plateforme').select('valeur').eq('cle', cle).maybeSingle();
  if (error || !data) return defaultTrue;
  const v = String(data.valeur ?? '').trim().toLowerCase();
  if (v === '') return defaultTrue;
  if (v === 'false' || v === '0' || v === 'non' || v === 'no' || v === 'off') return false;
  if (v === 'true' || v === '1' || v === 'oui' || v === 'yes' || v === 'on') return true;
  return defaultTrue;
}

function parseIaJson(texte) {
  const raw = String(texte || '')
    .replace(/```json/gi, '')
    .replace(/```/g, '')
    .replace(/\uFEFF/g, '')
    .trim();
  try {
    return JSON.parse(raw);
  } catch (errDirect) {
    const start = raw.indexOf('{');
    if (start === -1) throw new Error('Réponse IA non JSON');
    let depth = 0;
    let inString = false;
    let escaped = false;
    let end = -1;
    for (let i = start; i < raw.length; i += 1) {
      const ch = raw[i];
      if (inString) {
        if (escaped) escaped = false;
        else if (ch === '\\') escaped = true;
        else if (ch === '"') inString = false;
        continue;
      }
      if (ch === '"') {
        inString = true;
        continue;
      }
      if (ch === '{') depth += 1;
      if (ch === '}') {
        depth -= 1;
        if (depth === 0) {
          end = i;
          break;
        }
      }
    }
    if (end === -1) {
      throw new Error(`Réponse IA non JSON (${errDirect.message})`);
    }
    const bloc = raw
      .slice(start, end + 1)
      .replace(/,\s*([}\]])/g, '$1') // retire virgules finales invalides
      .replace(/[\u0000-\u0019]/g, ' ');
    return JSON.parse(bloc);
  }
}

function questionsFallback({ poste, domaine, niveau, nbQuestions }) {
  const base = [
    {
      question: `Pouvez-vous vous presenter rapidement et expliquer pourquoi le poste "${poste}" vous interesse ?`,
      type: 'motivation',
      theme: 'motivation',
      conseil: 'Structurez votre reponse en 3 parties: profil, motivations, valeur ajoutee.',
    },
    {
      question: `Parlez d'un projet concret en ${domaine || 'votre domaine'} que vous avez realise et de votre contribution precise.`,
      type: 'comportemental',
      theme: 'experience',
      conseil: 'Utilisez la methode STAR et donnez un resultat chiffre.',
    },
    {
      question: `Comment priorisez-vous vos taches quand plusieurs urgences arrivent en meme temps ?`,
      type: 'situation',
      theme: 'stress',
      conseil: 'Expliquez votre methode de priorisation et vos criteres.',
    },
    {
      question: `Quelles competences techniques sont les plus importantes pour ce poste et comment les appliquez-vous ?`,
      type: 'technique',
      theme: 'code',
      conseil: 'Citez des outils/technos et des exemples concrets d\'utilisation.',
    },
    {
      question: `Comment collaborez-vous avec une equipe (produit, design, metier) sur un projet ?`,
      type: 'comportemental',
      theme: 'equipe',
      conseil: 'Insistez sur communication, feedback et gestion des conflits.',
    },
    {
      question: `Si vous etiez recrute au niveau ${niveau || 'souhaite'}, que feriez-vous durant vos 30 premiers jours ?`,
      type: 'situation',
      theme: 'general',
      conseil: 'Proposez un plan 30-60-90 clair et realiste.',
    },
  ];
  return { questions: base.slice(0, nbQuestions) };
}

function evaluationFallback() {
  return {
    score: 50,
    feedback: 'Evaluation partielle: la reponse n\'a pas pu etre analysee completement.',
    points_forts: [],
    ameliorations: [
      'Structurez votre reponse avec la methode STAR',
      'Ajoutez des exemples concrets de vos realisations',
      'Concluez avec votre valeur ajoutee pour le poste',
    ],
  };
}

function salaireFallback() {
  return {
    salaire_min: 1500000,
    salaire_max: 3500000,
    salaire_median: 2500000,
    devise: 'GNF',
    conseils: [
      'Preparez des exemples concrets de valeur apportee',
      'Basez votre negotiation sur vos competences et le marche',
    ],
  };
}

export async function listRessourcesPubliees(req, res) {
  try {
    const userId = req.user.id;
    const { categorie, type } = req.query;

    let q = supabase
      .from('ressources_carrieres')
      .select(
        'id, titre, description, type_ressource, categorie, niveau, url_externe, fichier_url, image_couverture, duree_minutes, tags, est_mis_en_avant, nb_vues, date_publication, ordre_affichage',
      )
      .eq('est_publie', true)
      .order('ordre_affichage', { ascending: true })
      .order('date_publication', { ascending: false });

    if (categorie) q = q.eq('categorie', categorie);
    if (type) q = q.eq('type_ressource', type);

    const { data: rows, error } = await q;
    if (error) throw error;

    const ids = (rows || []).map((r) => r.id);
    let vuesSet = new Set();
    if (ids.length) {
      const { data: vues } = await supabase
        .from('ressources_vues')
        .select('ressource_id')
        .eq('utilisateur_id', userId)
        .in('ressource_id', ids);
      vuesSet = new Set((vues || []).map((v) => v.ressource_id));
    }

    const data = (rows || []).map((r) => ({
      ...r,
      deja_vue: vuesSet.has(r.id),
    }));

    const nbVues = data.filter((r) => r.deja_vue).length;

    return res.json({ success: true, data, meta: { nb_vues_utilisateur: nbVues } });
  } catch (err) {
    console.error('[listRessourcesPubliees]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}

export async function getRessourcePubliee(req, res) {
  try {
    const { id } = req.params;
    const { data, error } = await supabase
      .from('ressources_carrieres')
      .select('*')
      .eq('id', id)
      .eq('est_publie', true)
      .maybeSingle();

    if (error) throw error;
    if (!data) return res.status(404).json({ success: false, message: 'Ressource introuvable' });

    return res.json({ success: true, data });
  } catch (err) {
    console.error('[getRessourcePubliee]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}

export async function marquerVue(req, res) {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const { data: pub } = await supabase
      .from('ressources_carrieres')
      .select('id, est_publie')
      .eq('id', id)
      .eq('est_publie', true)
      .maybeSingle();

    if (!pub) return res.status(404).json({ success: false, message: 'Ressource introuvable' });

    const { data: existing } = await supabase
      .from('ressources_vues')
      .select('id')
      .eq('ressource_id', id)
      .eq('utilisateur_id', userId)
      .maybeSingle();

    if (!existing) {
      await supabase.from('ressources_vues').insert({
        ressource_id: id,
        utilisateur_id: userId,
        progression: Math.min(100, Math.max(0, parseInt(String(req.body?.progression ?? 0), 10) || 0)),
      });
      const { data: cur } = await supabase.from('ressources_carrieres').select('nb_vues').eq('id', id).single();
      const n = (cur?.nb_vues ?? 0) + 1;
      await supabase.from('ressources_carrieres').update({ nb_vues: n }).eq('id', id);
    } else if (req.body?.progression != null) {
      const p = Math.min(100, Math.max(0, parseInt(String(req.body.progression), 10) || 0));
      await supabase.from('ressources_vues').update({ progression: p, date_vue: new Date().toISOString() }).eq('id', existing.id);
    }

    return res.json({ success: true, message: 'Vue enregistrée' });
  } catch (err) {
    console.error('[marquerVue]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}

export async function genererQuestionsSimulateur(req, res) {
  try {
    if (!(await isParamActif('ia_simulateur_actif'))) {
      return res.status(403).json({
        success: false,
        message: "Simulateur d'entretien désactivé dans les paramètres IA.",
      });
    }

    const { poste_vise, domaine, niveau, nb_questions = 5 } = req.body || {};
    if (!String(poste_vise || '').trim()) {
      return res.status(400).json({ success: false, message: 'poste_vise requis' });
    }
    const n = Math.min(10, Math.max(3, parseInt(String(nb_questions), 10) || 5));

    const cles = await _getClesIA();
    const prompt = `Tu es un recruteur expert en Guinée (Afrique de l'Ouest).
Génère exactement ${n} questions d'entretien pour le poste suivant :

Poste visé : ${poste_vise}
Domaine    : ${domaine || 'non précisé'}
Niveau     : ${niveau || 'non précisé'}

Varie les types de questions :
- Questions techniques sur le domaine
- Questions comportementales (STAR)
- Questions de mise en situation
- Questions de motivation
- Questions sur les expériences passées

Pour chaque question, choisis un thème court (mot-clé) parmi :
code | equipe | stress | experience | finance | commercial | motivation | situation | general

Réponds UNIQUEMENT avec ce JSON :
{
  "questions": [
    {
      "question": "...",
      "type": "technique|comportemental|situation|motivation",
      "theme": "code",
      "conseil": "Tip pour bien répondre (1 phrase)"
    }
  ]
}`;

    const texte = await _appellerIA(prompt, cles, 'texte');
    if (!texte) return res.status(503).json({ success: false, message: 'IA non disponible' });

    let data = null;
    try {
      data = parseIaJson(texte);
    } catch (e1) {
      console.warn('[genererQuestionsSimulateur] parse initial echoue:', e1?.message || e1);
      // 2e tentative: demander au modele de reformater strictement le JSON.
      const fixPrompt = `Corrige ce contenu en JSON STRICT valide, sans markdown, sans commentaire.
Conserve uniquement le schema:
{
  "questions": [
    {
      "question": "...",
      "type": "technique|comportemental|situation|motivation",
      "theme": "code|equipe|stress|experience|finance|commercial|motivation|situation|general",
      "conseil": "..."
    }
  ]
}
Contenu a corriger:
${String(texte).slice(0, 6000)}`;
      try {
        const fixed = await _appellerIA(fixPrompt, cles, 'texte');
        if (fixed) data = parseIaJson(fixed);
      } catch (e2) {
        console.warn('[genererQuestionsSimulateur] parse reformate echoue:', e2?.message || e2);
      }
    }

    if (!data?.questions || !Array.isArray(data.questions) || data.questions.length === 0) {
      console.warn('[genererQuestionsSimulateur] fallback questions local utilise');
      data = questionsFallback({
        poste: String(poste_vise || 'Poste'),
        domaine: String(domaine || ''),
        niveau: String(niveau || ''),
        nbQuestions: n,
      });
    }

    const out = {
      questions: (data.questions || [])
        .slice(0, n)
        .map((q, idx) => ({
          question: String(q?.question || `Question ${idx + 1}`),
          type: String(q?.type || 'general').toLowerCase(),
          theme: String(q?.theme || 'general').toLowerCase(),
          conseil: String(q?.conseil || 'Structurez votre reponse avec un exemple concret.'),
        })),
    };

    return res.json({ success: true, data: out });
  } catch (err) {
    console.error('[genererQuestionsSimulateur]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}

export async function evaluerReponseSimulateur(req, res) {
  try {
    if (!(await isParamActif('ia_simulateur_actif'))) {
      return res.status(403).json({
        success: false,
        message: "Simulateur d'entretien désactivé dans les paramètres IA.",
      });
    }

    const { question, reponse, poste_vise, domaine, niveau } = req.body || {};
    if (!String(question || '').trim() || !String(reponse || '').trim()) {
      return res.status(400).json({ success: false, message: 'question et reponse requis' });
    }

    const cles = await _getClesIA();
    const prompt = `Tu es un recruteur expert. Évalue cette réponse d'entretien.

Contexte :
- Poste   : ${poste_vise || 'non précisé'}
- Domaine : ${domaine || 'non précisé'}
- Niveau  : ${niveau || 'non précisé'}

Question posée :
"${question}"

Réponse du candidat :
"${reponse}"

Évalue de manière bienveillante et constructive. Tiens compte du contexte guinéen/africain.

Réponds UNIQUEMENT avec ce JSON :
{
  "score": 50,
  "feedback": "feedback principal en 2-3 phrases",
  "points_forts": ["point fort 1"],
  "ameliorations": ["amélioration 1"]
}`;

    const texte = await _appellerIA(prompt, cles, 'texte');
    if (!texte) return res.status(503).json({ success: false, message: 'IA non disponible' });

    let data = null;
    try {
      data = parseIaJson(texte);
    } catch (e1) {
      console.warn('[evaluerReponseSimulateur] parse initial echoue:', e1?.message || e1);
      const fixPrompt = `Corrige ce contenu en JSON STRICT valide, sans markdown.
Schema attendu:
{
  "score": 50,
  "feedback": "...",
  "points_forts": ["..."],
  "ameliorations": ["..."]
}
Contenu:
${String(texte).slice(0, 6000)}`;
      try {
        const fixed = await _appellerIA(fixPrompt, cles, 'texte');
        if (fixed) data = parseIaJson(fixed);
      } catch (e2) {
        console.warn('[evaluerReponseSimulateur] parse reformate echoue:', e2?.message || e2);
      }
    }

    if (!data || typeof data !== 'object') data = evaluationFallback();
    if (!Array.isArray(data.points_forts)) data.points_forts = [];
    if (!Array.isArray(data.ameliorations)) data.ameliorations = evaluationFallback().ameliorations;
    if (!Number.isFinite(Number(data.score))) data.score = 50;
    data.score = Math.max(0, Math.min(100, Number(data.score)));
    if (!String(data.feedback || '').trim()) data.feedback = evaluationFallback().feedback;

    return res.json({ success: true, data });
  } catch (err) {
    console.error('[evaluerReponseSimulateur]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}

export async function sauvegarderSimulation(req, res) {
  try {
    if (!(await isParamActif('ia_simulateur_actif'))) {
      return res.status(403).json({
        success: false,
        message: "Simulateur d'entretien désactivé dans les paramètres IA.",
      });
    }

    const userId = req.user.id;
    const { poste_vise, domaine, niveau, questions, score_global } = req.body || {};

    const { error } = await supabase.from('simulations_entretien').insert({
      utilisateur_id: userId,
      poste_vise: poste_vise != null ? String(poste_vise) : null,
      domaine: domaine != null ? String(domaine) : null,
      niveau: niveau != null ? String(niveau) : null,
      questions: questions ?? [],
      score_global: score_global != null ? parseInt(String(score_global), 10) : null,
      statut: 'termine',
      duree_minutes: Array.isArray(questions) ? Math.max(1, Math.round(questions.length * 3)) : null,
    });

    if (error) throw error;
    return res.json({ success: true, message: 'Session sauvegardée' });
  } catch (err) {
    console.error('[sauvegarderSimulation]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}

export async function calculateurSalaire(req, res) {
  try {
    if (!(await isParamActif('ia_calculateur_actif'))) {
      return res.status(403).json({
        success: false,
        message: 'Calculateur de salaire désactivé dans les paramètres IA.',
      });
    }

    const { poste, domaine, niveau, ville } = req.body || {};
    if (!String(poste || '').trim()) {
      return res.status(400).json({ success: false, message: 'poste requis' });
    }

    const cles = await _getClesIA();
    const prompt = `Tu es un expert RH du marché de l'emploi en Guinée (GNF).

Poste : ${poste}
Domaine : ${domaine || 'non précisé'}
Niveau : ${niveau || 'non précisé'}
Ville : ${ville || 'Conakry'}

Estime une fourchette salariale mensuelle réaliste en GNF pour ce profil (secteur privé / ONG / grandes entreprises locales si pertinent).

Réponds UNIQUEMENT avec ce JSON :
{
  "salaire_min": 0,
  "salaire_max": 0,
  "salaire_median": 0,
  "devise": "GNF",
  "conseils": ["conseil négociation 1", "conseil 2"]
}

Les montants sont des entiers (pas de décimales).`;

    const texte = await _appellerIA(prompt, cles, 'texte');
    if (!texte) return res.status(503).json({ success: false, message: 'IA non disponible' });

    let data = null;
    try {
      data = parseIaJson(texte);
    } catch (e1) {
      console.warn('[calculateurSalaire] parse initial echoue:', e1?.message || e1);
      const fixPrompt = `Corrige ce contenu en JSON STRICT valide, sans markdown.
Schema attendu:
{
  "salaire_min": 0,
  "salaire_max": 0,
  "salaire_median": 0,
  "devise": "GNF",
  "conseils": ["..."]
}
Contenu:
${String(texte).slice(0, 6000)}`;
      try {
        const fixed = await _appellerIA(fixPrompt, cles, 'texte');
        if (fixed) data = parseIaJson(fixed);
      } catch (e2) {
        console.warn('[calculateurSalaire] parse reformate echoue:', e2?.message || e2);
      }
    }
    if (!data || typeof data !== 'object') data = salaireFallback();
    const coerce = (v) => {
      const n = parseInt(String(v ?? 0).replace(/\s/g, ''), 10);
      return Number.isFinite(n) ? n : 0;
    };
    const out = {
      salaire_min: coerce(data.salaire_min || salaireFallback().salaire_min),
      salaire_max: coerce(data.salaire_max || salaireFallback().salaire_max),
      salaire_median: coerce(data.salaire_median || salaireFallback().salaire_median),
      devise: String(data.devise || 'GNF'),
      conseils: Array.isArray(data.conseils) && data.conseils.length
        ? data.conseils.map((c) => String(c))
        : salaireFallback().conseils,
    };

    return res.json({ success: true, data: out });
  } catch (err) {
    console.error('[calculateurSalaire]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}
