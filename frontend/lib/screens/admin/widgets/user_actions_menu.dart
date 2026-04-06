import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../pages/user_detail_page.dart';

class UserActionsMenu extends StatelessWidget {
  const UserActionsMenu({
    super.key,
    required this.user,
    required this.onRefresh,
  });

  final Map<String, dynamic> user;
  final Future<void> Function() onRefresh;

  bool get _estActif => user['est_actif'] == true;
  bool get _estValide => user['est_valide'] == true;
  bool get _estBloque => _estValide && !_estActif;
  bool get _estAttente => !_estValide;

  Future<void> _patch(BuildContext context, String action, {String? raison}) async {
    final id = user['id']?.toString();
    if (id == null || id.isEmpty) return;
    try {
      await AdminService().patchUtilisateur(id, action: action, raison: raison);
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
    final id = user['id']?.toString();
    if (id == null || id.isEmpty) return;
    try {
      await AdminService().deleteUtilisateur(id);
      await onRefresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur supprimé'), backgroundColor: Color(0xFF10B981)),
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

  void _openProfil(BuildContext context) {
    final id = user['id']?.toString();
    if (id == null || id.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => UserDetailPage(userId: id)),
    );
  }

  Future<void> _bloquerDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bloquer ce compte'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Raison obligatoire'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Bloquer')),
        ],
      ),
    );
    if (ok != true) return;
    final r = ctrl.text.trim();
    if (r.isEmpty) return;
    await _patch(context, 'bloquer', raison: r);
  }

  Future<void> _rejeterDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter ce compte'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Raison (optionnel)'),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Rejeter')),
        ],
      ),
    );
    if (ok != true) return;
    final r = ctrl.text.trim();
    await _patch(context, 'rejeter', raison: r.isEmpty ? null : r);
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
    return PopupMenuButton<String>(
      tooltip: 'Actions',
      icon: const Icon(Icons.more_vert_outlined),
      onSelected: (v) async {
        switch (v) {
          case 'profil':
            _openProfil(context);
            break;
          case 'valider':
            await _patch(context, 'valider');
            break;
          case 'rejeter':
            await _rejeterDialog(context);
            break;
          case 'bloquer':
            await _bloquerDialog(context);
            break;
          case 'debloquer':
            await _confirm(
              context,
              title: 'Débloquer ce compte ?',
              message: 'L’utilisateur retrouvera l’accès à la plateforme.',
              confirmLabel: 'Débloquer',
              color: const Color(0xFF10B981),
              onOk: () => _patch(context, 'debloquer'),
            );
            break;
          case 'motif':
            if (!context.mounted) return;
            showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Motif du blocage'),
                content: Text(user['raison_blocage']?.toString() ?? 'Non précisé'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
                ],
              ),
            );
            break;
          case 'delete':
            await _confirm(
              context,
              title: 'Supprimer cet utilisateur ?',
              message: 'Action irréversible.',
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
              leading: Icon(Icons.person_outlined, color: Color(0xFF1A56DB)),
              title: Text('Voir le profil complet'),
            ),
          ),
        ];
        if (_estAttente) {
          items.addAll(const [
            PopupMenuItem<String>(
              value: 'valider',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.check_circle_outline, color: Color(0xFF10B981)),
                title: Text('Valider le compte'),
              ),
            ),
            PopupMenuItem<String>(
              value: 'rejeter',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.cancel_outlined, color: Color(0xFFF59E0B)),
                title: Text('Rejeter le compte'),
              ),
            ),
          ]);
        }
        if (_estActif && _estValide) {
          items.add(
            const PopupMenuItem<String>(
              value: 'bloquer',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.block_outlined, color: Color(0xFFF59E0B)),
                title: Text('Bloquer le compte'),
              ),
            ),
          );
        }
        if (_estBloque) {
          items.add(
            const PopupMenuItem<String>(
              value: 'debloquer',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.lock_open_outlined, color: Color(0xFF10B981)),
                title: Text('Débloquer le compte'),
              ),
            ),
          );
          final raison = user['raison_blocage']?.toString().trim() ?? '';
          if (raison.isNotEmpty) {
            items.add(
              const PopupMenuItem<String>(
                value: 'motif',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.info_outlined, color: Color(0xFF94A3B8)),
                  title: Text('Voir motif du blocage'),
                ),
              ),
            );
          }
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
