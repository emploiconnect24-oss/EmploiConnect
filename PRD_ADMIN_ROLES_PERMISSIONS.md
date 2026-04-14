# PRD — EmploiConnect · Système Rôles & Permissions Admin
## Product Requirements Document v9.8
**Stack : Flutter + Node.js/Express + Supabase**
**Date : Avril 2026**

---

## Vision

```
OBJECTIF :
L'administrateur principal peut créer des
"sous-administrateurs" avec des permissions
limitées à certaines sections.

EXEMPLE :
→ Modérateur offres : gère offres + candidatures
→ Gestionnaire RH : gère utilisateurs + entreprises
→ Community Manager : gère bannières + newsletter
→ Support : gère messages + notifications

L'admin principal garde TOUT.
Les sous-admins voient seulement ce qu'on leur accorde.
```

---

## 1. Migration SQL

```sql
-- database/migrations/059_admin_roles_permissions.sql

-- Table des rôles admin
CREATE TABLE IF NOT EXISTS admin_roles (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nom         TEXT NOT NULL UNIQUE,
  description TEXT,
  couleur     TEXT DEFAULT '#1A56DB',
  icone       TEXT DEFAULT 'admin_panel_settings',
  est_actif   BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Table des permissions par rôle
CREATE TABLE IF NOT EXISTS admin_permissions (
  id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  role_id  UUID REFERENCES admin_roles(id) ON DELETE CASCADE,
  section  TEXT NOT NULL,
  -- Sections disponibles :
  -- dashboard, utilisateurs, offres, entreprises,
  -- candidatures, messages, bannières, newsletter,
  -- parametres, illustrations, newsletter_envoi
  peut_voir     BOOLEAN DEFAULT FALSE,
  peut_modifier BOOLEAN DEFAULT FALSE,
  peut_supprimer BOOLEAN DEFAULT FALSE,
  UNIQUE(role_id, section)
);

-- Ajouter colonne role_id dans administrateurs
ALTER TABLE administrateurs
  ADD COLUMN IF NOT EXISTS role_id UUID
    REFERENCES admin_roles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS est_super_admin BOOLEAN
    DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS cree_par UUID
    REFERENCES administrateurs(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS derniere_connexion TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS est_actif BOOLEAN DEFAULT TRUE;

-- Rôles par défaut
INSERT INTO admin_roles (nom, description, couleur, icone)
VALUES
  ('Super Admin',
   'Accès complet à toute la plateforme',
   '#EF4444', 'security'),
  ('Modérateur Offres',
   'Gère les offres d''emploi et candidatures',
   '#1A56DB', 'work'),
  ('Gestionnaire Utilisateurs',
   'Gère les candidats et entreprises',
   '#10B981', 'people'),
  ('Community Manager',
   'Gère bannières, newsletter et contenu',
   '#8B5CF6', 'campaign'),
  ('Support Client',
   'Gère les messages et notifications',
   '#F59E0B', 'support_agent')
ON CONFLICT (nom) DO NOTHING;

-- Permissions pour "Modérateur Offres"
INSERT INTO admin_permissions
  (role_id, section, peut_voir, peut_modifier, peut_supprimer)
SELECT id, section, voir, modifier, supprimer
FROM admin_roles,
(VALUES
  ('dashboard',      true,  false, false),
  ('offres',         true,  true,  true),
  ('candidatures',   true,  true,  false),
  ('entreprises',    true,  false, false),
  ('utilisateurs',   true,  false, false)
) AS p(section, voir, modifier, supprimer)
WHERE nom = 'Modérateur Offres'
ON CONFLICT (role_id, section) DO NOTHING;

-- Permissions pour "Gestionnaire Utilisateurs"
INSERT INTO admin_permissions
  (role_id, section, peut_voir, peut_modifier, peut_supprimer)
SELECT id, section, voir, modifier, supprimer
FROM admin_roles,
(VALUES
  ('dashboard',    true, false, false),
  ('utilisateurs', true, true,  true),
  ('entreprises',  true, true,  false),
  ('candidatures', true, false, false)
) AS p(section, voir, modifier, supprimer)
WHERE nom = 'Gestionnaire Utilisateurs'
ON CONFLICT (role_id, section) DO NOTHING;

-- Permissions pour "Community Manager"
INSERT INTO admin_permissions
  (role_id, section, peut_voir, peut_modifier, peut_supprimer)
SELECT id, section, voir, modifier, supprimer
FROM admin_roles,
(VALUES
  ('dashboard',         true, false, false),
  ('bannieres',         true, true,  true),
  ('newsletter',        true, true,  false),
  ('newsletter_envoi',  true, true,  false),
  ('illustrations',     true, true,  false)
) AS p(section, voir, modifier, supprimer)
WHERE nom = 'Community Manager'
ON CONFLICT (role_id, section) DO NOTHING;

-- Permissions pour "Support Client"
INSERT INTO admin_permissions
  (role_id, section, peut_voir, peut_modifier, peut_supprimer)
SELECT id, section, voir, modifier, supprimer
FROM admin_roles,
(VALUES
  ('dashboard',  true, false, false),
  ('messages',   true, true,  false),
  ('utilisateurs', true, false, false)
) AS p(section, voir, modifier, supprimer)
WHERE nom = 'Support Client'
ON CONFLICT (role_id, section) DO NOTHING;

-- Marquer les admins existants comme super admins
UPDATE administrateurs
SET est_super_admin = TRUE
WHERE est_super_admin IS NULL OR est_super_admin = FALSE;
```

