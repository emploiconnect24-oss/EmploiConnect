import 'dart:html' as html;

Future<void> applyWebFavicon(String url) async {
  final clean = url.trim();
  if (clean.isEmpty) return;
  final withBust = '$clean?v=${DateTime.now().millisecondsSinceEpoch}';
  final existing = html.document.querySelector('link[rel="icon"]');
  if (existing is html.LinkElement) {
    existing.href = withBust;
    return;
  }
  final link = html.LinkElement()
    ..rel = 'icon'
    ..type = 'image/png'
    ..href = withBust;
  html.document.head?.append(link);
}
