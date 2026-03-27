import 'package:flutter/animation.dart';

class AppAnimations {
  // Durées
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 350);
  static const Duration medium = Duration(milliseconds: 500);
  static const Duration slow = Duration(milliseconds: 700);
  static const Duration slower = Duration(milliseconds: 900);

  // Courbes
  static const Curve standard = Curves.easeOut;
  static const Curve enter = Curves.easeOut;
  static const Curve exit = Curves.easeIn;
  static const Curve bounce = Curves.elasticOut;
  static const Curve smooth = Curves.easeInOut;

  // Délais stagger (pour listes de cartes)
  static Duration stagger(int index) => Duration(milliseconds: 80 * index);
}

