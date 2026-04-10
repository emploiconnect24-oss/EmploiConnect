import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Barre complétion profil animée — dashboard (PRD §4).
class DashboardCompletionPolish extends StatefulWidget {
  const DashboardCompletionPolish({
    super.key,
    required this.pourcentage,
    required this.manquants,
    this.onTap,
  });

  final int pourcentage;
  final List<dynamic> manquants;
  final VoidCallback? onTap;

  @override
  State<DashboardCompletionPolish> createState() => _DashboardCompletionPolishState();
}

class _DashboardCompletionPolishState extends State<DashboardCompletionPolish>
    with TickerProviderStateMixin {
  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;
  AnimationController? _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnim = Tween<double>(begin: 0, end: (widget.pourcentage.clamp(0, 100)) / 100).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic),
    );
    _progressCtrl.forward();
    if (widget.pourcentage < 100) {
      _pulseCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      )..repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant DashboardCompletionPolish oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pourcentage != widget.pourcentage) {
      _progressCtrl.stop();
      _progressCtrl.reset();
      _progressAnim = Tween<double>(begin: 0, end: (widget.pourcentage.clamp(0, 100)) / 100).animate(
        CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic),
      );
      _progressCtrl.forward();
      if (widget.pourcentage >= 100) {
        _pulseCtrl?.dispose();
        _pulseCtrl = null;
      } else if (_pulseCtrl == null) {
        _pulseCtrl = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1600),
        )..repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _pulseCtrl?.dispose();
    super.dispose();
  }

  String _subtitleManquant() {
    final m = widget.manquants;
    if (m.isEmpty) return 'Complétez les champs manquants';
    final first = m.first;
    if (first is Map && first['label'] != null) return '${first['label']} manquant';
    return 'Informations à compléter';
  }

  @override
  Widget build(BuildContext context) {
    final pct = widget.pourcentage.clamp(0, 100);
    final isComplete = pct >= 100;

    final pulse = _pulseCtrl;
    Widget card = GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isComplete
                  ? [const Color(0xFF059669), const Color(0xFF10B981)]
                  : pct >= 70
                      ? [const Color(0xFF1A56DB), const Color(0xFF0EA5E9)]
                      : [const Color(0xFF7C3AED), const Color(0xFF1A56DB)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: (isComplete ? const Color(0xFF10B981) : const Color(0xFF1A56DB))
                    .withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isComplete ? Icons.verified_rounded : Icons.person_outline_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isComplete ? 'Profil complet !' : 'Complétez votre profil',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          isComplete
                              ? 'Vous avez de meilleures chances d\'être contacté'
                              : _subtitleManquant(),
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _progressCtrl,
                    builder: (context, _) => Text(
                      '${((_progressAnim.value) * 100).round()}%',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: _progressCtrl,
                builder: (context, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Stack(
                    children: [
                      Container(
                        height: 9,
                        width: double.infinity,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      FractionallySizedBox(
                        widthFactor: _progressAnim.value.clamp(0.0, 1.0),
                        child: Container(
                          height: 9,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isComplete) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Compléter maintenant',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A56DB),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF1A56DB)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
    );
    if (pulse != null && !isComplete) {
      return AnimatedBuilder(
        animation: pulse,
        builder: (context, child) {
          final s = 1.0 + (pulse.value - 0.5) * 0.02;
          return Transform.scale(scale: s, child: child);
        },
        child: card,
      );
    }
    return card;
  }
}
