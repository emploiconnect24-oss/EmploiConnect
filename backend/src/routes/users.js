/**
 * Routes utilisateur : profil (GET/PATCH) - authentification requise
 */
import { Router } from 'express';
import bcrypt from 'bcryptjs';
import multer from 'multer';
import sharp from 'sharp';
import { supabase, BUCKET_ADMIN_AVATARS } from '../config/supabase.js';
import { authenticate } from '../middleware/auth.js';
import { ROLES } from '../config/constants.js';
import { logError } from '../utils/logger.js';
import { calculerCompletionProfil } from '../services/profilCompletion.service.js';

const router = Router();
const SALT_ROUNDS = 10;
const PHOTO_EXTS = new Set(['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'heif', 'bmp']);
const uploadPhoto = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 15 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    console.log('[Upload] Fichier reçu:', file.originalname, file.mimetype, file.size);
    cb(null, true);
  },
});

// Toutes les routes nécessitent une authentification
router.use(authenticate);

/**
 * GET /users/me
 * Retourne le profil de l'utilisateur connecté (+ profil chercheur/entreprise/admin si existant)
 */
router.get('/me', async (req, res) => {
  try {
    const { id, role } = req.user;

    const { data: user, error: errU } = await supabase
      .from('utilisateurs')
      .select(`
        id, email, nom, role, telephone, adresse, photo_url, est_actif, est_valide, date_creation,
        langue_interface, fuseau_horaire,
        notif_nouvelles_candidatures, notif_messages_recus, notif_offres_expiration, notif_resume_hebdo, notif_push,
        privacy_profile_visible, privacy_show_salary_default, privacy_allow_direct_contact
      `)
      .eq('id', id)
      .single();

    if (errU || !user) {
      return res.status(404).json({ message: 'Utilisateur introuvable' });
    }

    let profil = null;
    let completionProfil = null;
    if (role === ROLES.CHERCHEUR) {
      const { data: ch } = await supabase
        .from('chercheurs_emploi')
        .select('id, date_naissance, genre, competences, niveau_etude, disponibilite, titre_poste, about')
        .eq('utilisateur_id', id)
        .maybeSingle();
      profil = ch;
      const { data: cv } = await supabase
        .from('cv')
        .select('fichier_url, nom_fichier, competences_extrait')
        .eq('chercheur_id', ch?.id)
        .maybeSingle();
      completionProfil = calculerCompletionProfil(user, ch || null, cv || null);
    } else if (role === ROLES.ENTREPRISE) {
      const { data: ent } = await supabase
        .from('entreprises')
        .select('*')
        .eq('utilisateur_id', id)
        .single();
      profil = ent;
    } else if (role === ROLES.ADMIN) {
      const { data: adm } = await supabase
        .from('administrateurs')
        .select('id, niveau_acces')
        .eq('utilisateur_id', id)
        .single();
      profil = adm;
    }

    res.json({ user, profil, completion_profil: completionProfil });
  } catch (err) {
    logError('GET /users/me - erreur inattendue', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

/**
 * PATCH /users/me
 * Met à jour le profil (champs autorisés selon rôle)
 * Body: champs à mettre à jour (nom, telephone, adresse, photo_url; ou champs du profil chercheur/entreprise)
 */
router.patch('/me', async (req, res) => {
  try {
    const { id, role } = req.user;
    const body = req.body;

    const allowedUser = [
      'nom', 'telephone', 'adresse', 'photo_url',
      'langue_interface', 'fuseau_horaire',
      'notif_nouvelles_candidatures', 'notif_messages_recus', 'notif_offres_expiration', 'notif_resume_hebdo', 'notif_push',
      'privacy_profile_visible', 'privacy_show_salary_default', 'privacy_allow_direct_contact',
    ];
    const userUpdate = {};
    for (const key of allowedUser) {
      if (body[key] !== undefined) userUpdate[key] = body[key];
    }

    if (Object.keys(userUpdate).length > 0) {
      if (userUpdate.nom && String(userUpdate.nom).trim().length > 150) {
        return res.status(400).json({ message: 'Le nom ne doit pas dépasser 150 caractères' });
      }
      if (userUpdate.telephone && String(userUpdate.telephone).length > 30) {
        return res.status(400).json({ message: 'Le téléphone ne doit pas dépasser 30 caractères' });
      }
      if (userUpdate.adresse && String(userUpdate.adresse).length > 255) {
        return res.status(400).json({ message: 'L\'adresse ne doit pas dépasser 255 caractères' });
      }
      const { error: errU } = await supabase
        .from('utilisateurs')
        .update(userUpdate)
        .eq('id', id);
      if (errU) {
        logError('PATCH /users/me - erreur update utilisateur', errU);
        return res.status(500).json({ message: 'Erreur mise à jour profil' });
      }
    }

    if (role === ROLES.CHERCHEUR) {
      const allowedChercheur = [
        'date_naissance', 'genre', 'competences', 'niveau_etude', 'disponibilite',
        'titre_poste', 'about',
      ];
      const chUpdate = {};
      for (const key of allowedChercheur) {
        if (body[key] !== undefined) chUpdate[key] = body[key];
      }
      if (Object.keys(chUpdate).length > 0) {
        const { data: ch, error: errCh } = await supabase
          .from('chercheurs_emploi')
          .select('id')
          .eq('utilisateur_id', id)
          .maybeSingle();
        if (errCh) {
          logError('PATCH /users/me - chercheur introuvable', errCh);
        } else if (ch) {
          await supabase.from('chercheurs_emploi').update(chUpdate).eq('id', ch.id);
        } else {
          const { error: insErr } = await supabase
            .from('chercheurs_emploi')
            .insert({ utilisateur_id: id, ...chUpdate });
          if (insErr) logError('PATCH /users/me - création chercheur', insErr);
        }
      }
    } else if (role === ROLES.ENTREPRISE) {
      const allowedEnt = [
        'nom_entreprise', 'description', 'secteur_activite', 'taille_entreprise', 'site_web',
        'logo_url', 'adresse_siege', 'slogan', 'email_public', 'telephone_public', 'mission',
        'annee_fondation', 'banniere_url', 'linkedin', 'facebook', 'twitter', 'instagram',
        'whatsapp_business', 'valeurs', 'avantages',
      ];
      const entUpdate = {};
      for (const key of allowedEnt) {
        if (body[key] !== undefined) entUpdate[key] = body[key];
      }
      if (Object.keys(entUpdate).length > 0) {
        const { data: ent, error: errEnt } = await supabase
          .from('entreprises')
          .select('id')
          .eq('utilisateur_id', id)
          .single();
        if (errEnt) {
          logError('PATCH /users/me - entreprise introuvable', errEnt);
        } else if (ent) {
          await supabase.from('entreprises').update(entUpdate).eq('id', ent.id);
        }
      }
    }

    if (body.mot_de_passe) {
      if (body.mot_de_passe.length < 8) {
        return res.status(400).json({ message: 'Le mot de passe doit faire au moins 8 caractères' });
      }
      const hash = await bcrypt.hash(body.mot_de_passe, SALT_ROUNDS);
      await supabase.from('utilisateurs').update({ mot_de_passe: hash }).eq('id', id);
    }

    const { data: user } = await supabase
      .from('utilisateurs')
      .select(`
        id, email, nom, role, telephone, adresse, photo_url,
        langue_interface, fuseau_horaire,
        notif_nouvelles_candidatures, notif_messages_recus, notif_offres_expiration, notif_resume_hebdo, notif_push,
        privacy_profile_visible, privacy_show_salary_default, privacy_allow_direct_contact
      `)
      .eq('id', id)
      .single();

    res.json({ message: 'Profil mis à jour', user });
  } catch (err) {
    logError('PATCH /users/me - erreur inattendue', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

router.post('/me/photo', uploadPhoto.single('photo'), async (req, res) => {
  try {
    if (!req.file || !req.file.buffer) {
      return res.status(400).json({
        success: false,
        message: 'Aucun fichier reçu par le serveur',
      });
    }

    console.log('[uploadPhoto] Reçu:', {
      name: req.file.originalname,
      mime: req.file.mimetype,
      size: req.file.size,
    });

    let buffer = req.file.buffer;
    let mimeType = 'image/jpeg';
    let ext = 'jpg';

    try {
      buffer = await sharp(req.file.buffer, { failOnError: false })
        .resize(400, 400, { fit: 'cover', position: 'center' })
        .jpeg({ quality: 85 })
        .toBuffer();
      console.log('[uploadPhoto] Sharp OK');
    } catch (sharpErr) {
      console.warn('[uploadPhoto] Sharp échoué, buffer direct:', sharpErr.message);
      buffer = req.file.buffer;
      mimeType = req.file.mimetype || 'image/jpeg';
      const fromName = String(req.file.originalname || '').split('.').pop()?.toLowerCase() || '';
      ext = PHOTO_EXTS.has(fromName) ? fromName : 'jpg';
    }

    const bucket = BUCKET_ADMIN_AVATARS;
    const fileName = `avatar-${req.user.id}-${Date.now()}.${ext}`;

    console.log('[uploadPhoto] Upload vers bucket:', bucket, fileName);

    const { error: uploadErr } = await supabase.storage
      .from(bucket)
      .upload(fileName, buffer, {
        contentType: mimeType,
        upsert: true,
        cacheControl: '3600',
      });

    if (uploadErr) {
      console.error('[uploadPhoto] Erreur Supabase:', uploadErr);
      return res.status(500).json({
        success: false,
        message: `Erreur storage: ${uploadErr.message}`,
        detail: uploadErr,
      });
    }

    const { data: urlData } = supabase.storage.from(bucket).getPublicUrl(fileName);
    const photoUrl = urlData?.publicUrl || '';
    console.log('[uploadPhoto] URL publique:', photoUrl);

    const { error: userErr } = await supabase
      .from('utilisateurs')
      .update({
        photo_url: photoUrl,
        date_modification: new Date().toISOString(),
      })
      .eq('id', req.user.id);

    if (userErr) {
      return res.status(500).json({ success: false, message: 'Erreur sauvegarde photo utilisateur' });
    }

    return res.json({
      success: true,
      message: 'Photo mise à jour avec succès',
      data: { photo_url: photoUrl },
    });
  } catch (err) {
    console.error('[uploadPhoto] Exception:', err);
    logError('POST /users/me/photo - erreur', err);
    return res.status(500).json({
      success: false,
      message: err.message || 'Erreur upload',
    });
  }
});

/**
 * POST /users/me/push-token — enregistrer un token FCM (mobile / web).
 * Body: { token, plateforme?: 'android'|'ios'|'web' }
 */
router.post('/me/push-token', async (req, res) => {
  try {
    const raw = req.body?.token;
    const token = raw != null ? String(raw).trim() : '';
    if (token.length < 10) {
      return res.status(400).json({ message: 'token invalide' });
    }
    let plat = String(req.body?.plateforme || 'android').toLowerCase().replace(/[^a-z]/g, '');
    if (!plat) plat = 'android';
    plat = plat.slice(0, 20);
    const { error } = await supabase.from('device_push_tokens').upsert(
      {
        utilisateur_id: req.user.id,
        token,
        plateforme: plat,
        date_mise_a_jour: new Date().toISOString(),
      },
      { onConflict: 'utilisateur_id,token' },
    );
    if (error) {
      logError('POST /users/me/push-token', error);
      return res.status(500).json({ message: 'Erreur enregistrement token' });
    }
    return res.json({ success: true });
  } catch (err) {
    logError('POST /users/me/push-token - erreur', err);
    return res.status(500).json({ message: 'Erreur serveur' });
  }
});

/**
 * DELETE /users/me/push-token — Body: { token } ou supprime tous les tokens de l’utilisateur si body vide.
 */
router.delete('/me/push-token', async (req, res) => {
  try {
    const raw = req.body?.token ?? req.query?.token;
    const token = raw != null ? String(raw).trim() : '';
    const del = supabase.from('device_push_tokens').delete().eq('utilisateur_id', req.user.id);
    const { error } = token.length >= 10
      ? await del.eq('token', token)
      : await del;
    if (error) {
      logError('DELETE /users/me/push-token', error);
      return res.status(500).json({ message: 'Erreur suppression token' });
    }
    return res.json({ success: true });
  } catch (err) {
    logError('DELETE /users/me/push-token - erreur', err);
    return res.status(500).json({ message: 'Erreur serveur' });
  }
});

router.patch('/me/deactivate', async (req, res) => {
  try {
    const { error } = await supabase
      .from('utilisateurs')
      .update({ est_actif: false })
      .eq('id', req.user.id);
    if (error) throw error;
    return res.json({ success: true, message: 'Compte désactivé temporairement' });
  } catch (err) {
    logError('PATCH /users/me/deactivate - erreur', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.delete('/me', async (req, res) => {
  try {
    const deletedEmail = `deleted_${req.user.id}@deleted.local`;
    const { error } = await supabase
      .from('utilisateurs')
      .update({
        est_actif: false,
        est_valide: false,
        email: deletedEmail,
        nom: 'Compte supprimé',
        telephone: null,
        adresse: null,
      })
      .eq('id', req.user.id);
    if (error) throw error;
    return res.json({ success: true, message: 'Compte marqué comme supprimé' });
  } catch (err) {
    logError('DELETE /users/me - erreur', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

export default router;
