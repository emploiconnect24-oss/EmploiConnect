/**
 * /api/admin/sous-admins/* — gestion des comptes admin (super admin) + mes permissions.
 */
import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { supabase } from '../../config/supabase.js';
import { ROLES } from '../../config/constants.js';
import {
  getPermissionsAdmin,
  invaliderCacheAdmin,
  requireSuperAdmin,
} from '../../middleware/adminPermissions.js';

const router = Router();
const SALT_ROUNDS = 12;

async function getRoleById(roleId) {
  if (!roleId) return null;
  const { data } = await supabase
    .from('admin_roles')
    .select('id, nom')
    .eq('id', roleId)
    .maybeSingle();
  return data;
}

async function assertAssignableRole(roleId) {
  const role = await getRoleById(roleId);
  if (!role) {
    return { ok: false, message: 'Rôle invalide' };
  }
  if (role.nom === 'Super Admin') {
    return { ok: false, message: 'Le rôle Super Admin ne peut pas être assigné ainsi' };
  }
  return { ok: true, role };
}

router.get('/mes-permissions', async (req, res) => {
  try {
    const perms = await getPermissionsAdmin(req.admin?.id);
    if (!perms) {
      return res.status(403).json({
        success: false,
        message: 'Administrateur non trouvé',
      });
    }
    return res.json({ success: true, data: perms });
  } catch (err) {
    return res.status(500).json({
      success: false,
      message: err.message || 'Erreur serveur',
    });
  }
});

router.get('/roles', requireSuperAdmin, async (_req, res) => {
  try {
    const { data, error } = await supabase
      .from('admin_roles')
      .select(
        `
        id, nom, description, couleur, icone,
        permissions:admin_permissions (
          section, peut_voir, peut_modifier, peut_supprimer
        )
      `,
      )
      .eq('est_actif', true)
      .order('nom');
    if (error) throw error;
    return res.json({ success: true, data: data || [] });
  } catch (err) {
    return res.status(500).json({
      success: false,
      message: err.message || 'Erreur serveur',
    });
  }
});

router.put('/roles/:roleId/permissions', requireSuperAdmin, async (req, res) => {
  try {
    const { roleId } = req.params;
    const role = await getRoleById(roleId);
    if (!role || role.nom === 'Super Admin') {
      return res.status(403).json({
        success: false,
        message: 'Modification des permissions de ce rôle interdite',
      });
    }
    const permissions = Array.isArray(req.body?.permissions) ? req.body.permissions : null;
    if (!permissions?.length) {
      return res.status(400).json({
        success: false,
        message: 'Liste "permissions" requise',
      });
    }

    const rows = permissions.map((perm) => ({
      role_id: roleId,
      section: String(perm.section || '').trim(),
      peut_voir: Boolean(perm.peut_voir),
      peut_modifier: Boolean(perm.peut_modifier),
      peut_supprimer: Boolean(perm.peut_supprimer),
    }));

    const { error: upErr } = await supabase.from('admin_permissions').upsert(rows, {
      onConflict: 'role_id,section',
    });
    if (upErr) throw upErr;

    const { data: admins } = await supabase.from('administrateurs').select('id').eq('role_id', roleId);
    for (const a of admins || []) {
      invaliderCacheAdmin(a.id);
    }

    return res.json({
      success: true,
      message: 'Permissions mises à jour',
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      message: err.message || 'Erreur serveur',
    });
  }
});

router.get('/', requireSuperAdmin, async (_req, res) => {
  try {
    const { data, error } = await supabase
      .from('administrateurs')
      .select(
        `
        id,
        est_super_admin,
        est_actif,
        date_creation,
        derniere_connexion,
        role_id,
        utilisateurs ( nom, email ),
        admin_roles ( id, nom, couleur, icone )
      `,
      )
      .order('date_creation', { ascending: false });
    if (error) throw error;

    const mapped = (data || []).map((row) => {
      const u = Array.isArray(row.utilisateurs) ? row.utilisateurs[0] : row.utilisateurs;
      const r = Array.isArray(row.admin_roles) ? row.admin_roles[0] : row.admin_roles;
      return {
        id: row.id,
        nom: u?.nom ?? '',
        email: u?.email ?? '',
        est_super_admin: Boolean(row.est_super_admin),
        est_actif: row.est_actif !== false,
        created_at: row.date_creation,
        derniere_connexion: row.derniere_connexion,
        role: r || null,
      };
    });

    return res.json({ success: true, data: mapped });
  } catch (err) {
    return res.status(500).json({
      success: false,
      message: err.message || 'Erreur serveur',
    });
  }
});

