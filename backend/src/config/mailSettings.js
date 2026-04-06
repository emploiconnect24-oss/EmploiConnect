/**
 * Paramètres SMTP et templates lus depuis parametres_plateforme (admin).
 * Même logique de déchiffrement que rapidapi_key pour email_smtp_password.
 */
import crypto from 'crypto';
import { supabase } from './supabase.js';

const CACHE_MS = 5 * 60 * 1000;
let cache = null;
let cacheTime = 0;

const KEYS = [
  'email_service_actif',
  'email_smtp_host',
  'email_smtp_port',
  'email_smtp_user',
  'email_smtp_password',
  'email_nom_expediteur',
  'template_bienvenue_sujet',
  'template_bienvenue_corps',
  'template_candidature_sujet',
  'template_validation_sujet',
  'notif_email_candidature',
  'notif_email_validation',
  'notif_email_messages',
  'notif_email_offre_moderation',
  'notif_email_alertes_admin',
  'notif_email_confirmation_candidature',
  'notif_email_compte_rejete',
  'notif_email_statut_candidature',
  'notif_email_signalement_resolution',
  'notif_email_annulation_candidature_recruteur',
  'notif_email_signalement_concerne',
  'notif_email_reset_mdp',
  'notif_email_alerte_emploi',
  'notif_email_resume_hebdo',
  'notif_email_analyse_cv',
  'url_application_publique',
  'email_template_wrapper_html',
  'email_couleur_primaire',
  'template_reset_mdp_sujet',
  'template_alerte_offre_sujet',
  'template_resume_hebdo_sujet',
  'template_analyse_cv_sujet',
  'nom_plateforme',
];

function decryptIfNeeded(input) {
  const value = String(input || '');
  if (!value.includes(':')) return value;
  try {
    const encryptionKey = process.env.ENCRYPTION_KEY || '';
    if (encryptionKey.length < 16) return '';
    const [ivHex, encrypted] = value.split(':');
    const iv = Buffer.from(ivHex, 'hex');
    const key = crypto.scryptSync(encryptionKey, 'salt', 32);
    const decipher = crypto.createDecipheriv('aes-256-cbc', key, iv);
    let dec = decipher.update(encrypted, 'hex', 'utf8');
    dec += decipher.final('utf8');
    return dec;
  } catch (_) {
    return '';
  }
}

function boolFromDb(v) {
  return String(v ?? '').toLowerCase() === 'true';
}

/** Si la clé n'existe pas encore en BDD (migration non appliquée), comportement = activé. */
function boolFromDbDefaultTrue(map, key) {
  if (!(key in map) || map[key] === undefined || map[key] === null) return true;
  return boolFromDb(map[key]);
}

/**
 * @returns {Promise<{
 *   enabled: boolean,
 *   host: string,
 *   port: number,
 *   user: string,
 *   password: string,
 *   fromName: string,
 *   platformName: string,
 *   tplWelcomeSubject: string,
 *   tplWelcomeBody: string,
 *   tplCandidatureSubject: string,
 *   tplValidationSubject: string,
 *   notifEmailCandidature: boolean,
 *   notifEmailValidation: boolean,
 *   notifEmailMessages: boolean,
 *   notifEmailOffreModeration: boolean,
 *   notifEmailAlertesAdmin: boolean,
 *   notifEmailConfirmationCandidature: boolean,
 *   notifEmailCompteRejete: boolean,
 *   notifEmailStatutCandidature: boolean,
 *   notifEmailSignalementResolution: boolean,
 *   notifEmailAnnulationCandidatureRecruteur: boolean,
 *   notifEmailSignalementConcerne: boolean,
 *   notifEmailResetMdp: boolean,
 *   notifEmailAlerteEmploi: boolean,
 *   notifEmailResumeHebdo: boolean,
 *   notifEmailAnalyseCv: boolean,
 *   publicAppUrl: string,
 *   emailTemplateWrapperHtml: string,
 *   emailCouleurPrimaire: string,
 *   templateResetMdpSujet: string,
 *   templateAlerteOffreSujet: string,
 *   templateResumeHebdoSujet: string,
 *   templateAnalyseCvSujet: string,
 * }>}
 */
