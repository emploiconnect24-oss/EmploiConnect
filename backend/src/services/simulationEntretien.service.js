import { _appellerIA, _getClesIA } from './ia.service.js';

function stripJson(text) {
  const raw = String(text || '').replace(/```json/gi, '').replace(/```/g, '').trim();
  try {
    return JSON.parse(raw);
  } catch (_) {
    const s = raw.indexOf('{');
    const e = raw.lastIndexOf('}');
    if (s === -1 || e <= s) throw new Error('JSON IA invalide');
    return JSON.parse(raw.slice(s, e + 1));
  }
}

export async function genererPremierMessage(posteVise, profil, recruteur = {}) {
  try {
    const cles = await _getClesIA();
    const nomRecruteur = recruteur.nom || 'Recruteur EmploiConnect';
    const titreRecruteur = recruteur.titre || 'Responsable Recrutement';
    const prenom = String(profil.nom || 'Candidat').split(' ')[0];
    const prompt = `Tu es ${nomRecruteur}, ${titreRecruteur} chez EmploiConnect Guinee.
Tu conduis un entretien d'embauche pour: ${posteVise}.

Profil complet du candidat:
- Nom: ${profil.nom || 'Candidat'}
- Titre actuel: ${profil.titre_profil || 'Non precise'}
- Competences: ${JSON.stringify(profil.competences || [])}
- Experience: ${profil.experience_annees || 0} ans
- Niveau d'etudes: ${profil.niveau_etudes || ''}
- Domaine: ${profil.domaine_activite || ''}
- Langues: ${JSON.stringify(profil.langues || [])}
- Objectif: ${profil.objectif || ''}

Tu as deja son profil. Tu n'as pas besoin de demander son CV.
Tu peux faire reference a ses competences dans tes questions.

Commence par:
1. Te presenter (nom + titre)
2. Accueillir ${profil.nom || 'Candidat'} chaleureusement
3. Mentionner que tu as consulte son profil
4. Poser la 1ere question de presentation

Style: naturel, professionnel, chaleureux sans être familier — comme un vrai recruteur en visio.
Max 4 phrases. Pas de markdown.`;
    const rep = await _appellerIA(prompt, cles, 'texte');
    return String(rep || '').trim() || `Bonjour ${prenom}, je suis ${nomRecruteur}, ${titreRecruteur}. J'ai consulte votre profil pour le poste de ${posteVise}. Je vais vous poser quelques questions basees sur votre parcours. Pour commencer, pouvez-vous vous presenter s'il vous plait ?`;
  } catch (_) {
    const nomRecruteur = recruteur.nom || 'Recruteur EmploiConnect';
    const titreRecruteur = recruteur.titre || 'Responsable Recrutement';
    return `Bonjour ${profil.nom || 'Candidat'} ! Je suis ${nomRecruteur}, ${titreRecruteur}. Ravi de vous recevoir pour ce poste de ${posteVise}. Commencons. Pouvez-vous vous presenter ?`;
  }
}

