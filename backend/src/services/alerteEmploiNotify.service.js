/**
 * Emails + push quand une offre est publiée :
 * 1) alertes emploi enregistrées (mots-clés, secteur, ville…)
 * 2) similarité profil candidat / offre (RapidAPI Text Similarity si clé, sinon recoupement de termes)
 */
import { supabase } from '../config/supabase.js';
import { ROLES } from '../config/constants.js';
import { getMailSettings } from '../config/mailSettings.js';
import { sendAlerteOffreMatchEmail } from './mail.service.js';
import { sendFcmToUserIds } from './push.service.js';
import { getTextSimilarityScore } from './nlpRapidApi.js';

const IA_MIN = parseFloat(process.env.ALERTE_IA_SIMILARITY_MIN || '0.34');
const JACCARD_MIN = parseFloat(process.env.ALERTE_FALLBACK_JACCARD_MIN || '0.075');
const MAX_PROFIL_CHECKS = Math.min(
  200,
  Math.max(20, parseInt(process.env.ALERTE_IA_MAX_CANDIDATS_PAR_OFFRE || '70', 10) || 70),
);

function competencesToText(comp) {
  if (!comp) return '';
  if (Array.isArray(comp)) return comp.map((c) => (typeof c === 'string' ? c : c?.name || '')).join(' ');
  if (typeof comp === 'object') return Object.values(comp).join(' ');
  return String(comp);
}

function buildOffreText(offre) {
  const comp = competencesToText(offre.competences_requises);
  return [offre.titre, offre.description, offre.exigences, comp].filter(Boolean).join(' ').slice(0, 5000);
}

function buildProfilTextChercheur(ch) {
  const parts = [
    ch.titre_poste,
    ch.about,
    ch.niveau_etude,
    competencesToText(ch.competences),
  ];
  return parts.filter(Boolean).join(' ').slice(0, 4000);
}

function jaccardWords(t1, t2) {
  const norm = (s) =>
    String(s || '')
      .toLowerCase()
      .replace(/[^\p{L}\p{N}\s]/gu, ' ')
      .split(/\s+/)
      .filter((w) => w.length > 2);
  const a = new Set(norm(t1));
  const b = new Set(norm(t2));
  if (!a.size || !b.size) return 0;
  let inter = 0;
  for (const x of a) if (b.has(x)) inter += 1;
  const union = a.size + b.size - inter;
  return union ? inter / union : 0;
}

function alerteMatchesOffre(alerte, offre) {
  const bloc = `${offre.titre || ''} ${offre.description || ''} ${offre.exigences || ''}`.toLowerCase();
  const mots = String(alerte.mots_cles || '')
    .toLowerCase()
    .split(/[\s,;]+/)
    .filter((m) => m.length > 1);
  if (mots.length && !mots.some((m) => bloc.includes(m))) return false;

  if (alerte.secteur && String(alerte.secteur).trim()) {
    const d = (offre.domaine || '').toLowerCase();
    const s = String(alerte.secteur).toLowerCase().trim();
    if (s && !d.includes(s)) return false;
  }
  if (alerte.ville && String(alerte.ville).trim()) {
    const l = (offre.localisation || '').toLowerCase();
    const v = String(alerte.ville).toLowerCase().trim();
    if (v && !l.includes(v)) return false;
  }
  if (alerte.salaire_min != null && offre.salaire_max != null) {
    if (Number(offre.salaire_max) < Number(alerte.salaire_min)) return false;
  }
  const types = Array.isArray(alerte.types_contrat) ? alerte.types_contrat : [];
  if (types.length) {
    const tc = String(offre.type_contrat || '').toLowerCase();
    const ok = types.some((t) => String(t).toLowerCase() === tc);
    if (!ok) return false;
  }
  return true;
}

/**
 * Candidats dont le profil (titre, à-propos, compétences) ressemble à l’offre — en complément des alertes sauvegardées.
 */
