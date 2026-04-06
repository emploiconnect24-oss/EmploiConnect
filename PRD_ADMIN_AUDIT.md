# PRD — EmploiConnect · Audit & Complétion Backend Admin
## Product Requirements Document v3.2 — Backend Admin Audit Complet
**Stack : Node.js + Express · PostgreSQL/Supabase · Flutter**
**Outil : Cursor / Kirsoft AI**
**Objectif : Vérifier, compléter et solidifier TOUT le backend Admin**
**Statut : Phase 7.2 — Audit général avant passage au backend Candidat/Recruteur**
**Date : Mars 2026**

---

> ### ⚠️ INSTRUCTIONS POUR CURSOR
>
> Ce PRD est un **audit complet + complétion** du backend Admin.
> Pour chaque section :
> 1. **Vérifier** si la fonctionnalité existe déjà
> 2. **Compléter** ce qui manque
> 3. **Tester** avec un appel API
> Implémenter dans l'ordre exact. Ne pas sauter d'étapes.

---

## Table des Matières

1. [Audit Notifications — Backend + Flutter](#1-audit-notifications--backend--flutter)
2. [Audit Statistiques — Backend + Graphiques Flutter](#2-audit-statistiques--backend--graphiques-flutter)
3. [Audit Candidatures — Filtres + Export](#3-audit-candidatures--filtres--export)
4. [Audit TopBar — Recherche Globale + Badge Notifs](#4-audit-topbar--recherche-globale--badge-notifs)
5. [Audit Entreprises — Complétion](#5-audit-entreprises--complétion)
6. [Audit Offres d'Emploi — Complétion](#6-audit-offres-demploi--complétion)
7. [Audit Modération — Complétion](#7-audit-modération--complétion)
8. [Audit Paramètres — Complétion](#8-audit-paramètres--complétion)
9. [Audit Utilisateurs — Complétion](#9-audit-utilisateurs--complétion)
10. [Tests Globaux — Checklist finale](#10-tests-globaux--checklist-finale)

---

## 1. Audit Notifications — Backend + Flutter

### 1.1 Ce qui doit exister (vérifier)
```
✅ POST /api/admin/notifications   → Envoyer notification
✅ GET  /api/admin/notifications   → Historique
❓ GET  /api/notifications/mes     → Notifications de l'utilisateur connecté
❓ PATCH /api/notifications/:id    → Marquer comme lue
❓ PATCH /api/notifications/tout-lire → Marquer toutes lues
❓ DELETE /api/notifications/:id  → Supprimer une notification
```

### 1.2 Compléter `backend/src/routes/notifications.routes.js`

```javascript
// Ce fichier gère les notifications REÇUES par l'utilisateur connecté
// (admin, candidat, recruteur — route commune)
const express = require('express');
const router = express.Router();
const { auth } = require('../middleware/auth');

// Toutes les routes nécessitent auth
router.use(auth);

// GET /api/notifications/mes — Mes notifications
router.get('/mes', async (req, res) => {
  try {
    const { page = 1, limite = 20, non_lues_seulement = false } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limite);
    const { supabase } = require('../config/supabase');

    let query = supabase
      .from('notifications')
      .select('*', { count: 'exact' })
      .eq('destinataire_id', req.user.id)
      .order('date_creation', { ascending: false })
      .range(offset, offset + parseInt(limite) - 1);

    if (non_lues_seulement === 'true') {
      query = query.eq('est_lue', false);
    }

    const { data, count, error } = await query;
    if (error) throw error;

    // Compter les non lues
    const { count: nonLues } = await supabase
      .from('notifications')
      .select('id', { count: 'exact' })
      .eq('destinataire_id', req.user.id)
      .eq('est_lue', false);

    return res.json({
      success: true,
      data: {
        notifications: data || [],
        nb_non_lues: nonLues || 0,
        pagination: {
          total: count || 0,
          page: parseInt(page),
          limite: parseInt(limite),
          total_pages: Math.ceil((count || 0) / parseInt(limite)),
        }
      }
    });
  } catch (err) {
    console.error('[GET /notifications/mes]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// PATCH /api/notifications/:id — Marquer comme lue
router.patch('/:id', async (req, res) => {
  try {
    const { supabase } = require('../config/supabase');
    const { data, error } = await supabase
      .from('notifications')
      .update({ est_lue: true })
      .eq('id', req.params.id)
      .eq('destinataire_id', req.user.id) // sécurité : seulement ses notifs
      .select()
      .single();

    if (error) throw error;
    return res.json({ success: true, data });
  } catch (err) {
    console.error('[PATCH /notifications/:id]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// PATCH /api/notifications/tout-lire — Tout marquer comme lu
router.patch('/tout-lire/action', async (req, res) => {
  try {
    const { supabase } = require('../config/supabase');
    const { error } = await supabase
      .from('notifications')
      .update({ est_lue: true })
      .eq('destinataire_id', req.user.id)
      .eq('est_lue', false);

    if (error) throw error;
    return res.json({
      success: true,
      message: 'Toutes les notifications marquées comme lues'
    });
  } catch (err) {
    console.error('[PATCH /notifications/tout-lire]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// DELETE /api/notifications/:id
router.delete('/:id', async (req, res) => {
  try {
    const { supabase } = require('../config/supabase');
    const { error } = await supabase
      .from('notifications')
      .delete()
      .eq('id', req.params.id)
      .eq('destinataire_id', req.user.id);

    if (error) throw error;
    return res.json({ success: true, message: 'Notification supprimée' });
  } catch (err) {
    console.error('[DELETE /notifications/:id]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

module.exports = router;
```

### 1.3 Enregistrer la route dans `backend/src/routes/index.js`

```javascript
// Ajouter cette ligne dans routes/index.js
router.use('/notifications', require('./notifications.routes'));
```

### 1.4 Quand créer automatiquement une notification Admin ?

```javascript
// Créer ce service : backend/src/services/auto_notification.service.js
// Ce service crée automatiquement des notifications pour l'admin
// quand des événements importants se produisent

const { supabase } = require('../config/supabase');

// Récupérer tous les IDs admin
const getAdminIds = async () => {
  const { data } = await supabase
    .from('utilisateurs')
    .select('id')
    .eq('role', 'admin')
    .eq('est_actif', true);
  return (data || []).map(u => u.id);
};

// Notifier tous les admins
const notifierAdmins = async ({ titre, message, type, lien, objet_id }) => {
  try {
    const adminIds = await getAdminIds();
    if (adminIds.length === 0) return;

    const notifications = adminIds.map(id => ({
      destinataire_id:   id,
      type_destinataire: 'individuel',
      titre,
      message,
      type,
      lien,
    }));

    await supabase.from('notifications').insert(notifications);
  } catch (err) {
    console.error('[notifierAdmins] Erreur:', err.message);
    // Ne jamais bloquer le flux principal
  }
};

// ── ÉVÉNEMENTS QUI GÉNÈRENT UNE NOTIFICATION ADMIN ──────────

// Appelé lors d'une nouvelle inscription
const notifNouvelleInscription = async (utilisateur) => {
  await notifierAdmins({
    titre:   'Nouveau compte à valider',
    message: `${utilisateur.nom} vient de s'inscrire en tant que ${utilisateur.role}`,
    type:    'systeme',
    lien:    `/admin/utilisateurs/${utilisateur.id}`,
  });
};

// Appelé lors d'une nouvelle offre soumise
const notifNouvelleOffre = async (offre, entrepriseNom) => {
  await notifierAdmins({
    titre:   'Nouvelle offre en attente de validation',
    message: `${entrepriseNom} a soumis l'offre "${offre.titre}"`,
    type:    'offre',
    lien:    `/admin/offres/${offre.id}`,
  });
};

// Appelé lors d'un nouveau signalement
const notifNouveauSignalement = async (signalement) => {
  await notifierAdmins({
    titre:   '🚨 Nouveau signalement reçu',
    message: `Un signalement de type "${signalement.type_objet}" vient d'être soumis`,
    type:    'systeme',
    lien:    `/admin/moderation`,
  });
};

module.exports = {
  notifierAdmins,
  notifNouvelleInscription,
  notifNouvelleOffre,
  notifNouveauSignalement,
};
```

### 1.5 Intégrer les notifications automatiques dans les routes existantes

```javascript
// Dans backend/src/routes/auth.routes.js (ou controllers/auth.controller.js)
// APRÈS la création d'un compte réussi, ajouter :
const { notifNouvelleInscription } = require('../services/auto_notification.service');
// ...
// Après INSERT utilisateur réussi :
await notifNouvelleInscription(nouvelUtilisateur);

// Dans backend/src/controllers/offres.controller.js
// APRÈS la création d'une offre réussi :
const { notifNouvelleOffre } = require('../services/auto_notification.service');
// ...
await notifNouvelleOffre(nouvelleOffre, req.user.entreprise_nom);

// Dans backend/src/routes/signalements.routes.js
// APRÈS création d'un signalement :
const { notifNouveauSignalement } = require('../services/auto_notification.service');
await notifNouveauSignalement(nouveauSignalement);
```

### 1.6 Flutter — Page Notifications Admin complète

```dart
// lib/screens/admin/pages/notifications_page.dart
// Remplacer le contenu mock par données réelles

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final AdminService _svc = AdminService();
  List<dynamic> _notifications = [];
  int _nbNonLues = 0;
  bool _isLoading = true;
  String _filtre = 'toutes'; // 'toutes' | 'non_lues'

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await _svc.getMesNotifications(
        token,
        nonLuesSeulement: _filtre == 'non_lues',
      );
      setState(() {
        _notifications = res['data']['notifications'] ?? [];
        _nbNonLues     = res['data']['nb_non_lues'] ?? 0;
        _isLoading     = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _marquerToutLu() async {
    final token = context.read<AuthProvider>().token ?? '';
    await _svc.marquerToutesNotificationsLues(token);
    // Mettre à jour le badge dans AdminProvider
    context.read<AdminProvider>().updateNbNotifications(0);
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(children: [

        // En-tête
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Notifications', style: GoogleFonts.poppins(
              fontSize: 22, fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A))),
            if (_nbNonLues > 0)
              Text('$_nbNonLues notification(s) non lue(s)',
                style: GoogleFonts.inter(
                  fontSize: 14, color: const Color(0xFF1A56DB))),
          ]),
          if (_nbNonLues > 0)
            TextButton.icon(
              icon: const Icon(Icons.done_all, size: 16),
              label: const Text('Tout marquer comme lu'),
              onPressed: _marquerToutLu,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1A56DB)),
            ),
        ]),
        const SizedBox(height: 20),

        // Filtres
        Row(children: [
          _FiltreChip('Toutes', 'toutes', _filtre,
            () => setState(() { _filtre = 'toutes'; _loadNotifications(); })),
          const SizedBox(width: 8),
          _FiltreChip('Non lues ($_nbNonLues)', 'non_lues', _filtre,
            () => setState(() { _filtre = 'non_lues'; _loadNotifications(); })),
        ]),
        const SizedBox(height: 20),

        // Liste
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_notifications.isEmpty)
          _buildEmptyState()
        else
          ..._notifications.map((n) => _NotificationTile(
            notification: n,
            onMarkRead: () async {
              final token = context.read<AuthProvider>().token ?? '';
              await _svc.marquerNotificationLue(token, n['id']);
              _loadNotifications();
            },
            onDelete: () async {
              final token = context.read<AuthProvider>().token ?? '';
              await _svc.supprimerNotification(token, n['id']);
              _loadNotifications();
            },
          )),
      ]),
    );
  }

  Widget _buildEmptyState() => Center(
    child: Column(children: [
      const SizedBox(height: 40),
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF), shape: BoxShape.circle),
        child: const Icon(Icons.notifications_none_outlined,
          color: Color(0xFF1A56DB), size: 36)),
      const SizedBox(height: 16),
      Text('Aucune notification', style: GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A))),
      Text('Vous êtes à jour !', style: GoogleFonts.inter(
        fontSize: 14, color: const Color(0xFF64748B))),
    ]),
  );
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.onMarkRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final estLue = notification['est_lue'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: estLue ? Colors.white : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: estLue
              ? const Color(0xFFE2E8F0)
              : const Color(0xFF1A56DB).withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: _iconBg(notification['type']),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_icon(notification['type']),
            color: _iconColor(notification['type']), size: 20),
        ),
        title: Text(notification['titre'] ?? '',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: estLue ? FontWeight.w400 : FontWeight.w600,
            color: const Color(0xFF0F172A))),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['message'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF64748B)),
              maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(_formatDate(notification['date_creation']),
              style: GoogleFonts.inter(
                fontSize: 11, color: const Color(0xFF94A3B8))),
          ],
        ),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (!estLue)
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF1A56DB), shape: BoxShape.circle)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert,
              color: Color(0xFF94A3B8), size: 18),
            onSelected: (v) {
              if (v == 'lire') onMarkRead();
              if (v == 'supprimer') onDelete();
            },
            itemBuilder: (_) => [
              if (!estLue)
                const PopupMenuItem(value: 'lire',
                  child: Text('Marquer comme lue')),
              const PopupMenuItem(value: 'supprimer',
                child: Text('Supprimer',
                  style: TextStyle(color: Color(0xFFEF4444)))),
            ],
          ),
        ]),
        onTap: () {
          if (!estLue) onMarkRead();
          // Naviguer si lien disponible
          if (notification['lien'] != null) {
            context.push(notification['lien']);
          }
        },
      ),
    );
  }

  IconData _icon(String? type) {
    switch (type) {
      case 'candidature': return Icons.assignment_outlined;
      case 'offre':       return Icons.work_outline;
      case 'message':     return Icons.chat_bubble_outline;
      default:            return Icons.notifications_outlined;
    }
  }

  Color _iconBg(String? type) {
    switch (type) {
      case 'candidature': return const Color(0xFFEFF6FF);
      case 'offre':       return const Color(0xFFECFDF5);
      case 'message':     return const Color(0xFFF5F3FF);
      default:            return const Color(0xFFFEF3C7);
    }
  }

  Color _iconColor(String? type) {
    switch (type) {
      case 'candidature': return const Color(0xFF1A56DB);
      case 'offre':       return const Color(0xFF10B981);
      case 'message':     return const Color(0xFF8B5CF6);
      default:            return const Color(0xFFF59E0B);
    }
  }

  String _formatDate(String? d) {
    if (d == null) return '';
    try {
      final dt = DateTime.parse(d).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      return 'Il y a ${diff.inDays} jour(s)';
    } catch (_) { return ''; }
  }
}

