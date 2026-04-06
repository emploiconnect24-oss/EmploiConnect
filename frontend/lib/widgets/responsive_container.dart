import 'dart:math' as math;

import 'package:flutter/material.dart';

class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 980,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    // `Align` assouplit la contrainte de hauteur (max → ∞) : un `Column` avec
    // `Expanded` plante alors (assertion flex / hauteur non bornée). Dès que le
    // parent fournit une hauteur finie (ex. shell admin), on impose largeur +
    // hauteur explicites via `SizedBox`.
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPad = padding.horizontal;
        final verticalPad = padding.vertical;
        final availW = math.max(0.0, constraints.maxWidth - horizontalPad);
        // Largeur / hauteur nulles → hit-test impossible (« render box with no size »).
        final w = math.max(1.0, math.min(availW, maxWidth));
        final availH = constraints.maxHeight - verticalPad;

        if (constraints.hasBoundedHeight && availH.isFinite && availH > 0) {
          return Padding(
            padding: padding,
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: w,
                height: math.max(1.0, availH),
                child: child,
              ),
            ),
          );
        }

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

