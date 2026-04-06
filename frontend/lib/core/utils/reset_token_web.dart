import 'dart:html' as html;

/// Lit `?token=` depuis le hash (`/#/reset-password?token=...`).
String? readResetPasswordTokenFromUrl() {
  final h = html.window.location.hash;
  if (h.isEmpty || h == '#') return null;
  final path = h.startsWith('#') ? h.substring(1) : h;
  if (!path.contains('reset-password')) return null;
  final uri = Uri.parse('http://localhost$path');
  final t = uri.queryParameters['token'];
  return t != null && t.isNotEmpty ? t : null;
}
