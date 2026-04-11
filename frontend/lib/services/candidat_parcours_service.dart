import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

class CandidatParcoursService {
  final ApiService _api = ApiService();

  Map<String, dynamic> _ok(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw Exception(body['message'] as String? ?? 'Erreur ${res.statusCode}');
  }

  Future<Map<String, dynamic>> listRessources({String? categorie, String? type}) async {
    final q = <String>[];
    if (categorie != null && categorie.isNotEmpty) q.add('categorie=${Uri.encodeQueryComponent(categorie)}');
    if (type != null && type.isNotEmpty) q.add('type=${Uri.encodeQueryComponent(type)}');
    final suffix = q.isEmpty ? '' : '?${q.join('&')}';
    final res = await _api.get('/candidat/ressources-carrieres$suffix', useAuth: true);
    return _ok(res);
  }

  Future<Map<String, dynamic>> getRessource(String id) async {
    final res = await _api.get('/candidat/ressources-carrieres/$id', useAuth: true);
    return _ok(res);
  }

  Future<void> marquerVue(String id, {int progression = 0}) async {
    final res = await _api.post(
      '/candidat/ressources-carrieres/$id/vue',
      body: {'progression': progression},
      useAuth: true,
    );
    _ok(res);
  }

  Future<Map<String, dynamic>> genererQuestionsSimulateur(Map<String, dynamic> body) async {
    final res = await _api.post('/candidat/simulateur/generer-questions', body: body, useAuth: true);
    return _ok(res);
  }

  Future<Map<String, dynamic>> evaluerReponseSimulateur(Map<String, dynamic> body) async {
    final res = await _api.post('/candidat/simulateur/evaluer-reponse', body: body, useAuth: true);
    return _ok(res);
  }

  Future<Map<String, dynamic>> sauvegarderSimulation(Map<String, dynamic> body) async {
    final res = await _api.post('/candidat/simulateur/sauvegarder', body: body, useAuth: true);
    return _ok(res);
  }

  Future<Map<String, dynamic>> calculateurSalaire(Map<String, dynamic> body) async {
    final res = await _api.post('/candidat/calculateur-salaire', body: body, useAuth: true);
    return _ok(res);
  }
}
