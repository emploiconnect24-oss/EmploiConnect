import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_design_tokens.dart';

/// Bandeau défilant discret (`type_banniere == ticker`) — fond bleu très clair, sans bloc « INFO ».
class TickerBannieresWidget extends StatefulWidget {
  const TickerBannieresWidget({super.key, required this.bannieres});

  final List<Map<String, dynamic>> bannieres;

  @override
  State<TickerBannieresWidget> createState() => _TickerBannieresWidgetState();
}

class _TickerBannieresWidgetState extends State<TickerBannieresWidget> {
  late final ScrollController _scrollCtrl;
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
  }

  void _startAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!_scrollCtrl.hasClients) return;
      final max = _scrollCtrl.position.maxScrollExtent;
      final cur = _scrollCtrl.offset;
      if (max <= 0) return;
      if (cur >= max - 0.5) {
        _scrollCtrl.jumpTo(0);
      } else {
        _scrollCtrl.animateTo(
          cur + 1,
          duration: const Duration(milliseconds: 30),
          curve: Curves.linear,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final raw = widget.bannieres
        .map((b) => (b['titre'] ?? b['sous_titre'] ?? '').toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final items = raw.isEmpty ? <String>[] : [...raw, ...raw];

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: HomeDesign.tickerBg,
        border: Border(
          bottom: BorderSide(color: HomeDesign.primary.withValues(alpha: 0.08)),
        ),
      ),
      child: ListView.builder(
        controller: _scrollCtrl,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.isEmpty ? 1 : items.length,
        itemBuilder: (ctx, i) {
          if (items.isEmpty) {
            return _TickerItem(
              'EmploiConnect — Offres et talents en Guinée.',
            );
          }
          return _TickerItem(items[i]);
        },
      ),
    );
  }
}

class _TickerItem extends StatelessWidget {
  const _TickerItem(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: HomeDesign.primary.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            texte,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF475569),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 24),
          Container(
            width: 1,
            height: 16,
            color: HomeDesign.primary.withValues(alpha: 0.12),
          ),
        ],
      ),
    );
  }
}