export async function getMailSettings() {
  const now = Date.now();
  if (cache && (now - cacheTime) < CACHE_MS) {
    return cache;
  }

  try {
    const { data, error } = await supabase
      .from('parametres_plateforme')
      .select('cle, valeur')
      .in('cle', KEYS);

    if (error) throw error;

    const map = {};
    (data || []).forEach((p) => {
      map[p.cle] = p.valeur;
    });

    const rawPass = String(map.email_smtp_password || '').trim();
    let password = '';
    if (rawPass) {
      password = rawPass.includes(':')
        ? decryptIfNeeded(rawPass)
        : rawPass;
      if (rawPass.includes(':') && !password) {
        console.warn(
          '[mailSettings] Mot de passe SMTP chiffré illisible (ENCRYPTION_KEY ?).',
        );
      }
    }

    cache = {
      enabled: boolFromDb(map.email_service_actif),
      host: String(map.email_smtp_host || '').trim(),
      port: Number.parseInt(String(map.email_smtp_port || '587'), 10) || 587,
      user: String(map.email_smtp_user || '').trim(),
      password,
      fromName: String(map.email_nom_expediteur || 'EmploiConnect').trim() || 'EmploiConnect',
      platformName: String(map.nom_plateforme || 'EmploiConnect').trim() || 'EmploiConnect',
      tplWelcomeSubject: String(map.template_bienvenue_sujet || '').trim(),
      tplWelcomeBody: String(map.template_bienvenue_corps || '').trim(),
      tplCandidatureSubject: String(map.template_candidature_sujet || '').trim(),
      tplValidationSubject: String(map.template_validation_sujet || '').trim(),
      notifEmailCandidature: boolFromDbDefaultTrue(map, 'notif_email_candidature'),
      notifEmailValidation: boolFromDbDefaultTrue(map, 'notif_email_validation'),
      notifEmailMessages: boolFromDbDefaultTrue(map, 'notif_email_messages'),
      notifEmailOffreModeration: boolFromDbDefaultTrue(map, 'notif_email_offre_moderation'),
      notifEmailAlertesAdmin: boolFromDbDefaultTrue(map, 'notif_email_alertes_admin'),
      notifEmailConfirmationCandidature: boolFromDbDefaultTrue(
        map,
        'notif_email_confirmation_candidature',
      ),
      notifEmailCompteRejete: boolFromDbDefaultTrue(map, 'notif_email_compte_rejete'),
      notifEmailStatutCandidature: boolFromDbDefaultTrue(map, 'notif_email_statut_candidature'),
      notifEmailSignalementResolution: boolFromDbDefaultTrue(map, 'notif_email_signalement_resolution'),
      notifEmailAnnulationCandidatureRecruteur: boolFromDbDefaultTrue(
        map,
        'notif_email_annulation_candidature_recruteur',
      ),
      notifEmailSignalementConcerne: boolFromDbDefaultTrue(map, 'notif_email_signalement_concerne'),
      notifEmailResetMdp: boolFromDbDefaultTrue(map, 'notif_email_reset_mdp'),
      notifEmailAlerteEmploi: boolFromDbDefaultTrue(map, 'notif_email_alerte_emploi'),
      notifEmailResumeHebdo: boolFromDbDefaultTrue(map, 'notif_email_resume_hebdo'),
      notifEmailAnalyseCv: boolFromDbDefaultTrue(map, 'notif_email_analyse_cv'),
      publicAppUrl: String(map.url_application_publique || '').trim() || 'http://localhost:8080',
      emailTemplateWrapperHtml: String(map.email_template_wrapper_html || ''),
      emailCouleurPrimaire: String(map.email_couleur_primaire || '#1A56DB').trim() || '#1A56DB',
      templateResetMdpSujet: String(map.template_reset_mdp_sujet || '').trim(),
      templateAlerteOffreSujet: String(map.template_alerte_offre_sujet || '').trim(),
      templateResumeHebdoSujet: String(map.template_resume_hebdo_sujet || '').trim(),
      templateAnalyseCvSujet: String(map.template_analyse_cv_sujet || '').trim(),
    };
    cacheTime = now;
    return cache;
  } catch (err) {
    console.error('[getMailSettings]', err?.message || err);
    cache = {
      enabled: false,
      host: '',
      port: 587,
      user: '',
      password: '',
      fromName: 'EmploiConnect',
      platformName: 'EmploiConnect',
      tplWelcomeSubject: '',
      tplWelcomeBody: '',
      tplCandidatureSubject: '',
      tplValidationSubject: '',
      notifEmailCandidature: false,
      notifEmailValidation: false,
      notifEmailMessages: false,
      notifEmailOffreModeration: false,
      notifEmailAlertesAdmin: false,
      notifEmailConfirmationCandidature: false,
      notifEmailCompteRejete: false,
      notifEmailStatutCandidature: false,
      notifEmailSignalementResolution: false,
      notifEmailAnnulationCandidatureRecruteur: false,
      notifEmailSignalementConcerne: false,
      notifEmailResetMdp: false,
      notifEmailAlerteEmploi: false,
      notifEmailResumeHebdo: false,
      notifEmailAnalyseCv: false,
      publicAppUrl: 'http://localhost:8080',
      emailTemplateWrapperHtml: '',
      emailCouleurPrimaire: '#1A56DB',
      templateResetMdpSujet: '',
      templateAlerteOffreSujet: '',
      templateResumeHebdoSujet: '',
      templateAnalyseCvSujet: '',
    };
    cacheTime = now;
    return cache;
  }
}

export function invalidateMailSettingsCache() {
  cache = null;
  cacheTime = 0;
}
