import 'dart:async';
import 'package:flutter/material.dart';

class AdminSearchBar extends StatefulWidget {
  const AdminSearchBar({
    super.key,
    required this.hint,
    required this.onChanged,
    this.debounceMs = 300,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final int debounceMs;

  @override
  State<AdminSearchBar> createState() => _AdminSearchBarState();
}

class _AdminSearchBarState extends State<AdminSearchBar> {
  final _ctrl = TextEditingController();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onInput(String value) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: widget.debounceMs), () {
      widget.onChanged(value);
    });
    setState(() {});
  }

  void _clear() {
    _timer?.cancel();
    _ctrl.clear();
    widget.onChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      onChanged: _onInput,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _ctrl.text.isEmpty
            ? null
            : IconButton(
                onPressed: _clear,
                icon: const Icon(Icons.close),
              ),
      ),
    );
  }
}