---

## 2. Backend — Middleware permissions

```javascript
// backend/src/middleware/adminPermissions.js

const { createClient } = require('@supabase/supabase-js');
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY);

// Cache des permissions (5 minutes)
const _cache = new Map();

const getPermissionsAdmin = async (adminId) => {
  const cacheKey = `perms_${adminId}`;
  const cached = _cache.get(cacheKey);
  if (cached && Date.now() < cached.expiry) {
    return cached.data;
  }

  const { data: admin } = await supabase
    .from('administrateurs')
    .select(`
      id, est_super_admin, role_id,
      role:admin_roles(
        id, nom, couleur,
        permissions:admin_permissions(
          section, peut_voir,
          peut_modifier, peut_supprimer
        )
      )
    `)
    .eq('id', adminId)
    .single();

  if (!admin) return null;

  const perms = {
    est_super_admin: admin.est_super_admin || false,
    role:            admin.role,
    permissions:     {},
  };

  // Super admin → tout autorisé
  if (admin.est_super_admin) {
    const sections = [
      'dashboard', 'utilisateurs', 'offres',
      'entreprises', 'candidatures', 'messages',
      'bannieres', 'newsletter', 'newsletter_envoi',
      'illustrations', 'parametres',
    ];
    sections.forEach(s => {
      perms.permissions[s] = {
        peut_voir:      true,
        peut_modifier:  true,
        peut_supprimer: true,
      };
    });
  } else if (admin.role?.permissions) {
    admin.role.permissions.forEach(p => {
      perms.permissions[p.section] = {
        peut_voir:      p.peut_voir,
        peut_modifier:  p.peut_modifier,
        peut_supprimer: p.peut_supprimer,
      };
    });
  }

  _cache.set(cacheKey, {
    data:   perms,
    expiry: Date.now() + 5 * 60 * 1000,
  });

  return perms;
};

const invaliderCacheAdmin = (adminId) => {
  _cache.delete(`perms_${adminId}`);
};

// Middleware : vérifier une permission
const requirePermission = (section, action = 'peut_voir') =>
  async (req, res, next) => {
    try {
      const adminId = req.user?.id;
      if (!adminId) {
        return res.status(401).json({
          success: false,
          message: 'Non authentifié'
        });
      }

      const perms = await getPermissionsAdmin(adminId);
      if (!perms) {
        return res.status(403).json({
          success: false,
          message: 'Administrateur non trouvé'
        });
      }

      const sectionPerms = perms.permissions[section];
      if (!sectionPerms?.[action]) {
        return res.status(403).json({
          success: false,
          message: `Accès refusé : permission `
            + `"${action}" sur "${section}" requise`
        });
      }

      // Attacher les permissions à la requête
      req.adminPerms = perms;
      next();

    } catch (err) {
      res.status(500).json({
        success: false,
        message: err.message
      });
    }
  };

// Middleware : super admin uniquement
const requireSuperAdmin = async (req, res, next) => {
  try {
    const perms = await getPermissionsAdmin(req.user?.id);
    if (!perms?.est_super_admin) {
      return res.status(403).json({
        success: false,
        message: 'Accès réservé au Super Administrateur'
      });
    }
    req.adminPerms = perms;
    next();
  } catch (err) {
    res.status(500).json({
      success: false, message: err.message });
  }
};

module.exports = {
  getPermissionsAdmin,
  invaliderCacheAdmin,
  requirePermission,
  requireSuperAdmin,
};
```

