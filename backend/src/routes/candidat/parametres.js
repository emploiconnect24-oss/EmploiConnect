import bcrypt from 'bcryptjs';
import { Router } from 'express';
import { authenticate, requireRole } from '../../middleware/auth.js';
import { attachProfileIds } from '../../helpers/userProfile.js';
import { supabase } from '../../config/supabase.js';
import { ROLES } from '../../config/constants.js';

const router = Router();
router.use(authenticate, requireRole(ROLES.CHERCHEUR), attachProfileIds);

function mergePreferencesNotif(existing, patch) {
  if (!patch || typeof patch !== 'object') {
    return existing && typeof existing === 'object' && !Array.isArray(existing) ? { ...existing } : {};
  }
  const base = existing && typeof existing === 'object' && !Array.isArray(existing) ? { ...existing } : {};
  const next = { ...base, ...patch };
  if (patch.recherche && typeof patch.recherche === 'object') {
    const r0 = base.recherche && typeof base.recherche === 'object' ? { ...base.recherche } : {};
    next.recherche = { ...r0, ...patch.recherche };
  }
  return next;
}

router.get('/', async (req, res) => {
  try {
    const { data: user, error: uErr } = await supabase
      .from('utilisateurs')
      .select(`
        id, nom, email, telephone, adresse,
        langue_interface, fuseau_horaire,
        notif_nouvelles_candidatures, notif_messages_recus, notif_push,
        notif_offres_expiration, notif_resume_hebdo,
        privacy_profile_visible, privacy_allow_direct_contact,
        preferences_notif
      `)
      .eq('id', req.user.id)
      .single();
    if (uErr) throw uErr;

    const prefs = user?.preferences_notif && typeof user.preferences_notif === 'object'
      ? user.preferences_notif
      : {};

    const { data: chercheur } = await supabase
      .from('chercheurs_emploi')
      .select('id, profil_visible, recevoir_propositions, disponibilite')
      .eq('utilisateur_id', req.user.id)
      .maybeSingle();

    const rech = prefs.recherche && typeof prefs.recherche === 'object' ? prefs.recherche : {};

    return res.json({
      success: true,
      data: {
        compte: {
          nom: user?.nom || '',
          email: user?.email || '',
          telephone: user?.telephone || '',
          adresse: user?.adresse || '',
          langue_interface: user?.langue_interface || 'Français',
          fuseau_horaire: user?.fuseau_horaire || 'Africa/Conakry',
        },
        confidentialite: {
          profil_visible: chercheur?.profil_visible ?? user?.privacy_profile_visible ?? true,
          recevoir_propositions: chercheur?.recevoir_propositions ?? user?.privacy_allow_direct_contact ?? true,
          visible_recherche_talents: prefs.visible_recherche_talents !== false,
          candidatures_confidentielles: prefs.candidatures_confidentielles === true,
        },
        notifications: {
          email_candidature: user?.notif_nouvelles_candidatures ?? true,
          email_message: user?.notif_messages_recus ?? true,
          notif_in_app: user?.notif_push ?? true,
          offres_alertes_email: user?.notif_offres_expiration ?? true,
          resume_hebdo: user?.notif_resume_hebdo ?? false,
          conseils_email: prefs.conseils_email === true,
        },
        recherche_emploi: {
          disponibilite: chercheur?.disponibilite || 'Disponible immédiatement',
          types_contrat: Array.isArray(rech.types_contrat) ? rech.types_contrat : ['CDI', 'CDD'],
          villes: Array.isArray(rech.villes) ? rech.villes : ['Conakry'],
          secteurs: Array.isArray(rech.secteurs) ? rech.secteurs : ['Technologie'],
          salaire_souhaite: rech.salaire_souhaite != null ? String(rech.salaire_souhaite) : '',
        },
        meta: {
          chercheur_id: chercheur?.id || null,
        },
      },
    });
  } catch (err) {
    console.error('[candidat/parametres GET /]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.patch('/confidentialite', async (req, res) => {
  try {
    const {
      profil_visible: profilVisible,
      recevoir_propositions: recevoirPropositions,
      visible_recherche_talents: visibleTalents,
      candidatures_confidentielles: candConf,
    } = req.body || {};

    const userUpdates = {};
    if (profilVisible !== undefined) userUpdates.privacy_profile_visible = !!profilVisible;
    if (recevoirPropositions !== undefined) userUpdates.privacy_allow_direct_contact = !!recevoirPropositions;

    if (Object.keys(userUpdates).length > 0) {
      const { error } = await supabase
        .from('utilisateurs')
        .update(userUpdates)
        .eq('id', req.user.id);
      if (error) throw error;
    }

    if (req.chercheurId && (profilVisible !== undefined || recevoirPropositions !== undefined)) {
      const chUp = {};
      if (profilVisible !== undefined) chUp.profil_visible = !!profilVisible;
      if (recevoirPropositions !== undefined) chUp.recevoir_propositions = !!recevoirPropositions;
      if (Object.keys(chUp).length) {
        const { error: chErr } = await supabase
          .from('chercheurs_emploi')
          .update(chUp)
          .eq('id', req.chercheurId);
        if (chErr && chErr.code !== 'PGRST204') console.warn('[parametres confidentialite chercheur]', chErr.message);
      }
    }

    if (visibleTalents !== undefined || candConf !== undefined) {
      const { data: u2, error: rErr } = await supabase
        .from('utilisateurs')
        .select('preferences_notif')
        .eq('id', req.user.id)
        .single();
      if (rErr) throw rErr;
      const patch = {};
      if (visibleTalents !== undefined) patch.visible_recherche_talents = !!visibleTalents;
      if (candConf !== undefined) patch.candidatures_confidentielles = !!candConf;
      const merged = mergePreferencesNotif(u2?.preferences_notif, patch);
      const { error: uErr } = await supabase
        .from('utilisateurs')
        .update({ preferences_notif: merged })
        .eq('id', req.user.id);
      if (uErr) throw uErr;
    }

    return res.json({ success: true, message: 'Paramètres de confidentialité mis à jour' });
  } catch (err) {
    console.error('[candidat/parametres PATCH /confidentialite]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

/** PATCH /candidat/parametres/profil — nom, coordonnées, langue, fuseau, disponibilité */
router.patch('/profil', async (req, res) => {
  try {
    const {
      nom, telephone, adresse,
      langue_interface: langue,
      fuseau_horaire: fuseau,
      disponibilite,
    } = req.body || {};

    const userUpdates = {};
    if (nom !== undefined) userUpdates.nom = String(nom).trim().slice(0, 150);
    if (telephone !== undefined) userUpdates.telephone = telephone == null ? null : String(telephone).slice(0, 30);
    if (adresse !== undefined) userUpdates.adresse = adresse == null ? null : String(adresse).slice(0, 255);
    if (langue !== undefined) userUpdates.langue_interface = String(langue).slice(0, 30);
    if (fuseau !== undefined) userUpdates.fuseau_horaire = String(fuseau).slice(0, 60);

    if (Object.keys(userUpdates).length > 0) {
      const { error } = await supabase
        .from('utilisateurs')
        .update(userUpdates)
        .eq('id', req.user.id);
      if (error) throw error;
    }

    if (disponibilite !== undefined && req.chercheurId) {
      const { error: chErr } = await supabase
        .from('chercheurs_emploi')
        .update({ disponibilite: String(disponibilite).slice(0, 50) })
        .eq('id', req.chercheurId);
      if (chErr && chErr.code !== 'PGRST204') console.warn('[parametres profil disponibilite]', chErr.message);
    }

    return res.json({ success: true, message: 'Profil mis à jour' });
  } catch (err) {
    console.error('[candidat/parametres PATCH /profil]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

/** PATCH /candidat/parametres/recherche-emploi — critères sauvegardés (JSON preferences_notif.recherche) */
router.patch('/recherche-emploi', async (req, res) => {
  try {
    const {
      types_contrat: typesContrat,
      villes,
      secteurs,
      salaire_souhaite: salaireSouhaite,
    } = req.body || {};

    const { data: u2, error: rErr } = await supabase
      .from('utilisateurs')
      .select('preferences_notif')
      .eq('id', req.user.id)
      .single();
    if (rErr) throw rErr;

    const rechPatch = {};
    if (Array.isArray(typesContrat)) rechPatch.types_contrat = typesContrat.map((x) => String(x));
    if (Array.isArray(villes)) rechPatch.villes = villes.map((x) => String(x));
    if (Array.isArray(secteurs)) rechPatch.secteurs = secteurs.map((x) => String(x));
    if (salaireSouhaite !== undefined) {
      rechPatch.salaire_souhaite = salaireSouhaite === null || salaireSouhaite === ''
        ? null
        : String(salaireSouhaite);
    }

    const merged = mergePreferencesNotif(u2?.preferences_notif, { recherche: rechPatch });
    const { error: uErr } = await supabase
      .from('utilisateurs')
      .update({ preferences_notif: merged })
      .eq('id', req.user.id);
    if (uErr) throw uErr;

    return res.json({ success: true, message: 'Préférences de recherche enregistrées' });
  } catch (err) {
    console.error('[candidat/parametres PATCH /recherche-emploi]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.patch('/mot-de-passe', async (req, res) => {
  try {
    const { ancien_mot_de_passe: ancien, nouveau_mot_de_passe: nouveau } = req.body || {};
    if (!ancien || !nouveau) {
      return res.status(400).json({ success: false, message: 'Les deux mots de passe sont requis' });
    }
    if (String(nouveau).length < 8) {
      return res.status(400).json({ success: false, message: 'Minimum 8 caractères' });
    }

    const { data: user, error: uErr } = await supabase
      .from('utilisateurs')
      .select('mot_de_passe')
      .eq('id', req.user.id)
      .single();
    if (uErr) throw uErr;

    const ok = await bcrypt.compare(String(ancien), user?.mot_de_passe || '');
    if (!ok) {
      return res.status(400).json({ success: false, message: 'Mot de passe actuel incorrect' });
    }

    const hash = await bcrypt.hash(String(nouveau), 10);
    const { error } = await supabase
      .from('utilisateurs')
      .update({ mot_de_passe: hash })
      .eq('id', req.user.id);
    if (error) throw error;

    return res.json({ success: true, message: 'Mot de passe mis à jour' });
  } catch (err) {
    console.error('[candidat/parametres PATCH /mot-de-passe]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

export default router;
