import 'dart:convert';
import 'api_service.dart';

class AlertesService {
  final ApiService _api = ApiService();

  Future<List<Map<String, dynamic>>> listAlertes() async {
    final res = await _api.get('/candidat/alertes', useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur chargement alertes');
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final data = (map['data'] as List<dynamic>? ?? const []);
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> createAlerte(Map<String, dynamic> payload) async {
    final res = await _api.post('/candidat/alertes', body: payload, useAuth: true);
    if (res.statusCode != 201) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur création alerte');
    }
  }

  Future<void> updateAlerte(String id, Map<String, dynamic> payload) async {
    final res = await _api.patch('/candidat/alertes/$id', body: payload, useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur mise à jour alerte');
    }
  }

  Future<void> deleteAlerte(String id) async {
    final res = await _api.delete('/candidat/alertes/$id', useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur suppression alerte');
    }
  }
}