---

## 3. Routes admin — Gestion des sous-admins

```javascript
// backend/src/routes/admin/sousAdmins.routes.js

const express = require('express');
const router  = express.Router();
const bcrypt  = require('bcrypt');
const {
  requireSuperAdmin,
  invaliderCacheAdmin,
} = require('../../middleware/adminPermissions');

// GET /api/admin/sous-admins — Lister
router.get('/', requireSuperAdmin, async (req, res) => {
  try {
    const { data } = await supabase
      .from('administrateurs')
      .select(`
        id, nom, email, est_super_admin,
        est_actif, created_at, derniere_connexion,
        role:admin_roles(id, nom, couleur, icone)
      `)
      .order('created_at', { ascending: false });

    return res.json({ success: true, data: data || [] });
  } catch (err) {
    res.status(500).json({
      success: false, message: err.message });
  }
});

// POST /api/admin/sous-admins — Créer
router.post('/', requireSuperAdmin, async (req, res) => {
  try {
    const {
      nom, email, mot_de_passe, role_id
    } = req.body;

    if (!nom || !email || !mot_de_passe) {
      return res.status(400).json({
        success: false,
        message: 'Nom, email et mot de passe requis'
      });
    }

    // Vérifier email unique
    const { data: existant } = await supabase
      .from('administrateurs')
      .select('id')
      .eq('email', email)
      .single();

    if (existant) {
      return res.status(400).json({
        success: false,
        message: 'Cet email est déjà utilisé'
      });
    }

    // Hasher le mot de passe
    const hash = await bcrypt.hash(mot_de_passe, 12);

    // Créer l'admin
    const { data, error } = await supabase
      .from('administrateurs')
      .insert({
        nom,
        email:          email.toLowerCase().trim(),
        mot_de_passe:   hash,
        role_id:        role_id || null,
        est_super_admin: false,
        est_actif:      true,
        cree_par:       req.user.id,
      })
      .select()
      .single();

    if (error) throw error;

    console.log('[sousAdmin] ✅ Créé:',
      email, '| Rôle:', role_id);

    return res.status(201).json({
      success: true,
      data,
      message: `Compte créé pour ${nom} ✅`
    });

  } catch (err) {
    res.status(500).json({
      success: false, message: err.message });
  }
});

// PUT /api/admin/sous-admins/:id — Modifier
router.put('/:id', requireSuperAdmin, async (req, res) => {
  try {
    const {
      nom, role_id, est_actif, nouveau_mdp
    } = req.body;

    const updates = {};
    if (nom      !== undefined) updates.nom      = nom;
    if (role_id  !== undefined) updates.role_id  = role_id;
    if (est_actif !== undefined) updates.est_actif = est_actif;
    if (nouveau_mdp) {
      updates.mot_de_passe =
        await bcrypt.hash(nouveau_mdp, 12);
    }

    const { data, error } = await supabase
      .from('administrateurs')
      .update(updates)
      .eq('id', req.params.id)
      .neq('est_super_admin', true) // Protection
      .select()
      .single();

    if (error) throw error;

    // Invalider le cache de cet admin
    invaliderCacheAdmin(req.params.id);

    return res.json({
      success: true, data,
      message: 'Compte mis à jour ✅'
    });
  } catch (err) {
    res.status(500).json({
      success: false, message: err.message });
  }
});

// DELETE /api/admin/sous-admins/:id — Désactiver
router.delete('/:id', requireSuperAdmin,
  async (req, res) => {
  try {
    // Désactiver (pas supprimer) pour garder l'historique
    await supabase
      .from('administrateurs')
      .update({ est_actif: false })
      .eq('id', req.params.id)
      .neq('est_super_admin', true);

    invaliderCacheAdmin(req.params.id);

    return res.json({
      success: true,
      message: 'Compte désactivé ✅'
    });
  } catch (err) {
    res.status(500).json({
      success: false, message: err.message });
  }
});

// GET /api/admin/sous-admins/roles — Lister les rôles
router.get('/roles', requireSuperAdmin,
  async (req, res) => {
  try {
    const { data } = await supabase
      .from('admin_roles')
      .select(`
        id, nom, description, couleur, icone,
        permissions:admin_permissions(
          section, peut_voir,
          peut_modifier, peut_supprimer
        )
      `)
      .eq('est_actif', true)
      .order('nom');

    return res.json({ success: true, data: data || [] });
  } catch (err) {
    res.status(500).json({
      success: false, message: err.message });
  }
});

// PUT /api/admin/roles/:id/permissions — Modifier permissions
router.put('/roles/:id/permissions',
  requireSuperAdmin, async (req, res) => {
  try {
    const { permissions } = req.body;
    // permissions = [{ section, peut_voir, peut_modifier, peut_supprimer }]

    for (const perm of permissions) {
      await supabase
        .from('admin_permissions')
        .upsert({
          role_id:       req.params.id,
          section:       perm.section,
          peut_voir:     perm.peut_voir     || false,
          peut_modifier: perm.peut_modifier || false,
          peut_supprimer: perm.peut_supprimer || false,
        }, { onConflict: 'role_id,section' });
    }

    // Invalider cache de tous les admins avec ce rôle
    const { data: admins } = await supabase
      .from('administrateurs')
      .select('id')
      .eq('role_id', req.params.id);

    (admins || []).forEach(a =>
      invaliderCacheAdmin(a.id));

    return res.json({
      success: true,
      message: 'Permissions mises à jour ✅'
    });
  } catch (err) {
    res.status(500).json({
      success: false, message: err.message });
  }
});

// GET /api/admin/mes-permissions — Pour le front
router.get('/mes-permissions', async (req, res) => {
  try {
    const { getPermissionsAdmin } =
      require('../../middleware/adminPermissions');
    const perms = await getPermissionsAdmin(req.user.id);
    return res.json({ success: true, data: perms });
  } catch (err) {
    res.status(500).json({
      success: false, message: err.message });
  }
});

module.exports = router;
```

