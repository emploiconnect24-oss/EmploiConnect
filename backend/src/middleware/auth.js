/**
 * Middleware d'authentification (JWT custom)
 * Vérifie le token et attache user (id, email, role) à req.user
 */
import jwt from 'jsonwebtoken';
import { supabase } from '../config/supabase.js';
import { ROLES } from '../config/constants.js';

const JWT_SECRET = process.env.JWT_SECRET;

/**
 * Vérifie le JWT et charge l'utilisateur depuis la base (est_actif, est_valide)
 */
export async function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;
  const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : null;

  if (!token) {
    return res.status(401).json({ message: 'Token manquant' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const { data: user, error } = await supabase
      .from('utilisateurs')
      .select('id, email, nom, role, est_actif, est_valide')
      .eq('id', decoded.userId)
      .single();

    if (error || !user) {
      return res.status(401).json({ message: 'Utilisateur introuvable' });
    }
    if (!user.est_actif) {
      return res.status(403).json({ message: 'Compte désactivé' });
    }
    // Optionnel : exiger est_valide pour les non-admins (modération)
    if (user.role !== ROLES.ADMIN && !user.est_valide) {
      return res.status(403).json({ message: 'Compte en attente de validation' });
    }

    req.user = user;
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ message: 'Token expiré' });
    }
    return res.status(401).json({ message: 'Token invalide' });
  }
}

/**
 * Exige un des rôles passés (ex: requireRole('admin'), requireRole('chercheur', 'entreprise'))
 */
export function requireRole(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: 'Non authentifié' });
    }
    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ message: 'Droits insuffisants' });
    }
    next();
  };
}

/**
 * Authentification optionnelle : attache req.user si token valide, sinon continue sans erreur
 */
export async function optionalAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : null;
  if (!token) return next();
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const { data: user } = await supabase
      .from('utilisateurs')
      .select('id, email, nom, role, est_actif, est_valide')
      .eq('id', decoded.userId)
      .single();
    if (user && user.est_actif) req.user = user;
  } catch (_) { /* ignorer token invalide */ }
  next();
}
