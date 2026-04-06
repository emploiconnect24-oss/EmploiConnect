import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class RecruteurService {
  final String _base = '$apiBaseUrl$apiPrefix/recruteur';

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<Map<String, dynamic>> getDashboard(String token) async =>
      _handle(await http.get(Uri.parse('$_base/dashboard'), headers: _headers(token)));

  Future<Map<String, dynamic>> getOffres(String token, {int page = 1, int limite = 20, String? statut, String? recherche}) async {
    final uri = Uri.parse('$_base/offres').replace(queryParameters: {
      'page': '$page',
      'limite': '$limite',
      if (statut != null) 'statut': statut,
      if (recherche != null) 'recherche': recherche,
    });
    return _handle(await http.get(uri, headers: _headers(token)));
  }

  Future<Map<String, dynamic>> createOffre(String token, Map<String, dynamic> data) async =>
      _handle(await http.post(Uri.parse('$_base/offres'), headers: _headers(token), body: jsonEncode(data)));

  Future<Map<String, dynamic>> updateOffre(String token, String id, Map<String, dynamic> data) async =>
      _handle(await http.patch(Uri.parse('$_base/offres/$id'), headers: _headers(token), body: jsonEncode(data)));

  Future<Map<String, dynamic>> dupliquerOffre(String token, String id) async =>
      _handle(await http.post(Uri.parse('$_base/offres/$id/dupliquer'), headers: _headers(token)));

  Future<Map<String, dynamic>> cloturerOffre(String token, String id) async =>
      _handle(await http.patch(Uri.parse('$_base/offres/$id/cloturer'), headers: _headers(token)));

  Future<Map<String, dynamic>> deleteOffre(String token, String id) async =>
      _handle(await http.delete(Uri.parse('$_base/offres/$id'), headers: _headers(token)));

  Future<Map<String, dynamic>> getCandidatures(String token, {String? offreId, String? statut, String? recherche, String vue = 'liste', int page = 1, int limite = 50}) async {
    final uri = Uri.parse('$_base/candidatures').replace(queryParameters: {
      'vue': vue,
      'page': '$page',
      'limite': '$limite',
      if (offreId != null && offreId.isNotEmpty && offreId != 'null') 'offre_id': offreId,
      if (statut != null && statut.isNotEmpty) 'statut': statut,
      if (recherche != null && recherche.isNotEmpty) 'recherche': recherche,
    });
    return _handle(await http.get(uri, headers: _headers(token)));
  }

  Future<Map<String, dynamic>> getCandidature(String token, String id) async =>
      _handle(await http.get(Uri.parse('$_base/candidatures/$id'), headers: _headers(token)));

  Future<Map<String, dynamic>> actionCandidature(
    String token,
    String id,
    String action, {
    String? dateEntretien,
    String? lienVisio,
    String? raisonRefus,
    String? typeEntretien,
    String? lieuEntretien,
    String? notesEntretien,
  }) async =>
      _handle(await http.patch(
        Uri.parse('$_base/candidatures/$id'),
        headers: _headers(token),
        body: jsonEncode({
          'action': action,
          if (dateEntretien != null) 'date_entretien': dateEntretien,
          if (lienVisio != null) 'lien_visio': lienVisio,
          if (raisonRefus != null) 'raison_refus': raisonRefus,
          if (typeEntretien != null) 'type_entretien': typeEntretien,
          if (lieuEntretien != null) 'lieu_entretien': lieuEntretien,
          if (notesEntretien != null) 'notes_entretien': notesEntretien,
        }),
      ));

  Future<Map<String, dynamic>> getProfil(String token) async =>
      _handle(await http.get(Uri.parse('$_base/profil'), headers: _headers(token)));

  Future<Map<String, dynamic>> updateProfil(String token, Map<String, dynamic> data) async =>
      _handle(await http.patch(Uri.parse('$_base/profil'), headers: _headers(token), body: jsonEncode(data)));

  Future<Map<String, dynamic>> getConversations(String token) async =>
      _handle(await http.get(Uri.parse('$_base/messages'), headers: _headers(token)));

  /// [type] : `tous` (défaut, élargit aux chercheurs si besoin) ou `postule` (uniquement ayant postulé).
  Future<Map<String, dynamic>> searchMessagePeers(String token, String q, {String type = 'tous'}) async {
    final uri = Uri.parse('$_base/messages/peers/search').replace(queryParameters: {
      'q': q,
      'type': type,
    });
    return _handle(await http.get(uri, headers: _headers(token)));
  }

  Future<Map<String, dynamic>> getMessages(String token, String destinataireId) async =>
      _handle(await http.get(Uri.parse('$_base/messages/$destinataireId'), headers: _headers(token)));

  Future<Map<String, dynamic>> envoyerMessage(
    String token,
    String destinataireId,
    String contenu, {
    String? offreId,
    String? pieceJointeUrl,
    String? pieceJointeNom,
  }) async =>
      _handle(await http.post(
        Uri.parse('$_base/messages'),
        headers: _headers(token),
        body: jsonEncode({
          'destinataire_id': destinataireId,
          'contenu': contenu,
          if (offreId != null) 'offre_id': offreId,
          if (pieceJointeUrl != null) 'piece_jointe_url': pieceJointeUrl,
          if (pieceJointeNom != null) 'piece_jointe_nom': pieceJointeNom,
        }),
      ));

  /// Upload pièce jointe messagerie → `{ url, nom }` dans `data`.
  Future<Map<String, dynamic>> uploadMessagePieceJointe(String token, List<int> bytes, String filename) async {
    final uri = Uri.parse('$_base/messages/attachment');
    final req = http.MultipartRequest('POST', uri);
    req.headers['Authorization'] = 'Bearer $token';
    req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    return _handle(res);
  }

  Future<Map<String, dynamic>> getTalents(String token, {String? recherche, String? niveauEtude, String? disponibilite, String? ville, String? offreId, int page = 1, int limite = 20}) async {
    final uri = Uri.parse('$_base/talents').replace(queryParameters: {
      'page': '$page',
      'limite': '$limite',
      if (recherche != null) 'recherche': recherche,
      if (niveauEtude != null) 'niveau_etude': niveauEtude,
      if (disponibilite != null) 'disponibilite': disponibilite,
      if (ville != null) 'ville': ville,
      if (offreId != null) 'offre_id': offreId,
    });
    return _handle(await http.get(uri, headers: _headers(token)));
  }

  Future<Map<String, dynamic>> contacterTalent(String token, String talentId, String message, {String? offreId}) async =>
      _handle(await http.post(
        Uri.parse('$_base/talents/contacter'),
        headers: _headers(token),
        body: jsonEncode({
          'talent_utilisateur_id': talentId,
          'message': message,
          if (offreId != null) 'offre_id': offreId,
        }),
      ));

  Future<Map<String, dynamic>> getStats(String token, {String periode = '30d'}) async =>
      _handle(await http.get(Uri.parse('$_base/stats?periode=$periode'), headers: _headers(token)));

  Future<Map<String, dynamic>> getNotifications(
    String token, {
    int page = 1,
    int limite = 30,
    String? lu,
    String? type,
  }) async {
    final uri = Uri.parse('$_base/notifications').replace(queryParameters: {
      'page': '$page',
      'limite': '$limite',
      if (lu != null) 'lu': lu,
      if (type != null && type.isNotEmpty) 'type': type,
    });
    return _handle(await http.get(uri, headers: _headers(token)));
  }

  Future<void> marquerNotifLue(String token, String id) async {
    await http.patch(Uri.parse('$_base/notifications/$id/lire'), headers: _headers(token));
  }

  Future<void> marquerToutesLues(String token) async {
    await http.patch(Uri.parse('$_base/notifications/tout-lire/action'), headers: _headers(token));
  }

  Map<String, dynamic> _handle(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw Exception(body['message'] ?? 'Erreur ${res.statusCode}');
  }
}

