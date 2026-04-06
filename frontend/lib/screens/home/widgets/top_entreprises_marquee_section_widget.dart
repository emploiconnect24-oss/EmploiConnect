import 'package:flutter/material.dart';

import '../../../app/public_routes.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../services/public_site_service.dart';
import '../../../shared/widgets/section_header.dart';

const double _kMarqueeCardW = 240;
const double _kMarqueeGap = 16;
/// Hauteur fixe du bandeau (cartes + marquee) — évite RenderFlex overflow.
const double _kMarqueeRowH = 132;

/// Bandeau « Top entreprises » : une seule ligne, défilement horizontal infini (sans saut).
class TopEntreprisesMarqueeSectionWidget extends StatefulWidget {
  const TopEntreprisesMarqueeSectionWidget({super.key});

  @override
  State<TopEntreprisesMarqueeSectionWidget> createState() =>
      _TopEntreprisesMarqueeSectionWidgetState();
}

class _TopEntreprisesMarqueeSectionWidgetState extends State<TopEntreprisesMarqueeSectionWidget>
    with SingleTickerProviderStateMixin {
  final _svc = PublicSiteService();
  late Future<List<Map<String, dynamic>>> _future;
  late AnimationController _marquee;

  @override
  void initState() {
    super.initState();
    _future = _svc.getTopEntreprises(limit: 16);
    _marquee = AnimationController(vsync: this, duration: const Duration(seconds: 20));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!MediaQuery.disableAnimationsOf(context)) {
        _marquee.repeat();
      }
    });
  }

  @override
  void dispose() {
    _marquee.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 900;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF8FAFC),
            Color(0xFFEFF6FF),
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 80,
          vertical: isMobile ? 36 : 52,
        ),
        child: LayoutBuilder(
          builder: (context, outer) {
            final maxW = outer.maxWidth.isFinite && outer.maxWidth > 0
                ? outer.maxWidth
                : w;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(
                  title: 'Top entreprises recruteuses',
                  subtitle:
                      'Les employeurs les plus actifs sur la plateforme — cliquez pour voir leurs offres en un geste.',
                ),
                const SizedBox(height: 8),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A56DB).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFF1A56DB).withValues(alpha: 0.15)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.trending_up_rounded, size: 18, color: Color(0xFF1A56DB)),
                            SizedBox(width: 8),
                            Text(
                              'Classées par nombre d’offres publiées',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E40AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const SizedBox(
                        height: _kMarqueeRowH,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }
                    final raw = snap.data ?? const <Map<String, dynamic>>[];
                    if (raw.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Les entreprises les plus actives apparaîtront ici dès que des offres seront publiées.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF64748B), height: 1.45),
                        ),
                      );
                    }

                    if (reduceMotion) {
                      return _StaticRow(items: raw);
                    }

                    return MouseRegion(
                      onEnter: (_) {
                        if (reduceMotion) return;
                        _marquee.stop();
                      },
                      onExit: (_) {
                        if (reduceMotion) return;
                        if (!_marquee.isAnimating) _marquee.repeat();
                      },
                      child: SizedBox(
                        width: maxW,
                        child: _MarqueeLine(
                          controller: _marquee,
                          items: raw,
                          cardWidth: _kMarqueeCardW,
                          gap: _kMarqueeGap,
                          reverse: false,
                          height: _kMarqueeRowH,
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StaticRow extends StatelessWidget {
  const _StaticRow({required this.items});
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kMarqueeRowH,
      child: ClipRect(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: _kMarqueeGap),
                SizedBox(
                  width: _kMarqueeCardW,
                  height: _kMarqueeRowH,
                  child: _EntrepriseMarqueeCard(data: items[i]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MarqueeLine extends StatefulWidget {
  const _MarqueeLine({
    required this.controller,
    required this.items,
    required this.cardWidth,
    required this.gap,
    required this.reverse,
    required this.height,
  });

  final AnimationController controller;
  final List<Map<String, dynamic>> items;
  final double cardWidth;
  final double gap;
  final bool reverse;
  final double height;

  @override
  State<_MarqueeLine> createState() => _MarqueeLineState();
}

class _MarqueeLineState extends State<_MarqueeLine> {
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
    widget.controller.addListener(_syncScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncScroll());
  }

  @override
  void didUpdateWidget(covariant _MarqueeLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncScroll);
      widget.controller.addListener(_syncScroll);
    }
  }

  void _syncScroll() {
    if (!mounted) return;
    final n = widget.items.length;
    if (n == 0) return;
    final stripW = n * widget.cardWidth + (n - 1) * widget.gap;
    if (stripW <= 0) return;
    final period = stripW + widget.gap;
    if (!_scroll.hasClients) return;
    final v = widget.reverse ? (1.0 - widget.controller.value) : widget.controller.value;
    final target = v * period;
    final max = _scroll.position.maxScrollExtent;
    _scroll.jumpTo(target.clamp(0.0, max.isFinite ? max : 0.0));
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncScroll);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.items.length;
    if (n == 0) return const SizedBox.shrink();

    final stripW = n * widget.cardWidth + (n - 1) * widget.gap;
    if (stripW <= 0) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mqW = MediaQuery.sizeOf(context).width;
          final maxW = constraints.maxWidth.isFinite && constraints.maxWidth > 0
              ? constraints.maxWidth
              : mqW;
          return SizedBox(
            width: maxW,
            height: widget.height,
            child: ClipRect(
              clipBehavior: Clip.hardEdge,
              child: Stack(
                alignment: Alignment.centerLeft,
                clipBehavior: Clip.hardEdge,
                children: [
                  // ScrollView horizontal : le Row enfant a maxWidth = ∞ sur l’axe de défilement,
                  // donc plus d’overflow RenderFlex (contrairement à Stack/Transform/Row).
                  Positioned.fill(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      controller: _scroll,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildStrip(
                            widget.items,
                            widget.cardWidth,
                            widget.gap,
                            widget.height,
                          ),
                          SizedBox(width: widget.gap),
                          _buildStrip(
                            widget.items,
                            widget.cardWidth,
                            widget.gap,
                            widget.height,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 56,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFF8FAFC),
                              const Color(0xFFF8FAFC).withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 56,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFF8FAFC).withValues(alpha: 0),
                              const Color(0xFFF8FAFC),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _buildStrip(
    List<Map<String, dynamic>> items,
    double cw,
    double g,
    double rowH,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(width: g),
          SizedBox(
            width: cw,
            height: rowH,
            child: _EntrepriseMarqueeCard(data: items[i]),
          ),
        ],
      ],
    );
  }
}

class _EntrepriseMarqueeCard extends StatelessWidget {
  const _EntrepriseMarqueeCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final id = data['id']?.toString() ?? '';
    final nom = data['nom_entreprise']?.toString().trim().isNotEmpty == true
        ? data['nom_entreprise'].toString()
        : 'Entreprise';
    final nb = data['nb_offres'];
    final nbStr = nb is int ? '$nb' : (int.tryParse(nb?.toString() ?? '')?.toString() ?? '0');
    final logo = data['logo_url']?.toString().trim() ?? '';

    return LayoutBuilder(
      builder: (context, constraints) {
        final boxW = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : _kMarqueeCardW;
        final boxH = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : _kMarqueeRowH;

        return Material(
          color: Colors.white,
          elevation: 0,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            onTap: id.isEmpty
                ? null
                : () {
                    Navigator.of(context).pushNamed(
                      PublicRoutes.listForEntreprise(entrepriseId: id, nomEntreprise: nom),
                    );
                  },
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SizedBox(
                width: boxW,
                height: boxH,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _LogoThumb(url: logo, fallback: nom.isNotEmpty ? nom[0].toUpperCase() : '?'),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              nom,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: Color(0xFF0F172A),
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.work_outline_rounded, size: 13, color: scheme.primary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '$nbStr offre${nbStr == '1' ? '' : 's'} en ligne',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: scheme.primary,
                                    ),
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LogoThumb extends StatelessWidget {
  const _LogoThumb({required this.url, required this.fallback});

  final String url;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: context.themeExt.sectionBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? Center(
              child: Text(
                fallback,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A56DB),
                  fontSize: 18,
                ),
              ),
            )
          : Image.network(
              url,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  fallback,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A56DB),
                    fontSize: 18,
                  ),
                ),
              ),
            ),
    );
  }
}
