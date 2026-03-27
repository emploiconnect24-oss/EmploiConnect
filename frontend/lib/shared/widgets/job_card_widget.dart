import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'contract_badge.dart';

class JobCardWidget extends StatefulWidget {
  const JobCardWidget({
    super.key,
    required this.job,
    this.onTap,
  });

  final Map<String, dynamic> job;
  final VoidCallback? onTap;

  @override
  State<JobCardWidget> createState() => _JobCardWidgetState();
}

class _JobCardWidgetState extends State<JobCardWidget> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final titre = widget.job['title']?.toString() ?? 'Offre';
    final entreprise = widget.job['company']?.toString() ?? 'Entreprise';
    final localisation = widget.job['location']?.toString() ?? 'Guinée';
    final contrat = widget.job['contract']?.toString() ?? 'CDI';
    final description = widget.job['summary']?.toString() ?? '';
    final date = widget.job['date'] as DateTime? ?? DateTime.now();
    final initials = entreprise
        .split(' ')
        .where((e) => e.trim().isNotEmpty)
        .take(2)
        .map((e) => e.trim()[0].toUpperCase())
        .join();

    final relative = timeago.format(date, locale: 'fr_short');

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hover ? -6 : 0, 0),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _hover ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A56DB).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials.isEmpty ? 'EC' : initials,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF1A56DB),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          titre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _hover ? const Color(0xFF1A56DB) : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.apartment_outlined, size: 15, color: Color(0xFF64748B)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          entreprise,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 15, color: Color(0xFF64748B)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          localisation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ContractBadge(label: contrat),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF64748B), height: 1.45),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        relative,
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                      ),
                      const Spacer(),
                      Text(
                        'Voir les détails',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A56DB),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

