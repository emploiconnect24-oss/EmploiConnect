import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HoverScale extends StatefulWidget {
  const HoverScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 1.02,
    this.duration = const Duration(milliseconds: 160),
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enableHover = kIsWeb || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.windows;
    Widget w = AnimatedScale(
      scale: _hover ? widget.scale : 1,
      duration: widget.duration,
      curve: Curves.easeOut,
      child: widget.child,
    );

    if (widget.onTap != null) {
      w = InkWell(
        onTap: widget.onTap,
        child: w,
      );
    }

    if (!enableHover) return w;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: w,
    );
  }
}