async function notifierProfilsSimilariteOffre(offre, cfg, emailed, pushTargets, entrepriseNom, lienOffres) {
  const disabled =
    process.env.ALERTE_PROFIL_IA_ENABLED === '0' || process.env.ALERTE_PROFIL_IA_ENABLED === 'false';
  if (disabled) return;
  if (!cfg.enabled || !cfg.notifEmailAlerteEmploi) return;

  const offreText = buildOffreText(offre);
  if (offreText.trim().length < 25) return;

  const { data: chercheurs, error: chErr } = await supabase
    .from('chercheurs_emploi')
    .select('id, utilisateur_id, titre_poste, about, competences, niveau_etude')
    .limit(800);

  if (chErr || !chercheurs?.length) return;

  const uids = [...new Set(chercheurs.map((c) => c.utilisateur_id).filter(Boolean))];
  const { data: users } = await supabase
    .from('utilisateurs')
    .select('id, email, nom, notif_offres_expiration, notif_push, role, est_actif, est_valide')
    .in('id', uids);

  const userById = Object.fromEntries((users || []).map((u) => [u.id, u]));

  const rows = [];
  for (const ch of chercheurs) {
    const uid = ch.utilisateur_id;
    if (!uid || emailed.has(uid)) continue;
    const u = userById[uid];
    if (!u?.est_actif || u.role !== ROLES.CHERCHEUR || !u.est_valide) continue;
    if (u.notif_offres_expiration === false) continue;
    const pt = buildProfilTextChercheur(ch);
    if (pt.trim().length < 12) continue;
    const jac = jaccardWords(pt, offreText);
    rows.push({ uid, u, pt, jac });
  }

  rows.sort((a, b) => b.jac - a.jac);
  const candidates = rows.slice(0, MAX_PROFIL_CHECKS);

  for (const row of candidates) {
    let apiScore = null;
    try {
      apiScore = await getTextSimilarityScore(row.pt, offreText);
    } catch {
      apiScore = null;
    }
    const score = apiScore != null ? apiScore : row.jac;
    const threshold = apiScore != null ? IA_MIN : Math.max(JACCARD_MIN, 0.065);
    if (score < threshold) continue;

    if (cfg.enabled && cfg.notifEmailAlerteEmploi && row.u.email) {
      emailed.add(row.uid);
      void sendAlerteOffreMatchEmail({
        to: row.u.email,
        nom: row.u.nom,
        offreTitre: offre.titre,
        entrepriseNom,
        localisation: offre.localisation,
        typeContrat: offre.type_contrat,
        lienOffres,
      });
    }
    if (row.u.notif_push) pushTargets.push(row.uid);
  }
}

export async function notifierAlertesPourOffrePubliee(offreId) {
  const { data: offre } = await supabase
    .from('offres_emploi')
    .select(
      `
      id, titre, description, exigences, localisation, type_contrat, domaine,
      salaire_min, salaire_max, statut, competences_requises,
      entreprises ( nom_entreprise )
    `,
    )
    .eq('id', offreId)
    .maybeSingle();

  if (!offre) return;
  const st = String(offre.statut || '').toLowerCase();
  if (!['publiee', 'active'].includes(st)) return;

  const cfg = await getMailSettings();

  const { data: alertes, error: aErr } = await supabase
    .from('alertes_emploi')
    .select('id, chercheur_id, mots_cles, secteur, ville, salaire_min, types_contrat, est_active')
    .eq('est_active', true);

  let chToUser = {};
  let userById = {};

  if (!aErr && alertes?.length) {
    const chIds = [...new Set(alertes.map((a) => a.chercheur_id))];
    const { data: chs } = await supabase
      .from('chercheurs_emploi')
      .select('id, utilisateur_id')
      .in('id', chIds);
    chToUser = Object.fromEntries((chs || []).map((c) => [c.id, c.utilisateur_id]));

    const uids = [...new Set(Object.values(chToUser).filter(Boolean))];
    const { data: users } = await supabase
      .from('utilisateurs')
      .select('id, email, nom, notif_offres_expiration, notif_push, role, est_actif, est_valide')
      .in('id', uids);
    userById = Object.fromEntries((users || []).map((u) => [u.id, u]));
  }

  const entrepriseNom = offre.entreprises?.nom_entreprise || '';
  const base = cfg.publicAppUrl.replace(/\/$/, '');
  const lienOffres = `${base}/#/dashboard/offres`;

  const emailed = new Set();
  const pushTargets = [];

  if (alertes?.length) {
    for (const a of alertes) {
      if (!alerteMatchesOffre(a, offre)) continue;
      const uid = chToUser[a.chercheur_id];
      if (!uid) continue;
      const u = userById[uid];
      if (!u?.est_actif || u.role !== ROLES.CHERCHEUR || !u.est_valide) continue;

      if (cfg.enabled && cfg.notifEmailAlerteEmploi && u.notif_offres_expiration !== false && u.email) {
        if (!emailed.has(uid)) {
          emailed.add(uid);
          void sendAlerteOffreMatchEmail({
            to: u.email,
            nom: u.nom,
            offreTitre: offre.titre,
            entrepriseNom,
            localisation: offre.localisation,
            typeContrat: offre.type_contrat,
            lienOffres,
          });
        }
      }
      if (u.notif_push) pushTargets.push(uid);
    }
  }

  await notifierProfilsSimilariteOffre(offre, cfg, emailed, pushTargets, entrepriseNom, lienOffres);

  if (pushTargets.length) {
    void sendFcmToUserIds([...new Set(pushTargets)], {
      title: 'Nouvelle offre',
      body: `${offre.titre || 'Offre'} — peut correspondre à votre profil`,
      data: { type: 'alerte_emploi', offre_id: String(offreId) },
    });
  }
}
