/**
 * Résumé hebdomadaire par e-mail (lundi 8h Africa/Conakry via cron, sauf DISABLE_CRON).
 *
 * Qui reçoit : candidats (role chercheur) actifs, validés, avec notif_resume_hebdo = true
 *   ET paramètre plateforme notif_email_resume_hebdo + SMTP actifs.
 * Fréquence : au plus un envoi par compte tous les 5 jours (évite doublons si cron relancé).
 *
 * Contenu : offres publiées (statut publiee/active) dont date_publication est dans les 7 derniers jours.
 * Les offres sont triées par pertinence locale (mots du profil candidat : titre recherché, à-propos, compétences)
 * quand ces champs sont renseignés ; sinon ordre chronologique.
 */
import { supabase } from '../config/supabase.js';
import { getMailSettings } from '../config/mailSettings.js';
import { applyTemplateVars, buildWrappedEmailHtml } from './emailLayout.service.js';
import { sendPlatformEmail } from './mail.service.js';
import { ROLES } from '../config/constants.js';

function esc(s) {
  return String(s || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function profilTextePourTri(ch) {
  if (!ch) return '';
  const comp =
    ch.competences == null
      ? ''
      : Array.isArray(ch.competences)
        ? ch.competences.join(' ')
        : typeof ch.competences === 'object'
          ? JSON.stringify(ch.competences)
          : String(ch.competences);
  return [ch.titre_poste, ch.about, comp].filter(Boolean).join(' ').toLowerCase();
}

function scoreOffrePourProfil(profilLower, offre) {
  if (!profilLower || profilLower.length < 8) return 0;
  const blob = `${offre.titre || ''} ${offre.localisation || ''} ${offre.type_contrat || ''}`.toLowerCase();
  const mots = profilLower.split(/\s+/).filter((w) => w.length > 2);
  let n = 0;
  for (const w of mots) {
    if (blob.includes(w)) n += 1;
  }
  return n;
}

function trierOffresPourCandidat(offres, chercheur) {
  const p = profilTextePourTri(chercheur);
  if (!p.trim()) return [...(offres || [])];
  return [...(offres || [])].sort(
    (a, b) => scoreOffrePourProfil(p, b) - scoreOffrePourProfil(p, a),
  );
}

export async function runWeeklyDigestJob() {
  const cfg = await getMailSettings();
  if (!cfg.enabled || !cfg.notifEmailResumeHebdo) {
    console.log('[weeklyDigest] Skip (SMTP off ou notif_email_resume_hebdo désactivé côté plateforme)');
    return;
  }

  const since = new Date(Date.now() - 7 * 24 * 3600 * 1000).toISOString();

  const { data: offres } = await supabase
    .from('offres_emploi')
    .select('id, titre, localisation, type_contrat, date_publication, entreprises ( nom_entreprise )')
    .in('statut', ['publiee', 'active'])
    .gte('date_publication', since)
    .order('date_publication', { ascending: false })
    .limit(40);

  const { data: users } = await supabase
    .from('utilisateurs')
    .select('id, email, nom, notif_resume_hebdo, dernier_resume_hebdo_envoye_at, est_actif, est_valide, role')
    .eq('role', ROLES.CHERCHEUR)
    .eq('est_actif', true)
    .eq('est_valide', true)
    .eq('notif_resume_hebdo', true);

  const minGapMs = 5 * 24 * 3600 * 1000;
  const now = Date.now();

  const userIds = (users || []).map((u) => u.id);
  const { data: profils } = await supabase
    .from('chercheurs_emploi')
    .select('utilisateur_id, titre_poste, about, competences')
    .in('utilisateur_id', userIds);
  const profilByUser = Object.fromEntries((profils || []).map((p) => [p.utilisateur_id, p]));

  for (const u of users || []) {
    if (!u.email) continue;
    const last = u.dernier_resume_hebdo_envoye_at ? new Date(u.dernier_resume_hebdo_envoye_at).getTime() : 0;
    if (last && now - last < minGapMs) continue;

    const ch = profilByUser[u.id];
    const sorted = trierOffresPourCandidat(offres || [], ch).slice(0, 12);
    const nbOffres = sorted.length;

    const subject = (cfg.templateResumeHebdoSujet || '').trim()
      ? applyTemplateVars(cfg.templateResumeHebdoSujet, {
          plateforme: cfg.platformName,
          nom: u.nom || '',
          nb_offres: String(nbOffres),
          nombre_offres: String(nbOffres),
        })
      : `Votre résumé hebdo — ${cfg.platformName}`;

    const items = sorted.map((o) => {
      const ent = o.entreprises?.nom_entreprise || 'Entreprise';
      return `<li style="margin:10px 0;line-height:1.45;"><strong>${esc(o.titre)}</strong><br/><span style="color:#64748b;font-size:14px;">${esc(ent)} · ${esc(o.localisation || '')} · ${esc(o.type_contrat || '')}</span></li>`;
    });

    const inner =
      `<p style="margin:0 0 16px;">Bonjour ${esc(u.nom || '')},</p>`
      + `<p style="margin:0 0 12px;">Voici une sélection d’offres publiées sur <strong>${esc(cfg.platformName)}</strong> au cours des <strong>7 derniers jours</strong>.</p>`
      + `<p style="margin:0 0 16px;font-size:14px;color:#64748b;">Ce message est envoyé <strong>chaque lundi</strong> (fuseau Africa/Conakry) tant que l’option « résumé hebdomadaire » reste activée dans vos paramètres et que l’administrateur autorise les e-mails récapitulatifs.</p>`
      + `<p style="margin:0 0 12px;font-size:14px;color:#64748b;">Pour être alerté en temps réel lorsqu’une offre correspond à vos critères ou à votre profil, activez aussi les <strong>alertes emploi</strong> et les <strong>notifications par e-mail</strong> dans vos préférences.</p>`
      + `<ul style="margin:0;padding-left:20px;list-style:disc;">${items.join('') || '<li style="color:#64748b;">Aucune nouvelle offre sur cette période.</li>'}</ul>`
      + `<p style="margin:20px 0 0;font-size:14px;color:#64748b;">À bientôt sur la plateforme.</p>`;

    const html = await buildWrappedEmailHtml(inner);
    const textLines = sorted.map((o) => `- ${o.titre} (${o.entreprises?.nom_entreprise || ''})`);
    const text =
      `Bonjour ${u.nom || ''},\n\n`
      + 'Offres des 7 derniers jours sur la plateforme :\n'
      + `${textLines.join('\n') || '(aucune)'}\n\n`
      + 'Résumé envoyé automatiquement chaque lundi si l’option est activée.\n\n'
      + `— ${cfg.platformName}`;

    try {
      const r = await sendPlatformEmail({ to: u.email, subject, text, html });
      if (r.ok) {
        await supabase
          .from('utilisateurs')
          .update({ dernier_resume_hebdo_envoye_at: new Date().toISOString() })
          .eq('id', u.id);
      }
    } catch (e) {
      console.warn('[weeklyDigest]', u.email, e.message);
    }
  }

  console.log('[weeklyDigest] Terminé — candidats éligibles:', (users || []).length);
}
