import 'package:flutter/material.dart';

class ActionItem {
  const ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.dividerBefore = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool dividerBefore;
}

class ActionMenu extends StatelessWidget {
  const ActionMenu({super.key, required this.actions});

  final List<ActionItem> actions;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Actions',
      icon: const Icon(Icons.more_vert_outlined),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<int>>[];
        for (var i = 0; i < actions.length; i++) {
          final a = actions[i];
          if (a.dividerBefore) {
            items.add(const PopupMenuDivider());
          }
          items.add(
            PopupMenuItem<int>(
              value: i,
              child: Row(
                children: [
                  Icon(a.icon, size: 18, color: a.color ?? const Color(0xFF64748B)),
                  const SizedBox(width: 10),
                  Text(
                    a.label,
                    style: TextStyle(color: a.color ?? const Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
          );
        }
        return items;
      },
      onSelected: (i) => actions[i].onTap(),
    );
  }
}
