import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/public_routes.dart';

/// Navigation depuis liens bannières / CTA (chemins internes ou URLs).
Future<void> navigateHomeLink(BuildContext context, String? raw) async {
  final s = (raw ?? '').trim();
  if (s.isEmpty) return;
  if (s.startsWith('http://') || s.startsWith('https://')) {
    final u = Uri.tryParse(s);
    if (u != null && await canLaunchUrl(u)) {
      await launchUrl(u, mode: LaunchMode.externalApplication);
    }
    return;
  }
  final path = s.startsWith('/') ? s : '/$s';
  if (path == '/offres' || path.contains('public/offres')) {
    if (!context.mounted) return;
    await Navigator.of(context).pushNamed(PublicRoutes.listPath);
    return;
  }
  if (!context.mounted) return;
  await Navigator.of(context).pushNamed(path);
}
