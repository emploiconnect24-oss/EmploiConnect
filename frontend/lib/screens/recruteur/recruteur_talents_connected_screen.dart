import 'package:flutter/material.dart';

import 'pages/talents_page.dart';

/// Shell recruteur — Recherche talents (PRD redesign).
class RecruteurTalentsConnectedScreen extends StatelessWidget {
  const RecruteurTalentsConnectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TalentsPage(),
          ),
        ),
      ),
    );
  }
}
