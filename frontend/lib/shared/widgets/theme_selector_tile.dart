import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_extension.dart';
import '../../core/theme/theme_provider.dart';

class ThemeSelectorTile extends StatelessWidget {
  const ThemeSelectorTile({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider>();
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.themeExt.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: scheme.primary, size: 20),
              const SizedBox(width: 10),
              Text('Apparence', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: scheme.onSurface)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ThemeOption(
                  icon: Icons.wb_sunny_outlined,
                  label: 'Clair',
                  isSelected: provider.mode == AppThemeMode.light,
                  onTap: () => provider.setTheme(AppThemeMode.light),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ThemeOption(
                  icon: Icons.dark_mode_outlined,
                  label: 'Sombre',
                  isSelected: provider.mode == AppThemeMode.dark,
                  onTap: () => provider.setTheme(AppThemeMode.dark),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ThemeOption(
                  icon: Icons.settings_suggest_outlined,
                  label: 'Système',
                  isSelected: provider.mode == AppThemeMode.system,
                  onTap: () => provider.setTheme(AppThemeMode.system),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary.withValues(alpha: 0.10) : context.themeExt.inputFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? scheme.primary : context.themeExt.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: isSelected ? scheme.primary : scheme.onSurfaceVariant),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
