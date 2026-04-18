/**
 * Emails transactionnels (SMTP configuré en admin).
 * Ne bloque jamais les routes HTTP.
 */
import nodemailer from 'nodemailer';
import { supabase } from '../config/supabase.js';
import { ROLES } from '../config/constants.js';
import { getMailSettings } from '../config/mailSettings.js';
import { buildWrappedEmailHtml } from './emailLayout.service.js';

function applyTemplate(str, vars) {
  let out = String(str || '');
  Object.entries(vars).forEach(([k, v]) => {
    const re = new RegExp(`\\{\\{\\s*${k}\\s*\\}\\}`, 'g');
    out = out.replace(re, v == null ? '' : String(v));
  });
  return out;
}

function htmlEscape(s) {
  return String(s || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function textToHtml(text) {
  return `<p>${htmlEscape(text).replace(/\n/g, '<br/>')}</p>`;
}

async function createTransporter() {
  const cfg = await getMailSettings();
  if (!cfg.enabled || !cfg.host || !cfg.user || !cfg.password) {
    return null;
  }
  return nodemailer.createTransport({
    host: cfg.host,
    port: cfg.port,
    secure: cfg.port === 465,
    auth: {
      user: cfg.user,
      pass: cfg.password,
    },
  });
}

/**
 * @param {{ to: string, subject: string, text: string, html?: string }} opts
 * @returns {Promise<{ ok: boolean, error?: string }>}
 */
export async function sendPlatformEmail({ to, subject, text, html }) {
  const cfg = await getMailSettings();
  if (!cfg.enabled) {
    return { ok: false, error: 'Service email désactivé (admin)' };
  }
  if (!to || !subject) {
    return { ok: false, error: 'Destinataire ou sujet manquant' };
  }

  const transporter = await createTransporter();
  if (!transporter) {
    return { ok: false, error: 'SMTP incomplet (hôte, utilisateur ou mot de passe)' };
  }

  try {
    await transporter.sendMail({
      from: `"${cfg.fromName.replace(/"/g, '')}" <${cfg.from || cfg.user}>`,
      to: String(to).trim(),
      subject: String(subject).slice(0, 200),
      text: text || undefined,
      html: html || undefined,
    });
    return { ok: true };
  } catch (err) {
    console.warn('[mail] Envoi échoué:', err.message);
    return { ok: false, error: err.message };
  }
}

export async function sendWelcomeEmailOnRegister(user, validationManuelle) {
  const cfg = await getMailSettings();
  if (!cfg.enabled || !user?.email) return;

  const vars = {
    nom: user.nom || '',
    email: user.email || '',
    role: user.role || '',
    plateforme: cfg.platformName,
  };

  const subject = cfg.tplWelcomeSubject
    ? applyTemplate(cfg.tplWelcomeSubject, vars)
    : `Bienvenue sur ${cfg.platformName}`;

  let body = cfg.tplWelcomeBody
    ? applyTemplate(cfg.tplWelcomeBody, vars)
    : '';

  if (!body) {
    body = validationManuelle
      ? `Bonjour ${vars.nom},\n\nVotre compte sur ${cfg.platformName} a bien été créé.\nUn administrateur doit valider votre inscription avant que vous puissiez vous connecter.\n\nVous recevrez un message lorsque votre compte sera validé.\n\nCordialement,\nL'équipe ${cfg.platformName}`
      : `Bonjour ${vars.nom},\n\nVotre compte sur ${cfg.platformName} a bien été créé et est actif.\n\nVous pouvez maintenant rechercher des offres, compléter votre profil et postuler.\n\nCordialement,\nL'équipe ${cfg.platformName}`;
  }

  const appUrl = String(cfg.publicAppUrl || '').replace(/\/$/, '') || 'http://localhost:3001';
  const safeNom = htmlEscape(vars.nom);
  const safeEmail = htmlEscape(vars.email);
  const safePlateforme = htmlEscape(cfg.platformName);
  const ctaHref = `${appUrl}/offres`;
  const inner = validationManuelle
    ? `<h2 style="margin:0 0 10px;color:#0F172A;">Bienvenue ${safeNom} !</h2>
<p style="margin:0 0 14px;color:#374151;line-height:1.7;">Votre compte sur <strong>${safePlateforme}</strong> a été créé et attend la validation d'un administrateur.</p>
<div style="background:#F8FAFC;border:1px solid #E2E8F0;border-radius:10px;padding:14px;margin:0 0 14px;">
  <p style="margin:0;font-size:13px;color:#475569;">Email : <strong>${safeEmail}</strong></p>
</div>
<p style="margin:0;color:#64748B;font-size:13px;">Vous recevrez un email dès activation du compte.</p>`
    : `<h2 style="margin:0 0 10px;color:#0F172A;">Bienvenue sur ${safePlateforme}, ${safeNom} !</h2>
<p style="margin:0 0 14px;color:#374151;line-height:1.7;">Votre compte est actif et prêt à l'emploi.</p>
<div style="background:#F0F7FF;border-left:4px solid #1A56DB;border-radius:10px;padding:14px;margin:0 0 14px;">
  <p style="margin:0;font-size:13px;color:#1E40AF;">✅ Compte actif · 📧 <strong>${safeEmail}</strong></p>
</div>
<ul style="margin:0 0 16px;padding-left:18px;color:#374151;line-height:1.8;">
  <li>Rechercher des offres d'emploi</li>
  <li>Optimiser votre profil avec l'IA</li>
  <li>Postuler en quelques clics</li>
</ul>
<p style="text-align:center;margin:0;"><a href="${htmlEscape(ctaHref)}" style="display:inline-block;padding:12px 22px;background:#1A56DB;color:#fff;text-decoration:none;border-radius:8px;font-weight:600;">Voir les offres</a></p>`;
  const html = await buildWrappedEmailHtml(inner);

  void sendPlatformEmail({
    to: user.email,
    subject,
    text: body,
    html,
  }).then((r) => {
    if (!r.ok) console.warn('[mail] Bienvenue non envoyé:', r.error);
  });
}

export async function sendSousAdminWelcomeEmail({
  nom,
  email,
  motDePasse,
  roleNom,
}) {
  const cfg = await getMailSettings();
  if (!cfg.enabled || !email) return { ok: false, error: 'Email désactivé ou adresse manquante' };
  const appUrl = String(cfg.publicAppUrl || '').replace(/\/$/, '') || 'http://localhost:3001';
  const safeNom = htmlEscape(nom || '');
  const safeEmail = htmlEscape(email || '');
  const safeRole = htmlEscape(roleNom || 'Administrateur');
  const safePwd = htmlEscape(motDePasse || '');
  const safeApp = htmlEscape(`${appUrl}/admin/login`);
  const subject = 'Votre accès EmploiConnect — Bienvenue';
  const text =
    `Bonjour ${nom || ''},\n\n`
    + `Un compte administrateur a été créé sur ${cfg.platformName}.\n`
    + `Email: ${email}\nMot de passe: ${motDePasse}\nRôle: ${roleNom || 'Administrateur'}\n\n`
    + `Connexion: ${appUrl}/admin/login\n\n`
    + 'Veuillez changer votre mot de passe dès la première connexion.';
  const inner = `<h2 style="margin:0 0 12px;color:#0F172A;">Bienvenue, ${safeNom} !</h2>
<p style="margin:0 0 14px;color:#374151;line-height:1.7;">Un compte administrateur a été créé pour vous sur <strong>${htmlEscape(cfg.platformName)}</strong>.</p>
<div style="background:#F0F7FF;border-left:4px solid #1A56DB;border-radius:10px;padding:14px;margin:0 0 14px;">
  <p style="margin:0;color:#1E40AF;font-weight:700;">Vos informations de connexion</p>
  <p style="margin:6px 0 0;color:#374151;">📧 <strong>${safeEmail}</strong></p>
  <p style="margin:4px 0 0;color:#374151;">🔑 <strong>${safePwd}</strong></p>
  <p style="margin:4px 0 0;color:#374151;">👤 <strong>${safeRole}</strong></p>
</div>
<p style="margin:0 0 16px;color:#B91C1C;font-size:13px;">⚠️ Changez votre mot de passe dès la première connexion.</p>
<p style="text-align:center;margin:0;"><a href="${safeApp}" style="display:inline-block;padding:12px 22px;background:#1A56DB;color:#fff;text-decoration:none;border-radius:8px;font-weight:600;">Accéder au panneau admin</a></p>`;
  const html = await buildWrappedEmailHtml(inner);
  return sendPlatformEmail({ to: email, subject, text, html });
}

export async function sendAccountValidatedEmail(user) {
  const cfg = await getMailSettings();
  if (!cfg.enabled || !cfg.notifEmailValidation || !user?.email) return;

  const vars = {
    nom: user.nom || '',
    email: user.email || '',
    plateforme: cfg.platformName,
  };

  const subject = cfg.tplValidationSubject
    ? applyTemplate(cfg.tplValidationSubject, vars)
    : `Votre compte ${cfg.platformName} est validé`;

  const text = `Bonjour ${vars.nom},\n\n`
    + `Bonne nouvelle : votre compte sur ${cfg.platformName} a été validé par un administrateur.\n`
    + 'Vous pouvez maintenant vous connecter.\n\n'
    + `Cordialement,\nL'équipe ${cfg.platformName}`;

  void sendPlatformEmail({
    to: user.email,
    subject,
    text,
    html: textToHtml(text),
  }).then((r) => {
    if (!r.ok) console.warn('[mail] Validation non envoyée:', r.error);
  });
}

export async function sendAccountRejectedEmail(user, raison) {
  const cfg = await getMailSettings();
  if (!cfg.enabled || !cfg.notifEmailCompteRejete || !user?.email) return;

  const vars = {
    nom: user.nom || '',
    email: user.email || '',
    plateforme: cfg.platformName,
    raison: raison || '',
  };

  const subject = `Compte non retenu — ${cfg.platformName}`;
  const text = `Bonjour ${vars.nom},\n\n`
    + `Votre demande d'inscription sur ${cfg.platformName} n'a pas été retenue.\n`
    + (vars.raison ? `Motif : ${vars.raison}\n\n` : '\n')
    + 'Pour toute question, utilisez les coordonnées de contact du site.\n\n'
    + `— ${cfg.platformName}`;

  void sendPlatformEmail({
    to: user.email,
    subject,
    text,
    html: textToHtml(text),
  }).then((r) => {
    if (!r.ok) console.warn('[mail] Rejet compte non envoyé:', r.error);
  });
}

export async function sendNewCandidatureEmailToRecruiter({
  recruiterEmail,
  offreTitre,
  candidatNom,
}) {
  const cfg = await getMailSettings();
  if (!cfg.enabled || !cfg.notifEmailCandidature || !recruiterEmail) return;

  const titre = offreTitre || 'Votre offre';
  const cand = candidatNom || 'Un candidat';
  /** Alias pour sujets BDD historiques (ex. {{poste}}) et docs UI ({{titre_offre}}). */
  const vars = {
    offre_titre: titre,
    titre_offre: titre,
    poste: titre,
    candidat_nom: cand,
    candidat: cand,
    nom_candidat: cand,
    plateforme: cfg.platformName,
  };

  const subject = cfg.tplCandidatureSubject
    ? applyTemplate(cfg.tplCandidatureSubject, vars)
    : `Nouvelle candidature — ${titre}`;

  const text = `Bonjour,\n\n`
    + `${cand} vient de postuler à l'offre « ${titre} ».\n\n`
    + `Connectez-vous à ${cfg.platformName} pour consulter la candidature.\n\n`
    + `— ${cfg.platformName}`;

  void sendPlatformEmail({
    to: recruiterEmail,
    subject,
    text,
    html: textToHtml(text),
  }).then((r) => {
    if (!r.ok) console.warn('[mail] Candidature (recruteur) non envoyé:', r.error);
  });
}

export async function sendCandidatureConfirmationToCandidate({
  candidateEmail,
  candidateNom,
  offreTitre,
}) {
  const cfg = await getMailSettings();
  if (!cfg.enabled || !cfg.notifEmailConfirmationCandidature || !candidateEmail) return;

  const subject = `Candidature enregistrée — ${cfg.platformName}`;
  const text = `Bonjour ${candidateNom || ''},\n\n`
    + `Votre candidature pour l'offre « ${offreTitre || 'l’offre'} » a bien été enregistrée.\n\n`
    + 'Vous serez informé des évolutions depuis votre espace candidat.\n\n'
    + `— ${cfg.platformName}`;

  void sendPlatformEmail({
    to: candidateEmail,
    subject,
    text,
    html: textToHtml(text),
  }).then((r) => {
    if (!r.ok) console.warn('[mail] Confirmation candidature non envoyée:', r.error);
  });
}

function statutCandidatureLabel(statut) {
  const map = {
    en_attente: 'en attente',
    en_cours: 'en cours d’examen',
    entretien: 'entretien planifié',
    acceptee: 'acceptée',
    refusee: 'non retenue',
    annulee: 'annulée',
  };
  return map[statut] || statut || '';
}

/** Candidat : recruteur / admin a changé le statut (hors simple « en attente » inchangé côté métier). */
export async function sendCandidatureStatutEmailToCandidate({
  candidateEmail,
  candidateNom,
  offreTitre,
  statut,
  raisonRefus,
  dateEntretien,
  lienVisio = null,
  typeEntretien = null,
  lieuEntretien = null,
  notesEntretien = null,
}) {
  const cfg = await getMailSettings();
  if (!cfg.enabled || !cfg.notifEmailStatutCandidature || !candidateEmail) return;

  const titreOffre = offreTitre || 'l’offre';
  const label = statutCandidatureLabel(statut);
  let detail = '';
  if (statut === 'refusee' && raisonRefus) {
    detail = `\n\nMotif communiqué par le recruteur : ${raisonRefus}`;
  }
  if (statut === 'entretien' && dateEntretien) {
    try {
      const d = new Date(dateEntretien);
      detail = `\n\nDate d’entretien indiquée : ${Number.isNaN(d.getTime()) ? String(dateEntretien) : d.toLocaleString('fr-FR')}`;
    } catch (_) {
      detail = `\n\nDate d’entretien indiquée : ${dateEntretien}`;
    }
  }
  if (statut === 'entretien') {
    const lv = String(lienVisio || '').trim();
    if (lv) detail += `\nLien de connexion : ${lv}`;
    const ty = String(typeEntretien || '').trim();
    if (ty) detail += `\nFormat : ${ty}`;
    const lu = String(lieuEntretien || '').trim();
    if (lu) detail += `\nLieu : ${lu}`;
    const no = String(notesEntretien || '').trim();
    if (no) detail += `\nPrécisions : ${no.length > 400 ? `${no.slice(0, 400)}…` : no}`;
  }
  const subject = `Votre candidature — ${cfg.platformName}`;
  const text = `Bonjour ${candidateNom || ''},\n\n`
    + `Le statut de votre candidature pour « ${titreOffre} » est maintenant : ${label}.${detail}\n\n`
    + 'Consultez votre espace « Mes candidatures » sur la plateforme pour le détail.\n\n'
    + `— ${cfg.platformName}`;

  void sendPlatformEmail({
    to: candidateEmail,
    subject,
    text,
    html: textToHtml(text),
  }).then((r) => {
    if (!r.ok) console.warn('[mail] Statut candidature (candidat) non envoyé:', r.error);
  });
}

export async function sendCandidatureWithdrawalEmailToRecruiter({
  recruiterEmail,
  candidatNom,
  offreTitre,
}) {
  const cfg = await getMailSettings();
  if (!cfg.enabled || !cfg.notifEmailAnnulationCandidatureRecruteur || !recruiterEmail) return;

  const subject = `Candidature retirée — ${cfg.platformName}`;
  const text = `Bonjour,\n\n`
    + `${candidatNom || 'Un candidat'} a retiré sa candidature pour l’offre « ${offreTitre || 'votre offre'} ».\n\n`
    + `— ${cfg.platformName}`;

  void sendPlatformEmail({
    to: recruiterEmail,
    subject,
    text,
    html: textToHtml(text),
  }).then((r) => {
    if (!r.ok) console.warn('[mail] Annulation candidature (recruteur) non envoyé:', r.error);
  });
}

function truncateSignalementRaison(raison, maxLen) {
  const lim = maxLen ?? 900;
  const s = String(raison ?? '').trim().replace(/\r\n/g, '\n').replace(/\n{3,}/g, '\n\n');
  if (!s) return '';
  return s.length > lim ? `${s.slice(0, lim)}…` : s;
}

/** noteModeration prioritaire ; raison en complément (libellés selon destinataire). */
function blocsSignalementEmailReporter(noteModeration, raisonSignalement) {
  const mod = truncateSignalementRaison(noteModeration, 1200);
  const raison = truncateSignalementRaison(raisonSignalement, 900);
  let extra = '';
  if (mod) {
    extra += `\n\nMessage de la modération :\n« ${mod} »`;
  }
  if (raison) {
    extra += mod
      ? `\n\nPour rappel, votre texte de signalement :\n« ${raison} »`
      : `\n\nRappel du texte de votre signalement :\n« ${raison} »`;
  }
  return extra;
}

function blocsSignalementEmailConcerne(noteModeration, raisonSignalement) {
  const mod = truncateSignalementRaison(noteModeration, 1200);
  const raison = truncateSignalementRaison(raisonSignalement, 900);
  let extra = '';
  if (mod) {
    extra += `\n\nMessage de la modération :\n« ${mod} »`;
  }
  if (raison) {
    extra += mod
      ? `\n\nPour rappel, texte initial du signalement :\n« ${raison} »`
      : `\n\nTexte du signalement tel que transmis par le plaignant :\n« ${raison} »`;
  }
  return extra;
}

export async function sendSignalementResolutionEmailToReporter({
  reporterEmail,
  reporterNom,
  statutResolution,
  typeObjet,
  raisonSignalement,
  noteModeration,
}) {
  const cfg = await getMailSettings();
  if (!cfg.enabled || !cfg.notifEmailSignalementResolution || !reporterEmail) return;

  const traite = statutResolution === 'traite';
  const subject = traite
    ? `Votre signalement a été traité — ${cfg.platformName}`
    : `Votre signalement — ${cfg.platformName}`;
  const typeLabel = {
    offre: 'une offre',
    profil: 'un profil',
    candidature: 'une candidature',
    utilisateur: 'un profil',
  }[typeObjet] || 'un contenu';
  const extra = blocsSignalementEmailReporter(noteModeration, raisonSignalement);
  const text = traite
    ? `Bonjour ${reporterNom || ''},\n\n`
      + `Nous avons bien pris en compte votre signalement concernant ${typeLabel}. `
      + 'Il a été traité par notre équipe de modération.'
      + extra
      + `\n\nMerci de votre vigilance.\n\n— ${cfg.platformName}`
    : `Bonjour ${reporterNom || ''},\n\n`
      + `Votre signalement concernant ${typeLabel} a été classé sans suite par la modération.`
      + extra
      + `\n\n— ${cfg.platformName}`;

  void sendPlatformEmail({
    to: reporterEmail,
    subject,
    text,
    html: textToHtml(text),
  }).then((r) => {
    if (!r.ok) console.warn('[mail] Résolution signalement non envoyée:', r.error);
  });
}

/** Personne concernée par le contenu signalé (clôture du dossier par la modération). */
export async function sendSignalementConcerneEmail({
  concerneEmail,
  concerneNom,
  statutResolution,
  typeObjet,
  raisonSignalement,
  noteModeration,
}) {
  const cfg = await getMailSettings();
  if (!cfg.enabled || !cfg.notifEmailSignalementConcerne || !concerneEmail) return;

  const traite = statutResolution === 'traite';
  const sujet = {
    offre: 'votre offre',
    profil: 'votre profil',
    candidature: 'une candidature associée à votre compte',
    utilisateur: 'votre profil',
  }[typeObjet] || 'un contenu vous concernant';

  const subject = traite
    ? `Modération — signalement examiné — ${cfg.platformName}`
    : `Modération — suite à un signalement — ${cfg.platformName}`;

  const extra = blocsSignalementEmailConcerne(noteModeration, raisonSignalement);

  const text = traite
    ? `Bonjour ${concerneNom || ''},\n\n`
      + `Un signalement concernant ${sujet} a été examiné par notre équipe de modération et le dossier a été traité. `
      + 'Des mesures peuvent avoir été prises conformément à nos conditions d’utilisation.'
      + extra
      + `\n\nPour toute question, utilisez les coordonnées de contact du site.\n\n— ${cfg.platformName}`
    : `Bonjour ${concerneNom || ''},\n\n`
      + `Un signalement vous concernant (${sujet}) a été examiné par la modération et classé sans suite `
      + '(aucune mesure retenue à ce stade).'
      + extra
      + `\n\n— ${cfg.platformName}`;

  void sendPlatformEmail({
    to: concerneEmail,
    subject,
    text,
    html: textToHtml(text),
  }).then((r) => {
    if (!r.ok) console.warn('[mail] Signalement (personne concernée) non envoyé:', r.error);
  });
}

/** Email recruteur : décision admin sur une offre (validation, refus, vedette). */
export async function sendOffreModerationEmailToRecruiter(userId, titreNotif, messageBody) {
  const cfg = await getMailSettings();
  if (!cfg.enabled || !cfg.notifEmailOffreModeration || !userId) return;

  const { data: u } = await supabase
    .from('utilisateurs')
    .select('email')
    .eq('id', userId)
    .single();
  if (!u?.email) return;

  const subject = String(titreNotif || 'Votre offre').slice(0, 200);
  const text = `${messageBody}\n\n— ${cfg.platformName}`;

  void sendPlatformEmail({
    to: u.email,
    subject,
    text,
    html: textToHtml(text),
  }).then((r) => {
    if (!r.ok) console.warn('[mail] Modération offre (email) non envoyé:', r.error);
  });
}

/**
 * Nouveau message : respecte la préférence utilisateur notif_messages_recus (sauf false explicite).
 */
export async function sendNewMessageEmail(destinataireId, {
  senderLabel,
  excerpt,
  lienLibelle,
}) {
  const cfg = await getMailSettings();
  if (!cfg.enabled || !cfg.notifEmailMessages || !destinataireId) return;

  const { data: u } = await supabase
    .from('utilisateurs')
    .select('email, notif_messages_recus')
    .eq('id', destinataireId)
    .single();

  if (!u?.email || u.notif_messages_recus === false) return;

  const subject = `Nouveau message — ${cfg.platformName}`;
  const text = `${senderLabel} vous a écrit :\n\n« ${String(excerpt || '').slice(0, 500)} »\n\n`
    + `${lienLibelle || 'Ouvrez la messagerie sur la plateforme pour répondre.'}\n\n`
    + `— ${cfg.platformName}`;

  void sendPlatformEmail({
    to: u.email,
    subject,
    text,
    html: textToHtml(text),
  }).then((r) => {
    if (!r.ok) console.warn('[mail] Message (email) non envoyé:', r.error);
  });
}

/**
 * Code à 6 chiffres pour confirmer une nouvelle adresse e-mail (compte admin).
 * @returns {Promise<{ ok: boolean, error?: string }>}
 */
export async function sendAdminEmailChangeCodeEmail({ to, nom, code, minutesValid = 15 }) {
  const cfg = await getMailSettings();
  if (!cfg.enabled || !to || !code) {
    return { ok: false, error: 'Service e-mail désactivé ou paramètres manquants' };
  }
  const subject = `Code de vérification — ${cfg.platformName}`;
  const primary = htmlEscape(cfg.emailCouleurPrimaire || '#1A56DB');
  const safeCode = htmlEscape(code);
  const inner =
    `<p style="margin:0 0 16px;">Bonjour ${htmlEscape(nom || '') || 'cher administrateur'},</p>`
    + `<p style="margin:0 0 20px;">Vous avez demandé à utiliser cette adresse e-mail pour votre compte administrateur sur <strong>${htmlEscape(cfg.platformName)}</strong>.</p>`
    + `<p style="margin:0 0 12px;font-size:14px;color:#64748b;">Votre code de vérification (valable <strong>${minutesValid} minutes</strong>) :</p>`
    + `<p style="margin:24px 0;text-align:center;font-size:32px;letter-spacing:8px;font-weight:700;color:${primary};">${safeCode}</p>`
    + `<p style="margin:0;font-size:13px;color:#64748b;">Si vous n’êtes pas à l’origine de cette demande, ignorez cet e-mail : l’adresse de connexion de votre compte ne sera pas modifiée.</p>`;
  const html = await buildWrappedEmailHtml(inner);
  const text =
    `Bonjour,\n\nCode de vérification (${minutesValid} min) : ${code}\n\n`
    + 'Saisissez ce code dans le panneau d’administration pour valider votre nouvelle adresse e-mail.\n\n'
    + `— ${cfg.platformName}`;
  return sendPlatformEmail({ to, subject, text, html });
}

/**
 * Après validation du code : e-mail de confirmation sur la nouvelle adresse + alerte sur l’ancienne (sécurité).
 * @returns {Promise<{ ok: boolean, error?: string }>}
 */
export async function sendAdminEmailChangedConfirmationEmails({ nom, previousEmail, newEmail }) {
  const cfg = await getMailSettings();
  if (!cfg.enabled || !newEmail) {
    return { ok: false, error: 'Service e-mail désactivé ou adresse manquante' };
  }

  const safeNom = htmlEscape(nom || '');
  const safeNew = htmlEscape(newEmail);
  const plateforme = htmlEscape(cfg.platformName);

  const subjectOk = `Votre adresse e-mail a été modifiée — ${cfg.platformName}`;
  const innerOk =
    `<p style="margin:0 0 16px;">Bonjour ${safeNom || 'cher administrateur'},</p>`
    + `<p style="margin:0 0 16px;">La modification de votre adresse e-mail sur <strong>${plateforme}</strong> est <strong>confirmée</strong>.</p>`
    + `<p style="margin:0 0 12px;">Votre nouvelle adresse de connexion est :</p>`
    + `<p style="margin:16px 0;padding:16px;border-radius:12px;background:#f0fdf4;border:1px solid #bbf7d0;font-size:18px;font-weight:700;text-align:center;color:#166534;">${safeNew}</p>`
    + `<p style="margin:0;font-size:13px;color:#64748b;">Utilisez désormais cette adresse pour vous connecter. Votre mot de passe reste inchangé.</p>`;
  const htmlOk = await buildWrappedEmailHtml(innerOk);
  const textOk =
    `Bonjour,\n\nVotre adresse de connexion sur ${cfg.platformName} est maintenant : ${newEmail}\n\n`
    + 'Utilisez cette adresse pour vous connecter. Votre mot de passe reste le même.\n\n'
    + `— ${cfg.platformName}`;
  const rNew = await sendPlatformEmail({
    to: newEmail,
    subject: subjectOk,
    text: textOk,
    html: htmlOk,
  });

  const prevNorm = String(previousEmail || '').trim().toLowerCase();
  if (!prevNorm || prevNorm === String(newEmail).toLowerCase()) {
    return rNew;
  }

  const subjectAlert = `Alerte : adresse e-mail du compte modifiée — ${cfg.platformName}`;
  const innerAlert =
    `<p style="margin:0 0 16px;">Bonjour ${safeNom || 'cher administrateur'},</p>`
    + `<p style="margin:0 0 16px;">L’adresse e-mail de connexion de votre compte administrateur sur <strong>${plateforme}</strong> a été <strong>remplacée</strong> par :</p>`
    + `<p style="margin:16px 0;padding:14px;border-radius:12px;background:#fef3c7;border:1px solid #fcd34d;font-weight:600;text-align:center;">${safeNew}</p>`
    + `<p style="margin:0;font-size:13px;color:#64748b;">Si vous n’êtes pas à l’origine de ce changement, contactez immédiatement un autre administrateur ou sécurisez le compte.</p>`;
  const htmlAlert = await buildWrappedEmailHtml(innerAlert);
  const textAlert =
    `Alerte : l’adresse e-mail de votre compte ${cfg.platformName} a été modifiée.\n`
    + `Nouvelle adresse : ${newEmail}\n\n`
    + 'Si ce n’était pas vous, agissez immédiatement.\n\n'
    + `— ${cfg.platformName}`;
  const rOld = await sendPlatformEmail({
    to: previousEmail,
    subject: subjectAlert,
    text: textAlert,
    html: htmlAlert,
  });

  if (!rNew.ok) return rNew;
  if (!rOld.ok) return rOld;
  return { ok: true };
}

export async function sendPasswordResetEmail({ to, nom, resetLink }) {
  const cfg = await getMailSettings();
  if (!cfg.enabled || !cfg.notifEmailResetMdp || !to) return;
  const subject = cfg.templateResetMdpSujet
    ? applyTemplate(cfg.templateResetMdpSujet, { plateforme: cfg.platformName, nom: nom || '' })
    : `Réinitialisation de votre mot de passe — ${cfg.platformName}`;
  const primary = htmlEscape(cfg.emailCouleurPrimaire || '#1A56DB');
  const safeLink = htmlEscape(resetLink);
  const inner = `<p style="margin:0 0 16px;">Bonjour ${htmlEscape(nom || '') || 'cher utilisateur'},</p>`
    + `<p style="margin:0 0 20px;">Vous avez demandé à réinitialiser votre mot de passe sur <strong>${htmlEscape(cfg.platformName)}</strong>. Le lien ci-dessous est valable <strong>1 heure</strong>.</p>`
    + `<p style="margin:24px 0;text-align:center;"><a href="${safeLink}" style="display:inline-block;padding:14px 28px;background:${primary};color:#ffffff;text-decoration:none;border-radius:10px;font-weight:600;">Choisir un nouveau mot de passe</a></p>`
    + `<p style="margin:0;font-size:13px;color:#64748b;">Si vous n’êtes pas à l’origine de cette demande, vous pouvez ignorer cet email.</p>`;
  const html = await buildWrappedEmailHtml(inner);
  const text = `Bonjour,\n\nRéinitialisez votre mot de passe : ${resetLink}\n\n— ${cfg.platformName}`;
  void sendPlatformEmail({ to, subject, text, html }).then((r) => {
    if (!r.ok) console.warn('[mail] Reset MDP non envoyé:', r.error);
  });
}

export async function sendAlerteOffreMatchEmail({
  to,
  nom,
  offreTitre,
  entrepriseNom,
  localisation,
  typeContrat,
  lienOffres,
}) {
  const cfg = await getMailSettings();
  if (!cfg.enabled || !cfg.notifEmailAlerteEmploi || !to) return;
  const titre = offreTitre || '';
  const ent = entrepriseNom || '';
  const subject = cfg.templateAlerteOffreSujet
    ? applyTemplate(cfg.templateAlerteOffreSujet, {
      plateforme: cfg.platformName,
      titre_offre: titre,
      offre_titre: titre,
      poste: titre,
      nom: nom || '',
      entreprise: ent,
      entreprise_nom: ent,
      nom_entreprise: ent,
      localisation: localisation || '',
      type_contrat: typeContrat || '',
    })
    : `Nouvelle offre pour vous — ${cfg.platformName}`;
  const primary = htmlEscape(cfg.emailCouleurPrimaire || '#1A56DB');
  const link = htmlEscape(lienOffres || `${cfg.publicAppUrl.replace(/\/$/, '')}/#/dashboard/offres`);
  const inner = `<p style="margin:0 0 16px;">Bonjour ${htmlEscape(nom || '')},</p>`
    + `<p style="margin:0 0 12px;">Une nouvelle offre correspond à <strong>vos alertes enregistrées</strong> ou présente une <strong>forte proximité</strong> avec votre profil (compétences, titre recherché, expérience) :</p>`
    + `<div style="margin:16px 0;padding:16px;border-radius:12px;background:#f8fafc;border:1px solid #e2e8f0;">`
    + `<p style="margin:0 0 8px;font-size:17px;font-weight:700;color:#0f172a;">${htmlEscape(offreTitre || '')}</p>`
    + `<p style="margin:0;color:#475569;">${htmlEscape(entrepriseNom || '')} · ${htmlEscape(localisation || '')} · ${htmlEscape(typeContrat || '')}</p></div>`
    + `<p style="margin:24px 0;text-align:center;"><a href="${link}" style="display:inline-block;padding:12px 24px;background:${primary};color:#ffffff;text-decoration:none;border-radius:10px;font-weight:600;">Voir les offres</a></p>`;
  const html = await buildWrappedEmailHtml(inner);
  const text = `Nouvelle offre : ${offreTitre} (${entrepriseNom})\n${lienOffres}\n— ${cfg.platformName}`;
  void sendPlatformEmail({ to, subject, text, html }).then((r) => {
    if (!r.ok) console.warn('[mail] Alerte emploi non envoyée:', r.error);
  });
}

export async function sendCvAnalyseTermineeEmail({ to, nom }) {
  const cfg = await getMailSettings();
  if (!cfg.enabled || !cfg.notifEmailAnalyseCv || !to) return;
  const subject = cfg.templateAnalyseCvSujet
    ? applyTemplate(cfg.templateAnalyseCvSujet, { plateforme: cfg.platformName, nom: nom || '' })
    : `Analyse de votre CV terminée — ${cfg.platformName}`;
  const primary = htmlEscape(cfg.emailCouleurPrimaire || '#1A56DB');
  const base = cfg.publicAppUrl.replace(/\/$/, '');
  const link = htmlEscape(`${base}/#/dashboard/profil`);
  const inner = `<p style="margin:0 0 16px;">Bonjour ${htmlEscape(nom || '')},</p>`
    + `<p style="margin:0 0 20px;">L’analyse de votre CV sur ${htmlEscape(cfg.platformName)} est terminée. Vos compétences et expériences extraites sont à jour dans votre profil.</p>`
    + `<p style="margin:24px 0;text-align:center;"><a href="${link}" style="display:inline-block;padding:12px 24px;background:${primary};color:#ffffff;text-decoration:none;border-radius:10px;font-weight:600;">Ouvrir mon profil</a></p>`;
  const html = await buildWrappedEmailHtml(inner);
  const text = `Bonjour,\n\nL’analyse de votre CV est terminée. Consultez votre profil sur ${cfg.platformName}.\n\n— ${cfg.platformName}`;
  void sendPlatformEmail({ to, subject, text, html }).then((r) => {
    if (!r.ok) console.warn('[mail] Analyse CV email non envoyé:', r.error);
  });
}

/** Emails aux admins actifs (inscription, offre à modérer, signalement). */
export async function sendAdminAlertEmail({ titre, message, lienRelatif }) {
  const cfg = await getMailSettings();
  if (!cfg.enabled || !cfg.notifEmailAlertesAdmin) return;

  const { data: admins } = await supabase
    .from('utilisateurs')
    .select('email')
    .eq('role', ROLES.ADMIN)
    .eq('est_actif', true);

  const subject = `[${cfg.platformName}] ${String(titre || 'Alerte').slice(0, 160)}`;
  let text = String(message || '');
  if (lienRelatif) {
    text += `\n\nLien (interface admin) : ${lienRelatif}`;
  }
  text += `\n\n— ${cfg.platformName}`;
  const html = textToHtml(text);

  for (const a of admins || []) {
    if (!a.email) continue;
    void sendPlatformEmail({
      to: a.email,
      subject,
      text,
      html,
    }).then((r) => {
      if (!r.ok) console.warn('[mail] Alerte admin non envoyée:', a.email, r.error);
    });
  }
}

export async function verifySmtpConnection() {
  const cfg = await getMailSettings();

  if (!cfg.enabled) {
    return {
      ok: false,
      message:
        'Le service email est désactivé. Cochez « Activer l’envoi d’emails », cliquez sur « Enregistrer les paramètres » (en bas de la page), puis retestez.',
    };
  }
  if (!String(cfg.host || '').trim()) {
    return {
      ok: false,
      message: 'Hôte SMTP vide. Renseignez-le (ex. smtp.gmail.com), enregistrez, puis retestez.',
    };
  }
  if (!String(cfg.user || '').trim()) {
    return {
      ok: false,
      message:
        'Utilisateur SMTP vide (souvent la même adresse Gmail que l’expéditeur). Enregistrez après saisie, puis retestez.',
    };
  }
  if (!String(cfg.password || '').trim()) {
    return {
      ok: false,
      message:
        'Mot de passe SMTP absent en base. Saisissez le mot de passe (Gmail avec 2FA : mot de passe d’application), cliquez sur « Enregistrer les paramètres », puis retestez. Le bouton « Tester » seul n’enregistre rien.',
    };
  }

  const transporter = await createTransporter();
  if (!transporter) {
    return {
      ok: false,
      message:
        'SMTP incomplet. Si le mot de passe était chiffré : vérifiez ENCRYPTION_KEY dans le .env du backend (même clé qu’au moment de l’enregistrement), puis re-saisissez le mot de passe et enregistrez.',
    };
  }
  try {
    await transporter.verify();
    return { ok: true, message: 'Connexion SMTP OK' };
  } catch (e) {
    return { ok: false, message: e.message || 'Échec verify() SMTP' };
  }
}
