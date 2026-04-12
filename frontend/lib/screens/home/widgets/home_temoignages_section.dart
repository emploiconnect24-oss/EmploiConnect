import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_design_tokens.dart';

/// Témoignages en grille de petites cartes (fond blanc).
class HomeTemoignagesSection extends StatelessWidget {
  const HomeTemoignagesSection({super.key, required this.temoignages});

  final List<Map<String, dynamic>> temoignages;

  static const _defaut = <Map<String, dynamic>>[
    {
      'nom': 'Mamadou Barry',
      'poste': 'Développeur · Conakry',
      'message': 'EmploiConnect m\'a aidé à trouver mon emploi en 2 semaines. '
          'L\'IA a parfaitement compris mon profil !',
    },
    {
      'nom': 'Fatoumata Diallo',
      'poste': 'Comptable · Kindia',
      'message': 'Interface très intuitive et les offres sont vraiment adaptées à mon domaine. Je recommande !',
    },
    {
      'nom': 'Ibrahim Camara',
      'poste': 'RH Manager · Conakry',
      'message': 'On a recruté 3 excellents profils grâce à EmploiConnect. Le matching IA est impressionnant.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.sizeOf(context).width < 700 ? 24.0 : 60.0;
    final list = temoignages.isEmpty ? _defaut : temoignages;

    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: 56),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: HomeDesign.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: HomeDesign.primary.withValues(alpha: 0.14)),
              ),
              child: Text(
                'Témoignages',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: HomeDesign.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ce que disent nos utilisateurs',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: HomeDesign.dark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [for (final t in list) _CarteTemoignage(temoignage: t)],
            ),
          ],
        ),
      ),
    );
  }
}

class _CarteTemoignage extends StatefulWidget {
  const _CarteTemoignage({required this.temoignage});

  final Map<String, dynamic> temoignage;

  @override
  State<_CarteTemoignage> createState() => _CarteTemoignageState();
}

class _CarteTemoignageState extends State<_CarteTemoignage> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnim = Tween<double>(begin: 1, end: 1.03).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.temoignage;
    final message = (t['message'] ?? '').toString();
    final nom = (t['nom'] ?? '').toString();
    final poste = (t['poste'] ?? '').toString();
    final photo = t['photo']?.toString();
    final hasPhoto = photo != null && photo.isNotEmpty;
    final initial = nom.isNotEmpty ? nom[0].toUpperCase() : '?';

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _ctrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _ctrl.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered ? HomeDesign.primary.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered ? HomeDesign.primary.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.04),
                blurRadius: _hovered ? 20 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(
                  5,
                  (_) => const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '"$message"',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF374151),
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: HomeDesign.primary.withValues(alpha: 0.1),
                    backgroundImage: hasPhoto ? NetworkImage(photo) : null,
                    child: hasPhoto
                        ? null
                        : Text(
                            initial,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: HomeDesign.primary,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nom,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: HomeDesign.dark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          poste,
                          style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
