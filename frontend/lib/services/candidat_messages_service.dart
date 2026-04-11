import 'dart:convert';
import 'package:http/http.dart' as http;

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

  /// Upload pièce jointe → `{ url, nom }` dans `data`.
  Future<Map<String, dynamic>> uploadPieceJointe(
    List<int> bytes,
    String filename,
  ) async {
    final streamed = await _api.postMultipart(
      '/candidat/messages/attachment',
      fileBytes: bytes,
      filename: filename,
      fieldName: 'file',
      useAuth: true,
    );
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur upload');
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  Future<void> sendMessage(
    String destinataireId,
    String contenu, {
    String? offreId,
    String? pieceJointeUrl,
    String? pieceJointeNom,
  }) async {
    final res = await _api.post(
      '/candidat/messages',
      useAuth: true,
      body: {
        'destinataire_id': destinataireId,
        'contenu': contenu,
        if (offreId != null && offreId.isNotEmpty) 'offre_id': offreId,
        if (pieceJointeUrl != null && pieceJointeUrl.isNotEmpty)
          'piece_jointe_url': pieceJointeUrl,
        if (pieceJointeNom != null && pieceJointeNom.isNotEmpty)
          'piece_jointe_nom': pieceJointeNom,
      },
    );
    if (res.statusCode != 201) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur envoi message');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    final res = await _api.delete(
      '/candidat/messages/$messageId',
      useAuth: true,
    );
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur suppression');
    }
  }

  /// Indique au serveur que l’utilisateur tape (rafraîchit la présence ~6 s côté API).
  Future<void> sendTypingPing(String destinataireId) async {
    try {
      await _api.post(
        '/candidat/messages/typing',
        useAuth: true,
        body: {'destinataire_id': destinataireId},
      );
    } catch (_) {}
  }

  Future<bool> getPeerTyping(String destinataireId) async {
    try {
      final res = await _api.get(
        '/candidat/messages/peer-typing/${Uri.encodeComponent(destinataireId)}',
        useAuth: true,
      );
      if (res.statusCode != 200) return false;
      final map = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
      final data = map['data'] as Map?;
      return data?['peer_typing'] == true;
    } catch (_) {
      return false;
    }
  }
}
