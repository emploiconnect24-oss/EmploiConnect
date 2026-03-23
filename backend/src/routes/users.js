/**
 * Routes utilisateur : profil (GET/PATCH) - authentification requise
 */
import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { supabase } from '../config/supabase.js';
import { authenticate } from '../middleware/auth.js';
import { ROLES } from '../config/constants.js';
import { logError } from '../utils/logger.js';

const router = Router();
const SALT_ROUNDS = 10;

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
      .select('id, email, nom, role, telephone, adresse, photo_url, est_actif, est_valide, date_creation')
      .eq('id', id)
      .single();

    if (errU || !user) {
      return res.status(404).json({ message: 'Utilisateur introuvable' });
    }

    let profil = null;
    if (role === ROLES.CHERCHEUR) {
      const { data: ch } = await supabase
        .from('chercheurs_emploi')
        .select('id, date_naissance, genre, competences, niveau_etude, disponibilite')
        .eq('utilisateur_id', id)
        .single();
      profil = ch;
    } else if (role === ROLES.ENTREPRISE) {
      const { data: ent } = await supabase
        .from('entreprises')
        .select('id, nom_entreprise, description, secteur_activite, taille_entreprise, site_web, logo_url, adresse_siege')
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

    res.json({ user, profil });
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

    const allowedUser = ['nom', 'telephone', 'adresse', 'photo_url'];
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
      const allowedChercheur = ['date_naissance', 'genre', 'competences', 'niveau_etude', 'disponibilite'];
      const chUpdate = {};
      for (const key of allowedChercheur) {
        if (body[key] !== undefined) chUpdate[key] = body[key];
      }
      if (Object.keys(chUpdate).length > 0) {
        const { data: ch, error: errCh } = await supabase
          .from('chercheurs_emploi')
          .select('id')
          .eq('utilisateur_id', id)
          .single();
        if (errCh) {
          logError('PATCH /users/me - chercheur introuvable', errCh);
        } else if (ch) {
          await supabase.from('chercheurs_emploi').update(chUpdate).eq('id', ch.id);
        }
      }
    } else if (role === ROLES.ENTREPRISE) {
      const allowedEnt = ['nom_entreprise', 'description', 'secteur_activite', 'taille_entreprise', 'site_web', 'logo_url', 'adresse_siege'];
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
      .select('id, email, nom, role, telephone, adresse, photo_url')
      .eq('id', id)
      .single();

    res.json({ message: 'Profil mis à jour', user });
  } catch (err) {
    logError('PATCH /users/me - erreur inattendue', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

export default router;
