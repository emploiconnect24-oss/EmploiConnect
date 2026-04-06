import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../admin_jobs_screen.dart';
import '../pages/user_detail_page.dart';

class EntrepriseActionsMenu extends StatelessWidget {
  const EntrepriseActionsMenu({
    super.key,
    required this.entreprise,
    required this.onRefresh,
  });

  final Map<String, dynamic> entreprise;
  final Future<void> Function() onRefresh;

  Map<String, dynamic>? _user() {
    final u = entreprise['utilisateurs'];
    if (u is Map) return Map<String, dynamic>.from(u);
    if (u is List && u.isNotEmpty && u.first is Map) {
      return Map<String, dynamic>.from(u.first as Map);
    }
    return null;
  }

  bool get _estActif => _user()?['est_actif'] == true;
  bool get _estValide => _user()?['est_valide'] == true;

  String get _entrepriseId => entreprise['id']?.toString() ?? '';
  String? get _userId => _user()?['id']?.toString();

  Future<void> _patch(BuildContext context, String action, {String? raison}) async {
    if (_entrepriseId.isEmpty) return;
    try {
      await AdminService().patchEntrepriseAdmin(_entrepriseId, action: action, raison: raison);
      await onRefresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action effectuée'), backgroundColor: Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  Future<void> _delete(BuildContext context) async {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return;
    try {
      await AdminService().deleteUtilisateur(uid);
      await onRefresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compte supprimé'), backgroundColor: Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  void _openUserProfil(BuildContext context) {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => UserDetailPage(userId: uid)),
    );
  }

  void _openOffres(BuildContext context) {
    if (_entrepriseId.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Offres de l’entreprise')),
          body: AdminJobsScreen(filterEntrepriseId: _entrepriseId),
        ),
      ),
    );
  }

  Future<void> _raisonDialog(
    BuildContext context, {
    required String title,
    required String action,
    required String confirmLabel,
  }) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Raison obligatoire'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(confirmLabel)),
        ],
      ),
    );
    if (ok != true) return;
    final r = ctrl.text.trim();
    if (r.isEmpty) return;
    await _patch(context, action, raison: r);
  }

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color color,
    required Future<void> Function() onOk,
  }) async {
    final v = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (v == true) await onOk();
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = !_estValide
        ? 'En attente'
        : _estActif
            ? 'Actif'
            : 'Suspendu';

    return PopupMenuButton<String>(
      tooltip: 'Actions',
      icon: const Icon(Icons.more_vert_outlined),
      onSelected: (v) async {
        switch (v) {
          case 'profil':
            _openUserProfil(context);
            break;
          case 'jobs':
            _openOffres(context);
            break;
          case 'valider':
            await _patch(context, 'valider');
            break;
          case 'rejeter':
            await _raisonDialog(context, title: 'Rejeter cette entreprise ?', action: 'rejeter', confirmLabel: 'Rejeter');
            break;
          case 'suspendre':
            await _raisonDialog(context, title: 'Suspendre cette entreprise ?', action: 'suspendre', confirmLabel: 'Suspendre');
            break;
          case 'lever':
            await _confirm(
              context,
              title: 'Lever la suspension ?',
              message: 'L’entreprise pourra à nouveau publier des offres.',
              confirmLabel: 'Lever la suspension',
              color: const Color(0xFF10B981),
              onOk: () => _patch(context, 'lever_suspension'),
            );
            break;
          case 'delete':
            await _confirm(
              context,
              title: 'Supprimer ce compte entreprise ?',
              message: 'Action irréversible (compte utilisateur lié).',
              confirmLabel: 'Supprimer',
              color: const Color(0xFFEF4444),
              onOk: () => _delete(context),
            );
            break;
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'profil',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.business_outlined, color: Color(0xFF1A56DB)),
              title: Text('Voir le profil complet'),
            ),
          ),
          const PopupMenuItem<String>(
            value: 'jobs',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.work_outline, color: Color(0xFF64748B)),
              title: Text('Voir les offres'),
            ),
          ),
        ];
        if (statusLabel == 'En attente') {
          items.addAll(const [
            PopupMenuItem<String>(
              value: 'valider',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.check_circle_outline, color: Color(0xFF10B981)),
                title: Text('Valider l’entreprise'),
              ),
            ),
            PopupMenuItem<String>(
              value: 'rejeter',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.cancel_outlined, color: Color(0xFFF59E0B)),
                title: Text('Rejeter'),
              ),
            ),
          ]);
        }
        if (statusLabel == 'Actif') {
          items.add(
            const PopupMenuItem<String>(
              value: 'suspendre',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.pause_circle_outline, color: Color(0xFFF59E0B)),
                title: Text('Suspendre'),
              ),
            ),
          );
        }
        if (statusLabel == 'Suspendu') {
          items.add(
            const PopupMenuItem<String>(
              value: 'lever',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.play_circle_outline, color: Color(0xFF10B981)),
                title: Text('Lever la suspension'),
              ),
            ),
          );
        }
        items.addAll(const [
          PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'delete',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
              title: Text('Supprimer définitivement', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
            ),
          ),
        ]);
        return items;
      },
    );
  }
}