export async function genererProchainMessage(historique, posteVise, profil, nbQuestions, recruteur = {}) {
  try {
    const cles = await _getClesIA();
    const nomRecruteur = recruteur.nom || 'Recruteur';
    const titreRecruteur = recruteur.titre || 'Responsable Recrutement';
    const nomCandidat = profil.nom || 'Candidat';
    const histo = (historique || [])
      .slice(-8)
      .map((m) => `${m.role === 'recruteur' ? nomRecruteur : nomCandidat}: ${m.contenu}`)
      .join('\n');
    const prompt = `Tu es ${nomRecruteur}, ${titreRecruteur}, en train de conduire un entretien pour le poste de ${posteVise}.

Historique:
${histo}

Tu as pose ${nbQuestions} questions jusqu'ici.

Regles:
- Tu decides toi-meme quand terminer (entre 6 et 12 questions)
- Si les reponses sont insuffisantes, poursuis avec une question de relance ou un angle different (pas de repetition mecanique)
- Si les reponses sont tres bonnes, tu peux conclure naturellement
- Si le candidat est grossier, agressif, insultant ou manifestement de mauvaise foi, tu PEUX cloturer tot l'entretien (meme avant 6 questions) avec un message professionnel ferme et sobre, sans t'engueuler
- Pose UNE seule question a la fois
- Questions variees: motivation, competences, experiences, situations, objectifs, soft skills
- Ton: calme, pedagogique, humain — evite les formulations toutes faites de script RH

Si tu veux terminer, reponds exactement:
FIN_ENTRETIEN: <message de cloture chaleureux ou neutre selon le contexte>

Sinon, une courte reconnaissance de la derniere reponse si pertinent (1 phrase max), puis la prochaine question. Pas de markdown. Max 3 phrases au total.`;
    const rep = await _appellerIA(prompt, cles, 'texte');
    const texte = String(rep || '').trim();
    if (!texte) {
      return { message: 'Tres bien. Parlez-moi de vos objectifs professionnels.', estFin: false };
    }
    if (texte.includes('FIN_ENTRETIEN:')) {
      return { message: texte.replace('FIN_ENTRETIEN:', '').trim(), estFin: true };
    }
    if (nbQuestions >= 12) {
      return {
        message: `Merci beaucoup ${nomCandidat} pour cet entretien. Vous avez repondu a toutes nos questions. Nous reviendrons vers vous tres prochainement avec notre decision.`,
        estFin: true,
      };
    }
    return {
      message: texte,
      estFin: false,
    };
  } catch (_) {
    return {
      message: 'Pouvez-vous me parler de vos competences principales ?',
      estFin: nbQuestions >= 12,
    };
  }
}

function _normaliserRapport(parsed, fallback) {
  const clamp = (n, lo, hi) => Math.min(hi, Math.max(lo, Number.isFinite(n) ? n : lo));
  return {
    score_global: clamp(Number(parsed.score_global ?? fallback.score_global), 0, 100),
    note_presentation: clamp(Number(parsed.note_presentation ?? fallback.note_presentation), 0, 10),
    note_motivation: clamp(Number(parsed.note_motivation ?? fallback.note_motivation), 0, 10),
    note_competences: clamp(Number(parsed.note_competences ?? fallback.note_competences), 0, 10),
    note_communication: clamp(Number(parsed.note_communication ?? fallback.note_communication), 0, 10),
    points_forts: Array.isArray(parsed.points_forts) ? parsed.points_forts.map(String) : fallback.points_forts,
    points_ameliorer: Array.isArray(parsed.points_ameliorer)
      ? parsed.points_ameliorer.map(String)
      : fallback.points_ameliorer,
    conseils: Array.isArray(parsed.conseils) ? parsed.conseils.map(String) : fallback.conseils,
    verdict: String(parsed.verdict || fallback.verdict),
    commentaire_global: String(parsed.commentaire_global || fallback.commentaire_global),
  };
}

