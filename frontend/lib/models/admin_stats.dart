/// Statistiques agrégées renvoyées par `GET /api/admin/dashboard` ou stats imbriquées.
class AdminStats {
  const AdminStats({
    required this.totalUtilisateurs,
    required this.totalChercheurs,
    required this.totalEntreprises,
    required this.usersEnAttente,
    required this.usersBloques,
    required this.offresActives,
    required this.offresEnAttente,
    required this.offresRefusees,
    required this.offresExpirees,
    required this.totalCandidatures,
    required this.signalementsEnAttente,
  });

  final int totalUtilisateurs;
  final int totalChercheurs;
  final int totalEntreprises;
  final int usersEnAttente;
  final int usersBloques;
  final int offresActives;
  final int offresEnAttente;
  final int offresRefusees;
  final int offresExpirees;
  final int totalCandidatures;
  final int signalementsEnAttente;

  /// Parse la réponse [getDashboard] : `data.stats` + `data.stats.legacy`.
  factory AdminStats.fromDashboardBody(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>?;
    final json = data?['stats'] as Map<String, dynamic>?;
    final legacy = json?['legacy'] as Map<String, dynamic>?;
    if (json == null) {
      return const AdminStats(
        totalUtilisateurs: 0,
        totalChercheurs: 0,
        totalEntreprises: 0,
        usersEnAttente: 0,
        usersBloques: 0,
        offresActives: 0,
        offresEnAttente: 0,
        offresRefusees: 0,
        offresExpirees: 0,
        totalCandidatures: 0,
        signalementsEnAttente: 0,
      );
    }
    final u = json['utilisateurs'];
    final o = json['offres'];
    return AdminStats(
      totalUtilisateurs: _i(u, 'total'),
      totalChercheurs: _i(u, 'chercheurs'),
      totalEntreprises: _i(u, 'entreprises'),
      usersEnAttente: _i(u, 'en_attente'),
      usersBloques: _i(u, 'bloques'),
      offresActives: _i(o, 'actives'),
      offresEnAttente: _i(o, 'en_attente'),
      offresRefusees: _i(o, 'refusees'),
      offresExpirees: _i(o, 'expirees'),
      totalCandidatures: _i(legacy, 'nombre_candidatures'),
      signalementsEnAttente: _i(legacy, 'nombre_signalements_en_attente'),
    );
  }

  static int _i(dynamic m, String key) {
    if (m is! Map) return 0;
    final v = m[key];
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}
