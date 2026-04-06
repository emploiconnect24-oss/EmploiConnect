import 'package:flutter/material.dart';

import '../services/signalements_service.dart';

/// Affiche un dialogue pour envoyer un signalement (`POST /signalements`).
/// [typeObjet] : `offre` | `profil` | `candidature` (doit correspondre au backend).
Future<void> showSignalementContentDialog(
  BuildContext context, {
  required String typeObjet,
  required String objetId,
  required String dialogTitle,
  String? description,
}) async {
  final trimmedId = objetId.trim();
  if (trimmedId.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de signaler : identifiant manquant.')),
      );
    }
    return;
  }

  final raisonCtrl = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.flag_outlined, color: Theme.of(ctx).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(dialogTitle)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description != null && description.isNotEmpty) ...[
              Text(description, style: TextStyle(fontSize: 13, color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: raisonCtrl,
              decoration: const InputDecoration(
                labelText: 'Décrivez le problème',
                hintText: 'Minimum 10 caractères (contenu inapproprié, fraude, etc.)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              maxLength: 1000,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        FilledButton.icon(
          onPressed: () => Navigator.pop(ctx, true),
          icon: const Icon(Icons.send_outlined, size: 18),
          label: const Text('Envoyer le signalement'),
        ),
      ],
    ),
  );

  if (ok != true || !context.mounted) {
    raisonCtrl.dispose();
    return;
  }

  final r = raisonCtrl.text.trim();
  raisonCtrl.dispose();

  if (r.length < 10) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La description doit contenir au moins 10 caractères.')),
      );
    }
    return;
  }

  try {
    await SignalementsService().signaler(
      typeObjet: typeObjet,
      objetId: trimmedId,
      raison: r,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Signalement transmis. L’équipe de modération en sera informée.'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
