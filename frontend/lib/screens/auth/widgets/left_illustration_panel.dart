import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/logo_widget.dart';

class LeftIllustrationPanel extends StatelessWidget {
  final String imageUrl;
  final String? quote;
  final String? authorName;
  final String? authorRole;
  final String? authorInitial;
  final List<Map<String, String>>? stats;
  final Widget? customContent;

  const LeftIllustrationPanel({
    super.key,
    required this.imageUrl,
    this.quote,
    this.authorName,
    this.authorRole,
    this.authorInitial,
    this.stats,
    this.customContent,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInLeft(
      duration: const Duration(milliseconds: 700),
      child: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF1A56DB)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: -80, right: -80, child: _decorCircle(320, 0.07)),
            Positioned(bottom: 80, left: -60, child: _decorCircle(220, 0.05)),
            Positioned(bottom: -40, right: 60, child: _decorCircle(140, 0.09)),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(44, 40, 44, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _whiteLogo(),
                    const SizedBox(height: 44),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        height: 240,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 240,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white54,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 240,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.image_outlined,
                            color: Colors.white24,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (customContent != null)
                      customContent!
                    else if (quote != null)
                      _quoteCard(),
                    if (stats != null) ...[
                      const SizedBox(height: 32),
                      _statsRow(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decorCircle(double size, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: opacity),
    ),
  );

  Widget _whiteLogo() => Row(
    children: [
      const LogoWidget(
        height: 36,
        fallbackTextColor: Colors.white,
        fallbackAccentColor: Color(0xFFBAE6FD),
      ),
    ],
  );

  Widget _quoteCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.format_quote_rounded, color: Colors.white38, size: 28),
        const SizedBox(height: 8),
        Text(
          quote!,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 14,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF1A56DB),
              child: Text(
                authorInitial ?? (authorName?.substring(0, 1) ?? 'A'),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authorName ?? '',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  authorRole ?? '',
                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );

  Widget _statsRow() => Row(
    children: stats!
        .map(
          (s) => Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s['value'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  s['label'] ?? '',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white60),
                ),
              ],
            ),
          ),
        )
        .toList(),
  );
}
