import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_design_tokens.dart';

/// PRD §9 — Lien rapide admin pour gérer les bannières (affiché aux admins connectés).
class HomeAdminBanniereStrip extends StatelessWidget {
  const HomeAdminBanniereStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomeDesign.dark,
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed('/admin'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.tune_rounded, color: Color(0xFF93C5FD), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Configurer les bannières (admin)',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}