function _rapportHeuristique(historique, posteVise, profil, meta = {}) {
  const msgs = Array.isArray(historique) ? historique : [];
  const cand = msgs.filter((m) => m.role === 'candidat').map((m) => String(m.contenu || ''));
  const rec = msgs.filter((m) => m.role === 'recruteur').map((m) => String(m.contenu || ''));
  const avgLen = cand.length ? cand.reduce((a, b) => a + b.length, 0) / cand.length : 0;
  const totalCand = cand.join(' ').toLowerCase();
  const motsVagues = /(je sais pas|aucune idee|bof|n importe quoi|chiant|fermer|ta gueule)/i;
  let score = 48;
  if (avgLen > 120) score += 18;
  else if (avgLen > 50) score += 10;
  else if (avgLen < 25 && cand.length > 0) score -= 22;
  if (cand.length >= 8) score += 8;
  if (cand.length <= 2) score -= 18;
  if (meta.entretienCourt) score -= 15;
  if (motsVagues.test(totalCand)) score -= 25;
  const comp = Array.isArray(profil?.competences) ? profil.competences.slice(0, 3) : [];
  const citeComp = comp.filter((c) => totalCand.includes(String(c).toLowerCase()));
  if (citeComp.length) score += 6;
  score = Math.max(12, Math.min(96, Math.round(score)));

  const nom = profil?.nom || 'Le candidat';
  const snippet = cand[0] ? cand[0].slice(0, 120) : '';
  const points_forts = [];
  if (citeComp.length) {
    points_forts.push(`Mention explicite de compétences alignées avec le profil (${citeComp.join(', ')}).`);
  } else if (avgLen > 80) {
    points_forts.push(`Réponses développées (longueur moyenne ~${Math.round(avgLen)} caractères), ce qui laisse de la matière pour évaluer le fond.`);
  } else if (snippet) {
    points_forts.push(`Première réponse utile pour démarrer l'échange : « ${snippet}${snippet.length >= 120 ? '…' : ''} ».`);
  } else {
    points_forts.push(`Participation à l'entretien pour le poste « ${posteVise} ».`);
  }

  const points_ameliorer = [];
  if (meta.entretienCourt) {
    points_ameliorer.push("Entretien très court : peu de questions/réponses pour trancher sur l'adéquation au poste.");
  }
  if (avgLen < 40 && cand.length > 0) {
    points_ameliorer.push('Réponses souvent courtes : détailler davantage contexte, actions et résultats.');
  }
  if (!citeComp.length && comp.length) {
    points_ameliorer.push(`Relier davantage vos réponses aux compétences clés du profil (${comp.slice(0, 4).join(', ') || 'voir CV'}).`);
  }
  if (motsVagues.test(totalCand)) {
    points_ameliorer.push('Ton ou formulations inappropriés pour un entretien professionnel : à corriger impérativement.');
  }

  const conseils = [];
  if (avgLen < 60) {
    conseils.push('Pour chaque question, viser 3 parties : situation, action, résultat (même en 4–5 phrases).');
  }
  conseils.push(`Préparer 2 exemples concrets sur le métier « ${posteVise} » et les réutiliser selon les questions.`);

  let verdict = 'Bien';
  if (score >= 85) verdict = 'Excellent';
  else if (score >= 70) verdict = 'Tres bien';
  else if (score < 45) verdict = 'A ameliorer';

  const commentaire_global =
    `${nom} a produit ${cand.length} réponse(s) dans cet exercice pour le poste « ${posteVise} ». ` +
    (meta.entretienCourt
      ? "L'échange a été court : le bilan reste donc partiel. "
      : '') +
    `Le score ${score}/100 reflète ce qu'on peut déduire du transcript (clarté, exemples, adéquation, ton). Ce simulateur vise à vous aider à progresser, pas à vous juger.`;

  return {
    score_global: score,
    note_presentation: Math.round((score / 100) * 10),
    note_motivation: Math.round((score / 100) * 10),
    note_competences: Math.round((score / 100) * 10),
    note_communication: Math.round((score / 100) * 10),
    points_forts,
    points_ameliorer,
    conseils,
    verdict,
    commentaire_global,
  };
}

