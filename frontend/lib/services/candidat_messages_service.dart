import 'dart:convert';
import 'api_service.dart';

class CandidatMessagesService {
  final ApiService _api = ApiService();

  Future<List<Map<String, dynamic>>> getConversations() async {
    final res = await _api.get('/candidat/messages', useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur conversations');
    }
    final map = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    return List<Map<String, dynamic>>.from(map['data'] ?? const []);
  }

  Future<Map<String, dynamic>> getThread(String destinataireId) async {
    final res = await _api.get(
      '/candidat/messages/$destinataireId',
      useAuth: true,
    );
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur conversation');
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  Future<Map<String, dynamic>> getThreadSince(
    String destinataireId, {
    String? since,
  }) async {
    final q = since == null || since.isEmpty
        ? ''
        : '?since=${Uri.encodeQueryComponent(since)}';
    final res = await _api.get(
      '/candidat/messages/$destinataireId$q',
      useAuth: true,
    );
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur conversation');
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  Future<void> sendMessage(
    String destinataireId,
    String contenu, {
    String? offreId,
  }) async {
    final res = await _api.post(
      '/candidat/messages',
      useAuth: true,
      body: {
        'destinataire_id': destinataireId,
        'contenu': contenu,
        if (offreId != null && offreId.isNotEmpty) 'offre_id': offreId,
      },
    );
    if (res.statusCode != 201) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur envoi message');
    }
  }
}