---

## 4. Flutter — Page gestion sous-admins

```dart
// frontend/lib/screens/admin/pages/sous_admins_page.dart

class SousAdminsPage extends StatefulWidget {
  const SousAdminsPage({super.key});
  @override
  State<SousAdminsPage> createState() =>
    _SousAdminsPageState();
}

class _SousAdminsPageState extends State<SousAdminsPage>
    with SingleTickerProviderStateMixin {

  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _roles  = [];
  bool _isLoading = true;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  Widget build(BuildContext context) => Column(children: [

    // Header
    Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(children: [
        Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text('👥 Gestion des accès admin',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800)),
            Text(
              'Créez des comptes avec des permissions limitées',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B))),
          ])),
          ElevatedButton.icon(
            icon: const Icon(
              Icons.person_add_rounded, size: 16),
            label: const Text('Nouveau compte'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A56DB),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
            onPressed: () => _showDialogCreer()),
        ]),
        const SizedBox(height: 16),
        TabBar(
          controller: _tabCtrl,
          labelColor: const Color(0xFF1A56DB),
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: const Color(0xFF1A56DB),
          tabs: const [
            Tab(text: 'Comptes admins'),
            Tab(text: 'Rôles & Permissions'),
          ]),
      ])),

    // Contenu
    Expanded(child: TabBarView(
      controller: _tabCtrl,
      children: [
        _buildListeAdmins(),
        _buildListeRoles(),
      ])),
  ]);

  // ── Liste des admins ─────────────────────────────────
  Widget _buildListeAdmins() => _isLoading
      ? const Center(child: CircularProgressIndicator(
          color: Color(0xFF1A56DB)))
      : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _admins.length,
          itemBuilder: (ctx, i) {
            final admin = _admins[i];
            final role  = admin['role']
                as Map<String, dynamic>?;
            final actif = admin['est_actif'] as bool? ?? true;
            final superAdmin =
              admin['est_super_admin'] as bool? ?? false;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: actif
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFFFEF2F2)),
                boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2))]),
              child: Row(children: [

                // Avatar
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: superAdmin
                        ? const Color(0xFFEF4444)
                            .withOpacity(0.1)
                        : const Color(0xFF1A56DB)
                            .withOpacity(0.1),
                    shape: BoxShape.circle),
                  child: Center(child: Text(
                    (admin['nom'] as String? ?? 'A')[0]
                      .toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: superAdmin
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF1A56DB))))),
                const SizedBox(width: 12),

                // Infos
                Expanded(child: Column(
                  crossAxisAlignment:
                    CrossAxisAlignment.start,
                  children: [
                  Row(children: [
                    Text(admin['nom'] as String? ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A))),
                    if (superAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius:
                            BorderRadius.circular(100)),
                        child: Text('Super Admin',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white))),
                    ],
                  ]),
                  Text(admin['email'] as String? ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B))),
                  if (role != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Color(int.parse(
                          (role['couleur'] as String?
                            ?? '#1A56DB')
                            .replaceFirst('#', '0xFF')))
                              .withOpacity(0.1),
                        borderRadius:
                          BorderRadius.circular(100)),
                      child: Text(
                        role['nom'] as String? ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(int.parse(
                            (role['couleur'] as String?
                              ?? '#1A56DB')
                              .replaceFirst('#', '0xFF')))))),
                  ],
                ])),

                // Statut + Actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: actif
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFEF2F2),
                      borderRadius:
                        BorderRadius.circular(100)),
                    child: Text(
                      actif ? 'Actif' : 'Désactivé',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: actif
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444)))),
                  if (!superAdmin) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_rounded, size: 16),
                        color: const Color(0xFF1A56DB),
                        padding: EdgeInsets.zero,
                        constraints:
                          const BoxConstraints(),
                        onPressed: () =>
                          _showDialogModifier(admin)),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(
                          actif
                              ? Icons.block_rounded
                              : Icons.check_circle_outline,
                          size: 16),
                        color: actif
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                        padding: EdgeInsets.zero,
                        constraints:
                          const BoxConstraints(),
                        onPressed: () =>
                          _toggleActif(admin)),
                    ]),
                  ],
                ]),
              ]));
          });

  // ── Liste des rôles ──────────────────────────────────
  Widget _buildListeRoles() => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: _roles.length,
    itemBuilder: (ctx, i) {
      final role  = _roles[i];
      final perms = List<Map<String, dynamic>>.from(
        role['permissions'] ?? []);
      final couleur = Color(int.parse(
        (role['couleur'] as String? ?? '#1A56DB')
          .replaceFirst('#', '0xFF')));

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE2E8F0))),
        child: ExpansionTile(
          leading: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: couleur.withOpacity(0.1),
              shape: BoxShape.circle),
            child: Icon(Icons.admin_panel_settings_rounded,
              color: couleur, size: 18)),
          title: Text(role['nom'] as String? ?? '',
            style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w700)),
          subtitle: Text(
            role['description'] as String? ?? '',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF94A3B8))),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text('Permissions :',
                  style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: const Color(0xFF374151))),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6,
                  children: perms.map((p) {
                    final actions = <String>[];
                    if (p['peut_voir'] == true)
                      actions.add('Voir');
                    if (p['peut_modifier'] == true)
                      actions.add('Modifier');
                    if (p['peut_supprimer'] == true)
                      actions.add('Supprimer');
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: couleur.withOpacity(0.08),
                        borderRadius:
                          BorderRadius.circular(6)),
                      child: Text(
                        '${p['section']} : '
                        '${actions.join(' · ')}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: couleur)));
                  }).toList()),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit_rounded,
                      size: 14),
                    label: const Text(
                      'Modifier les permissions'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: couleur),
                      foregroundColor: couleur,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                          BorderRadius.circular(8))),
                    onPressed: () =>
                      _showDialogPermissions(role))),
              ])),
          ]));
    });

  // ── Dialog créer admin ───────────────────────────────
  void _showDialogCreer() => showDialog(
    context: context,
    builder: (ctx) => _DialogCreerAdmin(
      roles: _roles,
      onSaved: () {
        Navigator.pop(ctx);
        _loadData();
      }));

  // ── Dialog modifier admin ────────────────────────────
  void _showDialogModifier(Map<String, dynamic> admin) =>
    showDialog(
      context: context,
      builder: (ctx) => _DialogModifierAdmin(
        admin: admin,
        roles: _roles,
        onSaved: () {
          Navigator.pop(ctx);
          _loadData();
        }));

  // ── Dialog permissions rôle ──────────────────────────
  void _showDialogPermissions(Map<String, dynamic> role) =>
    showDialog(
      context: context,
      builder: (ctx) => _DialogPermissionsRole(
        role: role,
        onSaved: () {
          Navigator.pop(ctx);
          _loadData();
        }));

  Future<void> _toggleActif(
      Map<String, dynamic> admin) async {
    final actif = admin['est_actif'] as bool? ?? true;
    final token = context.read<AuthProvider>().token ?? '';
    await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/admin'
        '/sous-admins/${admin['id']}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'est_actif': !actif}));
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final headers = {'Authorization': 'Bearer $token'};

      final results = await Future.wait([
        http.get(Uri.parse(
          '${ApiConfig.baseUrl}/api/admin/sous-admins'),
          headers: headers),
        http.get(Uri.parse(
          '${ApiConfig.baseUrl}/api/admin/sous-admins/roles'),
          headers: headers),
      ]);

      final admins = jsonDecode(results[0].body);
      final roles  = jsonDecode(results[1].body);

      setState(() {
        _admins = List<Map<String, dynamic>>.from(
          admins['data'] ?? []);
        _roles  = List<Map<String, dynamic>>.from(
          roles['data'] ?? []);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }
}

// ── Dialog Créer Admin ───────────────────────────────────
class _DialogCreerAdmin extends StatefulWidget {
  final List<Map<String, dynamic>> roles;
  final VoidCallback onSaved;
  const _DialogCreerAdmin({
    required this.roles, required this.onSaved});
  @override
  State<_DialogCreerAdmin> createState() =>
    _DialogCreerAdminState();
}

class _DialogCreerAdminState extends State<_DialogCreerAdmin> {
  final _nomCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mdpCtrl   = TextEditingController();
  String? _roleId;
  bool    _isSaving = false;
  bool    _mdpVisible = false;

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16)),
    child: Container(
      width: 460,
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Header
        Row(children: [
          const Icon(Icons.person_add_rounded,
            color: Color(0xFF1A56DB), size: 22),
          const SizedBox(width: 10),
          Text('Créer un compte admin',
            style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w800)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context)),
        ]),
        const SizedBox(height: 20),

        // Champs
        _ChampDialogAdmin(_nomCtrl,
          'Nom complet *', 'Ex: Fatoumata Diallo',
          Icons.person_outline_rounded),
        const SizedBox(height: 12),
        _ChampDialogAdmin(_emailCtrl,
          'Email *', 'admin@emploiconnect.gn',
          Icons.email_outlined,
          keyType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        _ChampDialogAdmin(_mdpCtrl,
          'Mot de passe *', 'Minimum 8 caractères',
          Icons.lock_outline_rounded,
          obscure: !_mdpVisible,
          suffix: IconButton(
            icon: Icon(_mdpVisible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
              size: 16),
            onPressed: () =>
              setState(() => _mdpVisible = !_mdpVisible))),
        const SizedBox(height: 12),

        // Rôle
        Text('Rôle & Permissions *',
          style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: const Color(0xFF374151))),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _roleId,
          hint: Text('Sélectionner un rôle',
            style: GoogleFonts.inter(fontSize: 12)),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0)))),
          items: widget.roles.map((r) =>
            DropdownMenuItem<String>(
              value: r['id'] as String,
              child: Row(children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: Color(int.parse(
                      (r['couleur'] as String? ?? '#1A56DB')
                        .replaceFirst('#', '0xFF'))),
                    shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(r['nom'] as String? ?? '',
                  style: GoogleFonts.inter(fontSize: 13)),
              ]))).toList(),
          onChanged: (v) =>
            setState(() => _roleId = v)),
        const SizedBox(height: 20),

        // Boutons
        Row(children: [
          Expanded(child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(
                vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler',
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B))))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton.icon(
            icon: _isSaving
                ? const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                : const Icon(
                    Icons.check_rounded, size: 16),
            label: Text(
              _isSaving ? 'Création...' : 'Créer le compte',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A56DB),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
            onPressed: _isSaving ? null : _creer)),
        ]),
      ]));

  Future<void> _creer() async {
    if (_nomCtrl.text.isEmpty || _emailCtrl.text.isEmpty
        || _mdpCtrl.text.isEmpty || _roleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tous les champs sont requis'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/admin/sous-admins'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nom':         _nomCtrl.text.trim(),
          'email':       _emailCtrl.text.trim(),
          'mot_de_passe': _mdpCtrl.text,
          'role_id':     _roleId,
        }));

      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['message'] ?? '✅ Créé !'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating));
        widget.onSaved();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(body['message'] ?? 'Erreur'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur: $e'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

Widget _ChampDialogAdmin(
  TextEditingController ctrl,
  String label, String hint, IconData icone, {
  bool obscure = false,
  Widget? suffix,
  TextInputType? keyType,
}) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Text(label, style: GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w600,
    color: const Color(0xFF374151))),
  const SizedBox(height: 6),
  TextFormField(
    controller: ctrl,
    obscureText: obscure,
    keyboardType: keyType,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 12, color: const Color(0xFFCBD5E1)),
      prefixIcon: Icon(icone, size: 16,
        color: const Color(0xFF94A3B8)),
      suffixIcon: suffix,
      filled: true, fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0))))),
]);
```

