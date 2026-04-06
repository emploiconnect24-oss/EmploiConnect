/**
 * Notifications in-app + emails (non bloquant) pour évolutions candidatures et signalements.
 */
import { supabase } from '../config/supabase.js';
import {
  sendCandidatureStatutEmailToCandidate,
  sendCandidatureWithdrawalEmailToRecruiter,
  sendSignalementResolutionEmailToReporter,
  sendSignalementConcerneEmail,
} from './mail.service.js';

const STATUTS_NOTIF_CANDIDAT = new Set(['en_cours', 'entretien', 'acceptee', 'refusee']);

/** Raison partagée dans les notifs (tronquée ; pas de HTML). */
function raisonPourNotification(raison, maxLen) {
  const lim = maxLen ?? 320;
  const s = String(raison ?? '').trim().replace(/\s+/g, ' ');
  if (!s) return '';
  return s.length > lim ? `${s.slice(0, lim)}…` : s;
}

/** noteAdmin prioritaire ; raison en complément (même logique que les emails). */
function messageSignalementAvecModeration(intro, noteAdmin, raison) {
  const n = raisonPourNotification(noteAdmin, 280);
  const r = raisonPourNotification(raison, 220);
  const parts = [];
  if (n) parts.push(`Décision de la modération : « ${n} »`);
  if (r) parts.push(n ? `Rappel du signalement initial : « ${r} »` : `Motif indiqué : « ${r} »`);
  if (parts.length === 0) return intro;
  return `${intro} ${parts.join(' ')}`;
}

function titreMessageStatut(offreTitre, statut, raisonRefus, dateEntretien, entretienExtra = {}) {
  const t = offreTitre || 'Une offre';
  if (statut === 'en_cours') {
    return {
      titre: '📋 Candidature en examen',
      message: `Votre candidature pour « ${t} » est en cours d'examen.`,
    };
  }
  if (statut === 'entretien') {
    let msg = `Un entretien est prévu pour votre candidature « ${t} ».`;
    if (dateEntretien) {
      try {
        const d = new Date(dateEntretien);
        msg += Number.isNaN(d.getTime())
          ? ` Date : ${dateEntretien}.`
          : ` Date : ${d.toLocaleString('fr-FR')}.`;
      } catch (_) {
        msg += ` Date : ${dateEntretien}.`;
      }
    }
    const lv = String(entretienExtra.lienVisio || '').trim();
    if (lv) msg += ` Lien de connexion : ${lv}.`;
    const ty = String(entretienExtra.typeEntretien || '').trim();
    if (ty) msg += ` Format : ${ty}.`;
    const lu = String(entretienExtra.lieuEntretien || '').trim();
    if (lu) msg += ` Lieu : ${lu}.`;
    const no = String(entretienExtra.notesEntretien || '').trim();
    if (no) {
      const short = no.length > 200 ? `${no.slice(0, 200)}…` : no;
      msg += ` Précisions : ${short}`;
    }
    return { titre: '📅 Entretien', message: msg };
  }
  if (statut === 'acceptee') {
    return {
      titre: '✅ Candidature acceptée',
      message: `Bonne nouvelle : votre candidature pour « ${t} » a été acceptée.`,
    };
  }
  if (statut === 'refusee') {
    const r = raisonRefus ? ` Motif : ${raisonRefus}` : '';
    return {
      titre: 'Candidature non retenue',
      message: `Votre candidature pour « ${t} » n'a pas été retenue.${r}`,
    };
  }
  return { titre: 'Candidature', message: `Mise à jour pour « ${t} ».` };
}

async function insertDemandeTemoignageNotif(utilisateurId, { candidatureId, offreTitre, entrepriseNom }) {
  if (!utilisateurId || !candidatureId) return;
  try {
    const nomEnt = String(entrepriseNom || '').trim();
    const lieu = nomEnt ? ` chez ${nomEnt}` : '';
    const offre = String(offreTitre || 'cette offre').trim();
    await supabase.from('notifications').insert({
      destinataire_id: utilisateurId,
      type_destinataire: 'individuel',
      titre: '🌟 Partagez votre expérience',
      message:
        `Félicitations pour votre embauche${lieu} (« ${offre} »). `
        + 'Si vous le souhaitez, décrivez en quelques lignes votre parcours de recrutement (entretien, échanges…) : '
        + 'votre témoignage pourra être affiché sur la page d’accueil pour inspirer d’autres candidats.',
      type: 'systeme',
      lien: `/dashboard/temoignage?c=${candidatureId}`,
      est_lue: false,
    });
  } catch (e) {
    console.warn('[insertDemandeTemoignageNotif]', e.message);
  }
}

