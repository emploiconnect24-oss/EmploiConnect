import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IAScoreBadge extends StatefulWidget {
  final int score;
  final bool large;

  const IAScoreBadge({
    super.key,
    required this.score,
    this.large = false,
  });

  @override
  State<IAScoreBadge> createState() => _IAScoreBadgeState();
}

class _IAScoreBadgeState extends State<IAScoreBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _color {
    if (widget.score >= 80) return const Color(0xFF10B981);
    if (widget.score >= 60) return const Color(0xFF1A56DB);
    if (widget.score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String get _label {
    if (widget.score >= 80) return 'Excellent';
    if (widget.score >= 60) return 'Bon match';
    if (widget.score >= 40) return 'Moyen';
    return 'Faible';
  }

  @override
  Widget build(BuildContext context) {
    return widget.large ? _buildLarge() : _buildCompact();
  }

  Widget _buildCompact() => AnimatedBuilder(
        animation: _anim,
        builder: (context, child) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 12, color: Color(0xFF1A56DB)),
              const SizedBox(width: 4),
              Text(
                '${(widget.score * _anim.value).toInt()}% · $_label',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _color,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildLarge() => Column(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, child) => Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: (widget.score / 100) * _anim.value,
                    strokeWidth: 7,
                    backgroundColor: _color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(_color),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(widget.score * _anim.value).toInt()}',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _color,
                        ),
                      ),
                      Text(
                        '%',
                        style: GoogleFonts.inter(fontSize: 10, color: _color),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _color,
              ),
            ),
          ),
        ],
      );
}

