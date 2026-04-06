import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../../entreprise/offre_form_screen.dart';
import '../admin_offre_detail_screen.dart';

/// Menu actions offre admin selon `statut` et `en_vedette`.
class OffreActionsMenu extends StatelessWidget {
  const OffreActionsMenu({
    super.key,
    required this.offre,
    required this.onRefresh,
  });

  final Map<String, dynamic> offre;
  final Future<void> Function() onRefresh;

  String get _raw => (offre['statut']?.toString() ?? '').toLowerCase().trim();
  bool get _ved => offre['en_vedette'] == true;

  Future<void> _patch(BuildContext context, String action, {String? raisonRefus}) async {
    final id = offre['id']?.toString();
    if (id == null || id.isEmpty) return;
    try {
      await AdminService().patchOffreAdmin(id, action: action, raisonRefus: raisonRefus);
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
    final id = offre['id']?.toString();
    if (id == null || id.isEmpty) return;
    try {
      await AdminService().deleteOffreAdmin(id);
      await onRefresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offre supprimée'), backgroundColor: Color(0xFF10B981)),
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

  void _openDetail(BuildContext context) {
    final id = offre['id']?.toString();
    if (id == null || id.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => AdminOffreDetailScreen(offreId: id)),
    );
  }

  Future<void> _openEdit(BuildContext context) async {
    final id = offre['id']?.toString();
    if (id == null || id.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => OffreFormScreen(offreId: id)),
    );
    await onRefresh();
  }

  Future<void> _refuserDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refuser l’offre'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Motif obligatoire'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Refuser')),
        ],
      ),
    );
    if (ok != true) return;
    final r = ctrl.text.trim();
    if (r.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le motif est obligatoire.')),
        );
      }
      return;
    }
    await _patch(context, 'refuser', raisonRefus: r);
  }

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required Future<void> Function() onConfirm,
  }) async {
    final v = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: confirmColor, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (v == true) await onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Actions',
      icon: const Icon(Icons.more_vert_outlined),
      onSelected: (v) async {
        switch (v) {
          case 'detail':
            _openDetail(context);
            break;
          case 'edit':
            await _openEdit(context);
            break;
          case 'valider':
            await _patch(context, 'valider');
            break;
          case 'refuser':
            await _refuserDialog(context);
            break;
          case 'vedette_on':
            await _patch(context, 'mettre_en_vedette');
            break;
          case 'vedette_off':
            await _patch(context, 'retirer_vedette');
            break;
          case 'archiver':
            await _confirm(
              context,
              title: 'Archiver cette offre ?',
              message: 'L’offre ne sera plus visible pour les candidats.',
              confirmLabel: 'Archiver',
              confirmColor: const Color(0xFF94A3B8),
              onConfirm: () => _patch(context, 'archiver'),
            );
            break;
          case 'desarchiver':
            await _confirm(
              context,
              title: 'Désarchiver cette offre ?',
              message: 'L’offre sera republiée.',
              confirmLabel: 'Désarchiver',
              confirmColor: const Color(0xFF1A56DB),
              onConfirm: () => _patch(context, 'desarchiver'),
            );
            break;
          case 'republier':
            await _patch(context, 'republier');
            break;
          case 'delete':
            await _confirm(
              context,
              title: 'Supprimer cette offre ?',
              message: 'Action irréversible.',
              confirmLabel: 'Supprimer',
              confirmColor: const Color(0xFFEF4444),
              onConfirm: () => _delete(context),
            );
            break;
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'detail',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.visibility_outlined, color: Color(0xFF64748B)),
              title: Text('Voir les détails'),
            ),
          ),
        ];

        if (_raw == 'en_attente' || _raw == 'brouillon') {
          items.addAll(const [
            PopupMenuItem<String>(
              value: 'valider',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.check_circle_outline, color: Color(0xFF10B981)),
                title: Text('Valider et publier'),
              ),
            ),
            PopupMenuItem<String>(
              value: 'refuser',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.cancel_outlined, color: Color(0xFFEF4444)),
                title: Text('Refuser'),
              ),
            ),
          ]);
        }

        if (_raw == 'active' || _raw == 'publiee' || _raw == 'publiée') {
          items.add(
            PopupMenuItem<String>(
              value: _ved ? 'vedette_off' : 'vedette_on',
              child: ListTile(
                dense: true,
                leading: Icon(
                  _ved ? Icons.star_border_outlined : Icons.star_outlined,
                  color: const Color(0xFFF59E0B),
                ),
                title: Text(_ved ? 'Retirer de la vedette' : 'Mettre en vedette'),
              ),
            ),
          );
          items.add(
            const PopupMenuItem<String>(
              value: 'archiver',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.archive_outlined, color: Color(0xFF94A3B8)),
                title: Text('Archiver'),
              ),
            ),
          );
        }

        if (_raw == 'suspendue' || _raw == 'refusee' || _raw == 'refusée') {
          items.add(
            const PopupMenuItem<String>(
              value: 'republier',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.refresh_outlined, color: Color(0xFF10B981)),
                title: Text('Republier'),
              ),
            ),
          );
        }

        if (_raw == 'fermee') {
          items.add(
            const PopupMenuItem<String>(
              value: 'desarchiver',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.unarchive_outlined, color: Color(0xFF1A56DB)),
                title: Text('Désarchiver (republier)'),
              ),
            ),
          );
        }

        items.addAll(const [
          PopupMenuItem<String>(
            value: 'edit',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.edit_outlined),
              title: Text('Modifier'),
            ),
          ),
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
