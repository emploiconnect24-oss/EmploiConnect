import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/public_site_service.dart';
import '../../../shared/widgets/section_header.dart';

/// Témoignages de candidats recrutés (vitrine).
class SuccessStoriesSectionWidget extends StatefulWidget {
  const SuccessStoriesSectionWidget({super.key});

  @override
  State<SuccessStoriesSectionWidget> createState() => _SuccessStoriesSectionWidgetState();
}

class _SuccessStoriesSectionWidgetState extends State<SuccessStoriesSectionWidget> {
  final _svc = PublicSiteService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _svc.getTemoignagesPublic(limit: 10);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 900;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 80, vertical: isMobile ? 36 : 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Ils ont été recrutés',
            subtitle:
                'Retours authentiques de candidats dont la candidature a été acceptée — parcours, entretien, intégration.',
          ),
          const SizedBox(height: 28),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              final list = snap.data ?? const [];
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Les premiers témoignages apparaîtront ici lorsque des candidats recrutés partageront leur expérience.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF64748B), height: 1.5),
                  ),
                );
              }
              return LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  final cardW = w >= 1100 ? (w - 48) / 3 : (w >= 700 ? (w - 24) / 2 : w);
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final t in list)
                        SizedBox(
                          width: cardW.clamp(280.0, 420.0),
                          child: _StoryCard(data: t),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final nom = (data['candidat_nom'] ?? 'Candidat').toString();
    final ent = (data['entreprise_nom'] ?? '').toString();
    final msg = (data['message'] ?? '').toString();
    final photo = (data['candidat_photo_url'] ?? '').toString().trim();
    final logo = (data['entreprise_logo_url'] ?? '').toString().trim();

    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF1A56DB).withValues(alpha: 0.12),
                  backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                  child: photo.isEmpty
                      ? Text(
                          nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A56DB),
                            fontSize: 22,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nom,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (logo.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                logo,
                                width: 22,
                                height: 22,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const SizedBox.shrink(),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              ent.isEmpty ? 'Entreprise partenaire' : 'Recruté(e) chez $ent',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A56DB),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '« $msg »',
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.55,
                color: const Color(0xFF334155),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
