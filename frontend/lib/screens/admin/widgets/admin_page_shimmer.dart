import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/theme_extension.dart';

Color _bone(BuildContext context) =>
    Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.9);

/// Shimmer pleine largeur pour les pages admin (liste, table).
class AdminListScreenShimmer extends StatelessWidget {
  const AdminListScreenShimmer({super.key, this.showHeaderAction = true, this.tableRows = 8});

  final bool showHeaderAction;
  final int tableRows;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.themeExt.shimmerBase,
      highlightColor: context.themeExt.shimmerHighlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 26, width: 280, decoration: _r(_bone(context))),
                    const SizedBox(height: 10),
                    Container(height: 14, width: 220, decoration: _r(_bone(context))),
                  ],
                ),
              ),
              if (showHeaderAction) ...[
                const SizedBox(width: 12),
                Container(
                  height: 40,
                  width: 200,
                  decoration: _r(_bone(context)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.themeExt.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Container(height: 48, decoration: _r(_bone(context)))),
                    const SizedBox(width: 12),
                    Container(height: 48, width: 140, decoration: _r(_bone(context))),
                    const SizedBox(width: 12),
                    Container(height: 48, width: 140, decoration: _r(_bone(context))),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    5,
                    (_) => Container(height: 36, width: 88, decoration: _r(_bone(context))),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            tableRows,
            (i) => Padding(
              padding: EdgeInsets.only(bottom: i == tableRows - 1 ? 0 : 10),
              child: Container(
                height: 56,
                decoration: _r(_bone(context)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Grille de cartes + blocs type dashboard admin.
class AdminDashboardShimmer extends StatelessWidget {
  const AdminDashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final bone = _bone(context);
    return Shimmer.fromColors(
      baseColor: context.themeExt.shimmerBase,
      highlightColor: context.themeExt.shimmerHighlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 52, height: 52, decoration: _r(bone)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 22, width: 200, decoration: _r(bone)),
                    const SizedBox(height: 8),
                    Container(height: 14, width: 260, decoration: _r(bone)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, c) {
              final cross = c.maxWidth > 980 ? 3 : (c.maxWidth > 640 ? 2 : 1);
              const spacing = 12.0;
              final w = (c.maxWidth - (cross - 1) * spacing) / cross;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: List.generate(
                  6,
                  (_) => Container(
                    width: w,
                    height: 110,
                    decoration: _r(bone),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Container(height: 20, width: 180, decoration: _r(bone)),
          const SizedBox(height: 12),
          Container(
            height: 200,
            width: double.infinity,
            decoration: _r(bone),
          ),
          const SizedBox(height: 20),
          Container(height: 20, width: 200, decoration: _r(bone)),
          const SizedBox(height: 12),
          ...List.generate(4, (_) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(height: 72, decoration: _r(bone)),
              )),
        ],
      ),
    );
  }
}

/// Modération : compteurs + liste.
class AdminModerationShimmer extends StatelessWidget {
  const AdminModerationShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final bone = _bone(context);
    return Shimmer.fromColors(
      baseColor: context.themeExt.shimmerBase,
      highlightColor: context.themeExt.shimmerHighlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 26, width: 320, decoration: _r(bone)),
          const SizedBox(height: 8),
          Container(height: 14, width: 260, decoration: _r(bone)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(
              3,
              (_) => Container(width: 160, height: 88, decoration: _r(bone)),
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(6, (_) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(height: 100, decoration: _r(bone)),
              )),
        ],
      ),
    );
  }
}

/// Statistiques : chips + KPI + graphiques.
class AdminStatisticsShimmer extends StatelessWidget {
  const AdminStatisticsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final bone = _bone(context);
    return Shimmer.fromColors(
      baseColor: context.themeExt.shimmerBase,
      highlightColor: context.themeExt.shimmerHighlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 26, width: 300, decoration: _r(bone)),
                    const SizedBox(height: 8),
                    Container(height: 14, width: 240, decoration: _r(bone)),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                children: List.generate(5, (_) => Container(height: 36, width: 48, decoration: _r(bone))),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, c) {
              final cross = c.maxWidth >= 1200 ? 4 : (c.maxWidth >= 760 ? 2 : 1);
              const spacing = 12.0;
              final w = (c.maxWidth - (cross - 1) * spacing) / cross;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: List.generate(4, (_) => Container(width: w, height: 96, decoration: _r(bone))),
              );
            },
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth < 980) {
                return Column(
                  children: [
                    Container(height: 320, width: double.infinity, decoration: _r(bone)),
                    const SizedBox(height: 12),
                    Container(height: 320, width: double.infinity, decoration: _r(bone)),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Container(height: 320, decoration: _r(bone))),
                  const SizedBox(width: 12),
                  Expanded(child: Container(height: 320, decoration: _r(bone))),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Container(height: 220, width: double.infinity, decoration: _r(bone)),
        ],
      ),
    );
  }
}

/// Paramètres : menu + panneaux.
class AdminSettingsShimmer extends StatelessWidget {
  const AdminSettingsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final bone = _bone(context);
    return Shimmer.fromColors(
      baseColor: context.themeExt.shimmerBase,
      highlightColor: context.themeExt.shimmerHighlight,
      child: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth < 960) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 24, width: 220, decoration: _r(bone)),
                const SizedBox(height: 14),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: List.generate(6, (_) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(width: 100, height: 36, decoration: _r(bone)),
                        )),
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(8, (_) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Container(height: 52, decoration: _r(bone)),
                    )),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 22, width: 160, decoration: _r(bone)),
                    const SizedBox(height: 12),
                    ...List.generate(6, (_) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(height: 40, width: double.infinity, decoration: _r(bone)),
                        )),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: List.generate(
                    8,
                    (_) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Container(height: 52, decoration: _r(bone)),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Historique notifications (table compacte).
class AdminNotificationsHistoryShimmer extends StatelessWidget {
  const AdminNotificationsHistoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final bone = _bone(context);
    return Shimmer.fromColors(
      baseColor: context.themeExt.shimmerBase,
      highlightColor: context.themeExt.shimmerHighlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Container(height: 18, decoration: _r(bone))),
              Container(width: 40, height: 40, decoration: _r(bone)),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(5, (_) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(height: 44, decoration: _r(bone)),
              )),
        ],
      ),
    );
  }
}

BoxDecoration _r(Color c) => BoxDecoration(
      color: c,
      borderRadius: BorderRadius.circular(10),
    );