Widget _FiltreChip(String label, String value, String current,
    VoidCallback onTap) {
  final isSelected = value == current;
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF1A56DB)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(label, style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: isSelected ? Colors.white : const Color(0xFF64748B))),
    ),
  );
}
```

### 1.7 Badge Notifications dans le TopBar — Dynamique

```dart
// Dans admin_topbar.dart — icône notification avec badge dynamique

Consumer<AdminProvider>(
  builder: (ctx, adminProvider, _) => Stack(children: [
    IconButton(
      icon: const Icon(Icons.notifications_outlined,
        color: Color(0xFF64748B)),
      onPressed: () => ctx.push('/admin/notifications'),
    ),
    if (adminProvider.nbNotificationsNonLues > 0)
      Positioned(
        top: 6, right: 6,
        child: Container(
          width: 18, height: 18,
          decoration: const BoxDecoration(
            color: Color(0xFFEF4444), shape: BoxShape.circle),
          child: Center(
            child: Text(
              adminProvider.nbNotificationsNonLues > 9
                  ? '9+' : '${adminProvider.nbNotificationsNonLues}',
              style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: Colors.white),
            ),
          ),
        ),
      ),
  ]),
)

// Dans AdminProvider, ajouter :
int nbNotificationsNonLues = 0;

void updateNbNotifications(int nb) {
  nbNotificationsNonLues = nb;
  notifyListeners();
}

