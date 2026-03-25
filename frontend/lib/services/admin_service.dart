import 'dart:convert';
import 'api_service.dart';

class AdminService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getStatistiques() async {
    final res = await _api.get('/admin/statistiques', useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur stats');
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  Future<({List<Map<String, dynamic>> utilisateurs, int? total})> getUtilisateurs({
    String? role,
    bool? estValide,
    bool? estActif,
    int offset = 0,
    int limit = 20,
  }) async {
    final q = <String, String>{
      'offset': '$offset',
      'limit': '$limit',
      ...?(role == null ? null : {'role': role}),
      ...?(estValide == null ? null : {'est_valide': estValide.toString()}),
      ...?(estActif == null ? null : {'est_actif': estActif.toString()}),
    };
    final uri =
        '/admin/utilisateurs?${q.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
    final res = await _api.get(uri, useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur utilisateurs');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (data['utilisateurs'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    return (utilisateurs: list, total: data['total'] as int?);
  }

  Future<Map<String, dynamic>> patchUtilisateur(
    String id, {
    bool? estValide,
    bool? estActif,
  }) async {
    final body = <String, dynamic>{};
    if (estValide != null) body['est_valide'] = estValide;
    if (estActif != null) body['est_actif'] = estActif;
    final res = await _api.patch('/admin/utilisateurs/$id', body: body, useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur');
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  Future<({List<Map<String, dynamic>> signalements, int? total})> getSignalements({
    String? statut,
    String? typeObjet,
    int offset = 0,
    int limit = 50,
  }) async {
    final q = <String, String>{
      'offset': '$offset',
      'limit': '$limit',
      ...?(statut == null ? null : {'statut': statut}),
      ...?(typeObjet == null ? null : {'type_objet': typeObjet}),
    };
    final uri =
        '/admin/signalements?${q.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
    final res = await _api.get(uri, useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur signalements');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (data['signalements'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    return (signalements: list, total: data['total'] as int?);
  }

  Future<Map<String, dynamic>> traiterSignalement(String id, String statut) async {
    final res = await _api.patch(
      '/admin/signalements/$id',
      body: {'statut': statut},
      useAuth: true,
    );
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur');
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }
}
