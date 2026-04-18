/**
 * Permissions admin (cache ~5 min) — basé sur administrateurs.id (req.admin.id).
 */
import { supabase } from '../config/supabase.js';

const _cache = new Map();
const TTL_MS = 5 * 60 * 1000;

const SUPER_SECTIONS = [
  'dashboard',
  'utilisateurs',
  'offres',
  'entreprises',
  'candidatures',
  'signalements',
  'temoignages',
  'parcours',
  'statistiques',
  'recherche',
  'messages',
  'bannieres',
  'newsletter',
  'newsletter_envoi',
  'illustrations',
  'messages_contact',
  'equipe',
  'parametres',
  'apropos',
];

function fullAccessPermissions() {
  const permissions = {};
  for (const s of SUPER_SECTIONS) {
    permissions[s] = {
      peut_voir: true,
      peut_modifier: true,
      peut_supprimer: true,
    };
  }
  return permissions;
}

export function invaliderCacheAdmin(adminId) {
  if (!adminId) return;
  _cache.delete(`perms_${adminId}`);
}

export async function getPermissionsAdmin(adminId) {
  if (!adminId) return null;
  const cacheKey = `perms_${adminId}`;
  const cached = _cache.get(cacheKey);
  if (cached && Date.now() < cached.expiry) {
    return cached.data;
  }

  const { data: admin, error } = await supabase
    .from('administrateurs')
    .select(
      `
      id,
      est_super_admin,
      role_id,
      admin_roles (
        id,
        nom,
        couleur,
        icone,
        admin_permissions (
          section,
          peut_voir,
          peut_modifier,
          peut_supprimer
        )
      )
    `,
    )
    .eq('id', adminId)
    .maybeSingle();

  if (error || !admin) {
    return null;
  }

  const role = Array.isArray(admin.admin_roles) ? admin.admin_roles[0] : admin.admin_roles;
  const perms = {
    est_super_admin: Boolean(admin.est_super_admin),
    role: role
      ? {
          id: role.id,
          nom: role.nom,
          couleur: role.couleur,
          icone: role.icone,
          permissions: role.admin_permissions,
        }
      : null,
    permissions: {},
  };

  if (admin.est_super_admin) {
    perms.permissions = fullAccessPermissions();
  } else if (role?.admin_permissions?.length) {
    for (const p of role.admin_permissions) {
      perms.permissions[p.section] = {
        peut_voir: Boolean(p.peut_voir),
        peut_modifier: Boolean(p.peut_modifier),
        peut_supprimer: Boolean(p.peut_supprimer),
      };
    }
  }

  _cache.set(cacheKey, { data: perms, expiry: Date.now() + TTL_MS });
  return perms;
}

export function requirePermission(section, action = 'peut_voir') {
  return async (req, res, next) => {
    try {
      const adminId = req.admin?.id;
      if (!adminId) {
        return res.status(401).json({
          success: false,
          message: 'Authentification administrateur requise',
        });
      }

      const perms = await getPermissionsAdmin(adminId);
      if (!perms) {
        return res.status(403).json({
          success: false,
          message: 'Administrateur non trouvé',
        });
      }

      const sectionPerms = perms.permissions[section];
      if (!sectionPerms?.[action]) {
        return res.status(403).json({
          success: false,
          message: `Accès refusé : permission "${action}" sur "${section}" requise`,
        });
      }

      req.adminPerms = perms;
      return next();
    } catch (err) {
      return res.status(500).json({
        success: false,
        message: err.message || 'Erreur serveur',
      });
    }
  };
}

export async function requireSuperAdmin(req, res, next) {
  try {
    const adminId = req.admin?.id;
    if (!adminId) {
      return res.status(401).json({
        success: false,
        message: 'Authentification administrateur requise',
      });
    }
    const perms = await getPermissionsAdmin(adminId);
    if (!perms?.est_super_admin) {
      return res.status(403).json({
        success: false,
        message: 'Accès réservé au Super Administrateur',
      });
    }
    req.adminPerms = perms;
    return next();
  } catch (err) {
    return res.status(500).json({
      success: false,
      message: err.message || 'Erreur serveur',
    });
  }
}
