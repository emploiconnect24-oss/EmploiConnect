# PRD — EmploiConnect · Corrections & Complétion Module Admin
## Product Requirements Document v3.1 — Admin Fix & Complete
**Stack : Flutter + Node.js/Express + PostgreSQL/Supabase**
**Outil : Cursor / Kirsoft AI**
**Objectif : Corriger et compléter TOUTES les options manquantes Admin**
**Statut : Phase 7.1 — Révision générale Admin**
**Date : Mars 2026**

---

> ### ⚠️ INSTRUCTIONS CRITIQUES POUR CURSOR
>
> Ce PRD est une **révision générale complète** du module Admin.
> Il corrige les bugs et ajoute les options manquantes identifiées lors des tests.
> Implémenter **strictement dans l'ordre** des sections.
> Chaque section = une tâche précise avec son code complet.

---

## Problèmes Identifiés (à corriger tous)

```
❌ 1. Offres : "Enlever en vedette" manquant quand déjà en vedette
❌ 2. Offres : "Désarchiver" manquant quand déjà archivée
❌ 3. Entreprises : "Débloquer/Enlever suspension" manquant
❌ 4. Utilisateurs : "Débloquer" manquant quand déjà bloqué
❌ 5. Utilisateurs : "Voir le profil" ne fonctionne pas
❌ 6. Profil Admin : page vide au clic sur "Mon profil"
❌ 7. Profil Admin : photo de profil non modifiable
❌ 8. Overflow pixels sur mobile (RenderFlex overflow)
❌ 9. Actions contextuelles non adaptées selon l'état actuel
❌ 10. Backend : routes manquantes pour certaines actions
```

---

## Table des Matières