export async function genererRapportFinal(historique, posteVise, profil, meta = {}) {
  const fallback = _rapportHeuristique(historique, posteVise, profil, meta);
  const nomRec = meta?.recruteur?.nom || 'Recruteur';
  const titreRec = meta?.recruteur?.titre || '';
  const conv = (historique || [])
    .map((m, i) => {
      const role = m.role === 'recruteur' ? `Recruteur (${nomRec}${titreRec ? `, ${titreRec}` : ''})` : `Candidat (${profil?.nom || 'Candidat'})`;
      return `[${i + 1}] ${role}: ${m.contenu}`;
    })
    .join('\n');
  const profilResume = JSON.stringify({
    nom: profil?.nom,
    titre_profil: profil?.titre_profil,
    competences: profil?.competences || [],
    experience_annees: profil?.experience_annees,
    objectif: profil?.objectif,
    domaine: profil?.domaine_activite,
  });

  const promptBase = `Tu es un expert RH senior et coach carrière. Tu rédiges un compte-rendu sincère mais bienveillant après un entretien simulé pour le poste: "${posteVise}".
Le candidat utilisera ce retour pour progresser : sois honnête sur les axes d'amélioration, jamais méprisant.

TRANSCRIPT (ordre chronologique — ne rien inventer; tout argument doit pouvoir se rattacher à ce texte):
${conv || '(vide)'}

Résumé profil candidat (contexte uniquement):
${profilResume}

Métadonnées: questions posées au candidat ≈ ${meta.nbQuestions ?? '?'}. Entretien court (peu d'échanges) = ${meta.entretienCourt ? 'oui' : 'non'}.

GRILLE INDICATIVE pour score_global (adapter au cas réel, pas mécanique):
- 85-100: réponses précises, exemples pertinents, lien clair avec le poste, ton professionnel.
- 65-84: bon niveau global avec quelques lacunes identifiables dans le transcript.
- 45-64: réponses inégales, manque d'exemples ou de structure, ou peu d'éléments vérifiables.
- 15-44: problèmes graves (hors sujet, ton inadapté, fuites, agressivité) OU entretien trop court pour conclure positivement.
Ne plafonne pas artificiellement à 65 : si la performance est faible dans le transcript, le score doit le refléter.

RÈGLES STRICTES:
1) score_global (0-100): cohérent avec la qualité observée (précision, structure STAR si pertinent, exemples, adéquation au poste, ton). Une fin brutale ou un candidat inapproprié dans le transcript → score bas.
2) notes 0-10 (note_presentation, note_motivation, note_competences, note_communication): chacune doit varier selon le transcript (pas quatre notes identiques par défaut).
3) points_forts (3 à 5 items): chaque phrase cite ou paraphrase un fait tiré du transcript (projet, compétence nommée, chiffre, responsabilité). INTERDIT sans preuve textuelle: "communication claire", "bonne présentation", "attitude positive", "écoute active", "esprit d'équipe".
4) points_ameliorer (3 à 5 items): un manque précis par item, lié à une réponse ou un trou dans l'échange (ex: "Quand on vous demande X, vous répondez Y sans exemple"). Formulation respectueuse (vous / le candidat).
5) conseils (3 à 5 items): actions concrètes pour le PROCHAIN entretien (préparation, structure de réponse, reformulation). Une piste par axe d'amélioration.
6) verdict: Excellent | Tres bien | Bien | A ameliorer — aligné avec le score_global.
7) commentaire_global: 4 à 7 phrases en français, ton de retour oral professionnel : synthèse du déroulé, pourquoi ce score, ce qui manquait ou ce qui a bien fonctionné, et une phrase d'encouragement ou de perspective réaliste. Si l'entretien s'est arrêté tôt, l'expliquer sans dramatiser.

Réponds UNIQUEMENT avec un JSON valide (pas de markdown), exactement ces clés:
{
  "score_global": <number>,
  "note_presentation": <number>,
  "note_motivation": <number>,
  "note_competences": <number>,
  "note_communication": <number>,
  "points_forts": ["..."],
  "points_ameliorer": ["..."],
  "conseils": ["..."],
  "verdict": "...",
  "commentaire_global": "..."
}`;

  try {
    const cles = await _getClesIA();
    const rep = await _appellerIA(promptBase, cles, 'texte');
    if (!rep) throw new Error('IA indisponible');
    let parsed;
    try {
      parsed = stripJson(rep);
    } catch (e1) {
      const rep2 = await _appellerIA(
        `Le texte suivant devait être un JSON strict (compte-rendu d'entretien) mais est invalide. Extrais les champs ou reconstruis-les pour produire UNIQUEMENT un JSON avec les clés: score_global, note_presentation, note_motivation, note_competences, note_communication, points_forts, points_ameliorer, conseils, verdict, commentaire_global. Pas de markdown, pas de texte hors JSON.\n\n---\n${String(rep).slice(0, 12000)}\n---`,
        cles,
        'texte',
      );
      parsed = stripJson(rep2);
    }
    const out = _normaliserRapport(parsed, fallback);
    if (out.points_forts.length < 2) out.points_forts = fallback.points_forts;
    if (out.points_ameliorer.length < 2) out.points_ameliorer = fallback.points_ameliorer;
    if (out.conseils.length < 2) out.conseils = fallback.conseils;
    return out;
  } catch (e) {
    console.error('[simulation] Rapport:', e?.message || e);
    return fallback;
  }
}
