import { supabase } from '../config/supabase.js';
import { _appellerIA, _getClesIA, calculerMatchingScore } from './ia.service.js';
import { sendPlatformEmail } from './mail.service.js';
import { buildWrappedEmailHtml } from './emailLayout.service.js';
import { loadProfilMatchingPourChercheur } from './matchingProfil.service.js';

function esc(s) {
  return String(s ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function nettoyerJsonIa(texte) {
  const brut = String(texte || '')
    .replace(/```json/gi, '')
    .replace(/```/g, '')
    .replace(/\uFEFF/g, '')
    .trim();
  try {
    return JSON.parse(brut);
  } catch (_) {
    // Extraire le premier objet JSON complet via comptage d'accolades
    const start = brut.indexOf('{');
    if (start === -1) throw new Error('JSON IA invalide');
    let depth = 0;
    let inString = false;
    let escaped = false;
    let end = -1;
    for (let i = start; i < brut.length; i += 1) {
      const ch = brut[i];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (ch === '\\') {
          escaped = true;
        } else if (ch === '"') {
          inString = false;
        }
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
    if (end === -1) throw new Error('JSON IA invalide');
    const bloc = brut
      .slice(start, end + 1)
      .replace(/[\u0000-\u0019]/g, ' ');
    return JSON.parse(bloc);
  }
}

function toListe(value) {
  if (Array.isArray(value)) return value;
  if (value && typeof value === 'object') return Object.values(value);
  return [];
}

function _estimerAnneesExperience(depuisProfil) {
  const exps = toListe(depuisProfil);
  if (!exps.length) return 0;
  let annees = 0;
  for (const e of exps) {
    const texte = typeof e === 'string'
      ? e
      : `${e?.duree || ''} ${e?.description || ''} ${e?.title || ''}`;
    const match = String(texte).match(/(\d+)\s*an/i);
    if (match) {
      annees = Math.max(annees, Number(match[1]) || 0);
    }
  }
  return annees || Math.min(10, exps.length * 2);
}

function _niveauDepuisScore(score) {
  if (!Number.isFinite(score)) return 'inconnu';
  if (score >= 80) return 'excellent';
  if (score >= 60) return 'bon';
  if (score >= 40) return 'moyen';
  return 'faible';
}

async function _getParamBoolean(cle, fallback = true) {
  try {
    const { data } = await supabase
      .from('parametres_plateforme')
      .select('valeur')
      .eq('cle', cle)
      .maybeSingle();
    const v = String(data?.valeur ?? '').toLowerCase().trim();
    if (!v) return fallback;
    return ['true', '1', 'oui', 'on'].includes(v);
  } catch (_) {
    return fallback;
  }
}

async function _getParamInt(cle, fallback) {
  try {
    const { data } = await supabase
      .from('parametres_plateforme')
      .select('valeur')
      .eq('cle', cle)
      .maybeSingle();
    const n = parseInt(String(data?.valeur ?? ''), 10);
    return Number.isFinite(n) ? n : fallback;
  } catch (_) {
    return fallback;
  }
}

async function getSeuilAlerte(type = 'candidat') {
  const cle = type === 'entreprise'
    ? 'matching_seuil_alerte_entreprise'
    : 'matching_seuil_alerte_candidat';
  const fallback = type === 'entreprise' ? 70 : 65;
  return _getParamInt(cle, fallback);
}

async function _matchingAlertesActif() {
  return _getParamBoolean('matching_alertes_actif', true);
}

function _analyseFallback(candidat, offre, score) {
  const compsCand = new Set(toListe(candidat?.competences).map((c) => String(c).toLowerCase()));
  const compsOffre = toListe(offre?.competences_requises).map((c) => String(c));
  const communes = compsOffre
    .filter((c) => compsCand.has(String(c).toLowerCase()))
    .slice(0, 5);
  const manquantes = compsOffre
    .filter((c) => !compsCand.has(String(c).toLowerCase()))
    .slice(0, 5);
  return {
    score,
    niveau: _niveauDepuisScore(score),
    points_forts: communes.length ? communes : ['Profil partiellement compatible'],
    points_faibles: manquantes,
    conseils: [
      'Adaptez votre lettre de motivation aux competences demandees',
      'Mettez a jour votre profil avec vos competences recentes',
      'Consultez Parcours Carriere pour renforcer vos points faibles',
    ],
    message_court: score >= 60
      ? 'Bonne compatibilite globale pour cette offre.'
      : 'Compatibilite partielle. Vous pouvez postuler avec une candidature ciblee.',
    recommande_parcours: score < 60,
    source: 'fallback_local',
  };
}

async function _calculerScoreCohérent(candidat, offre) {
  try {
    // Utilise le même moteur que les recommandations/cartes
    const wrap = await loadProfilMatchingPourChercheur(candidat.id);
    const profil = wrap?.profil;
    if (profil) {
      const s = await calculerMatchingScore(profil, offre);
      if (Number.isFinite(s)) return Math.max(0, Math.min(100, Math.round(s)));
    }
  } catch (e) {
    console.warn('[analyser] calcul score coherent indisponible:', e?.message || e);
  }
  return _calculerScoreRapide(candidat, offre);
}

/**
 * Même moteur que les recommandations (calculerMatchingScore + fallback),
 * avec profil déjà chargé pour les boucles d’alertes.
 */
async function _scoreAlerteAvecProfilCache(candidat, offre, profilCache) {
  try {
    if (profilCache) {
      const s = await calculerMatchingScore(profilCache, offre);
      if (Number.isFinite(s)) return Math.max(0, Math.min(100, Math.round(s)));
    }
  } catch (e) {
    console.warn('[matchingAlerte] score alerte:', e?.message || e);
  }
  return _calculerScoreRapide(candidat, offre);
}

function _badgeCouleur(score) {
  if (score >= 80) return { bg: '#ECFDF5', border: '#10B981', text: '#047857', label: 'Excellent match' };
  if (score >= 60) return { bg: '#FFFBEB', border: '#F59E0B', text: '#B45309', label: 'Bonne compatibilité' };
  return { bg: '#FEF2F2', border: '#EF4444', text: '#B91C1C', label: 'Compatibilité à creuser' };
}

function _htmlCarteOffre(offre, score, appUrl) {
  const b = _badgeCouleur(score);
  const titre = esc(offre.titre || 'Offre');
  const sousTitre = [
    offre.entreprise?.nom_entreprise || 'Entreprise',
    offre.localisation || '',
    offre.type_contrat || '',
  ]
    .map((x) => String(x || '').trim())
    .filter(Boolean)
    .join(' · ') || '—';
  const url = `${String(appUrl || '').replace(/\/$/, '')}/offres/${offre.id}`;
  return `
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin:0 0 14px;border-collapse:separate;border:1px solid #E2E8F0;border-radius:12px;overflow:hidden;background:#FAFBFC;">
<tr>
<td style="padding:16px 18px;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0"><tr>
    <td style="vertical-align:top;">
      <p style="margin:0 0 6px;font-size:17px;font-weight:700;color:#0F172A;line-height:1.3;">${titre}</p>
      <p style="margin:0 0 10px;font-size:14px;color:#64748B;line-height:1.4;">${esc(sousTitre)}</p>
      <span style="display:inline-block;font-size:12px;font-weight:700;padding:5px 10px;border-radius:999px;background:${b.bg};border:1px solid ${b.border};color:${b.text};">${esc(b.label)} · ${score}%</span>
    </td>
    <td style="width:120px;vertical-align:middle;text-align:right;">
      <a href="${esc(url)}" style="display:inline-block;background:#1E293B;color:#ffffff;text-decoration:none;font-weight:700;font-size:13px;padding:10px 14px;border-radius:10px;">Voir l'offre</a>
    </td>
  </tr></table>
</td>
</tr>
</table>`;
}

async function _envoyerEmailMatching({ to, subject, text, innerHtml }) {
  const html = await buildWrappedEmailHtml(innerHtml);
  await sendPlatformEmail({ to, subject, text, html });
}

export async function analyserCompatibilite(candidatId, offreId) {
  try {
    console.log('[analyser] Debut analyse');
    console.log('[analyser] candidatId:', candidatId);
    console.log('[analyser] offreId:', offreId);
    const cles = await _getClesIA();
    console.log('[analyser] Anthropic:', cles.anthropicKey ? 'OK' : 'KO');
    console.log('[analyser] OpenAI:', cles.openaiKey ? 'OK' : 'KO');

    const { data: candidat, error: errCandidat } = await supabase
      .from('chercheurs_emploi')
      .select(`
        id, utilisateur_id, competences, niveau_etude, titre_poste, experiences, about
      `)
      .or(`id.eq.${candidatId},utilisateur_id.eq.${candidatId}`)
      .maybeSingle();
    let utilisateur = null;
    if (candidat?.utilisateur_id) {
      const { data: userRow } = await supabase
        .from('utilisateurs')
        .select('nom, email')
        .eq('id', candidat.utilisateur_id)
        .maybeSingle();
      utilisateur = userRow || null;
    }

    console.log('[analyser] Candidat trouve:', candidat ? 'OK' : 'KO');
    if (errCandidat) {
      console.error('[analyser] Erreur candidat:', errCandidat.message);
      console.error('[analyser] Detail candidat:', JSON.stringify(errCandidat));
    }
    if (candidat) {
      console.log('[analyser] Candidat.id:', candidat.id, '| utilisateur_id:', candidat.utilisateur_id);
      console.log('[analyser] Competences candidat:', JSON.stringify(toListe(candidat.competences)));
    }

    const { data: offre, error: errOffre } = await supabase
      .from('offres_emploi')
      .select(`
        id, titre, description, competences_requises, niveau_experience_requis,
        type_contrat, localisation, salaire_min, salaire_max,
        entreprise:entreprises(id, nom_entreprise, utilisateur_id)
      `)
      .eq('id', offreId)
      .maybeSingle();
    console.log('[analyser] Offre trouvee:', offre ? 'OK' : 'KO');
    if (errOffre) {
      console.error('[analyser] Erreur offre:', errOffre.message);
      console.error('[analyser] Detail offre:', JSON.stringify(errOffre));
    }
    if (offre) {
      console.log('[analyser] Titre offre:', offre.titre);
      console.log('[analyser] Competences requises:', JSON.stringify(toListe(offre.competences_requises)));
    }

    if (!candidat || !offre) {
      console.warn('[analyser] Candidat ou offre introuvable', {
        candidatFound: Boolean(candidat),
        offreFound: Boolean(offre),
        candidatId,
        offreId,
      });
      return null;
    }

    const prompt = `Tu es un expert en recrutement tres exigeant.
Analyse finement la compatibilite entre ce candidat et cette offre.
Ta reponse doit etre personnalisee, concrete, et differente selon le profil et l'offre.

PROFIL CANDIDAT :
- Titre : ${candidat.titre_poste || 'Non precise'}
- Competences : ${JSON.stringify(toListe(candidat.competences))}
- Niveau etudes : ${candidat.niveau_etude || 'Non precise'}
- Experience : ${_estimerAnneesExperience(candidat.experiences)} ans
- Resume profil : ${String(candidat.about || '').substring(0, 500) || 'Non precise'}
- Experiences : ${JSON.stringify(toListe(candidat.experiences).slice(0, 5))}

OFFRE D'EMPLOI :
- Titre : ${offre.titre || 'Offre'}
- Entreprise : ${offre.entreprise?.nom_entreprise || 'Entreprise'}
- Competences requises : ${JSON.stringify(toListe(offre.competences_requises))}
- Niveau experience requis : ${offre.niveau_experience_requis || 'Non precise'}
- Type contrat : ${offre.type_contrat || 'Non precise'}
- Localisation : ${offre.localisation || 'Non precise'}
- Description : ${String(offre.description || '').substring(0, 800)}

Reponds UNIQUEMENT en JSON valide :
{
  "score": <nombre entre 0 et 100>,
  "niveau": "<excellent|bon|moyen|faible>",
  "points_forts": ["max 4 points precis lies au profil et a l'offre"],
  "points_faibles": ["max 4 points precis lies au profil et a l'offre"],
  "conseils": ["max 4 actions concretes, non generiques, basees sur les ecarts detectes"],
  "message_court": "<une phrase honnete et specifique a ce candidat>",
  "recommande_parcours": <true|false>
}`;

    let analyse = null;
    let score = null;
    try {
      console.log('[analyser] Appel IA...');
      const reponse = await _appellerIA(prompt, cles, 'matching');
      if (!reponse) {
        console.warn('[analyser] Reponse IA vide, fallback local active');
      } else {
        console.log('[analyser] Reponse IA brute (extrait):', String(reponse).substring(0, 180));
        analyse = nettoyerJsonIa(reponse);
        score = Number.isFinite(Number(analyse?.score))
          ? Math.max(0, Math.min(100, Number(analyse.score)))
          : null;
        console.log('[analyser] Parse JSON OK, score:', score);
      }
    } catch (iaErr) {
      console.warn('[analyser] Erreur IA, fallback local:', iaErr?.message || iaErr);
    }

    // Score de reference uniquement (debug/monitoring), ne pas ecraser le score IA.
    const scoreCohérent = await _calculerScoreCohérent(candidat, offre);
    if (!analyse) {
      analyse = _analyseFallback(candidat, offre, scoreCohérent);
      score = scoreCohérent;
      console.log('[analyser] Fallback local utilise, score coherent:', score);
    } else {
      score = Number.isFinite(Number(analyse?.score))
        ? Math.max(0, Math.min(100, Number(analyse.score)))
        : scoreCohérent;
      analyse.score = score;
      if (!analyse.niveau || typeof analyse.niveau !== 'string') {
        analyse.niveau = _niveauDepuisScore(score);
      }
      if (!Array.isArray(analyse.points_forts)) {
        analyse.points_forts = _analyseFallback(candidat, offre, score).points_forts;
      }
      if (!Array.isArray(analyse.points_faibles)) {
        analyse.points_faibles = _analyseFallback(candidat, offre, score).points_faibles;
      }
      if (!Array.isArray(analyse.conseils)) {
        analyse.conseils = _analyseFallback(candidat, offre, score).conseils;
      }
      if (!analyse.message_court) {
        analyse.message_court = _analyseFallback(candidat, offre, score).message_court;
      }
      if (typeof analyse.recommande_parcours !== 'boolean') {
        analyse.recommande_parcours = score < 60;
      }
      analyse.score_reference = scoreCohérent;
      console.log('[analyser] Analyse IA normalisee, score IA:', score, '| score reference:', scoreCohérent);
    }

    await supabase
      .from('candidatures')
      .update({
        score_matching: score,
        analyse_ia: analyse,
        conseils_ia: JSON.stringify(toListe(analyse?.conseils)),
      })
      .eq('offre_id', offreId)
      .eq('chercheur_id', candidatId);

    return { analyse, candidat: { ...candidat, utilisateur }, offre };
  } catch (e) {
    console.error('[matchingAvance] analyserCompatibilite:', e?.message || e);
    return null;
  }
}

function _calculerScoreRapide(candidat, offre) {
  try {
    const compsCand = new Set(toListe(candidat?.competences).map((c) => String(c).toLowerCase()));
    const compsOffre = new Set(toListe(offre?.competences_requises).map((c) => String(c).toLowerCase()));
    let scoreComp = 40;
    if (compsOffre.size) {
      let match = 0;
      compsOffre.forEach((c) => {
        if (compsCand.has(c)) match += 1;
      });
      scoreComp = (match / compsOffre.size) * 60;
    }
    const expReq = parseInt(String(offre?.niveau_experience_requis || '0'), 10) || 0;
    const expCand = Number(_estimerAnneesExperience(candidat?.experiences));
    const scoreExp = expCand >= expReq ? 25 : Math.max(0, 25 - (expReq - expCand) * 5);
    const domaine = String(candidat?.about || '').toLowerCase();
    const desc = String(offre?.description || '').toLowerCase();
    const scoreDomaine = domaine && desc.includes(domaine) ? 15 : 5;
    return Math.min(100, Math.round(scoreComp + scoreExp + scoreDomaine));
  } catch (_) {
    return 0;
  }
}

async function envoyerAlerteOffreCandidat(candidat, offre, score) {
  const appUrl = process.env.PUBLIC_APP_URL || 'http://localhost:3001';
  const prenom = esc(candidat.nom || '');
  const inner = `
<p style="margin:0 0 16px;font-size:16px;color:#0F172A;">Bonjour <strong>${prenom}</strong>,</p>
<p style="margin:0 0 18px;color:#475569;line-height:1.6;">Nous avons détecté une <strong>nouvelle offre</strong> alignée avec votre profil.</p>
${_htmlCarteOffre(offre, score, appUrl)}
<p style="margin:16px 0 0;font-size:13px;color:#94A3B8;">Les pourcentages sont calculés avec le même moteur de matching que la plateforme (IA + signaux locaux lorsque l’IA est indisponible).</p>`;
  await _envoyerEmailMatching({
    to: candidat.email,
    subject: `Offre compatible : ${offre.titre || 'Offre'}`,
    text: `Bonjour ${candidat.nom || ''}, une offre compatible est disponible : ${offre.titre || 'Offre'} (${score}%). ${appUrl}/offres/${offre.id}`,
    innerHtml: inner,
  });
}

/**
 * Un seul e-mail avec plusieurs offres (mise à jour de profil).
 * @param {{ nom?: string, email: string }} candidat
 * @param {{ offre: object, score: number }[]} items
 */
async function envoyerDigestOffresCompatiblesCandidat(candidat, items) {
  const appUrl = process.env.PUBLIC_APP_URL || 'http://localhost:3001';
  const n = items.length;
  const prenom = esc(candidat.nom || '');
  const cartes = items.map(({ offre, score }) => _htmlCarteOffre(offre, score, appUrl)).join('');
  const inner = `
<p style="margin:0 0 16px;font-size:16px;color:#0F172A;">Bonjour <strong>${prenom}</strong>,</p>
<p style="margin:0 0 18px;color:#475569;line-height:1.6;">Suite à la mise à jour de votre profil, voici <strong>${n}</strong> offre${n > 1 ? 's' : ''} qui correspond${n > 1 ? 'ent' : ''} bien à votre parcours.</p>
${cartes}
<p style="margin:16px 0 0;font-size:13px;color:#94A3B8;">Scores calculés avec le moteur de matching plateforme (cohérent avec vos recommandations).</p>`;
  const sujet =
    n === 1
      ? `Offre compatible : ${items[0].offre.titre || 'Offre'}`
      : `${n} offres compatibles avec votre profil`;
  const texte = `Bonjour ${candidat.nom || ''}, ${n} offre(s) compatible(s). Consultez : ${appUrl}/offres`;
  await _envoyerEmailMatching({
    to: candidat.email,
    subject: sujet,
    text: texte,
    innerHtml: inner,
  });
}

export async function traiterAlertesNouvelleOffre(offreId) {
  try {
    if (!(await _matchingAlertesActif())) return;
    const { data: offre } = await supabase
      .from('offres_emploi')
      .select(
        'id, titre, description, competences_requises, niveau_experience_requis, localisation, type_contrat, entreprise:entreprises(id, nom_entreprise)',
      )
      .eq('id', offreId)
      .maybeSingle();
    if (!offre) return;
    const seuilCandidat = await getSeuilAlerte('candidat');
    const pauseMs = Math.max(0, await _getParamInt('matching_alertes_pause_ms', 600));
    const maxParExecution = Math.max(1, await _getParamInt('matching_alertes_max_par_execution', 25));
    let nbEnvoyees = 0;

    const { data: candidats } = await supabase
      .from('chercheurs_emploi')
      .select(`
        id, utilisateur_id, competences, niveau_etude, titre_poste, experiences, about,
        utilisateur:utilisateurs(id, nom, email, est_actif)
      `)
      .limit(50);

    for (const candidat of (candidats || [])) {
      if (nbEnvoyees >= maxParExecution) break;
      const user = candidat.utilisateur;
      if (!user?.email || user.est_actif === false) continue;

      const { data: deja } = await supabase
        .from('alertes_matching_envoyees')
        .select('id')
        .eq('candidat_id', candidat.id)
        .eq('offre_id', offreId)
        .eq('type_alerte', 'offre_compatible')
        .maybeSingle();
      if (deja) continue;

      const rapid = _calculerScoreRapide(candidat, offre);
      if (rapid < Math.max(12, seuilCandidat - 42)) continue;

      const wrapProfil = await loadProfilMatchingPourChercheur(candidat.id);
      const score = await _scoreAlerteAvecProfilCache(candidat, offre, wrapProfil?.profil);
      if (score < seuilCandidat) continue;

      await envoyerAlerteOffreCandidat(
        { id: candidat.id, nom: user.nom, email: user.email },
        offre,
        score,
      );

      await supabase.from('alertes_matching_envoyees').insert({
        candidat_id: candidat.id,
        offre_id: offre.id,
        type_alerte: 'offre_compatible',
        score,
      });
      nbEnvoyees += 1;
      if (pauseMs > 0) await new Promise((r) => setTimeout(r, pauseMs));
    }
  } catch (e) {
    console.error('[matchingAvance] traiterAlertesNouvelleOffre:', e?.message || e);
  }
}

async function envoyerAlerteProfilEntreprise(entreprise, candidat, offre, score) {
  const appUrl = process.env.PUBLIC_APP_URL || 'http://localhost:3001';
  const base = String(appUrl || '').replace(/\/$/, '');
  const lien = `${base}/recruteur/candidatures?offre=${offre.id}`;
  const b = _badgeCouleur(score);
  const inner = `
<p style="margin:0 0 16px;font-size:16px;color:#0F172A;">Bonjour <strong>${esc(entreprise.nom || '')}</strong>,</p>
<p style="margin:0 0 18px;color:#475569;line-height:1.6;">Un candidat ressort comme <strong>compatible</strong> avec votre offre <strong>${esc(offre.titre || 'Offre')}</strong>.</p>
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin:0 0 16px;border-collapse:separate;border:1px solid #E2E8F0;border-radius:12px;overflow:hidden;background:#FAFBFC;">
<tr><td style="padding:16px 18px;">
<p style="margin:0 0 8px;font-size:15px;color:#0F172A;"><strong>${esc(candidat.nom || 'Candidat')}</strong>${candidat.titre_profil ? ` <span style="color:#64748B;font-weight:400;">— ${esc(candidat.titre_profil)}</span>` : ''}</p>
<span style="display:inline-block;font-size:12px;font-weight:700;padding:5px 10px;border-radius:999px;background:${b.bg};border:1px solid ${b.border};color:${b.text};">Compatibilité estimée · ${score}%</span>
</td></tr></table>
<p style="margin:0;"><a href="${esc(lien)}" style="display:inline-block;background:#1E293B;color:#ffffff;text-decoration:none;font-weight:700;font-size:14px;padding:12px 18px;border-radius:10px;">Voir les candidatures</a></p>
<p style="margin:16px 0 0;font-size:13px;color:#94A3B8;">Score issu du moteur de matching plateforme (cohérent avec l’espace recruteur).</p>`;
  await _envoyerEmailMatching({
    to: entreprise.email,
    subject: `Profil compatible : ${offre.titre || 'Offre'}`,
    text: `Un profil compatible (${score}%) a été détecté pour votre offre ${offre.titre || 'Offre'}. ${lien}`,
    innerHtml: inner,
  });
}

export async function traiterAlerteProfilCompatible({ candidatId, offreId }) {
  try {
    if (!(await _matchingAlertesActif())) return;
    const { data: candidat } = await supabase
      .from('chercheurs_emploi')
      .select(`
        id, titre_poste, competences, niveau_etude, experiences, about,
        utilisateur:utilisateurs(nom, email)
      `)
      .eq('id', candidatId)
      .maybeSingle();
    const { data: offre } = await supabase
      .from('offres_emploi')
      .select(
        'id, titre, description, competences_requises, niveau_experience_requis, localisation, entreprise_id, entreprise:entreprises(id, nom_entreprise, utilisateur_id)',
      )
      .eq('id', offreId)
      .maybeSingle();
    if (!candidat || !offre?.entreprise?.utilisateur_id) return;

    const { data: entrepriseUser } = await supabase
      .from('utilisateurs')
      .select('email')
      .eq('id', offre.entreprise.utilisateur_id)
      .maybeSingle();
    if (!entrepriseUser?.email) return;

    const { data: deja } = await supabase
      .from('alertes_matching_envoyees')
      .select('id')
      .eq('entreprise_id', offre.entreprise.id)
      .eq('candidat_id', candidatId)
      .eq('offre_id', offreId)
      .eq('type_alerte', 'profil_compatible')
      .maybeSingle();
    if (deja) return;

    const seuilEntreprise = await getSeuilAlerte('entreprise');
    const wrapProfil = await loadProfilMatchingPourChercheur(candidat.id);
    const score = await _scoreAlerteAvecProfilCache(candidat, offre, wrapProfil?.profil);
    if (score < seuilEntreprise) return;

    await envoyerAlerteProfilEntreprise(
      { id: offre.entreprise.id, nom: offre.entreprise.nom_entreprise, email: entrepriseUser.email },
      { nom: candidat.utilisateur?.nom, titre_profil: candidat.titre_poste },
      offre,
      score,
    );
    await supabase.from('alertes_matching_envoyees').insert({
      entreprise_id: offre.entreprise.id,
      candidat_id: candidatId,
      offre_id: offreId,
      type_alerte: 'profil_compatible',
      score,
    });
  } catch (e) {
    console.error('[matchingAvance] traiterAlerteProfilCompatible:', e?.message || e);
  }
}

export async function traiterAlertesNouveauProfil(candidatId) {
  try {
    if (!(await _matchingAlertesActif())) return;
    const seuilCandidat = await getSeuilAlerte('candidat');
    const pauseMs = Math.max(0, await _getParamInt('matching_alertes_pause_ms', 600));
    const maxOffresDigest = Math.min(
      12,
      Math.max(1, await _getParamInt('matching_digest_max_offres', 8)),
    );
    const maxScoresIA = Math.min(
      40,
      Math.max(8, await _getParamInt('matching_alertes_score_pool', 25)),
    );

    const { data: candidat } = await supabase
      .from('chercheurs_emploi')
      .select(`
        id, utilisateur_id, competences, niveau_etude, titre_poste, experiences, about,
        utilisateur:utilisateurs(id, nom, email, est_actif)
      `)
      .or(`utilisateur_id.eq.${candidatId},id.eq.${candidatId}`)
      .maybeSingle();
    if (!candidat?.utilisateur?.email || candidat.utilisateur.est_actif === false) return;

    const { data: offres } = await supabase
      .from('offres_emploi')
      .select(
        'id, titre, description, competences_requises, niveau_experience_requis, localisation, type_contrat, entreprise:entreprises(id, nom_entreprise)',
      )
      .eq('statut', 'publiee')
      .order('date_publication', { ascending: false })
      .limit(40);
    if (!Array.isArray(offres) || offres.length === 0) return;

    const { data: dejaRows } = await supabase
      .from('alertes_matching_envoyees')
      .select('offre_id')
      .eq('candidat_id', candidat.id)
      .eq('type_alerte', 'offre_compatible');
    const dejaSet = new Set((dejaRows || []).map((r) => r.offre_id));

    const wrapProfil = await loadProfilMatchingPourChercheur(candidat.id);
    const profilCache = wrapProfil?.profil;

    let candidatsOffres = (offres || [])
      .filter((o) => !dejaSet.has(o.id))
      .map((offre) => ({ offre, rapid: _calculerScoreRapide(candidat, offre) }))
      .filter(({ rapid }) => rapid >= Math.max(10, seuilCandidat - 38))
      .sort((a, b) => b.rapid - a.rapid)
      .slice(0, maxScoresIA);

    if (candidatsOffres.length === 0) {
      candidatsOffres = (offres || [])
        .filter((o) => !dejaSet.has(o.id))
        .slice(0, maxScoresIA)
        .map((offre) => ({ offre, rapid: _calculerScoreRapide(candidat, offre) }));
    }

    const matches = [];
    for (const { offre } of candidatsOffres) {
      const score = await _scoreAlerteAvecProfilCache(candidat, offre, profilCache);
      if (score >= seuilCandidat) matches.push({ offre, score });
    }
    matches.sort((a, b) => b.score - a.score);
    const slice = matches.slice(0, maxOffresDigest);
    if (slice.length === 0) {
      console.log('[matchingAvance] traiterAlertesNouveauProfil: aucun match au-dessus du seuil');
      return;
    }

    await envoyerDigestOffresCompatiblesCandidat(
      { nom: candidat.utilisateur.nom, email: candidat.utilisateur.email },
      slice,
    );

    for (const { offre, score } of slice) {
      await supabase.from('alertes_matching_envoyees').insert({
        candidat_id: candidat.id,
        offre_id: offre.id,
        type_alerte: 'offre_compatible',
        score,
      });
    }
    if (pauseMs > 0) await new Promise((r) => setTimeout(r, pauseMs));
    console.log(
      `[matchingAvance] traiterAlertesNouveauProfil: digest ${slice.length} offre(s) (seuil ${seuilCandidat})`,
    );
  } catch (e) {
    console.error('[matchingAvance] traiterAlertesNouveauProfil:', e?.message || e);
  }
}

export { _calculerScoreRapide };
