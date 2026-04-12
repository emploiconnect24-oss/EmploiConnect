import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'google_auth_obtain_stub.dart'
    if (dart.library.io) 'google_auth_obtain_io.dart'
    if (dart.library.html) 'google_auth_obtain_web.dart'
    if (dart.library.js_interop) 'google_auth_obtain_web.dart';

/// Connexion Google côté app → [POST /api/auth/google] avec `id_token` et/ou `access_token`.
class GoogleAuthService {
  GoogleAuthService._();

  static ({bool actif, String clientId})? _cachedConfig;

  static Future<void> prefetchConfig() async {
    try {
      _cachedConfig = await _fetchConfig();
      final id = _cachedConfig!.clientId;
      debugPrint(
        '[GoogleAuth] prefetchConfig: actif=${_cachedConfig!.actif} '
        'client_id=${id.isEmpty ? "(vide)" : "${id.length > 12 ? id.substring(0, 12) : id}..."}',
      );
    } catch (e, st) {
      debugPrint('[GoogleAuth] prefetchConfig erreur: $e\n$st');
      _cachedConfig = (actif: false, clientId: '');
    }
  }

  static ({bool actif, String clientId}) _parseConfigBody(Map<String, dynamic>? body) {
    final nested = body?['data'] as Map<String, dynamic>?;
    final Map<String, dynamic>? src = nested ?? body;
    final actif = src?['actif'] == true || src?['actif'] == 'true';
    final id = src?['client_id']?.toString().trim() ?? '';
    return (actif: actif, clientId: id);
  }

  static Future<({bool actif, String clientId})> _fetchConfig() async {
    final uri = Uri.parse('$apiBaseUrl$apiPrefix/auth/google-config');
    debugPrint('[GoogleAuth] GET $uri');
    final res = await http.get(uri, headers: const {'Accept': 'application/json'});
    debugPrint('[GoogleAuth] google-config status=${res.statusCode}');
    if (res.statusCode != 200) {
      debugPrint('[GoogleAuth] google-config body: ${res.body}');
      return (actif: false, clientId: '');
    }
    Map<String, dynamic>? body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('[GoogleAuth] JSON invalide: $e');
      return (actif: false, clientId: '');
    }
    final parsed = _parseConfigBody(body);
    _cachedConfig = parsed;
    return parsed;
  }

  /// Jetons Google : **id_token** (JWT) si disponible, sinon **access_token** (popup Web).
  static Future<({String? idToken, String? accessToken})> obtainGoogleTokens() async {
    try {
      debugPrint('[GoogleAuth] obtainGoogleTokens (kIsWeb=$kIsWeb)');
      final cfg = _cachedConfig ?? await _fetchConfig();
      if (!cfg.actif) {
        debugPrint('[GoogleAuth] OAuth Google désactivé côté serveur');
        return (idToken: null, accessToken: null);
      }
      if (cfg.clientId.isEmpty) {
        debugPrint('[GoogleAuth] Client ID vide — Admin → Authentification ou prefetch échoué');
        return (idToken: null, accessToken: null);
      }

      if (kIsWeb) {
        debugPrint('[GoogleAuth] Web: flux popup GoogleSignIn');
      } else {
        debugPrint('[GoogleAuth] natif: GoogleSignIn (serverClientId)');
      }

      final tokens = await obtainGoogleTokensPlatform(clientIdFromBackend: cfg.clientId);
      final hasId = tokens.idToken != null && tokens.idToken!.isNotEmpty;
      final hasAt = tokens.accessToken != null && tokens.accessToken!.isNotEmpty;
      if (!hasId && !hasAt) {
        if (kIsWeb) {
          debugPrint(
            '[GoogleAuth] Web: aucun jeton — popup bloquée, navigation privée, ou origines OAuth.',
          );
        } else {
          debugPrint('[GoogleAuth] natif: aucun jeton après signIn');
        }
        return (idToken: null, accessToken: null);
      }
      debugPrint(
        '[GoogleAuth] jetons: id_token=${hasId ? "${tokens.idToken!.length} c." : "—"} '
        'access_token=${hasAt ? "${tokens.accessToken!.length} c." : "—"}',
      );
      return tokens;
    } catch (e, st) {
      debugPrint('[GoogleAuth] obtainGoogleTokens erreur: $e\n$st');
      final s = e.toString();
      if (s.contains('people.googleapis.com') ||
          s.contains('People API has not been used') ||
          (s.contains('People API') && s.contains('disabled'))) {
        throw Exception(
          'People API: désactivée sur le projet Google Cloud du Client ID. '
          'Console → Bibliothèque → « People API » → Activer.',
        );
      }
      final short = s.length > 480 ? '${s.substring(0, 480)}…' : s;
      throw Exception(short);
    }
  }

  static Future<void> signOutGoogleOnly() async {
    final cfg = _cachedConfig ?? await _fetchConfig();
    await signOutGooglePlatform(clientIdFromBackend: cfg.clientId);
  }
}
