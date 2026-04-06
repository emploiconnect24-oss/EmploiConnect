import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Page de démonstration : explique les 3 briques IA et renvoie vers les recommandations.
class IADemoPage extends StatelessWidget {
  const IADemoPage({super.key, this.onOpenRecommandations});

  final VoidCallback? onOpenRecommandations;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Intelligence Artificielle',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Matching & Analyse CV',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Notre IA analyse votre profil et votre CV pour vous proposer '
              'les offres les plus adaptées à vos compétences.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _buildDemoCard(
              titre: '📄 Analyse de votre CV',
              description:
                  'L\'IA extrait automatiquement vos compétences depuis votre '
                  'CV pour améliorer vos scores de matching.',
              apiName: 'Resume Parser API',
              statut: '⏳ Après upload CV (Profil)',
              couleur: const Color(0xFF10B981),
            ),
            const SizedBox(height: 14),
            _buildDemoCard(
              titre: '🎯 Score de compatibilité',
              description:
                  'Chaque offre peut afficher un score de 0 à 100 % : comparaison '
                  'entre le texte de votre profil / CV et l’offre (similarité, '
                  'via Twinword Text Similarity sur RapidAPI, configurée côté serveur). '
                  'Vous le voyez dans la recherche d’offres, les recommandations et le détail d’une offre.',
              apiName: 'Twinword Text Similarity',
              statut: '✅ Liste d\'offres & recommandations',
              couleur: const Color(0xFF1A56DB),
            ),
            const SizedBox(height: 14),
            _buildDemoCard(
              titre: '⭐ Mots-clés des offres',
              description:
                  'Lors de la création d\'une offre, l\'IA enrichit les '
                  'compétences requises pour un matching plus précis.',
              apiName: 'Topic Tagging API',
              statut: '✅ Côté recruteur (création d\'offre)',
              couleur: const Color(0xFF8B5CF6),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: Text(
                  'Tester mon matching maintenant',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56DB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onOpenRecommandations,
              ),
            ),
          ],
        ),
      );

  Widget _buildDemoCard({
    required String titre,
    required String description,
    required String apiName,
    required String statut,
    required Color couleur,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.auto_awesome_rounded, color: couleur, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          apiName,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          statut,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: couleur,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
