import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/theme_extension.dart';

class TipsCarouselWidget extends StatefulWidget {
  const TipsCarouselWidget({super.key});

  @override
  State<TipsCarouselWidget> createState() => _TipsCarouselWidgetState();
}

class _TipsCarouselWidgetState extends State<TipsCarouselWidget> {
  final ScrollController _controller = ScrollController();
  Timer? _timer;
  bool _paused = false;

  static const _cardW = 280.0;
  static const _cardH = 160.0;
  static const _gap = 14.0;
  static const _tick = Duration(milliseconds: 2800);

  final _tips = const <_TipCardData>[
    _TipCardData(
      audience: 'Candidat',
      title: 'Optimisez votre CV',
      tag: 'CV',
      icon: Icons.description_outlined,
    ),
    _TipCardData(
      audience: 'Candidat',
      title: 'Préparez vos entretiens',
      tag: 'Entretien',
      icon: Icons.record_voice_over_outlined,
    ),
    _TipCardData(
      audience: 'Candidat',
      title: 'Personnalisez vos lettres',
      tag: 'Motivation',
      icon: Icons.edit_note_outlined,
    ),
    _TipCardData(
      audience: 'Candidat',
      title: 'Activez votre réseau',
      tag: 'Réseau',
      icon: Icons.groups_outlined,
    ),
    _TipCardData(
      audience: 'Recruteur',
      title: 'Rédigez des offres claires',
      tag: 'Offres',
      icon: Icons.campaign_outlined,
    ),
    _TipCardData(
      audience: 'Recruteur',
      title: 'Répondez rapidement',
      tag: 'Process',
      icon: Icons.schedule_outlined,
    ),
    _TipCardData(
      audience: 'Recruteur',
      title: 'Valorisez votre marque',
      tag: 'Marque',
      icon: Icons.auto_awesome_outlined,
    ),
    _TipCardData(
      audience: 'Recruteur',
      title: 'Définissez vos critères',
      tag: 'Tri',
      icon: Icons.tune_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_tick, (_) => _autoScroll());
  }

  void _autoScroll() {
    if (_paused) return;
    if (!mounted || !_controller.hasClients) return;
    final max = _controller.position.maxScrollExtent;
    if (max <= 0) return;

    final next = (_controller.offset + (_cardW + _gap)).clamp(0.0, max);
    if (next >= max - 2) {
      _controller.animateTo(
        0,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
      );
    } else {
      _controller.animateTo(
        next,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 900;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      color: context.themeExt.sectionBg,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 80, vertical: isMobile ? 36 : 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Conseils & bonnes pratiques',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 26 : 34,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Des astuces concrètes pour candidats et recruteurs — à appliquer immédiatement.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: scheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 22),
            MouseRegion(
              onEnter: (_) => setState(() => _paused = true),
              onExit: (_) => setState(() => _paused = false),
              child: SizedBox(
                height: _cardH,
                child: ListView.separated(
                  controller: _controller,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _tips.length,
                  separatorBuilder: (context, index) => const SizedBox(width: _gap),
                  itemBuilder: (context, i) {
                    final t = _tips[i];
                    final isBlue = i.isEven;
                    final bg = isBlue ? const Color(0xFFDCEBFF) : const Color(0xFFD1FAE5);
                    final tint = isBlue ? const Color(0xFF1A56DB) : const Color(0xFF10B981);
                    return _TipCard(
                      data: t,
                      bg: bg,
                      tint: tint,
                      width: _cardW,
                      height: _cardH,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCardData {
  const _TipCardData({
    required this.audience,
    required this.title,
    required this.tag,
    required this.icon,
  });

  final String audience;
  final String title;
  final String tag;
  final IconData icon;
}

class _TipCard extends StatefulWidget {
  const _TipCard({
    required this.data,
    required this.bg,
    required this.tint,
    required this.width,
    required this.height,
  });

  final _TipCardData data;
  final Color bg;
  final Color tint;
  final double width;
  final double height;

  @override
  State<_TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<_TipCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.width,
        height: widget.height,
        transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: widget.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hover ? 0.10 : 0.06),
              blurRadius: _hover ? 22 : 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.data.icon, color: widget.tint),
                  ),
                  const Spacer(),
                  _Pill(
                    label: widget.data.audience,
                    bg: Colors.white.withValues(alpha: 0.75),
                  fg: scheme.onSurface,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.data.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const Spacer(),
              _Pill(
                label: widget.data.tag,
                bg: widget.tint.withValues(alpha: 0.14),
                fg: widget.tint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