/**
 * @param {string} chercheurEmploiId - id ligne chercheurs_emploi
 * @param {object} opts
 * @param {string|null} [opts.candidatureId] - pour proposer le formulaire témoignage si acceptée
 * @param {string|null} [opts.entrepriseNom]
 */
export async function notifyChercheurCandidatureStatutChanged(chercheurEmploiId, {
  offreTitre,
  statut,
  raisonRefus,
  dateEntretien,
  lienVisio = null,
  typeEntretien = null,
  lieuEntretien = null,
  notesEntretien = null,
  candidatureId = null,
  entrepriseNom = null,
}) {
  if (!chercheurEmploiId || !statut || !STATUTS_NOTIF_CANDIDAT.has(statut)) return;

  const { data: ch } = await supabase
    .from('chercheurs_emploi')
    .select('utilisateur_id')
    .eq('id', chercheurEmploiId)
    .maybeSingle();
  if (!ch?.utilisateur_id) return;

  const { data: u } = await supabase
    .from('utilisateurs')
    .select('email, nom')
    .eq('id', ch.utilisateur_id)
    .maybeSingle();

  const { titre, message } = titreMessageStatut(offreTitre, statut, raisonRefus, dateEntretien, {
    lienVisio,
    typeEntretien,
    lieuEntretien,
    notesEntretien,
  });

  try {
    await supabase.from('notifications').insert({
      destinataire_id: ch.utilisateur_id,
      type_destinataire: 'individuel',
      titre,
      message,
      type: 'candidature',
      lien: '/dashboard/candidatures',
      est_lue: false,
    });
  } catch (e) {
    console.warn('[notifyChercheurCandidatureStatutChanged] in-app:', e.message);
  }

  void sendCandidatureStatutEmailToCandidate({
    candidateEmail: u?.email,
    candidateNom: u?.nom,
    offreTitre,
    statut,
    raisonRefus,
    dateEntretien,
    lienVisio,
    typeEntretien,
    lieuEntretien,
    notesEntretien,
  });

  if (statut === 'acceptee' && candidatureId) {
    void insertDemandeTemoignageNotif(ch.utilisateur_id, {
      candidatureId,
      offreTitre,
      entrepriseNom,
    });
  }
}

export async function notifyRecruteurCandidatureAnnuleeParCandidat({ offreId, candidatNom }) {
  if (!offreId) return;

  const { data: offre } = await supabase
    .from('offres_emploi')
    .select('titre, entreprise_id')
    .eq('id', offreId)
    .maybeSingle();
  if (!offre?.entreprise_id) return;

  const { data: ent } = await supabase
    .from('entreprises')
    .select('utilisateur_id')
    .eq('id', offre.entreprise_id)
    .maybeSingle();
  if (!ent?.utilisateur_id) return;

  const { data: owner } = await supabase
    .from('utilisateurs')
    .select('email')
    .eq('id', ent.utilisateur_id)
    .maybeSingle();

  const titre = 'Candidature retirée';
  const message = `${candidatNom || 'Un candidat'} a retiré sa candidature pour « ${offre.titre || 'votre offre'} ».`;

  try {
    await supabase.from('notifications').insert({
      destinataire_id: ent.utilisateur_id,
      type_destinataire: 'individuel',
      titre,
      message,
      type: 'candidature',
      lien: '/dashboard-recruteur/candidatures',
      est_lue: false,
    });
  } catch (e) {
    console.warn('[notifyRecruteurCandidatureAnnuleeParCandidat] in-app:', e.message);
  }

  void sendCandidatureWithdrawalEmailToRecruiter({
    recruiterEmail: owner?.email,
    candidatNom,
    offreTitre: offre.titre,
  });
}

async function lienNotifPourUtilisateur(utilisateurId) {
  const { data: u } = await supabase
    .from('utilisateurs')
    .select('role')
    .eq('id', utilisateurId)
    .maybeSingle();
  if (u?.role === 'entreprise') return '/dashboard-recruteur/notifications';
  return '/dashboard/notifications';
}

/**
 * @param {string} signalantUserId - utilisateur_signalant_id
 * @param {'traite'|'rejete'} statutResolution
 */