// Dans loadDashboard(), ajouter l'appel pour compter les non lues :
final notifRes = await _service.getMesNotifications(token);
nbNotificationsNonLues = notifRes['data']['nb_non_lues'] ?? 0;
```

---

## 2. Audit Statistiques — Backend + Graphiques Flutter

### 2.1 Vérifier et compléter `GET /api/admin/statistiques`

```javascript
// Ajouter dans dashboard.controller.js ces routes manquantes :

// ── GET /api/admin/statistiques/export ──────────────────────
// Export CSV des statistiques
const exportStatistiques = async (req, res) => {
  try {
    const { periode = '30d' } = req.query;
    const { supabase } = require('../../config/supabase');

    // Récupérer les données d'évolution
    const periodeJours = { '7d': 7, '30d': 30, '3m': 90 }[periode] || 30;
    const dateDebut = new Date(
      Date.now() - periodeJours * 24 * 60 * 60 * 1000
    );

    const [users, offres, candidats] = await Promise.all([
      supabase.from('utilisateurs')
        .select('nom, email, role, date_creation')
        .gte('date_creation', dateDebut.toISOString()),
      supabase.from('offres_emploi')
        .select('titre, localisation, statut, date_creation')
        .gte('date_creation', dateDebut.toISOString()),
      supabase.from('candidatures')
        .select('statut, date_candidature')
        .gte('date_candidature', dateDebut.toISOString()),
    ]);

    // Construire le CSV
    const lines = ['Type,Valeur,Date'];
    (users.data || []).forEach(u =>
      lines.push(`Utilisateur,${u.role},${u.date_creation?.split('T')[0]}`));
    (offres.data || []).forEach(o =>
      lines.push(`Offre,${o.statut},${o.date_creation?.split('T')[0]}`));
    (candidats.data || []).forEach(c =>
      lines.push(`Candidature,${c.statut},${c.date_candidature?.split('T')[0]}`));

    const csv = lines.join('\n');

    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition',
      `attachment; filename="stats_emploiconnect_${periode}.csv"`);
    return res.send('\uFEFF' + csv); // BOM pour Excel
  } catch (err) {
    console.error('[exportStatistiques]', err);
    res.status(500).json({ success: false, message: 'Erreur export' });
  }
};