router.post('/', requireSuperAdmin, async (req, res) => {
  try {
    const { nom, email, mot_de_passe, role_id } = req.body || {};
    if (!nom || !email || !mot_de_passe) {
      return res.status(400).json({
        success: false,
        message: 'Nom, email et mot de passe requis',
      });
    }
    if (String(mot_de_passe).length < 8) {
      return res.status(400).json({
        success: false,
        message: 'Le mot de passe doit faire au moins 8 caractères',
      });
    }

    if (role_id) {
      const check = await assertAssignableRole(role_id);
      if (!check.ok) {
        return res.status(400).json({ success: false, message: check.message });
      }
    }

    const emailNorm = String(email).trim().toLowerCase();
    const { data: existant } = await supabase
      .from('utilisateurs')
      .select('id')
      .eq('email', emailNorm)
      .maybeSingle();
    if (existant) {
      return res.status(400).json({
        success: false,
        message: 'Cet email est déjà utilisé',
      });
    }

    const hash = await bcrypt.hash(String(mot_de_passe), SALT_ROUNDS);
    const { data: newUser, error: errUser } = await supabase
      .from('utilisateurs')
      .insert({
        email: emailNorm,
        mot_de_passe: hash,
        nom: String(nom).trim(),
        role: ROLES.ADMIN,
        est_actif: true,
        est_valide: true,
      })
      .select('id, email, nom')
      .single();

    if (errUser || !newUser) {
      return res.status(500).json({
        success: false,
        message: errUser?.message || 'Erreur création utilisateur',
      });
    }

    const { data: adminRow, error: errAdmin } = await supabase
      .from('administrateurs')
      .insert({
        utilisateur_id: newUser.id,
        role_id: role_id || null,
        est_super_admin: false,
        est_actif: true,
        cree_par: req.admin?.id ?? null,
      })
      .select('id')
      .single();

    if (errAdmin || !adminRow) {
      await supabase.from('utilisateurs').delete().eq('id', newUser.id);
      return res.status(500).json({
        success: false,
        message: errAdmin?.message || 'Erreur création profil administrateur',
      });
    }

    return res.status(201).json({
      success: true,
      data: {
        id: adminRow.id,
        nom: newUser.nom,
        email: newUser.email,
        est_super_admin: false,
        est_actif: true,
        role: role_id ? (await getRoleById(role_id)) : null,
      },
      message: `Compte créé pour ${newUser.nom}`,
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      message: err.message || 'Erreur serveur',
    });
  }
});

router.put('/:id', requireSuperAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { nom, role_id, est_actif, nouveau_mdp } = req.body || {};

    const { data: row, error: fetchErr } = await supabase
      .from('administrateurs')
      .select('id, utilisateur_id, est_super_admin')
      .eq('id', id)
      .maybeSingle();

    if (fetchErr || !row || row.est_super_admin) {
      return res.status(403).json({
        success: false,
        message: 'Compte introuvable ou protégé (super admin)',
      });
    }

    if (role_id !== undefined && role_id !== null) {
      const check = await assertAssignableRole(role_id);
      if (!check.ok) {
        return res.status(400).json({ success: false, message: check.message });
      }
    }

    if (nom !== undefined) {
      const { error: nu } = await supabase
        .from('utilisateurs')
        .update({ nom: String(nom).trim() })
        .eq('id', row.utilisateur_id);
      if (nu) throw nu;
    }

    if (nouveau_mdp) {
      if (String(nouveau_mdp).length < 8) {
        return res.status(400).json({
          success: false,
          message: 'Le mot de passe doit faire au moins 8 caractères',
        });
      }
      const hash = await bcrypt.hash(String(nouveau_mdp), SALT_ROUNDS);
      const { error: hp } = await supabase
        .from('utilisateurs')
        .update({ mot_de_passe: hash })
        .eq('id', row.utilisateur_id);
      if (hp) throw hp;
    }

    const adminUpdates = {};
    if (role_id !== undefined) adminUpdates.role_id = role_id;
    if (est_actif !== undefined) adminUpdates.est_actif = Boolean(est_actif);

    if (Object.keys(adminUpdates).length > 0) {
      const { error: ua } = await supabase.from('administrateurs').update(adminUpdates).eq('id', id);
      if (ua) throw ua;
    }

    invaliderCacheAdmin(id);

    return res.json({
      success: true,
      message: 'Compte mis à jour',
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      message: err.message || 'Erreur serveur',
    });
  }
});

router.delete('/:id', requireSuperAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { error } = await supabase
      .from('administrateurs')
      .update({ est_actif: false })
      .eq('id', id)
      .eq('est_super_admin', false);

    if (error) throw error;

    invaliderCacheAdmin(id);

    return res.json({
      success: true,
      message: 'Compte désactivé',
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      message: err.message || 'Erreur serveur',
    });
  }
});

export default router;