export async function notifySignalementResolutionPourSignalant(signalantUserId, {
  statutResolution,
  typeObjet,
  raison,
  noteAdmin,
}) {
  if (!signalantUserId || !['traite', 'rejete'].includes(statutResolution)) return;

  const { data: u } = await supabase
    .from('utilisateurs')
    .select('email, nom')
    .eq('id', signalantUserId)
    .maybeSingle();
  if (!u) return;

  const traite = statutResolution === 'traite';
  const titre = traite ? 'Signalement traité' : 'Signalement classé sans suite';
  const typeLabel = {
    offre: 'une offre',
    profil: 'un profil',
    candidature: 'une candidature',
    utilisateur: 'un profil',
  }[typeObjet] || 'un contenu';
  const intro = traite
    ? `Votre signalement concernant ${typeLabel} a été traité par la modération.`
    : `Votre signalement concernant ${typeLabel} a été classé sans suite par la modération.`;
  const corps = messageSignalementAvecModeration(intro, noteAdmin, raison);
  const message = traite ? `${corps} Merci pour votre signalement.` : corps;

  const lien = await lienNotifPourUtilisateur(signalantUserId);

  try {
    await supabase.from('notifications').insert({
      destinataire_id: signalantUserId,
      type_destinataire: 'individuel',
      titre,
      message,
      type: 'systeme',
      lien,
      est_lue: false,
    });
  } catch (e) {
    console.warn('[notifySignalementResolutionPourSignalant] in-app:', e.message);
  }

  void sendSignalementResolutionEmailToReporter({
    reporterEmail: u.email,
    reporterNom: u.nom,
    statutResolution,
    typeObjet,
    raisonSignalement: raison,
    noteModeration: noteAdmin,
  });
}

/**
 * Résout l’utilisateur « concerné » par le contenu signalé (propriétaire offre, profil, ou candidat).
 * @param {string} objetId
 * @param {string} typeObjet
 * @returns {Promise<string|null>} utilisateurs.id
 */
export async function resolveUtilisateurConcerneSignalement(objetId, typeObjet) {
  if (!objetId || !typeObjet) return null;
  const t = String(typeObjet).toLowerCase();

  if (t === 'profil' || t === 'utilisateur') {
    return objetId;
  }

  if (t === 'offre') {
    const { data: offre } = await supabase
      .from('offres_emploi')
      .select('entreprise_id')
      .eq('id', objetId)
      .maybeSingle();
    if (!offre?.entreprise_id) return null;
    const { data: ent } = await supabase
      .from('entreprises')
      .select('utilisateur_id')
      .eq('id', offre.entreprise_id)
      .maybeSingle();
    return ent?.utilisateur_id || null;
  }

  if (t === 'candidature') {
    const { data: cand } = await supabase
      .from('candidatures')
      .select('chercheur_id')
      .eq('id', objetId)
      .maybeSingle();
    if (!cand?.chercheur_id) return null;
    const { data: ch } = await supabase
      .from('chercheurs_emploi')
      .select('utilisateur_id')
      .eq('id', cand.chercheur_id)
      .maybeSingle();
    return ch?.utilisateur_id || null;
  }

  return null;
}

/**
 * @param {string|null} signalantUserId - pour éviter doublon si signalement sur soi-même
 */
export async function notifySignalementResolutionPourConcerne(objetId, typeObjet, {
  signalantUserId,
  statutResolution,
  raison,
  noteAdmin,
}) {
  if (!objetId || !['traite', 'rejete'].includes(statutResolution)) return;

  const concerneId = await resolveUtilisateurConcerneSignalement(objetId, typeObjet);
  if (!concerneId || concerneId === signalantUserId) return;

  const { data: u } = await supabase
    .from('utilisateurs')
    .select('email, nom')
    .eq('id', concerneId)
    .maybeSingle();
  if (!u) return;

  const traite = statutResolution === 'traite';
  const titre = traite ? 'Signalement examiné' : 'Signalement classé sans suite';
  const typeLabel = {
    offre: 'votre offre',
    profil: 'votre profil',
    candidature: 'une de vos candidatures',
    utilisateur: 'votre profil',
  }[typeObjet] || 'un contenu vous concernant';
  const intro = traite
    ? `Un signalement concernant ${typeLabel} a été traité par la modération.`
    : `Un signalement concernant ${typeLabel} a été examiné et classé sans suite par la modération.`;
  const message = messageSignalementAvecModeration(intro, noteAdmin, raison);

  const lien = await lienNotifPourUtilisateur(concerneId);

  try {
    await supabase.from('notifications').insert({
      destinataire_id: concerneId,
      type_destinataire: 'individuel',
      titre,
      message,
      type: 'systeme',
      lien,
      est_lue: false,
    });
  } catch (e) {
    console.warn('[notifySignalementResolutionPourConcerne] in-app:', e.message);
  }

  void sendSignalementConcerneEmail({
    concerneEmail: u.email,
    concerneNom: u.nom,
    statutResolution,
    typeObjet,
    raisonSignalement: raison,
    noteModeration: noteAdmin,
  });
}