// ── GET /api/admin/statistiques/top-entreprises ─────────────
const getTopEntreprises = async (req, res) => {
  try {
    const { supabase } = require('../../config/supabase');

    // Top entreprises par nombre d'offres
    const { data: offres } = await supabase
      .from('offres_emploi')
      .select(`
        entreprise_id,
        entreprise:entreprise_id (
          nom_entreprise, logo_url
        )
      `);

    const counts = {};
    (offres || []).forEach(o => {
      const id  = o.entreprise_id;
      const nom = o.entreprise?.nom_entreprise || 'Inconnu';
      if (!counts[id]) counts[id] = { id, nom, logo: o.entreprise?.logo_url, nb: 0 };
      counts[id].nb++;
    });

    const top = Object.values(counts)
      .sort((a, b) => b.nb - a.nb)
      .slice(0, 10);

    return res.json({ success: true, data: top });
  } catch (err) {
    console.error('[getTopEntreprises]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
```

### 2.2 Enregistrer les nouvelles routes statistiques

```javascript
// Dans dashboard.routes.js, ajouter :
router.get('/statistiques',              ctrl.getStatistiques);
router.get('/statistiques/export',       ctrl.exportStatistiques);
router.get('/statistiques/top-entreprises', ctrl.getTopEntreprises);
router.get('/activite',                  ctrl.getActivite);
```

### 2.3 Flutter — Page Statistiques avec vraies données

```dart
// lib/screens/admin/pages/statistics_page.dart
// Remplacer toutes les données mock par des appels API réels

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});
  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final AdminService _svc = AdminService();
  String _periode = '30d';
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _loadStats(); }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await _svc.getStatistiques(token, periode: _periode);
      setState(() { _stats = res['data']; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // En-tête + sélecteur période
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Statistiques & Analytiques',
            style: GoogleFonts.poppins(
              fontSize: 22, fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A))),
          // Sélecteur période
          Row(children: [
            for (final p in ['7d', '30d', '3m', '6m', '1an'])
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: GestureDetector(
                  onTap: () => setState(() { _periode = p; _loadStats(); }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _periode == p
                          ? const Color(0xFF1A56DB)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(p, style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w500,
                      color: _periode == p
                          ? Colors.white : const Color(0xFF64748B))),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            // Bouton export CSV
            OutlinedButton.icon(
              icon: const Icon(Icons.download_outlined, size: 16),
              label: const Text('Exporter CSV'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
                textStyle: GoogleFonts.inter(fontSize: 13),
              ),
              onPressed: () => _exportCSV(),
            ),
          ]),
        ]),
        const SizedBox(height: 24),

        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_stats != null) ...[

          // KPIs
          _buildKPIs(),
          const SizedBox(height: 24),

          // Graphique évolution
          _buildEvolutionChart(),
          const SizedBox(height: 24),

          // Distribution
          Row(children: [
            Expanded(child: _buildDistributionCard(
              'Par ville', _stats!['distribution_villes'] ?? {})),
            const SizedBox(width: 20),
            Expanded(child: _buildDistributionCard(
              'Par secteur', _stats!['distribution_secteurs'] ?? {})),
          ]),
        ],
      ]),
    );
  }

  Widget _buildKPIs() {
    final kpis = _stats!['kpis'] ?? {};
    return LayoutBuilder(builder: (ctx, constraints) {
      final cols = constraints.maxWidth < 600 ? 2 : 3;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16, mainAxisSpacing: 16,
        childAspectRatio: 2.0,
        children: [
          _KpiCard(
            'Nouveaux utilisateurs',
            '${kpis['nouveaux_utilisateurs']?['valeur'] ?? 0}',
            '${kpis['nouveaux_utilisateurs']?['tendance'] ?? 0}%',
            Icons.people_rounded,
            const Color(0xFF1A56DB),
            const Color(0xFFEFF6FF),
          ),
          _KpiCard(
            'Nouvelles offres',
            '${kpis['nouvelles_offres']?['valeur'] ?? 0}',
            '${kpis['nouvelles_offres']?['tendance'] ?? 0}%',
            Icons.work_rounded,
            const Color(0xFF10B981),
            const Color(0xFFECFDF5),
          ),
          _KpiCard(
            'Candidatures',
            '${kpis['nouvelles_candidatures']?['valeur'] ?? 0}',
            '${kpis['nouvelles_candidatures']?['tendance'] ?? 0}%',
            Icons.assignment_rounded,
            const Color(0xFF8B5CF6),
            const Color(0xFFF5F3FF),
          ),
        ],
      );
    });
  }

  Widget _buildEvolutionChart() {
    final evolution = List<Map<String, dynamic>>.from(
      _stats!['evolution_par_jour'] ?? []);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Évolution sur la période', style: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A))),
        const SizedBox(height: 16),
        if (evolution.isEmpty)
          const Center(child: Text('Aucune donnée disponible'))
        else
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: const Color(0xFFE2E8F0), strokeWidth: 1),
                  drawVerticalLine: false,
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, reservedSize: 30,
                      interval: (evolution.length / 5).toDouble(),
                    )),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Courbe utilisateurs
                  LineChartBarData(
                    spots: evolution.asMap().entries.map((e) =>
                      FlSpot(e.key.toDouble(),
                        (e.value['utilisateurs'] as num).toDouble())
                    ).toList(),
                    isCurved: true,
                    color: const Color(0xFF1A56DB),
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF1A56DB).withOpacity(0.08)),
                  ),
                  // Courbe offres
                  LineChartBarData(
                    spots: evolution.asMap().entries.map((e) =>
                      FlSpot(e.key.toDouble(),
                        (e.value['offres'] as num).toDouble())
                    ).toList(),
                    isCurved: true,
                    color: const Color(0xFF10B981),
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF10B981).withOpacity(0.08)),
                  ),
                ],
              ),
            ),
          ),
        // Légende
        const SizedBox(height: 12),
        Row(children: [
          _LegendItem(const Color(0xFF1A56DB), 'Utilisateurs'),
          const SizedBox(width: 20),
          _LegendItem(const Color(0xFF10B981), 'Offres'),
        ]),
      ]),
    );
  }

  Widget _buildDistributionCard(
      String titre, Map<String, dynamic> data) {
    final sorted = data.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));
    final top5 = sorted.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titre, style: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A))),
        const SizedBox(height: 14),
        if (top5.isEmpty)
          const Text('Aucune donnée')
        else
          ...top5.map((e) {
            final total = data.values.fold<num>(0, (a, b) => a + (b as num));
            final pct = total > 0
                ? ((e.value as num) / total * 100).toStringAsFixed(1)
                : '0.0';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(e.key,
                      style: GoogleFonts.inter(
                        fontSize: 13, color: const Color(0xFF334155)),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text('$pct%', style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A56DB))),
                  ]),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: total > 0
                        ? (e.value as num) / total : 0,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation(
                      Color(0xFF1A56DB)),
                    minHeight: 5,
                  ),
                ),
              ]),
            );
          }),
      ]),
    );
  }

  Future<void> _exportCSV() async {
    try {
      final token = context.read<AuthProvider>().token ?? '';
      // Appel API export — télécharger le fichier
      await _svc.exportStatistiques(token, periode: _periode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Export CSV téléchargé'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur export: $e'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

// Ajouter fl_chart dans pubspec.yaml si pas déjà présent :
// fl_chart: ^0.68.0
```

---

## 3. Audit Candidatures — Filtres + Export

### 3.1 Compléter `GET /api/admin/candidatures`

```javascript
// Vérifier et compléter dans candidatures.controller.js
// Ajouter ces filtres manquants :

const getCandidatures = async (req, res) => {
  try {
    const {
      page = 1, limite = 20,
      statut,
      offre_id,
      entreprise_nom,   // ← NOUVEAU : filtre par nom entreprise
      chercheur_nom,    // ← NOUVEAU : filtre par nom candidat
      date_debut,       // ← NOUVEAU : filtre par date
      date_fin,         // ← NOUVEAU
      ordre = 'date_candidature',
      direction = 'desc',
    } = req.query;

    const { supabase } = require('../../config/supabase');
    const offset = (parseInt(page) - 1) * parseInt(limite);

    let query = supabase
      .from('candidatures')
      .select(`
        id, statut, score_compatibilite,
        date_candidature, date_modification,
        lettre_motivation,
        chercheur:chercheur_id (
          id,
          utilisateur:utilisateur_id (
            id, nom, email, photo_url, telephone
          )
        ),
        offre:offre_id (
          id, titre, localisation, type_contrat,
          entreprise:entreprise_id (
            id, nom_entreprise, logo_url
          )
        ),
        cv:cv_id (id, fichier_url, nom_fichier)
      `, { count: 'exact' })
      .order(ordre, { ascending: direction === 'asc' })
      .range(offset, offset + parseInt(limite) - 1);

    if (statut)     query = query.eq('statut', statut);
    if (offre_id)   query = query.eq('offre_id', offre_id);
    if (date_debut) query = query.gte('date_candidature', date_debut);
    if (date_fin)   query = query.lte('date_candidature', date_fin);

    const { data, count, error } = await query;
    if (error) throw error;

    // Filtres post-requête sur les données jointes
    let results = data || [];
    if (chercheur_nom) {
      results = results.filter(c =>
        c.chercheur?.utilisateur?.nom?.toLowerCase()
          .includes(chercheur_nom.toLowerCase()));
    }
    if (entreprise_nom) {
      results = results.filter(c =>
        c.offre?.entreprise?.nom_entreprise?.toLowerCase()
          .includes(entreprise_nom.toLowerCase()));
    }

    // Stats globales
    const { data: statsData } = await supabase
      .from('candidatures').select('statut');
    const stats = {
      total:     statsData?.length || 0,
      en_attente:statsData?.filter(c => c.statut === 'en_attente').length || 0,
      en_cours:  statsData?.filter(c => c.statut === 'en_cours').length || 0,
      entretien: statsData?.filter(c => c.statut === 'entretien').length || 0,
      acceptees: statsData?.filter(c => c.statut === 'acceptee').length || 0,
      refusees:  statsData?.filter(c => c.statut === 'refusee').length || 0,
    };

    return res.json({
      success: true,
      data: {
        candidatures: results,
        stats,
        pagination: {
          total: count || 0,
          page: parseInt(page),
          limite: parseInt(limite),
          total_pages: Math.ceil((count || 0) / parseInt(limite)),
        }
      }
    });
  } catch (err) {
    console.error('[admin/getCandidatures]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Ajouter export CSV candidatures
const exportCandidatures = async (req, res) => {
  try {
    const { supabase } = require('../../config/supabase');
    const { data } = await supabase
      .from('candidatures')
      .select(`
        statut, score_compatibilite, date_candidature,
        chercheur:chercheur_id (
          utilisateur:utilisateur_id (nom, email)
        ),
        offre:offre_id (
          titre,
          entreprise:entreprise_id (nom_entreprise)
        )
      `)
      .order('date_candidature', { ascending: false });

    const lines = ['Candidat,Email,Poste,Entreprise,Statut,Score IA,Date'];
    (data || []).forEach(c => {
      const nom = c.chercheur?.utilisateur?.nom || '';
      const email = c.chercheur?.utilisateur?.email || '';
      const poste = c.offre?.titre || '';
      const ent   = c.offre?.entreprise?.nom_entreprise || '';
      const score = c.score_compatibilite || '';
      const date  = c.date_candidature?.split('T')[0] || '';
      lines.push(`"${nom}","${email}","${poste}","${ent}",${c.statut},${score},${date}`);
    });

    const csv = lines.join('\n');
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition',
      'attachment; filename="candidatures_emploiconnect.csv"');
    return res.send('\uFEFF' + csv);
  } catch (err) {
    res.status(500).json({ success: false, message: 'Erreur export' });
  }
};
```

### 3.2 Ajouter la route export

```javascript
// Dans candidatures.routes.js
router.get('/',        ctrl.getCandidatures);
router.get('/export',  ctrl.exportCandidatures); // ← NOUVEAU
```

---

## 4. Audit TopBar — Recherche Globale + Badge Notifs

### 4.1 Backend — Route de recherche globale

```javascript
// Créer backend/src/routes/admin/search.routes.js

const express = require('express');
const router = express.Router();
const { auth } = require('../../middleware/auth');
const { requireAdmin } = require('../../middleware/adminAuth');
const { supabase } = require('../../config/supabase');

router.use(auth, requireAdmin);

// GET /api/admin/recherche?q=terme
router.get('/', async (req, res) => {
  try {
    const { q } = req.query;
    if (!q || q.trim().length < 2) {
      return res.json({ success: true, data: { resultats: [] } });
    }

    const terme = q.trim();

    // Rechercher en parallèle dans plusieurs tables
    const [users, offres, entreprises] = await Promise.all([
      supabase.from('utilisateurs')
        .select('id, nom, email, role, photo_url')
        .or(`nom.ilike.%${terme}%,email.ilike.%${terme}%`)
        .limit(5),

      supabase.from('offres_emploi')
        .select('id, titre, localisation, statut')
        .ilike('titre', `%${terme}%`)
        .limit(5),

      supabase.from('entreprises')
        .select('id, nom_entreprise, logo_url, utilisateur_id')
        .ilike('nom_entreprise', `%${terme}%`)
        .limit(5),
    ]);

    const resultats = [
      ...(users.data || []).map(u => ({
        type: 'utilisateur',
        id: u.id,
        titre: u.nom,
        sous_titre: `${u.email} · ${u.role}`,
        photo: u.photo_url,
        lien: `/admin/utilisateurs/${u.id}`,
      })),
      ...(offres.data || []).map(o => ({
        type: 'offre',
        id: o.id,
        titre: o.titre,
        sous_titre: `${o.localisation} · ${o.statut}`,
        lien: `/admin/offres/${o.id}`,
      })),
      ...(entreprises.data || []).map(e => ({
        type: 'entreprise',
        id: e.id,
        titre: e.nom_entreprise,
        sous_titre: 'Entreprise',
        photo: e.logo_url,
        lien: `/admin/entreprises/${e.utilisateur_id}`,
      })),
    ];

    return res.json({ success: true, data: { resultats } });
  } catch (err) {
    console.error('[recherche globale]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

module.exports = router;
```

### 4.2 Enregistrer la route recherche

```javascript
// Dans routes/admin/index.js
router.use('/recherche', require('./search.routes'));
```

### 4.3 Flutter — Barre de recherche globale fonctionnelle

```dart
// Dans admin_topbar.dart — remplacer la barre de recherche statique

class _GlobalSearchBar extends StatefulWidget {
  @override
  State<_GlobalSearchBar> createState() => _GlobalSearchBarState();
}

class _GlobalSearchBarState extends State<_GlobalSearchBar> {
  final _ctrl     = TextEditingController();
  final _focusNode = FocusNode();
  List<dynamic> _resultats = [];
  bool _showResults = false;
  Timer? _debounce;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(children: [
        // Champ de recherche
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(children: [
            const SizedBox(width: 10),
            const Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _ctrl,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14, color: const Color(0xFFCBD5E1)),
                  border: InputBorder.none, isDense: true,
                ),
                style: GoogleFonts.inter(
                  fontSize: 14, color: const Color(0xFF0F172A)),
                onChanged: _onSearch,
              ),
            ),
            if (_ctrl.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _ctrl.clear();
                  setState(() { _resultats = []; _showResults = false; });
                },
                child: const Icon(Icons.clear,
                  color: Color(0xFF94A3B8), size: 16),
              ),
            const SizedBox(width: 8),
          ]),
        ),

        // Résultats dropdown
        if (_showResults && _resultats.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [BoxShadow(
                color: Color(0x14000000), blurRadius: 20,
                offset: Offset(0, 8))],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _resultats.length,
              itemBuilder: (ctx, i) {
                final r = _resultats[i];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: _typeColor(r['type']),
                    backgroundImage: r['photo'] != null
                        ? NetworkImage(r['photo']) : null,
                    child: r['photo'] == null
                        ? Icon(_typeIcon(r['type']),
                            color: Colors.white, size: 14)
                        : null,
                  ),
                  title: Text(r['titre'] ?? '',
                    style: GoogleFonts.inter(fontSize: 13,
                      fontWeight: FontWeight.w500)),
                  subtitle: Text(r['sous_titre'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 11, color: const Color(0xFF94A3B8))),
                  onTap: () {
                    setState(() => _showResults = false);
                    _ctrl.clear();
                    if (r['lien'] != null) context.push(r['lien']);
                  },
                );
              },
            ),
          ),
      ]),
    );
  }

  void _onSearch(String query) {
    _debounce?.cancel();
    if (query.length < 2) {
      setState(() { _resultats = []; _showResults = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final token = context.read<AuthProvider>().token ?? '';
        final res = await AdminService().rechercheGlobale(token, query);
        setState(() {
          _resultats  = res['data']['resultats'] ?? [];
          _showResults = true;
        });
      } catch (_) {}
    });
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'utilisateur': return Icons.person_outlined;
      case 'offre':       return Icons.work_outline;
      case 'entreprise':  return Icons.business_outlined;
      default:            return Icons.search;
    }
  }

  Color _typeColor(String? type) {
    switch (type) {
      case 'utilisateur': return const Color(0xFF1A56DB);
      case 'offre':       return const Color(0xFF10B981);
      case 'entreprise':  return const Color(0xFF8B5CF6);
      default:            return const Color(0xFF94A3B8);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
```

---

## 5. Audit Entreprises — Complétion

### 5.1 Route manquante : GET /api/admin/entreprises/:id

```javascript
// Ajouter dans entreprises.controller.js

const getEntrepriseDetail = async (req, res) => {
  try {
    const { id } = req.params; // utilisateur_id
    const { supabase } = require('../../config/supabase');

    const { data: user, error } = await supabase
      .from('utilisateurs')
      .select(`
        id, nom, email, telephone, adresse,
        est_actif, est_valide, date_creation,
        raison_blocage, derniere_connexion,
        entreprise:entreprises (
          id, nom_entreprise, description,
          secteur_activite, taille_entreprise,
          site_web, logo_url, adresse_siege
        )
      `)
      .eq('id', id)
      .single();

    if (error || !user) {
      return res.status(404).json({
        success: false, message: 'Entreprise non trouvée'
      });
    }

    // Offres de l'entreprise
    const { data: offres } = await supabase
      .from('offres_emploi')
      .select('id, titre, statut, date_publication, nombre_postes')
      .eq('entreprise_id', user.entreprise?.id)
      .order('date_publication', { ascending: false });

    // Candidatures reçues
    const { count: nbCandidatures } = await supabase
      .from('candidatures')
      .select('id', { count: 'exact' })
      .in('offre_id', (offres || []).map(o => o.id));

    return res.json({
      success: true,
      data: {
        ...user,
        offres: offres || [],
        nb_candidatures_total: nbCandidatures || 0,
      }
    });
  } catch (err) {
    console.error('[getEntrepriseDetail]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
```

### 5.2 Enregistrer la route

```javascript
// Dans entreprises.routes.js
router.get('/',    ctrl.getEntreprises);
router.get('/:id', ctrl.getEntrepriseDetail); // ← NOUVEAU
router.patch('/:id', auditLog('ACTION_ENTREPRISE', 'entreprise'),
  ctrl.updateEntreprise);
router.delete('/:id', auditLog('SUPPRIMER_ENTREPRISE', 'entreprise'),
  ctrl.deleteEntreprise);
```

---

## 6. Audit Offres d'Emploi — Complétion

### 6.1 Vérifier que toutes les actions fonctionnent

```javascript
// Vérifier dans offres.routes.js que ces routes existent :
router.get('/',     ctrl.getOffres);
router.get('/:id',  ctrl.getOffreDetail);  // ← vérifier
router.patch('/:id', ctrl.updateOffre);    // ← avec toutes les actions
router.delete('/:id', ctrl.deleteOffre);

// Ajouter export CSV offres
router.get('/export/csv', async (req, res) => {
  try {
    const { supabase } = require('../../config/supabase');
    const { data } = await supabase
      .from('offres_emploi')
      .select(`
        titre, localisation, type_contrat, statut,
        salaire_min, salaire_max, devise,
        date_publication, date_limite,
        entreprise:entreprise_id (nom_entreprise)
      `)
      .order('date_creation', { ascending: false });

    const lines = ['Titre,Entreprise,Ville,Contrat,Salaire Min,Salaire Max,Statut,Date Publication'];
    (data || []).forEach(o => {
      lines.push([
        `"${o.titre}"`,
        `"${o.entreprise?.nom_entreprise || ''}"`,
        `"${o.localisation || ''}"`,
        o.type_contrat || '',
        o.salaire_min || '',
        o.salaire_max || '',
        o.statut,
        o.date_publication?.split('T')[0] || '',
      ].join(','));
    });

    const csv = lines.join('\n');
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition',
      'attachment; filename="offres_emploiconnect.csv"');
    return res.send('\uFEFF' + csv);
  } catch (err) {
    res.status(500).json({ success: false, message: 'Erreur export' });
  }
});
```

---

## 7. Audit Modération — Complétion

```javascript
// Vérifier et s'assurer que ces routes existent :
// GET  /api/admin/signalements              → liste avec détails
// PATCH /api/admin/signalements/:id         → traiter/ignorer/urgent
// POST  /api/signalements                  → créer (côté public)

// Ajouter : GET /api/admin/signalements/:id (détail)
router.get('/:id', async (req, res) => {
  try {
    const { supabase } = require('../../config/supabase');
    const { data, error } = await supabase
      .from('signalements')
      .select(`
        *,
        signalant:utilisateur_signalant_id (nom, email, role),
        admin_traitant:admin_traitant_id (nom, email)
      `)
      .eq('id', req.params.id)
      .single();

    if (error || !data) {
      return res.status(404).json({
        success: false, message: 'Signalement non trouvé'
      });
    }

    return res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});
```

---

## 8. Audit Paramètres — Complétion

```javascript
// Vérifier que ces routes existent et fonctionnent :
// GET /api/admin/parametres                → tous les paramètres groupés
// PUT /api/admin/parametres                → modifier batch
// POST /api/admin/parametres/vider-cache   → vider cache

// Ajouter : GET /api/admin/parametres/:cle (lire un paramètre spécifique)
router.get('/:cle', async (req, res) => {
  try {
    const { supabase } = require('../../config/supabase');
    const { data, error } = await supabase
      .from('parametres_plateforme')
      .select('*')
      .eq('cle', req.params.cle)
      .single();

    if (error || !data) {
      return res.status(404).json({
        success: false, message: 'Paramètre non trouvé'
      });
    }

    let valeur = data.valeur;
    if (data.type_valeur === 'boolean') valeur = data.valeur === 'true';
    if (data.type_valeur === 'integer') valeur = parseInt(data.valeur);

    return res.json({ success: true, data: { ...data, valeur } });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});
```

---

## 9. Audit Utilisateurs — Complétion

```javascript
// Vérifier que ces routes existent :
// GET    /api/admin/utilisateurs            → liste paginée + filtres
// GET    /api/admin/utilisateurs/:id        → détail complet
// PATCH  /api/admin/utilisateurs/:id        → toutes actions
// DELETE /api/admin/utilisateurs/:id        → suppression

// Ajouter export CSV utilisateurs
router.get('/export/csv', async (req, res) => {
  try {
    const { supabase } = require('../../config/supabase');
    const { data } = await supabase
      .from('utilisateurs')
      .select('nom, email, role, telephone, adresse, est_actif, est_valide, date_creation')
      .order('date_creation', { ascending: false });

    const lines = ['Nom,Email,Rôle,Téléphone,Adresse,Actif,Validé,Date inscription'];
    (data || []).forEach(u => {
      lines.push([
        `"${u.nom}"`, `"${u.email}"`, u.role,
        `"${u.telephone || ''}"`, `"${u.adresse || ''}"`,
        u.est_actif ? 'Oui' : 'Non',
        u.est_valide ? 'Oui' : 'Non',
        u.date_creation?.split('T')[0] || '',
      ].join(','));
    });

    const csv = lines.join('\n');
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition',
      'attachment; filename="utilisateurs_emploiconnect.csv"');
    return res.send('\uFEFF' + csv);
  } catch (err) {
    res.status(500).json({ success: false, message: 'Erreur export' });
  }
});
```

---

## 10. Tests Globaux — Checklist finale

### Ajouter dans AdminService Flutter les méthodes manquantes

```dart
// frontend/lib/services/admin_service.dart — COMPLÉTER

// Notifications
Future<Map<String, dynamic>> getMesNotifications(
  String token, {bool nonLuesSeulement = false}) async {
  final res = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/api/notifications/mes'
      '?non_lues_seulement=$nonLuesSeulement'),
    headers: _headers(token),
  );
  return _handleResponse(res);
}

Future<Map<String, dynamic>> marquerNotificationLue(
  String token, String id) async {
  final res = await http.patch(
    Uri.parse('${ApiConfig.baseUrl}/api/notifications/$id'),
    headers: _headers(token),
  );
  return _handleResponse(res);
}

Future<Map<String, dynamic>> marquerToutesNotificationsLues(
  String token) async {
  final res = await http.patch(
    Uri.parse('${ApiConfig.baseUrl}/api/notifications/tout-lire/action'),
    headers: _headers(token),
  );
  return _handleResponse(res);
}

Future<Map<String, dynamic>> supprimerNotification(
  String token, String id) async {
  final res = await http.delete(
    Uri.parse('${ApiConfig.baseUrl}/api/notifications/$id'),
    headers: _headers(token),
  );
  return _handleResponse(res);
}

// Recherche globale
Future<Map<String, dynamic>> rechercheGlobale(
  String token, String query) async {
  final res = await http.get(
    Uri.parse('$_base/recherche?q=${Uri.encodeComponent(query)}'),
    headers: _headers(token),
  );
  return _handleResponse(res);
}

// Export CSV
Future<void> exportStatistiques(String token, {String periode = '30d'}) async {
  // Sur Flutter Web : ouvrir l'URL dans le navigateur
  // Sur mobile : télécharger et sauvegarder
  final url = '${ApiConfig.baseUrl}/api/admin/statistiques/export'
      '?periode=$periode';
  // Utiliser url_launcher pour ouvrir l'URL
  await launchUrl(Uri.parse(url));
}

// Détail entreprise
Future<Map<String, dynamic>> getEntrepriseDetail(
  String token, String utilisateurId) async {
  final res = await http.get(
    Uri.parse('$_base/entreprises/$utilisateurId'),
    headers: _headers(token),
  );
  return _handleResponse(res);
}
```

### Tests à effectuer dans cet ordre

```
ORDRE DE TEST :

1. ✅ GET  /api/admin/dashboard          → données temps réel
2. ✅ GET  /api/admin/statistiques?periode=30d → KPIs + évolution
3. ✅ GET  /api/admin/statistiques/export → téléchargement CSV
4. ✅ GET  /api/notifications/mes        → notifications de l'admin
5. ✅ PATCH /api/notifications/tout-lire/action → marquer toutes lues
6. ✅ GET  /api/admin/recherche?q=orange → résultats multi-types
7. ✅ GET  /api/admin/utilisateurs?statut=bloque → users bloqués
8. ✅ GET  /api/admin/utilisateurs/export/csv → CSV users
9. ✅ GET  /api/admin/offres?statut=en_attente → offres à valider
10. ✅ GET  /api/admin/offres/export/csv  → CSV offres
11. ✅ GET  /api/admin/entreprises        → liste avec offres count
12. ✅ GET  /api/admin/entreprises/:id   → détail entreprise
13. ✅ GET  /api/admin/candidatures/export → CSV candidatures
14. ✅ GET  /api/admin/signalements?statut=urgent → urgents
15. ✅ GET  /api/admin/parametres        → tous groupés
16. ✅ PUT  /api/admin/parametres        → modifier un paramètre
17. ✅ POST /api/admin/notifications     → envoyer à tous
18. ✅ GET  /api/admin/profil            → profil admin connecté
19. ✅ PATCH /api/admin/profil           → modifier nom/tel
```

### Vérifications Flutter

```
VÉRIFIER DANS L'APP :

1. ✅ Badge notifications dans TopBar = nombre réel de non lues
2. ✅ Clic sur la cloche → page notifications avec vraies données
3. ✅ Marquer comme lu → badge diminue en temps réel
4. ✅ Recherche globale → résultats apparaissent après 400ms
5. ✅ Résultat cliqué → navigation vers la bonne page
6. ✅ Stat cards dashboard = données temps réel (pas de 1284 hardcodé)
7. ✅ Graphique statistiques = courbes avec données réelles
8. ✅ Sélecteur période (7d/30d/3m) → graphique se met à jour
9. ✅ Bouton Export CSV → téléchargement démarre
10. ✅ Filtres candidatures (statut/entreprise/dates) → résultats filtrés
11. ✅ Aucun RenderFlex overflow sur 375px (mobile)
12. ✅ Pull-to-refresh sur toutes les listes
```

---

*PRD EmploiConnect v3.2 — Audit & Complétion Backend Admin*
*Cursor / Kirsoft AI — Phase 7.2*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
