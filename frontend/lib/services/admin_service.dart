import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'api_service.dart';

/// Service API administration (`/api/admin/*`), JWT via [ApiService].
class AdminService {
  final ApiService _api = ApiService();

  static int? _readTotal(Map<String, dynamic> data) {
    final t = data['total'];
    if (t is int) return t;
    final inner = data['data'];
    if (inner is Map) {
      final p = inner['pagination'];
      if (p is Map && p['total'] is int) return p['total'] as int;
    }
    return null;
  }

  Map<String, dynamic> _parseJsonOk(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw Exception(body['message'] as String? ?? 'Erreur ${res.statusCode}');
  }

  // ── DASHBOARD & STATS ─────────────────────────────────────

  Future<Map<String, dynamic>> getDashboard() async {
    final res = await _api.get('/admin/dashboard', useAuth: true);
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> getStatistiques({String periode = '30d'}) async {
    final res = await _api.get('/admin/statistiques?periode=$periode', useAuth: true);
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> getStatistiquesHistorique({String periode = '30d'}) async {
    final res = await _api.get('/admin/statistiques/historique?periode=$periode', useAuth: true);
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> getTopEntreprises() async {
    final res = await _api.get('/admin/statistiques/top-entreprises', useAuth: true);
    return _parseJsonOk(res);
  }

  Future<String> exportStatistiquesCsv({String periode = '30d'}) async {
    final res = await _api.get(
      '/admin/statistiques/export?periode=${Uri.encodeQueryComponent(periode)}',
      useAuth: true,
    );
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur export');
    }
    return res.body;
  }

  Future<Map<String, dynamic>> rechercheGlobale(String query) async {
    final q = query.trim();
    if (q.length < 2) {
      return {'success': true, 'data': <String, dynamic>{}};
    }
    final res = await _api.get(
      '/admin/recherche?q=${Uri.encodeQueryComponent(q)}',
      useAuth: true,
    );
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> getActivite({int page = 1, int limite = 20}) async {
    final res = await _api.get('/admin/activite?page=$page&limite=$limite', useAuth: true);
    return _parseJsonOk(res);
  }

  // ── UTILISATEURS ───────────────────────────────────────────

  Future<Map<String, dynamic>> getUtilisateursStats() async {
    final res = await _api.get('/admin/utilisateurs/stats', useAuth: true);
    return _parseJsonOk(res);
  }

  Future<({List<Map<String, dynamic>> utilisateurs, int? total})> getUtilisateurs({
    String? role,
    bool? estValide,
    bool? estActif,
    int offset = 0,
    int limit = 20,
    int page = 1,
    String? statut,
    String? recherche,
  }) async {
    final q = <String, String>{
      'offset': '$offset',
      'limit': '$limit',
      'page': '$page',
      'limite': '$limit',
      ...?(role == null ? null : {'role': role}),
      ...?(estValide == null ? null : {'est_valide': estValide.toString()}),
      ...?(estActif == null ? null : {'est_actif': estActif.toString()}),
      ...?(statut == null ? null : {'statut': statut}),
      ...?(recherche == null ? null : {'recherche': recherche}),
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
        ((data['data'] is Map ? (data['data'] as Map)['utilisateurs'] : null) as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    final total = _readTotal(data);
    return (utilisateurs: list, total: total);
  }

  Future<Map<String, dynamic>> getUtilisateur(String id) async {
    final res = await _api.get('/admin/utilisateurs/$id', useAuth: true);
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> patchUtilisateur(
    String id, {
    bool? estValide,
    bool? estActif,
    String? action,
    String? raison,
  }) async {
    final body = <String, dynamic>{};
    if (estValide != null) body['est_valide'] = estValide;
    if (estActif != null) body['est_actif'] = estActif;
    if (action != null) body['action'] = action;
    if (raison != null) body['raison'] = raison;
    final res = await _api.patch('/admin/utilisateurs/$id', body: body, useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur');
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  Future<Map<String, dynamic>> deleteUtilisateur(String id) async {
    final res = await _api.delete('/admin/utilisateurs/$id', useAuth: true);
    return _parseJsonOk(res);
  }

  // ── OFFRES ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> getOffres({
    int page = 1,
    int limite = 20,
    String? statut,
    String? recherche,
  }) async {
    final q = <String, String>{
      'page': '$page',
      'limite': '$limite',
      ...?(statut == null ? null : {'statut': statut}),
      ...?(recherche == null ? null : {'recherche': recherche}),
    };
    final uri =
        '/admin/offres?${q.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
    final res = await _api.get(uri, useAuth: true);
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> getOffreAdmin(String id) async {
    final res = await _api.get('/admin/offres/$id', useAuth: true);
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> patchOffreAdmin(
    String id, {
    required String action,
    String? raisonRefus,
  }) async {
    final body = <String, dynamic>{'action': action};
    if (raisonRefus != null) body['raison_refus'] = raisonRefus;
    final res = await _api.patch('/admin/offres/$id', body: body, useAuth: true);
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> deleteOffreAdmin(String id) async {
    final res = await _api.delete('/admin/offres/$id', useAuth: true);
    return _parseJsonOk(res);
  }

  // ── ENTREPRISES ────────────────────────────────────────────

  Future<Map<String, dynamic>> getEntreprises({
    int page = 1,
    int limite = 20,
    String? statut,
  }) async {
    final q = <String, String>{
      'page': '$page',
      'limite': '$limite',
      ...?(statut == null ? null : {'statut': statut}),
    };
    final uri =
        '/admin/entreprises?${q.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
    final res = await _api.get(uri, useAuth: true);
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> patchEntrepriseAdmin(
    String entrepriseId, {
    required String action,
    String? raison,
  }) async {
    final body = <String, dynamic>{'action': action};
    if (raison != null) body['raison'] = raison;
    final res = await _api.patch('/admin/entreprises/$entrepriseId', body: body, useAuth: true);
    return _parseJsonOk(res);
  }

  // ── CANDIDATURES ───────────────────────────────────────────

  Future<Map<String, dynamic>> getCandidaturesAdmin({
    int page = 1,
    int limite = 20,
    String? statut,
    String? entrepriseId,
    String? chercheurId,
    String? offreId,
    String? dateDebut,
    String? dateFin,
    String? chercheurNom,
    String? entrepriseNom,
  }) async {
    final q = <String, String>{
      'page': '$page',
      'limite': '$limite',
      ...?(statut == null ? null : {'statut': statut}),
      ...?(entrepriseId == null ? null : {'entreprise_id': entrepriseId}),
      ...?(chercheurId == null ? null : {'chercheur_id': chercheurId}),
      ...?(offreId == null ? null : {'offre_id': offreId}),
      ...?(dateDebut == null ? null : {'date_debut': dateDebut}),
      ...?(dateFin == null ? null : {'date_fin': dateFin}),
      ...?(chercheurNom == null || chercheurNom.isEmpty ? null : {'chercheur_nom': chercheurNom}),
      ...?(entrepriseNom == null || entrepriseNom.isEmpty ? null : {'entreprise_nom': entrepriseNom}),
    };
    final uri =
        '/admin/candidatures?${q.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
    final res = await _api.get(uri, useAuth: true);
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> getCandidatureAdmin(String candidatureId) async {
    final res = await _api.get('/admin/candidatures/$candidatureId', useAuth: true);
    return _parseJsonOk(res);
  }

  Future<String> exportCandidaturesCsv() async {
    final res = await _api.get('/admin/candidatures/export', useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur export');
    }
    return res.body;
  }

  Future<String> exportOffresCsv() async {
    final res = await _api.get('/admin/offres/export/csv', useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur export');
    }
    return res.body;
  }

  Future<String> exportUtilisateursCsv() async {
    final res = await _api.get('/admin/utilisateurs/export/csv', useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur export');
    }
    return res.body;
  }

  Future<Map<String, dynamic>> getEntrepriseDetail(String id) async {
    final res = await _api.get('/admin/entreprises/$id', useAuth: true);
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> getMesNotifications({
    bool nonLuesSeulement = false,
    int page = 1,
    int limite = 20,
  }) async {
    final res = await _api.get(
      '/notifications/mes?page=$page&limite=$limite&non_lues_seulement=$nonLuesSeulement',
      useAuth: true,
    );
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> marquerNotificationLue(String id) async {
    final res = await _api.patch('/notifications/$id', body: {}, useAuth: true);
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> marquerToutesNotificationsLues() async {
    final res = await _api.patch('/notifications/tout-lire/action', body: {}, useAuth: true);
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> supprimerNotification(String id) async {
    final res = await _api.delete('/notifications/$id', useAuth: true);
    return _parseJsonOk(res);
  }

  // ── SIGNALEMENTS ───────────────────────────────────────────

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
        ((data['data'] is Map ? (data['data'] as Map)['signalements'] : null) as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    final total = _readTotal(data);
    return (signalements: list, total: total);
  }

  Future<Map<String, dynamic>> traiterSignalement(
    String id,
    String statut, {
    String? noteAdmin,
  }) async {
    final body = <String, dynamic>{'statut': statut};
    if (noteAdmin != null && noteAdmin.trim().isNotEmpty) {
      body['note_admin'] = noteAdmin.trim();
    }
    final res = await _api.patch(
      '/admin/signalements/$id',
      body: body,
      useAuth: true,
    );
    return _parseJsonOk(res);
  }

  Future<({List<Map<String, dynamic>> temoignages, int? total})> getTemoignagesAdmin({
    String statut = 'all',
    int offset = 0,
    int limit = 50,
  }) async {
    final q = <String, String>{
      'offset': '$offset',
      'limit': '$limit',
      'statut': statut,
    };
    final uri =
        '/admin/temoignages?${q.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
    final res = await _api.get(uri, useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur témoignages');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final inner = data['data'] is Map ? data['data'] as Map<String, dynamic> : null;
    final list = (inner?['temoignages'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        const <Map<String, dynamic>>[];
    final total = inner?['total'] is int ? inner!['total'] as int : _readTotal(data);
    return (temoignages: list, total: total);
  }

  Future<Map<String, dynamic>> modererTemoignage(
    String id, {
    required String action,
    String? noteModeration,
  }) async {
    final body = <String, dynamic>{'action': action};
    if (noteModeration != null && noteModeration.trim().isNotEmpty) {
      body['note_moderation'] = noteModeration.trim();
    }
    final res = await _api.patch(
      '/admin/temoignages/$id',
      body: body,
      useAuth: true,
    );
    return _parseJsonOk(res);
  }

  // ── NOTIFICATIONS ─────────────────────────────────────────

  Future<Map<String, dynamic>> envoyerNotification({
    required String titre,
    required String message,
    required String typeDestinataire,
    String? destinataireId,
    String type = 'systeme',
    String? lien,
  }) async {
    final notifBody = <String, dynamic>{
      'titre': titre,
      'message': message,
      'type': type,
      'type_destinataire': typeDestinataire,
    };
    if (destinataireId != null) notifBody['destinataire_id'] = destinataireId;
    if (lien != null) notifBody['lien'] = lien;
    final res = await _api.post(
      '/admin/notifications',
      body: notifBody,
      useAuth: true,
    );
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> getNotificationsAdmin({int page = 1, int limite = 20}) async {
    final res = await _api.get('/admin/notifications?page=$page&limite=$limite', useAuth: true);
    return _parseJsonOk(res);
  }

  // ── PARAMÈTRES ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getParametres({String? categorie}) async {
    final uri = categorie == null
        ? '/admin/parametres'
        : '/admin/parametres?categorie=${Uri.encodeQueryComponent(categorie)}';
    final res = await _api.get(uri, useAuth: true);
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> updateParametres(List<Map<String, dynamic>> parametres) async {
    final res = await _api.put(
      '/admin/parametres',
      body: {'parametres': parametres},
      useAuth: true,
    );
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> viderCacheParametres() async {
    final res = await _api.post('/admin/parametres/vider-cache', body: {}, useAuth: true);
    return _parseJsonOk(res);
  }

  /// Réponse toujours parsée (y compris `success: false` en HTTP 200).
  Future<Map<String, dynamic>> testerConnexionIA() async {
    final res = await _api.post('/admin/parametres/tester-ia', body: {}, useAuth: true);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Teste verify() + envoi d’un email (destinataire = [email] ou email du compte admin).
  Future<Map<String, dynamic>> testerSMTP({String? destinataire}) async {
    final res = await _api.post(
      '/admin/parametres/tester-smtp',
      body: (destinataire != null && destinataire.isNotEmpty)
          ? {'destinataire': destinataire}
          : <String, dynamic>{},
      useAuth: true,
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadLogoPlateforme({
    required List<int> fileBytes,
    required String filename,
    String? mimeType,
  }) async {
    MediaType? contentType;
    if (mimeType != null && mimeType.isNotEmpty) {
      try {
        contentType = MediaType.parse(mimeType);
      } catch (_) {
        contentType = null;
      }
    }
    final streamed = await _api.postMultipart(
      '/admin/parametres/upload-logo',
      fileBytes: fileBytes,
      filename: filename,
      fieldName: 'logo',
      useAuth: true,
      contentType: contentType,
    );
    final res = await http.Response.fromStream(streamed);
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> getBannieresAdmin() async {
    final res = await _api.get('/admin/bannieres', useAuth: true);
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> createBanniereAdmin({
    required Map<String, String> fields,
    List<int>? imageBytes,
    String? imageFilename,
    String? imageMime,
  }) async {
    MediaType? ct;
    if (imageMime != null) {
      try {
        ct = MediaType.parse(imageMime);
      } catch (_) {
        ct = null;
      }
    }
    final streamed = await _api.postMultipartForm(
      '/admin/bannieres',
      fields: fields,
      fileBytes: imageBytes,
      filename: imageFilename,
      fileFieldName: 'image',
      fileContentType: ct,
    );
    final res = await http.Response.fromStream(streamed);
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> updateBanniereAdmin(String id, Map<String, dynamic> body) async {
    final res = await _api.patch('/admin/bannieres/$id', body: body, useAuth: true);
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> deleteBanniereAdmin(String id) async {
    final res = await _api.delete('/admin/bannieres/$id', useAuth: true);
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> reordonnerBannieresAdmin(List<Map<String, dynamic>> ordre) async {
    final res = await _api.patch(
      '/admin/bannieres/reordonner/ordre',
      body: {'ordre': ordre},
      useAuth: true,
    );
    return _parseJsonOk(res);
  }

  // ── PROFIL ADMIN (connecté) ───────────────────────────────

  Future<Map<String, dynamic>> getProfilAdmin() async {
    final res = await _api.get('/admin/profil', useAuth: true);
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> updateProfilAdmin({
    String? nom,
    String? telephone,
    String? adresse,
    String? ancienMdp,
    String? nouveauMdp,
  }) async {
    final body = <String, dynamic>{};
    if (nom != null) body['nom'] = nom;
    if (telephone != null) body['telephone'] = telephone;
    if (adresse != null) body['adresse'] = adresse;
    if (ancienMdp != null) body['ancien_mdp'] = ancienMdp;
    if (nouveauMdp != null) body['nouveau_mdp'] = nouveauMdp;
    final res = await _api.patch('/admin/profil', body: body, useAuth: true);
    return _parseJsonOk(res);
  }

  /// Envoie un code à 6 chiffres sur la nouvelle adresse (changement e-mail admin).
  Future<Map<String, dynamic>> demandeChangementEmailAdmin(String nouvelEmail) async {
    final res = await _api.post(
      '/admin/profil/email/demande',
      body: {'nouvel_email': nouvelEmail.trim()},
      useAuth: true,
    );
    return _parseJsonOk(res);
  }

  /// Confirme le code reçu par e-mail et applique la nouvelle adresse.
  Future<Map<String, dynamic>> confirmerChangementEmailAdmin({
    required String nouvelEmail,
    required String code,
  }) async {
    final res = await _api.post(
      '/admin/profil/email/confirmer',
      body: {
        'nouvel_email': nouvelEmail.trim(),
        'code': code.trim(),
      },
      useAuth: true,
    );
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> uploadAdminPhoto({
    required List<int> fileBytes,
    required String filename,
    String? mimeType,
  }) async {
    MediaType? contentType;
    if (mimeType != null && mimeType.isNotEmpty) {
      try {
        contentType = MediaType.parse(mimeType);
      } catch (_) {
        contentType = null;
      }
    }
    final streamed = await _api.postMultipart(
      '/admin/profil/photo',
      fileBytes: fileBytes,
      filename: filename,
      fieldName: 'photo',
      useAuth: true,
      contentType: contentType,
    );
    final res = await http.Response.fromStream(streamed);
    return _parseJsonOk(res);
  }

  // ── PARCOURS CARRIÈRE (RESSOURCES) ─────────────────────────

  Future<Map<String, dynamic>> getRessourcesParcoursAdmin() async {
    final res = await _api.get('/admin/ressources', useAuth: true);
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> getRessourceParcoursAdmin(String id) async {
    final res = await _api.get('/admin/ressources/$id', useAuth: true);
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> createRessourceParcoursAdmin({
    required Map<String, String> fields,
    List<int>? fichierBytes,
    String? fichierFilename,
    String? fichierMime,
    List<int>? couvertureBytes,
    String? couvertureFilename,
    String? couvertureMime,
  }) async {
    MediaType? ctFichier;
    if (fichierMime != null) {
      try {
        ctFichier = MediaType.parse(fichierMime);
      } catch (_) {
        ctFichier = null;
      }
    }
    MediaType? ctCouv;
    if (couvertureMime != null) {
      try {
        ctCouv = MediaType.parse(couvertureMime);
      } catch (_) {
        ctCouv = null;
      }
    }
    final files = <String, ({List<int> bytes, String filename, MediaType? contentType})>{};
    if (fichierBytes != null && fichierFilename != null && fichierFilename.isNotEmpty) {
      files['fichier'] = (bytes: fichierBytes, filename: fichierFilename, contentType: ctFichier);
    }
    if (couvertureBytes != null && couvertureFilename != null && couvertureFilename.isNotEmpty) {
      files['couverture'] = (bytes: couvertureBytes, filename: couvertureFilename, contentType: ctCouv);
    }
    final streamed = await _api.postMultipartFormMulti(
      '/admin/ressources',
      fields: fields,
      files: files.isEmpty ? null : files,
    );
    final res = await http.Response.fromStream(streamed);
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> patchPublierRessourceParcoursAdmin(String id, bool estPublie) async {
    final res = await _api.patch(
      '/admin/ressources/$id/publier',
      body: {'est_publie': estPublie},
      useAuth: true,
    );
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> patchRessourceParcoursAdmin(String id, Map<String, dynamic> body) async {
    final res = await _api.patch('/admin/ressources/$id', body: body, useAuth: true);
    return _parseJsonOk(res);
  }

  Future<Map<String, dynamic>> deleteRessourceParcoursAdmin(String id) async {
    final res = await _api.delete('/admin/ressources/$id');
    return _parseJsonOk(res);
  }

  // ── ILLUSTRATIONS IA (homepage, DALL-E) ───────────────────

  Future<Map<String, dynamic>> getIllustrationsIaListe() async {
    final res = await _api.get('/illustration/liste', useAuth: true);
    return _parseJsonOk(res);
  }

  /// Réponse brute (success peut être false avec HTTP 200).
  Future<Map<String, dynamic>> postIllustrationGenerer() async {
    final res = await _api.post('/illustration/generer', body: {}, useAuth: true);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> patchIllustrationActiver(String id) async {
    final res = await _api.patch('/illustration/$id/activer', body: {}, useAuth: true);
    return _parseJsonOk(res);
  }

  /// Test isolé Anthropic ou OpenAI (texte) — réponse JSON même si `success: false`.
  Future<Map<String, dynamic>> postAdminTestIa(String provider) async {
    final res = await _api.post(
      '/admin/test-ia',
      body: {'provider': provider},
      useAuth: true,
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Test DALL-E (image 256×256, dall-e-2).
  Future<Map<String, dynamic>> postAdminTestDalle() async {
    final res = await _api.post('/admin/test-dalle', body: {}, useAuth: true);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