---

## 5. Flutter — Sidebar adaptée aux permissions

```dart
// Dans admin_sidebar.dart
// Charger les permissions et cacher les sections non autorisées

class AdminSidebar extends StatefulWidget {
  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> {
  Map<String, dynamic> _permissions = {};
  bool _estSuperAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/admin'
          '/sous-admins/mes-permissions'),
        headers: {'Authorization': 'Bearer $token'});
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        setState(() {
          _estSuperAdmin =
            body['data']['est_super_admin'] as bool? ?? false;
          _permissions = Map<String, dynamic>.from(
            body['data']['permissions'] ?? {});
        });
      }
    } catch (_) {
      // Par défaut : tout visible
      setState(() => _estSuperAdmin = true);
    }
  }

  bool _peutVoir(String section) {
    if (_estSuperAdmin) return true;
    return (_permissions[section]
        as Map?)?['peut_voir'] == true;
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    // ... header existant ...

    // Masquer les items selon les permissions
    if (_peutVoir('dashboard'))
      _SidebarItem(titre: 'Dashboard', ...),
    if (_peutVoir('utilisateurs'))
      _SidebarItem(titre: 'Utilisateurs', ...),
    if (_peutVoir('offres'))
      _SidebarItem(titre: 'Offres d\'emploi', ...),
    if (_peutVoir('entreprises'))
      _SidebarItem(titre: 'Entreprises', ...),
    if (_peutVoir('candidatures'))
      _SidebarItem(titre: 'Candidatures', ...),
    if (_peutVoir('messages'))
      _SidebarItem(titre: 'Messages', ...),
    if (_peutVoir('bannieres'))
      _SidebarItem(titre: 'Bannières', ...),
    if (_peutVoir('newsletter'))
      _SidebarItem(titre: 'Newsletter', ...),

    // Paramètres = Super Admin uniquement
    if (_estSuperAdmin)
      _SidebarItem(titre: 'Paramètres', ...),

    // Sous-admins = Super Admin uniquement
    if (_estSuperAdmin)
      _SidebarItem(titre: 'Gestion accès', ...),
  ]);
}
```

---

## 6. Ajouter la route dans index.js

```javascript
// backend/src/routes/admin/index.js
const sousAdminsRoutes =
  require('./sousAdmins.routes');
router.use('/sous-admins', auth, requireAdmin,
  sousAdminsRoutes);
```

---

## Ajouter dans admin_shell_screen.dart

```dart
// Ajouter la route :
GoRoute(
  path: '/admin/acces',
  builder: (_, __) => const SousAdminsPage()),
```

---

## Critères d'Acceptation

- [ ] Super admin peut créer un compte sous-admin
- [ ] Assigner un rôle avec permissions limitées
- [ ] Sous-admin voit seulement ses sections
- [ ] Super admin peut modifier/désactiver un compte
- [ ] Super admin peut modifier les permissions d'un rôle
- [ ] Paramètres = Super Admin uniquement
- [ ] Cache permissions 5 minutes
- [ ] Protection contre modification des Super Admins

---

*PRD EmploiConnect v9.8 — Rôles & Permissions Admin*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
