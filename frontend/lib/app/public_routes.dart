/// Routes publiques (offres vitrine) — utilisées avec [Navigator.pushNamed]
/// et déclarées dans [MaterialApp.onGenerateRoute] (`main.dart`) ainsi que dans [GoRouter] (`router.dart`).
abstract final class PublicRoutes {
  PublicRoutes._();

  static const listPath = '/public/offres';

  /// Préfixe du chemin détail ; l’identifiant suit (éventuellement encodé par [offre]).
  static const offrePrefix = '/public/offre/';

  /// Liste publique ; [search] est passé en query `q`.
  static String list({String? search}) {
    final s = search?.trim();
    if (s == null || s.isEmpty) return listPath;
    return '$listPath?q=${Uri.encodeQueryComponent(s)}';
  }

  /// Liste publique filtrée sur une entreprise (top entreprises / vitrine).
  static String listForEntreprise({required String entrepriseId, String? nomEntreprise}) {
    final e = entrepriseId.trim();
    if (e.isEmpty) return listPath;
    final n = nomEntreprise?.trim();
    if (n == null || n.isEmpty) {
      return '$listPath?e=${Uri.encodeQueryComponent(e)}';
    }
    return '$listPath?e=${Uri.encodeQueryComponent(e)}&n=${Uri.encodeQueryComponent(n)}';
  }

  static String offre(String id) => '$offrePrefix${Uri.encodeComponent(id)}';

  /// Partie chemin sans `?…` (pour résoudre la route dans `onGenerateRoute`).
  static String pathOnly(String name) {
    final i = name.indexOf('?');
    return (i >= 0 ? name.substring(0, i) : name).trim();
  }

  static String? queryParam(String name, String key) {
    final i = name.indexOf('?');
    if (i < 0) return null;
    final map = Uri.splitQueryString(name.substring(i + 1));
    final v = map[key];
    if (v == null || v.isEmpty) return null;
    return v;
  }
}
