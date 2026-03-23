/**
 * Routes d'authentification : inscription (custom) et connexion (JWT)
 */
import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { supabase } from '../config/supabase.js';
import { ROLES } from '../config/constants.js';
import { logError } from '../utils/logger.js';

const router = Router();
const JWT_SECRET = process.env.JWT_SECRET;
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';
const SALT_ROUNDS = 10;

// Limitation de débit spécifique sur /auth/login pour éviter le brute-force
const loginLimiter = rateLimit({
  windowMs: Number(process.env.LOGIN_RATE_LIMIT_WINDOW_MS || 15 * 60 * 1000), // 15 minutes
  max: Number(process.env.LOGIN_RATE_LIMIT_MAX || 5), // 5 tentatives par fenêtre / IP
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Trop de tentatives de connexion, réessayez plus tard.' },
});

/**
 * POST /auth/register
 * Body: { email, mot_de_passe, nom, role, telephone?, adresse? }
 * role: 'chercheur' | 'entreprise' | 'admin'
 */
router.post('/register', async (req, res) => {
  try {
    const { email, mot_de_passe, nom, role, telephone, adresse } = req.body;

    if (!email || !mot_de_passe || !nom || !role) {
      return res.status(400).json({
        message: 'Champs requis : email, mot_de_passe, nom, role',
      });
    }

    const validRoles = [ROLES.CHERCHEUR, ROLES.ENTREPRISE, ROLES.ADMIN];
    if (!validRoles.includes(role)) {
      return res.status(400).json({
        message: 'role doit être : chercheur, entreprise ou admin',
      });
    }

    const emailNorm = String(email).trim().toLowerCase();
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(emailNorm)) {
      return res.status(400).json({ message: 'Format d\'email invalide' });
    }

    if (String(nom).trim().length > 150) {
      return res.status(400).json({ message: 'Le nom ne doit pas dépasser 150 caractères' });
    }
    if (mot_de_passe.length < 8) {
      return res.status(400).json({ message: 'Le mot de passe doit faire au moins 8 caractères' });
    }

    const mot_de_passe_hash = await bcrypt.hash(mot_de_passe, SALT_ROUNDS);

    const { data: existing } = await supabase
      .from('utilisateurs')
      .select('id')
      .eq('email', emailNorm)
      .single();

    if (existing) {
      return res.status(409).json({ message: 'Un compte existe déjà avec cet email' });
    }

    const { data: newUser, error: errUser } = await supabase
      .from('utilisateurs')
      .insert({
        email: emailNorm,
        mot_de_passe: mot_de_passe_hash,
        nom: String(nom).trim(),
        role,
        telephone: telephone || null,
        adresse: adresse || null,
        est_actif: true,
        est_valide: role === ROLES.ADMIN, // Les admins sont validés par défaut
      })
      .select('id, email, nom, role, date_creation')
      .single();

    if (errUser) {
      logError('Register utilisateur - erreur insertion', errUser);
      return res.status(500).json({ message: 'Erreur lors de la création du compte' });
    }

    // Créer le profil selon le rôle
    if (role === ROLES.CHERCHEUR) {
      await supabase.from('chercheurs_emploi').insert({ utilisateur_id: newUser.id });
    } else if (role === ROLES.ENTREPRISE) {
      await supabase.from('entreprises').insert({
        utilisateur_id: newUser.id,
        nom_entreprise: nom, // À compléter côté frontend avec un champ dédié si besoin
      });
    } else if (role === ROLES.ADMIN) {
      await supabase.from('administrateurs').insert({ utilisateur_id: newUser.id });
    }

    const token = jwt.sign(
      { userId: newUser.id, email: newUser.email, role: newUser.role },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    res.status(201).json({
      message: 'Compte créé',
      user: {
        id: newUser.id,
        email: newUser.email,
        nom: newUser.nom,
        role: newUser.role,
      },
      token,
      expiresIn: JWT_EXPIRES_IN,
    });
  } catch (err) {
    logError('Register - erreur inattendue', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

/**
 * POST /auth/login
 * Body: { email, mot_de_passe }
 */
router.post('/login', loginLimiter, async (req, res) => {
  try {
    const { email, mot_de_passe } = req.body;

    if (!email || !mot_de_passe) {
      return res.status(400).json({ message: 'Email et mot de passe requis' });
    }

    const emailNorm = String(email).trim().toLowerCase();
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(emailNorm)) {
      return res.status(400).json({ message: 'Format d\'email invalide' });
    }

    const { data: user, error } = await supabase
      .from('utilisateurs')
      .select('id, email, nom, role, mot_de_passe, est_actif, est_valide')
      .eq('email', emailNorm)
      .single();

    if (error || !user) {
      return res.status(401).json({ message: 'Email ou mot de passe incorrect' });
    }

    const match = await bcrypt.compare(mot_de_passe, user.mot_de_passe);
    if (!match) {
      return res.status(401).json({ message: 'Email ou mot de passe incorrect' });
    }

    if (!user.est_actif) {
      return res.status(403).json({ message: 'Compte désactivé' });
    }

    if (user.role !== ROLES.ADMIN && !user.est_valide) {
      return res.status(403).json({ message: 'Compte en attente de validation par un administrateur' });
    }

    const token = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    res.json({
      message: 'Connexion réussie',
      user: {
        id: user.id,
        email: user.email,
        nom: user.nom,
        role: user.role,
      },
      token,
      expiresIn: JWT_EXPIRES_IN,
    });
  } catch (err) {
    logError('Login - erreur inattendue', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

export default router;