1. [Corrections Backend — Nouvelles Routes](#1-corrections-backend--nouvelles-routes)
2. [Fix Gestion Offres — Actions Contextuelles](#2-fix-gestion-offres--actions-contextuelles)
3. [Fix Gestion Utilisateurs — Actions Complètes](#3-fix-gestion-utilisateurs--actions-complètes)
4. [Fix Gestion Entreprises — Actions Complètes](#4-fix-gestion-entreprises--actions-complètes)
5. [Page Profil Administrateur](#5-page-profil-administrateur)
6. [Corrections Overflow Mobile](#6-corrections-overflow-mobile)
7. [Widget ActionMenu Intelligent](#7-widget-actionmenu-intelligent)
8. [Mise à jour AdminService Flutter](#8-mise-à-jour-adminservice-flutter)
9. [Critères d'Acceptation](#9-critères-dacceptation)

---

## 1. Corrections Backend — Nouvelles Routes

### 1.1 Ajouter dans `backend/src/routes/admin/offres.routes.js`

```javascript
const express = require('express');
const router = express.Router();
const { auth } = require('../../middleware/auth');
const { requireAdmin } = require('../../middleware/adminAuth');
const { auditLog } = require('../../middleware/auditLog');
const ctrl = require('../../controllers/admin/offres.controller');

// Toutes les routes nécessitent auth + admin
router.use(auth, requireAdmin);

router.get('/',     ctrl.getOffres);
router.get('/:id',  ctrl.getOffreDetail);

// PATCH avec action contextuelle intelligente
router.patch('/:id',
  auditLog('ACTION_OFFRE', 'offre'),
  ctrl.updateOffre
);

router.delete('/:id',
  auditLog('SUPPRIMER_OFFRE', 'offre'),
  ctrl.deleteOffre
);

module.exports = router;
```

### 1.2 Mettre à jour `backend/src/controllers/admin/offres.controller.js`

```javascript
// AJOUTER cette fonction manquante : getOffreDetail
const getOffreDetail = async (req, res) => {
  try {
    const { id } = req.params;
    const { data: offre, error } = await supabase
      .from('offres_emploi')
      .select(`
        *,
        entreprise:entreprise_id (
          id, nom_entreprise, logo_url, secteur_activite,
          adresse_siege,
          utilisateur:utilisateur_id (
            id, nom, email, telephone, est_actif, est_valide
          )
        )
      `)
      .eq('id', id)
      .single();

    if (error || !offre) {
      return res.status(404).json({
        success: false, message: 'Offre non trouvée'
      });
    }

    // Nombre de candidatures
    const { count: nbCandidatures } = await supabase
      .from('candidatures')
      .select('id', { count: 'exact' })
      .eq('offre_id', id);

    return res.json({
      success: true,
      data: { ...offre, nb_candidatures: nbCandidatures || 0 }
    });
  } catch (err) {
    console.error('[getOffreDetail]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// METTRE À JOUR updateOffre — logique contextuelle complète
const updateOffre = async (req, res) => {
  try {
    const { id } = req.params;
    const { action, raison_refus } = req.body;

    // Récupérer l'état actuel de l'offre
    const { data: offreActuelle, error: fetchErr } = await supabase
      .from('offres_emploi')
      .select('id, statut, en_vedette, titre')
      .eq('id', id)
      .single();

    if (fetchErr || !offreActuelle) {
      return res.status(404).json({
        success: false, message: 'Offre non trouvée'
      });
    }

    let updateData = {
      date_modification: new Date().toISOString()
    };
    let messageReponse = '';

    switch (action) {

      // ── VALIDATION ──────────────────────────────────────────
      case 'valider':
        updateData.statut = 'publiee';
        updateData.valide_par = req.user.id;
        updateData.date_validation = new Date().toISOString();
        updateData.date_publication = new Date().toISOString();
        updateData.raison_refus = null;
        // Calculer date limite selon paramètre plateforme
        const { data: param } = await supabase
          .from('parametres_plateforme')
          .select('valeur')
          .eq('cle', 'duree_validite_offre_jours')
          .single();
        const nbJours = parseInt(param?.valeur || '30');
        const dateLimite = new Date();
        dateLimite.setDate(dateLimite.getDate() + nbJours);
        updateData.date_limite = dateLimite.toISOString();
        messageReponse = 'Offre validée et publiée avec succès';
        break;

      // ── REFUS ───────────────────────────────────────────────
      case 'refuser':
        if (!raison_refus) {
          return res.status(400).json({
            success: false,
            message: 'Un motif de refus est obligatoire'
          });
        }
        updateData.statut = 'refusee';
        updateData.raison_refus = raison_refus;
        messageReponse = 'Offre refusée';
        break;

      // ── VEDETTE : toggle intelligent ────────────────────────
      case 'mettre_en_vedette':
        updateData.en_vedette = true;
        messageReponse = 'Offre mise en vedette';
        break;

      case 'retirer_vedette':
        updateData.en_vedette = false;
        messageReponse = 'Offre retirée de la vedette';
        break;

      // ── ARCHIVAGE : toggle intelligent ──────────────────────
      case 'archiver':
        updateData.statut = 'expiree';
        messageReponse = 'Offre archivée';
        break;

      case 'desarchiver':
        // Restaurer en publiée si elle était archivée
        updateData.statut = 'publiee';
        updateData.date_publication = new Date().toISOString();
        messageReponse = 'Offre restaurée et publiée';
        break;

      case 'republier':
        updateData.statut = 'publiee';
        updateData.date_publication = new Date().toISOString();
        messageReponse = 'Offre republiée avec succès';
        break;

      default:
        return res.status(400).json({
          success: false,
          message: `Action '${action}' invalide. Actions: valider, refuser, mettre_en_vedette, retirer_vedette, archiver, desarchiver, republier`
        });
    }

    const { data, error } = await supabase
      .from('offres_emploi')
      .update(updateData)
      .eq('id', id)
      .select('id, titre, statut, en_vedette, raison_refus')
      .single();

    if (error) throw error;

    return res.json({
      success: true,
      message: messageReponse,
      data
    });
  } catch (err) {
    console.error('[admin/updateOffre]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
```

### 1.3 Mettre à jour `backend/src/controllers/admin/users.controller.js`

```javascript
// COMPLÉTER updateUtilisateur avec toutes les actions
const updateUtilisateur = async (req, res) => {
  try {
    const { id } = req.params;
    const { action, raison } = req.body;

    // Empêcher modification de soi-même pour certaines actions
    if (['bloquer', 'supprimer'].includes(action) && id === req.user.id) {
      return res.status(400).json({
        success: false,
        message: 'Vous ne pouvez pas effectuer cette action sur votre propre compte'
      });
    }

    // Récupérer état actuel
    const { data: userActuel } = await supabase
      .from('utilisateurs')
      .select('id, nom, est_actif, est_valide, role')
      .eq('id', id)
      .single();

    if (!userActuel) {
      return res.status(404).json({
        success: false, message: 'Utilisateur non trouvé'
      });
    }

    let updateData = { date_modification: new Date().toISOString() };
    let messageReponse = '';

    switch (action) {
      case 'valider':
        updateData.est_valide = true;
        updateData.est_actif  = true;
        updateData.traite_par = req.user.id;
        messageReponse = `Compte de ${userActuel.nom} validé`;
        break;

      case 'activer':
        updateData.est_actif      = true;
        updateData.raison_blocage = null;
        updateData.traite_par     = req.user.id;
        messageReponse = `Compte de ${userActuel.nom} activé`;
        break;

      // ── BLOQUER ─────────────────────────────────────────────
      case 'bloquer':
        if (!raison) {
          return res.status(400).json({
            success: false,
            message: 'Une raison est obligatoire pour bloquer un compte'
          });
        }
        updateData.est_actif      = false;
        updateData.raison_blocage = raison;
        updateData.traite_par     = req.user.id;
        messageReponse = `Compte de ${userActuel.nom} bloqué`;
        break;

      // ── DÉBLOQUER ────────────────────────────────────────────
      case 'debloquer':
        updateData.est_actif      = true;
        updateData.raison_blocage = null;
        updateData.traite_par     = req.user.id;
        messageReponse = `Compte de ${userActuel.nom} débloqué`;
        break;

      // ── REJETER (refuser la validation) ─────────────────────
      case 'rejeter':
        updateData.est_valide     = false;
        updateData.est_actif      = false;
        updateData.raison_blocage = raison || 'Compte rejeté par l\'administrateur';
        messageReponse = `Compte de ${userActuel.nom} rejeté`;
        break;

      default:
        return res.status(400).json({
          success: false,
          message: 'Action invalide. Valeurs: valider, activer, bloquer, debloquer, rejeter'
        });
    }

    const { data, error } = await supabase
      .from('utilisateurs')
      .update(updateData)
      .eq('id', id)
      .select('id, nom, email, role, est_actif, est_valide, raison_blocage')
      .single();

    if (error) throw error;

    return res.json({
      success: true,
      message: messageReponse,
      data
    });
  } catch (err) {
    console.error('[updateUtilisateur]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
```

### 1.4 Mettre à jour `backend/src/controllers/admin/entreprises.controller.js`

```javascript
// COMPLÉTER updateEntreprise avec toutes les actions
const updateEntreprise = async (req, res) => {
  try {
    const { id } = req.params; // utilisateur_id
    const { action, raison } = req.body;

    // Vérifier l'état actuel
    const { data: userActuel } = await supabase
      .from('utilisateurs')
      .select('id, nom, est_actif, est_valide')
      .eq('id', id)
      .single();

    if (!userActuel) {
      return res.status(404).json({
        success: false, message: 'Entreprise non trouvée'
      });
    }

    let updateData = {};
    let messageReponse = '';

    switch (action) {
      case 'valider':
        updateData = {
          est_valide: true, est_actif: true,
          traite_par: req.user.id,
          raison_blocage: null
        };
        messageReponse = `Entreprise ${userActuel.nom} validée`;
        break;

      case 'suspendre':
        if (!raison) {
          return res.status(400).json({
            success: false,
            message: 'Une raison est obligatoire pour suspendre'
          });
        }
        updateData = {
          est_actif: false,
          raison_blocage: raison
        };
        messageReponse = `Entreprise ${userActuel.nom} suspendue`;
        break;

      // ── LEVER LA SUSPENSION ──────────────────────────────────
      case 'lever_suspension':
        updateData = {
          est_actif: true,
          raison_blocage: null
        };
        messageReponse = `Suspension levée pour ${userActuel.nom}`;
        break;

      case 'rejeter':
        updateData = {
          est_valide: false, est_actif: false,
          raison_blocage: raison || 'Dossier incomplet'
        };
        messageReponse = `Entreprise ${userActuel.nom} rejetée`;
        break;

      default:
        return res.status(400).json({
          success: false,
          message: 'Action invalide. Valeurs: valider, suspendre, lever_suspension, rejeter'
        });
    }

    updateData.date_modification = new Date().toISOString();

    const { data, error } = await supabase
      .from('utilisateurs')
      .update(updateData)
      .eq('id', id)
      .select('id, nom, email, est_actif, est_valide, raison_blocage')
      .single();

    if (error) throw error;

    return res.json({
      success: true,
      message: messageReponse,
      data
    });
  } catch (err) {
    console.error('[updateEntreprise]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
```

### 1.5 Ajouter Route Profil Admin

```javascript
// backend/src/routes/admin/profil.routes.js
const express = require('express');
const router = express.Router();
const { auth } = require('../../middleware/auth');
const { requireAdmin } = require('../../middleware/adminAuth');
const ctrl = require('../../controllers/admin/profil.controller');

router.use(auth, requireAdmin);

router.get('/',       ctrl.getProfilAdmin);
router.patch('/',     ctrl.updateProfilAdmin);
router.post('/photo', ctrl.uploadPhotoAdmin);

module.exports = router;
```

### 1.6 Créer `backend/src/controllers/admin/profil.controller.js`

```javascript
const { supabase } = require('../../config/supabase');
const bcrypt = require('bcryptjs');
const path = require('path');

// GET /api/admin/profil
const getProfilAdmin = async (req, res) => {
  try {
    const { data: user, error } = await supabase
      .from('utilisateurs')
      .select(`
        id, nom, email, telephone, adresse, photo_url,
        date_creation, derniere_connexion,
        admin:administrateurs (niveau_acces)
      `)
      .eq('id', req.user.id)
      .single();

    if (error || !user) {
      return res.status(404).json({
        success: false, message: 'Profil non trouvé'
      });
    }

    // Ne jamais retourner le mot de passe
    return res.json({ success: true, data: user });
  } catch (err) {
    console.error('[getProfilAdmin]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// PATCH /api/admin/profil
const updateProfilAdmin = async (req, res) => {
  try {
    const { nom, telephone, adresse, ancien_mdp, nouveau_mdp } = req.body;

    const updateData = { date_modification: new Date().toISOString() };
    if (nom)       updateData.nom       = nom;
    if (telephone) updateData.telephone = telephone;
    if (adresse)   updateData.adresse   = adresse;

    // Changement de mot de passe
    if (nouveau_mdp) {
      if (!ancien_mdp) {
        return res.status(400).json({
          success: false,
          message: 'Ancien mot de passe requis'
        });
      }

      // Vérifier ancien mot de passe
      const { data: userAvecMdp } = await supabase
        .from('utilisateurs')
        .select('mot_de_passe')
        .eq('id', req.user.id)
        .single();

      const mdpValide = await bcrypt.compare(
        ancien_mdp, userAvecMdp.mot_de_passe
      );

      if (!mdpValide) {
        return res.status(400).json({
          success: false,
          message: 'Ancien mot de passe incorrect'
        });
      }

      if (nouveau_mdp.length < 8) {
        return res.status(400).json({
          success: false,
          message: 'Le nouveau mot de passe doit contenir au moins 8 caractères'
        });
      }

      updateData.mot_de_passe = await bcrypt.hash(nouveau_mdp, 10);
    }

    const { data, error } = await supabase
      .from('utilisateurs')
      .update(updateData)
      .eq('id', req.user.id)
      .select('id, nom, email, telephone, adresse, photo_url')
      .single();

    if (error) throw error;

    return res.json({
      success: true,
      message: 'Profil mis à jour avec succès',
      data
    });
  } catch (err) {
    console.error('[updateProfilAdmin]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// POST /api/admin/profil/photo
// Upload photo de profil admin
const uploadPhotoAdmin = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false, message: 'Aucun fichier fourni'
      });
    }

    const ext = path.extname(req.file.originalname).toLowerCase();
    const allowed = ['.jpg', '.jpeg', '.png', '.webp'];
    if (!allowed.includes(ext)) {
      return res.status(400).json({
        success: false,
        message: 'Format invalide. Acceptés: JPG, PNG, WEBP'
      });
    }

    // Upload dans Supabase Storage
    const fileName = `admin-${req.user.id}-${Date.now()}${ext}`;
    const bucket = process.env.SUPABASE_STORAGE_BUCKET || 'cv-files';

    const { data: uploadData, error: uploadError } = await supabase.storage
      .from(bucket)
      .upload(`photos/${fileName}`, req.file.buffer, {
        contentType: req.file.mimetype,
        upsert: true,
      });

    if (uploadError) throw uploadError;

    // URL publique
    const { data: urlData } = supabase.storage
      .from(bucket)
      .getPublicUrl(`photos/${fileName}`);

    const photoUrl = urlData.publicUrl;

    // Mettre à jour l'utilisateur
    await supabase
      .from('utilisateurs')
      .update({ photo_url: photoUrl })
      .eq('id', req.user.id);

    return res.json({
      success: true,
      message: 'Photo mise à jour avec succès',
      data: { photo_url: photoUrl }
    });
  } catch (err) {
    console.error('[uploadPhotoAdmin]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

module.exports = { getProfilAdmin, updateProfilAdmin, uploadPhotoAdmin };
```

### 1.7 Mettre à jour `backend/src/routes/admin/index.js`

```javascript
// Ajouter les nouvelles routes
const express = require('express');
const router = express.Router();

router.use('/dashboard',    require('./dashboard.routes'));
router.use('/utilisateurs', require('./users.routes'));
router.use('/offres',       require('./offres.routes'));
router.use('/entreprises',  require('./entreprises.routes'));
router.use('/candidatures', require('./candidatures.routes'));
router.use('/signalements', require('./signalements.routes'));
router.use('/notifications',require('./notifications.routes'));
router.use('/parametres',   require('./parametres.routes'));
router.use('/profil',       require('./profil.routes')); // NOUVEAU

module.exports = router;
```

---

## 2. Fix Gestion Offres — Actions Contextuelles

### `frontend/lib/screens/admin/widgets/offre_actions_menu.dart`

```dart
// Widget ActionMenu INTELLIGENT pour les offres
// Les actions affichées dépendent du statut ACTUEL de l'offre

class OffreActionsMenu extends StatelessWidget {
  final Map<String, dynamic> offre;
  final VoidCallback onRefresh;

  const OffreActionsMenu({
    super.key, required this.offre, required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final statut    = offre['statut'] as String? ?? '';
    final enVedette = offre['en_vedette'] as bool? ?? false;
    final adminSvc  = AdminService();

    // ── Construire la liste d'actions selon l'état ──────────
    final List<_AdminAction> actions = [];

    // Voir le détail — toujours disponible
    actions.add(_AdminAction(
      icon: Icons.visibility_outlined,
      label: 'Voir les détails',
      color: const Color(0xFF64748B),
      onTap: () => context.push('/admin/offres/${offre['id']}'),
    ));

    // Actions selon statut
    if (statut == 'en_attente') {
      actions.add(_AdminAction(
        icon: Icons.check_circle_outline,
        label: 'Valider et publier',
        color: const Color(0xFF10B981),
        onTap: () => _doAction(context, adminSvc, 'valider'),
      ));
      actions.add(_AdminAction(
        icon: Icons.cancel_outlined,
        label: 'Refuser',
        color: const Color(0xFFEF4444),
        onTap: () => _showRefuserDialog(context, adminSvc),
      ));
    }

    if (statut == 'publiee') {
      // Vedette : toggle intelligent
      if (enVedette) {
        actions.add(_AdminAction(
          icon: Icons.star_border_outlined,
          label: 'Retirer de la vedette',
          color: const Color(0xFFF59E0B),
          onTap: () => _doAction(context, adminSvc, 'retirer_vedette'),
        ));
      } else {
        actions.add(_AdminAction(
          icon: Icons.star_outlined,
          label: 'Mettre en vedette',
          color: const Color(0xFFF59E0B),
          onTap: () => _doAction(context, adminSvc, 'mettre_en_vedette'),
        ));
      }
      actions.add(_AdminAction(
        icon: Icons.archive_outlined,
        label: 'Archiver',
        color: const Color(0xFF94A3B8),
        onTap: () => _showConfirm(context, adminSvc,
          'Archiver cette offre ?',
          'L\'offre ne sera plus visible pour les candidats.',
          'Archiver', const Color(0xFF94A3B8), 'archiver'),
      ));
    }

    if (statut == 'refusee') {
      actions.add(_AdminAction(
        icon: Icons.refresh_outlined,
        label: 'Republier',
        color: const Color(0xFF10B981),
        onTap: () => _doAction(context, adminSvc, 'republier'),
      ));
    }

    if (statut == 'expiree') {
      // DÉSARCHIVER — option manquante ajoutée ici
      actions.add(_AdminAction(
        icon: Icons.unarchive_outlined,
        label: 'Désarchiver (republier)',
        color: const Color(0xFF1A56DB),
        onTap: () => _showConfirm(context, adminSvc,
          'Désarchiver cette offre ?',
          'L\'offre sera republiée et visible par les candidats.',
          'Désarchiver', const Color(0xFF1A56DB), 'desarchiver'),
      ));
    }

    // Supprimer — toujours en dernier avec séparateur
    actions.add(_AdminAction(
      icon: Icons.delete_outline,
      label: 'Supprimer définitivement',
      color: const Color(0xFFEF4444),
      isDanger: true,
      onTap: () => _showConfirm(context, adminSvc,
        'Supprimer cette offre ?',
        'Cette action est irréversible. Toutes les candidatures seront perdues.',
        'Supprimer', const Color(0xFFEF4444), 'supprimer',
        isDelete: true),
    ));

    return PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      elevation: 8,
      itemBuilder: (_) => actions.asMap().entries.map((e) {
        final i = e.key;
        final action = e.value;
        return PopupMenuItem<int>(
          value: i,
          child: Row(children: [
            Icon(action.icon, color: action.color, size: 18),
            const SizedBox(width: 10),
            Text(action.label, style: GoogleFonts.inter(
              fontSize: 14,
              color: action.color,
              fontWeight: action.isDanger
                  ? FontWeight.w600 : FontWeight.w400,
            )),
          ]),
        );
      }).toList(),
      onSelected: (i) => actions[i].onTap(),
    );
  }

  // Exécuter une action simple
  Future<void> _doAction(
    BuildContext context, AdminService svc, String action
  ) async {
    try {
      final token = context.read<AuthProvider>().token ?? '';
      await svc.updateOffre(token, offre['id'], action);
      onRefresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Action effectuée avec succès'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  // Dialog de refus avec champ motif
  void _showRefuserDialog(BuildContext context, AdminService svc) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Refuser cette offre', style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Précisez le motif du refus (obligatoire) :',
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
          const SizedBox(height: 12),
          TextFormField(
            controller: ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ex: Offre incomplète, informations manquantes...',
              filled: true, fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.inter(
              color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444), elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              final token = context.read<AuthProvider>().token ?? '';
              await svc.updateOffre(
                token, offre['id'], 'refuser',
                raisonRefus: ctrl.text.trim()
              );
              onRefresh();
            },
            child: Text('Refuser', style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // Dialog de confirmation générique
  void _showConfirm(
    BuildContext context, AdminService svc,
    String titre, String message, String btnLabel,
    Color btnColor, String action, {bool isDelete = false}
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(titre, style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text(message, style: GoogleFonts.inter(
          fontSize: 14, color: const Color(0xFF64748B))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: btnColor, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              if (isDelete) {
                final token = context.read<AuthProvider>().token ?? '';
                await AdminService().deleteOffre(token, offre['id']);
              } else {
                await _doAction(context, AdminService(), action);
              }
              onRefresh();
            },
            child: Text(btnLabel, style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _AdminAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDanger;
  const _AdminAction({
    required this.icon, required this.label,
    required this.color, required this.onTap,
    this.isDanger = false,
  });
}
```

---

## 3. Fix Gestion Utilisateurs — Actions Complètes

```dart
// Dans users_page.dart — remplacer le widget ActionMenu existant
// par ce widget intelligent qui adapte les actions selon l'état

class UserActionsMenu extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onRefresh;

  const UserActionsMenu({
    super.key, required this.user, required this.onRefresh,
  });

  bool get _estActif   => user['est_actif'] == true;
  bool get _estValide  => user['est_valide'] == true;
  bool get _estBloque  => _estValide && !_estActif;
  bool get _estAttente => !_estValide;

  @override
  Widget build(BuildContext context) {
    final List<_AdminAction> actions = [];

    // ── Voir profil — TOUJOURS disponible ───────────────────
    actions.add(_AdminAction(
      icon: Icons.person_outlined,
      label: 'Voir le profil complet',
      color: const Color(0xFF1A56DB),
      onTap: () => context.push('/admin/utilisateurs/${user['id']}'),
    ));

    // ── Actions selon état ────────────────────────────────
    if (_estAttente) {
      // En attente de validation
      actions.add(_AdminAction(
        icon: Icons.check_circle_outline,
        label: 'Valider le compte',
        color: const Color(0xFF10B981),
        onTap: () => _doAction(context, 'valider'),
      ));
      actions.add(_AdminAction(
        icon: Icons.cancel_outlined,
        label: 'Rejeter le compte',
        color: const Color(0xFFF59E0B),
        onTap: () => _showActionWithRaison(
          context, 'Rejeter ce compte ?',
          'Le compte sera refusé. L\'utilisateur ne pourra pas accéder à la plateforme.',
          'Rejeter', const Color(0xFFF59E0B), 'rejeter'
        ),
      ));
    }

    if (_estActif && _estValide) {
      // Compte actif → proposer blocage
      actions.add(_AdminAction(
        icon: Icons.block_outlined,
        label: 'Bloquer le compte',
        color: const Color(0xFFF59E0B),
        onTap: () => _showBloquerDialog(context),
      ));
    }

    if (_estBloque) {
      // Compte bloqué → proposer déblocage
      // ── OPTION MANQUANTE AJOUTÉE ICI ──
      actions.add(_AdminAction(
        icon: Icons.lock_open_outlined,
        label: 'Débloquer le compte',
        color: const Color(0xFF10B981),
        onTap: () => _showConfirm(
          context,
          'Débloquer ce compte ?',
          'L\'utilisateur retrouvera accès à la plateforme.',
          'Débloquer', const Color(0xFF10B981), 'debloquer',
        ),
      ));
    }

    // Raison du blocage (si bloqué)
    if (_estBloque && user['raison_blocage'] != null) {
      actions.add(_AdminAction(
        icon: Icons.info_outlined,
        label: 'Voir motif du blocage',
        color: const Color(0xFF94A3B8),
        onTap: () => _showMotifBlocage(context),
      ));
    }

    // ── Supprimer — toujours en dernier ───────────────────
    actions.add(_AdminAction(
      icon: Icons.delete_outline,
      label: 'Supprimer définitivement',
      color: const Color(0xFFEF4444),
      isDanger: true,
      onTap: () => _showConfirm(
        context,
        'Supprimer cet utilisateur ?',
        'Cette action est irréversible. Toutes les données seront perdues.',
        'Supprimer', const Color(0xFFEF4444), '__delete__',
      ),
    ));

    return PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      elevation: 8,
      itemBuilder: (_) => actions.asMap().entries.map((e) =>
        PopupMenuItem<int>(
          value: e.key,
          child: Row(children: [
            Icon(e.value.icon, color: e.value.color, size: 18),
            const SizedBox(width: 10),
            Text(e.value.label, style: GoogleFonts.inter(
              fontSize: 14, color: e.value.color,
              fontWeight: e.value.isDanger
                  ? FontWeight.w600 : FontWeight.w400,
            )),
          ]),
        )
      ).toList(),
      onSelected: (i) => actions[i].onTap(),
    );
  }

  Future<void> _doAction(BuildContext context, String action,
      {String? raison}) async {
    try {
      final token = context.read<AuthProvider>().token ?? '';
      await AdminService().updateUtilisateur(
        token, user['id'], action, raison: raison);
      onRefresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Action effectuée avec succès'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  void _showBloquerDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Bloquer ce compte', style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Précisez la raison du blocage :',
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
          const SizedBox(height: 12),
          TextFormField(
            controller: ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ex: Comportement inapproprié, faux compte...',
              filled: true, fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B), elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              await _doAction(context, 'bloquer', raison: ctrl.text.trim());
            },
            child: Text('Bloquer', style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showMotifBlocage(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Motif du blocage', style: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text(
          user['raison_blocage'] ?? 'Non précisé',
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF334155)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showConfirm(BuildContext context, String titre, String message,
      String btnLabel, Color btnColor, String action) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(titre, style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text(message, style: GoogleFonts.inter(
          fontSize: 14, color: const Color(0xFF64748B))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: btnColor, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              if (action == '__delete__') {
                final token = context.read<AuthProvider>().token ?? '';
                await AdminService().deleteUtilisateur(token, user['id']);
                onRefresh();
              } else {
                await _doAction(context, action);
              }
            },
            child: Text(btnLabel, style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showActionWithRaison(BuildContext context, String titre,
      String message, String btnLabel, Color btnColor, String action) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(titre, style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(message, style: GoogleFonts.inter(
            fontSize: 14, color: const Color(0xFF64748B))),
          const SizedBox(height: 12),
          TextFormField(
            controller: ctrl,
            decoration: InputDecoration(
              hintText: 'Raison (optionnel)',
              filled: true, fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: btnColor, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _doAction(context, action,
                raison: ctrl.text.isNotEmpty ? ctrl.text : null);
            },
            child: Text(btnLabel, style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
```

---

## 4. Fix Gestion Entreprises — Actions Complètes

```dart
// Dans companies_page.dart — widget intelligent pour les entreprises

class EntrepriseActionsMenu extends StatelessWidget {
  final Map<String, dynamic> entreprise;
  final VoidCallback onRefresh;

  const EntrepriseActionsMenu({
    super.key, required this.entreprise, required this.onRefresh,
  });

  bool get _estActif  => entreprise['utilisateur']?['est_actif'] == true;
  bool get _estValide => entreprise['utilisateur']?['est_valide'] == true;

  @override
  Widget build(BuildContext context) {
    final List<_AdminAction> actions = [
      _AdminAction(
        icon: Icons.business_outlined,
        label: 'Voir le profil complet',
        color: const Color(0xFF1A56DB),
        onTap: () => context.push(
          '/admin/entreprises/${entreprise['utilisateur']['id']}'
        ),
      ),
      _AdminAction(
        icon: Icons.work_outline,
        label: 'Voir les offres',
        color: const Color(0xFF64748B),
        onTap: () => context.push(
          '/admin/offres?entreprise_id=${entreprise['id']}'
        ),
      ),
    ];

    // Valider si en attente
    if (!_estValide) {
      actions.add(_AdminAction(
        icon: Icons.check_circle_outline,
        label: 'Valider l\'entreprise',
        color: const Color(0xFF10B981),
        onTap: () => _doAction(context, 'valider'),
      ));
      actions.add(_AdminAction(
        icon: Icons.cancel_outlined,
        label: 'Rejeter',
        color: const Color(0xFFF59E0B),
        onTap: () => _showAvecRaison(context, 'rejeter',
          'Rejeter cette entreprise ?', 'Rejeter'),
      ));
    }

    // Suspendre si actif
    if (_estActif && _estValide) {
      actions.add(_AdminAction(
        icon: Icons.pause_circle_outline,
        label: 'Suspendre',
        color: const Color(0xFFF59E0B),
        onTap: () => _showAvecRaison(context, 'suspendre',
          'Suspendre cette entreprise ?', 'Suspendre'),
      ));
    }

    // ── LEVER SUSPENSION — OPTION MANQUANTE AJOUTÉE ──────────
    if (!_estActif && _estValide) {
      actions.add(_AdminAction(
        icon: Icons.play_circle_outline,
        label: 'Lever la suspension',
        color: const Color(0xFF10B981),
        onTap: () => _showConfirm(context,
          'Lever la suspension ?',
          'L\'entreprise retrouvera accès à la plateforme et pourra publier des offres.',
          'Lever la suspension', const Color(0xFF10B981), 'lever_suspension',
        ),
      ));
    }

    actions.add(_AdminAction(
      icon: Icons.delete_outline,
      label: 'Supprimer définitivement',
      color: const Color(0xFFEF4444),
      isDanger: true,
      onTap: () => _showConfirm(context,
        'Supprimer cette entreprise ?',
        'Toutes les offres et données seront supprimées. Action irréversible.',
        'Supprimer', const Color(0xFFEF4444), '__delete__',
      ),
    ));

    return PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      elevation: 8,
      itemBuilder: (_) => actions.asMap().entries.map((e) =>
        PopupMenuItem<int>(
          value: e.key,
          child: Row(children: [
            Icon(e.value.icon, color: e.value.color, size: 18),
            const SizedBox(width: 10),
            Text(e.value.label, style: GoogleFonts.inter(
              fontSize: 14, color: e.value.color,
              fontWeight: e.value.isDanger
                  ? FontWeight.w600 : FontWeight.w400,
            )),
          ]),
        )
      ).toList(),
      onSelected: (i) => actions[i].onTap(),
    );
  }

  Future<void> _doAction(BuildContext ctx, String action,
      {String? raison}) async {
    try {
      final token = ctx.read<AuthProvider>().token ?? '';
      await AdminService().updateEntreprise(
        token, entreprise['utilisateur']['id'], action, raison: raison);
      onRefresh();
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  void _showAvecRaison(BuildContext ctx, String action,
      String titre, String btnLabel) {
    final ctrl = TextEditingController();
    showDialog(context: ctx, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(titre, style: GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w700)),
      content: TextFormField(
        controller: ctrl,
        maxLines: 2,
        decoration: InputDecoration(
          hintText: 'Raison (obligatoire)',
          filled: true, fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
          child: const Text('Annuler')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444), elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () async {
            if (ctrl.text.trim().isEmpty) return;
            Navigator.pop(ctx);
            await _doAction(ctx, action, raison: ctrl.text.trim());
          },
          child: Text(btnLabel, style: GoogleFonts.inter(
            color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ],
    ));
  }

  void _showConfirm(BuildContext ctx, String titre, String message,
      String btnLabel, Color btnColor, String action) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(titre, style: GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w700)),
      content: Text(message, style: GoogleFonts.inter(
        fontSize: 14, color: const Color(0xFF64748B))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
          child: const Text('Annuler')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: btnColor, elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () async {
            Navigator.pop(ctx);
            if (action == '__delete__') {
              final token = ctx.read<AuthProvider>().token ?? '';
              await AdminService().deleteUtilisateur(
                token, entreprise['utilisateur']['id']);
              onRefresh();
            } else {
              await _doAction(ctx, action);
            }
          },
          child: Text(btnLabel, style: GoogleFonts.inter(
            color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ],
    ));
  }
}
```

---

## 5. Page Profil Administrateur

```dart
// lib/screens/admin/pages/admin_profil_page.dart
// Page accessible depuis "Mon profil" dans le menu avatar du TopBar

class AdminProfilPage extends StatefulWidget {
  const AdminProfilPage({super.key});
  @override
  State<AdminProfilPage> createState() => _AdminProfilPageState();
}

class _AdminProfilPageState extends State<AdminProfilPage> {
  final AdminService _svc = AdminService();
  Map<String, dynamic>? _profil;
  bool _isLoading = true;
  bool _isSaving  = false;
  String? _error;

  final _nomCtrl    = TextEditingController();
  final _telCtrl    = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _ancienMdpCtrl = TextEditingController();
  final _nvMdpCtrl     = TextEditingController();
  final _confirmMdpCtrl= TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfil();
  }

  Future<void> _loadProfil() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res   = await _svc.getProfilAdmin(token);
      final data  = res['data'] as Map<String, dynamic>;
      setState(() {
        _profil = data;
        _nomCtrl.text     = data['nom']       ?? '';
        _telCtrl.text     = data['telephone'] ?? '';
        _adresseCtrl.text = data['adresse']   ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Erreur: $_error'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Colonne gauche : Photo + Infos rapides ───────────
        Expanded(flex: 35, child: Column(children: [
          _buildPhotoCard(),
          const SizedBox(height: 16),
          _buildQuickInfoCard(),
        ])),
        const SizedBox(width: 24),

        // ── Colonne droite : Formulaire ──────────────────────
        Expanded(flex: 65, child: Column(children: [
          _buildInfosCard(),
          const SizedBox(height: 16),
          _buildPasswordCard(),
        ])),
      ]),
    );
  }

  // Card photo de profil
  Widget _buildPhotoCard() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(children: [
      // Avatar cliquable
      GestureDetector(
        onTap: _pickAndUploadPhoto,
        child: Stack(alignment: Alignment.bottomRight, children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: const Color(0xFF1A56DB),
            backgroundImage: _profil?['photo_url'] != null
                ? NetworkImage(_profil!['photo_url']) : null,
            child: _profil?['photo_url'] == null
                ? Text(
                    (_profil?['nom'] as String? ?? 'A')[0].toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 36, fontWeight: FontWeight.w700,
                      color: Colors.white))
                : null,
          ),
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF1A56DB),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Text(_profil?['nom'] ?? 'Administrateur',
        style: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A))),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          _profil?['admin']?['niveau_acces'] ?? 'Admin',
          style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      const SizedBox(height: 8),
      Text(_profil?['email'] ?? '',
        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
      const SizedBox(height: 4),
      Text(
        'Membre depuis ${_formatDate(_profil?['date_creation'])}',
        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
    ]),
  );

  // Infos rapides
  Widget _buildQuickInfoCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Informations rapides', style: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
      const SizedBox(height: 12),
      _InfoRow(Icons.access_time_outlined,
        'Dernière connexion',
        _formatDate(_profil?['derniere_connexion'])),
      const SizedBox(height: 8),
      _InfoRow(Icons.shield_outlined,
        'Niveau d\'accès',
        _profil?['admin']?['niveau_acces'] ?? 'admin'),
    ]),
  );

  // Formulaire infos
  Widget _buildInfosCard() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Informations personnelles', style: GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
      const SizedBox(height: 20),

      _label('Nom complet'),
      const SizedBox(height: 6),
      _inputField(_nomCtrl, 'Votre nom', Icons.person_outline),
      const SizedBox(height: 16),

      _label('Email'),
      const SizedBox(height: 6),
      // Email non modifiable
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(children: [
          const Icon(Icons.email_outlined, size: 18, color: Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          Text(_profil?['email'] ?? '', style: GoogleFonts.inter(
            fontSize: 14, color: const Color(0xFF94A3B8))),
          const Spacer(),
          Text('Non modifiable', style: GoogleFonts.inter(
            fontSize: 11, color: const Color(0xFFCBD5E1))),
        ]),
      ),
      const SizedBox(height: 16),

      _label('Téléphone'),
      const SizedBox(height: 6),
      _inputField(_telCtrl, '+224 620 00 00 00', Icons.phone_outlined),
      const SizedBox(height: 16),

      _label('Adresse'),
      const SizedBox(height: 6),
      _inputField(_adresseCtrl, 'Conakry, Guinée', Icons.location_on_outlined),
      const SizedBox(height: 24),

      // Bouton sauvegarder
      SizedBox(
        width: double.infinity, height: 48,
        child: ElevatedButton.icon(
          icon: _isSaving
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_outlined, size: 18),
          label: Text(_isSaving ? 'Sauvegarde...' : 'Sauvegarder les modifications',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _isSaving ? null : _saveProfil,
        ),
      ),
    ]),
  );

  // Card changement mot de passe
  Widget _buildPasswordCard() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.lock_outline, color: Color(0xFF1A56DB), size: 20),
        const SizedBox(width: 8),
        Text('Changer le mot de passe', style: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
      ]),
      const SizedBox(height: 20),

      _label('Mot de passe actuel'),
      const SizedBox(height: 6),
      _passwordField(_ancienMdpCtrl, 'Votre mot de passe actuel'),
      const SizedBox(height: 16),

      _label('Nouveau mot de passe'),
      const SizedBox(height: 6),
      _passwordField(_nvMdpCtrl, 'Minimum 8 caractères'),
      const SizedBox(height: 16),

      _label('Confirmer le nouveau mot de passe'),
      const SizedBox(height: 6),
      _passwordField(_confirmMdpCtrl, 'Répétez le nouveau mot de passe'),
      const SizedBox(height: 20),

      SizedBox(
        width: double.infinity, height: 48,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.lock_reset_outlined, size: 18),
          label: Text('Modifier le mot de passe',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1A56DB),
            side: const BorderSide(color: Color(0xFF1A56DB)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _changePassword,
        ),
      ),
    ]),
  );

  Future<void> _pickAndUploadPhoto() async {
    // Utiliser image_picker
    // Puis appeler _svc.uploadPhotoAdmin(token, file)
    // Puis recharger le profil
    try {
      // final picker = ImagePicker();
      // final file = await picker.pickImage(source: ImageSource.gallery);
      // if (file == null) return;
      // final token = context.read<AuthProvider>().token ?? '';
      // final res = await _svc.uploadPhotoAdmin(token, file.path);
      // setState(() => _profil!['photo_url'] = res['data']['photo_url']);
      _loadProfil(); // Recharger après upload
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur upload: $e'),
        backgroundColor: const Color(0xFFEF4444),
      ));
    }
  }

  Future<void> _saveProfil() async {
    setState(() => _isSaving = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      await _svc.updateProfilAdmin(token,
        nom: _nomCtrl.text.trim(),
        telephone: _telCtrl.text.trim(),
        adresse: _adresseCtrl.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profil mis à jour avec succès'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur: $e'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _changePassword() async {
    if (_nvMdpCtrl.text != _confirmMdpCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Les mots de passe ne correspondent pas'),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    try {
      final token = context.read<AuthProvider>().token ?? '';
      await _svc.updateProfilAdmin(token,
        ancienMdp: _ancienMdpCtrl.text,
        nouveauMdp: _nvMdpCtrl.text,
      );
      _ancienMdpCtrl.clear();
      _nvMdpCtrl.clear();
      _confirmMdpCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Mot de passe modifié avec succès'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur: $e'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Widget _label(String text) => Text(text, style: GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF374151)));

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon) =>
    TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        filled: true, fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1A56DB), width: 1.5),
        ),
      ),
    );

  Widget _passwordField(TextEditingController ctrl, String hint) {
    bool obscure = true;
    return StatefulBuilder(
      builder: (_, setS) => TextFormField(
        controller: ctrl,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.lock_outline, size: 18, color: Color(0xFF94A3B8)),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
              size: 18, color: const Color(0xFF94A3B8)),
            onPressed: () => setS(() => obscure = !obscure),
          ),
          filled: true, fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF1A56DB), width: 1.5)),
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final d = DateTime.parse(dateStr).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) { return 'N/A'; }
  }

  @override
  void dispose() {
    _nomCtrl.dispose(); _telCtrl.dispose();
    _adresseCtrl.dispose(); _ancienMdpCtrl.dispose();
    _nvMdpCtrl.dispose(); _confirmMdpCtrl.dispose();
    super.dispose();
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 15, color: const Color(0xFF94A3B8)),
    const SizedBox(width: 8),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
      Text(value, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155))),
    ])),
  ]);
}
```

---

## 6. Corrections Overflow Mobile

```dart
// RÈGLE GLOBALE à appliquer dans TOUS les widgets admin
// qui causent des RenderFlex overflow sur mobile

// ── PROBLÈME FRÉQUENT 1 : Row avec trop d'éléments ──────────
// AVANT ❌
Row(children: [
  Text('Titre long qui dépasse'),
  SizedBox(width: 16),
  Text('Autre texte'),
  Spacer(),
  ElevatedButton(child: Text('Bouton long')),
])

// APRÈS ✅ — utiliser Flexible ou Expanded
Row(children: [
  Flexible(child: Text('Titre long', overflow: TextOverflow.ellipsis)),
  const SizedBox(width: 8),
  ElevatedButton(child: Text('Bouton', overflow: TextOverflow.ellipsis)),
])

// ── PROBLÈME FRÉQUENT 2 : StatCards en Row ──────────────────
// AVANT ❌ — 4 cards en Row fixe
Row(children: [
  StatCard(value: '1284'), StatCard(value: '487'),
  StatCard(value: '156'),  StatCard(value: '23'),
])

// APRÈS ✅ — grille responsive
LayoutBuilder(builder: (ctx, constraints) {
  final cols = constraints.maxWidth < 600 ? 2 : 4;
  return GridView.count(
    crossAxisCount: cols,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 12, mainAxisSpacing: 12,
    childAspectRatio: constraints.maxWidth < 600 ? 1.4 : 2.0,
    children: [
      StatCard(value: '1284', label: 'Utilisateurs'),
      StatCard(value: '487',  label: 'Offres'),
      StatCard(value: '156',  label: 'Entreprises'),
      StatCard(value: '23',   label: 'En attente'),
    ],
  );
})

// ── PROBLÈME FRÉQUENT 3 : Tableaux en Row ───────────────────
// Envelopper les tableaux dans SingleChildScrollView horizontal
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: DataTable(/* ... */),
)

// ── PROBLÈME FRÉQUENT 4 : Textes longs dans les cards ───────
// Toujours ajouter maxLines + overflow sur les textes de cards
Text(
  titre,
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
)

// ── PROBLÈME FRÉQUENT 5 : TopBar sur mobile ─────────────────
// Masquer la barre de recherche sur mobile
if (!isMobile) _GlobalSearchBar(),
// Sur mobile : remplacer par une icône
if (isMobile) IconButton(
  icon: const Icon(Icons.search_rounded),
  onPressed: () => _showSearchDialog(context),
)

// ── VÉRIFICATION BREAKPOINTS à appliquer partout ─────────────
// Utiliser LayoutBuilder ou MediaQuery dans TOUS les widgets
// qui ont des Row complexes

// Pattern standard à suivre :
Widget build(BuildContext context) {
  return LayoutBuilder(builder: (ctx, constraints) {
    final isMobile = constraints.maxWidth < 768;
    return isMobile ? _buildMobileLayout() : _buildDesktopLayout();
  });
}
```

---

## 7. Widget ActionMenu Intelligent — connecter "Mon profil"

```dart
// Dans admin_topbar.dart — menu avatar avec "Mon profil" fonctionnel

class _AdminAvatarMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      elevation: 12,
      itemBuilder: (_) => [
        // En-tête avec infos admin
        PopupMenuItem<String>(
          enabled: false,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF1A56DB),
                backgroundImage: adminProvider.photoUrl != null
                    ? NetworkImage(adminProvider.photoUrl!) : null,
                child: adminProvider.photoUrl == null
                    ? Text((adminProvider.nom ?? 'A')[0],
                        style: GoogleFonts.inter(
                          color: Colors.white, fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(adminProvider.nom ?? 'Administrateur',
                  style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A))),
                Text('Super Admin', style: GoogleFonts.inter(
                  fontSize: 11, color: const Color(0xFF64748B))),
              ]),
            ]),
            const SizedBox(height: 8),
            const Divider(height: 1),
          ]),
        ),

        // ── Mon profil ── OPTION AJOUTÉE ────────────────────
        PopupMenuItem<String>(
          value: 'profil',
          child: Row(children: [
            const Icon(Icons.person_outline,
              color: Color(0xFF64748B), size: 18),
            const SizedBox(width: 10),
            Text('Mon profil', style: GoogleFonts.inter(
              fontSize: 14, color: const Color(0xFF334155))),
          ]),
        ),

        // Paramètres
        PopupMenuItem<String>(
          value: 'parametres',
          child: Row(children: [
            const Icon(Icons.settings_outlined,
              color: Color(0xFF64748B), size: 18),
            const SizedBox(width: 10),
            Text('Paramètres', style: GoogleFonts.inter(
              fontSize: 14, color: const Color(0xFF334155))),
          ]),
        ),

        // Thème
        PopupMenuItem<String>(
          value: 'theme',
          child: Row(children: [
            Icon(
              context.isDark
                  ? Icons.wb_sunny_outlined
                  : Icons.dark_mode_outlined,
              color: const Color(0xFF64748B), size: 18),
            const SizedBox(width: 10),
            Text(context.isDark ? 'Mode clair' : 'Mode sombre',
              style: GoogleFonts.inter(
                fontSize: 14, color: const Color(0xFF334155))),
          ]),
        ),

        const PopupMenuDivider(),

        // Déconnexion
        PopupMenuItem<String>(
          value: 'deconnexion',
          child: Row(children: [
            const Icon(Icons.logout_outlined,
              color: Color(0xFFEF4444), size: 18),
            const SizedBox(width: 10),
            Text('Déconnexion', style: GoogleFonts.inter(
              fontSize: 14, color: const Color(0xFFEF4444),
              fontWeight: FontWeight.w600)),
          ]),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'profil':
            // ── NAVIGUER VERS LA PAGE PROFIL ──
            context.push('/admin/profil');
            break;
          case 'parametres':
            context.push('/admin/parametres');
            break;
          case 'theme':
            context.read<ThemeProvider>().toggleTheme(context);
            break;
          case 'deconnexion':
            _showLogoutDialog(context);
            break;
        }
      },
      child: Row(children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFF1A56DB),
          backgroundImage: adminProvider.photoUrl != null
              ? NetworkImage(adminProvider.photoUrl!) : null,
          child: adminProvider.photoUrl == null
              ? Text((adminProvider.nom ?? 'A')[0],
                  style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))
              : null,
        ),
        const SizedBox(width: 6),
        const Icon(Icons.arrow_drop_down, color: Color(0xFF94A3B8)),
      ]),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Déconnexion', style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text('Êtes-vous sûr de vouloir vous déconnecter ?',
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444), elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
              context.go('/connexion');
            },
            child: Text('Se déconnecter', style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
```

---

## 8. Mise à jour AdminService Flutter

```dart
// Ajouter dans frontend/lib/services/admin_service.dart

// ── PROFIL ADMIN ───────────────────────────────────────────
Future<Map<String, dynamic>> getProfilAdmin(String token) async {
  final res = await http.get(
    Uri.parse('$_base/profil'),
    headers: _headers(token),
  );
  return _handleResponse(res);
}

Future<Map<String, dynamic>> updateProfilAdmin(
  String token, {
  String? nom, String? telephone, String? adresse,
  String? ancienMdp, String? nouveauMdp,
}) async {
  final body = <String, dynamic>{};
  if (nom != null && nom.isNotEmpty) body['nom'] = nom;
  if (telephone != null) body['telephone'] = telephone;
  if (adresse != null) body['adresse'] = adresse;
  if (ancienMdp != null) body['ancien_mdp'] = ancienMdp;
  if (nouveauMdp != null) body['nouveau_mdp'] = nouveauMdp;

  final res = await http.patch(
    Uri.parse('$_base/profil'),
    headers: _headers(token),
    body: jsonEncode(body),
  );
  return _handleResponse(res);
}

// Ajouter route /admin/profil dans GoRouter
// GoRoute(
//   path: '/admin/profil',
//   builder: (ctx, state) => const AdminProfilPage(),
// ),
```

---

## 9. Critères d'Acceptation

### ✅ Backend — Actions Contextuelles
- [ ] `PATCH /api/admin/offres/:id` accepte : `valider`, `refuser`, `mettre_en_vedette`, `retirer_vedette`, `archiver`, `desarchiver`, `republier`
- [ ] `PATCH /api/admin/utilisateurs/:id` accepte : `valider`, `activer`, `bloquer`, `debloquer`, `rejeter`
- [ ] `PATCH /api/admin/entreprises/:id` accepte : `valider`, `suspendre`, `lever_suspension`, `rejeter`
- [ ] `GET /api/admin/profil` retourne les infos complètes de l'admin connecté
- [ ] `PATCH /api/admin/profil` met à jour nom, téléphone, adresse, mot de passe

### ✅ Frontend — Offres
- [ ] Menu actions offre affiche "Retirer de la vedette" si `en_vedette == true`
- [ ] Menu actions offre affiche "Mettre en vedette" si `en_vedette == false`
- [ ] Menu actions offre affiche "Désarchiver" si `statut == 'expiree'`
- [ ] Dialog refus avec champ motif obligatoire
- [ ] Confirmation pour archiver/désarchiver

### ✅ Frontend — Utilisateurs
- [ ] Menu actions affiche "Débloquer" si compte bloqué
- [ ] Menu actions affiche "Bloquer" si compte actif
- [ ] Menu actions affiche "Valider" si compte en attente
- [ ] "Voir le profil" navigue vers la page détail `/admin/utilisateurs/:id`
- [ ] Dialog blocage avec champ raison obligatoire
- [ ] "Voir motif du blocage" affiché si raison_blocage existe

### ✅ Frontend — Entreprises
- [ ] Menu actions affiche "Lever la suspension" si entreprise suspendue
- [ ] Menu actions affiche "Suspendre" si entreprise active
- [ ] Dialog suspension avec raison obligatoire

### ✅ Frontend — Profil Admin
- [ ] Clic "Mon profil" → navigue vers `/admin/profil`
- [ ] Page profil affiche photo (ou initiale), nom, email, téléphone
- [ ] Photo cliquable → dialog upload → photo mise à jour instantanément
- [ ] Formulaire infos sauvegardable
- [ ] Section changement mot de passe fonctionnelle
- [ ] Déconnexion depuis menu avatar avec confirmation

### ✅ Mobile — Overflow
- [ ] Aucun `RenderFlex overflow` sur 375px
- [ ] Stat cards : 2 colonnes sur mobile (pas 4 en ligne)
- [ ] Tableaux : scroll horizontal sur mobile
- [ ] Textes : `maxLines + overflow: ellipsis` partout
- [ ] TopBar : barre recherche masquée sur mobile

### ✅ Global
- [ ] Toutes les actions affichent une SnackBar succès (vert) ou erreur (rouge)
- [ ] Toutes les listes se rafraîchissent automatiquement après chaque action
- [ ] Pull-to-refresh fonctionnel sur toutes les pages admin

---

*PRD EmploiConnect v3.1 — Corrections & Complétion Admin*
*Cursor / Kirsoft AI — Phase 7.1*
