import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dialogs ajout / édition — page profil (PRD §5).
Future<Map<String, String>?> showProfilExperienceDialog(
  BuildContext context, {
  Map<String, String>? existing,
}) async {
  final posteCtrl = TextEditingController(text: existing?['poste'] ?? '');
  final entCtrl = TextEditingController(text: existing?['entreprise'] ?? '');
  final villeCtrl = TextEditingController(text: existing?['ville'] ?? 'Conakry');
  final periodeCtrl = TextEditingController(text: existing?['periode'] ?? '');
  final missionCtrl = TextEditingController(text: existing?['mission'] ?? '');

  final result = await showDialog<Map<String, String>>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        existing == null ? 'Ajouter une expérience' : 'Modifier l\'expérience',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: posteCtrl,
              decoration: const InputDecoration(labelText: 'Poste *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: entCtrl,
              decoration: const InputDecoration(labelText: 'Entreprise *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: villeCtrl,
              decoration: const InputDecoration(labelText: 'Ville'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: periodeCtrl,
              decoration: const InputDecoration(labelText: 'Période (ex. 2023 - 2026)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: missionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Missions',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        FilledButton(
          onPressed: () {
            if (posteCtrl.text.trim().isEmpty || entCtrl.text.trim().isEmpty) return;
            Navigator.pop(ctx, {
              'poste': posteCtrl.text.trim(),
              'entreprise': entCtrl.text.trim(),
              'ville': villeCtrl.text.trim(),
              'periode': periodeCtrl.text.trim(),
              'mission': missionCtrl.text.trim(),
            });
          },
          child: Text(existing == null ? 'Ajouter' : 'Enregistrer'),
        ),
      ],
    ),
  );
  posteCtrl.dispose();
  entCtrl.dispose();
  villeCtrl.dispose();
  periodeCtrl.dispose();
  missionCtrl.dispose();
  return result;
}

Future<Map<String, String>?> showProfilCompetenceDialog(
  BuildContext context, {
  Map<String, String>? existing,
}) async {
  const levels = ['Débutant', 'Intermédiaire', 'Expert'];
  final ctrl = TextEditingController(text: existing?['name'] ?? '');
  var niveau = existing?['level'] ?? 'Intermédiaire';
  if (!levels.contains(niveau)) niveau = 'Intermédiaire';

  final result = await showDialog<Map<String, String>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          existing == null ? 'Ajouter une compétence' : 'Modifier la compétence',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(labelText: 'Compétence *', hintText: 'Ex. Flutter'),
            ),
            const SizedBox(height: 12),
            Text('Niveau', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: levels.map((n) {
                final sel = niveau == n;
                return ChoiceChip(
                  label: Text(n),
                  selected: sel,
                  onSelected: (_) => setS(() => niveau = n),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, {'name': ctrl.text.trim(), 'level': niveau});
            },
            child: Text(existing == null ? 'Ajouter' : 'Enregistrer'),
          ),
        ],
      ),
    ),
  );
  ctrl.dispose();
  return result;
}

Future<Map<String, String>?> showProfilFormationDialog(
  BuildContext context, {
  Map<String, String>? existing,
}) async {
  final dipCtrl = TextEditingController(text: existing?['diplome'] ?? '');
  final ecoleCtrl = TextEditingController(text: existing?['ecole'] ?? '');
  final villeCtrl = TextEditingController(text: existing?['ville'] ?? '');
  final anneeCtrl = TextEditingController(text: existing?['annee'] ?? '');

  final result = await showDialog<Map<String, String>>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        existing == null ? 'Ajouter une formation' : 'Modifier la formation',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: dipCtrl, decoration: const InputDecoration(labelText: 'Diplôme *')),
            const SizedBox(height: 10),
            TextField(controller: ecoleCtrl, decoration: const InputDecoration(labelText: 'Établissement *')),
            const SizedBox(height: 10),
            TextField(controller: villeCtrl, decoration: const InputDecoration(labelText: 'Ville')),
            const SizedBox(height: 10),
            TextField(controller: anneeCtrl, decoration: const InputDecoration(labelText: 'Année')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        FilledButton(
          onPressed: () {
            if (dipCtrl.text.trim().isEmpty || ecoleCtrl.text.trim().isEmpty) return;
            Navigator.pop(ctx, {
              'diplome': dipCtrl.text.trim(),
              'ecole': ecoleCtrl.text.trim(),
              'ville': villeCtrl.text.trim(),
              'annee': anneeCtrl.text.trim(),
            });
          },
          child: Text(existing == null ? 'Ajouter' : 'Enregistrer'),
        ),
      ],
    ),
  );
  dipCtrl.dispose();
  ecoleCtrl.dispose();
  villeCtrl.dispose();
  anneeCtrl.dispose();
  return result;
}

Future<Map<String, String>?> showProfilLangueDialog(
  BuildContext context, {
  Map<String, String>? existing,
}) async {
  const levels = ['Notions', 'Intermédiaire', 'Courant'];
  final ctrl = TextEditingController(text: existing?['name'] ?? '');
  var niveau = existing?['level'] ?? 'Intermédiaire';
  if (!levels.contains(niveau)) niveau = 'Intermédiaire';

  final result = await showDialog<Map<String, String>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          existing == null ? 'Ajouter une langue' : 'Modifier la langue',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(labelText: 'Langue *'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: levels.map((n) {
                final sel = niveau == n;
                return ChoiceChip(
                  label: Text(n),
                  selected: sel,
                  onSelected: (_) => setS(() => niveau = n),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, {'name': ctrl.text.trim(), 'level': niveau});
            },
            child: Text(existing == null ? 'Ajouter' : 'Enregistrer'),
          ),
        ],
      ),
    ),
  );
  ctrl.dispose();
  return result;
}
