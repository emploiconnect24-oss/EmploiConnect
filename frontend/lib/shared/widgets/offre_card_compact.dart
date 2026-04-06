import 'package:flutter/material.dart';

class OffreCardCompact extends StatelessWidget {
  const OffreCardCompact({
    super.key,
    required this.offre,
    this.onPostuler,
    this.onSauvegarder,
    this.onIgnorer,
    this.estSauvegardee = false,
  });

  final Map<String, dynamic> offre;
  final VoidCallback? onPostuler;
  final VoidCallback? onSauvegarder;
  final VoidCallback? onIgnorer;
  final bool estSauvegardee;

  @override
  Widget build(BuildContext context) {
    final entreprise =
        (offre['entreprise'] as Map?)?.cast<String, dynamic>() ??
        (offre['entreprises'] as Map?)?.cast<String, dynamic>() ??
        {};
    final titre = (offre['titre'] ?? '').toString();
    final nomEnt = (entreprise['nom_entreprise'] ?? 'Entreprise').toString();
    final localisation = (offre['localisation'] ?? '').toString();
    final contrat = (offre['type_contrat'] ?? '').toString();
    final score = (offre['score_compatibilite'] as num?)?.round();
    final vedette = offre['en_vedette'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: vedette ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    nomEnt.isNotEmpty ? nomEnt[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A56DB),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      nomEnt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$localisation · $contrat',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              if (score != null && score > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '$score% IA',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A56DB),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (onIgnorer != null)
                IconButton(
                  onPressed: onIgnorer,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
              if (onSauvegarder != null)
                IconButton(
                  onPressed: onSauvegarder,
                  icon: Icon(
                    estSauvegardee ? Icons.bookmark : Icons.bookmark_border,
                  ),
                  color: estSauvegardee
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF64748B),
                  visualDensity: VisualDensity.compact,
                ),
              const Spacer(),
              if (onPostuler != null)
                FilledButton(
                  onPressed: onPostuler,
                  child: const Text('Postuler'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
