import 'dart:async';
import 'package:flutter/material.dart';

class TypewriterText extends StatefulWidget {
  const TypewriterText({
    super.key,
    required this.texts,
    this.textStyle,
    this.charDelay = const Duration(milliseconds: 40),
    this.pause = const Duration(milliseconds: 900),
  });

  final List<String> texts;
  final TextStyle? textStyle;
  final Duration charDelay;
  final Duration pause;

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  Timer? _timer;
  int _textIndex = 0;
  int _charIndex = 0;
  bool _pausing = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.texts != widget.texts) {
      _textIndex = 0;
      _charIndex = 0;
      _pausing = false;
      _start();
    }
  }

  void _start() {
    _timer?.cancel();
    if (widget.texts.isEmpty) return;
    _timer = Timer.periodic(widget.charDelay, (_) {
      if (!mounted) return;
      final current = widget.texts[_textIndex];
      if (_pausing) return;
      if (_charIndex < current.length) {
        setState(() => _charIndex++);
      } else {
        _pausing = true;
        Future<void>.delayed(widget.pause, () {
          if (!mounted) return;
          setState(() {
            _pausing = false;
            _textIndex = (_textIndex + 1) % widget.texts.length;
            _charIndex = 0;
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.texts.isEmpty) return const SizedBox.shrink();
    final text = widget.texts[_textIndex];
    final shown = text.substring(0, _charIndex.clamp(0, text.length));
    return Text(
      shown,
      style: widget.textStyle,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

