import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'google_auth_service.dart';

const _keyToken = 'emploiconnect_token';
const _keyUser = 'emploiconnect_user';
const _keySessionIdleMin = 'emploiconnect_session_idle_min';

String _messageErreurGoogleSignIn(Object e) {
  final s = e.toString();
  if (s.contains('people.googleapis.com') ||
      s.contains('People API') ||
      (s.contains('PERMISSION_DENIED') && s.contains('SERVICE_DISABLED'))) {
    return 'L’API Google « People » n’est pas activée sur le projet Cloud utilisé par '
        'votre Client ID. Dans Google Cloud Console : Bibliothèque → « People API » → '
        'Activer, puis attendez quelques minutes. '
        'Lien direct : https://console.cloud.google.com/apis/library/people.googleapis.com';
  }
  return s;
}

class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  Future<void> saveSession(
    String token,
    Map<String, dynamic> user, {
    int? sessionIdleMinutes,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode(user));
    if (sessionIdleMinutes != null && sessionIdleMinutes > 0) {
      await prefs.setInt(_keySessionIdleMin, sessionIdleMinutes);
    } else {
      await prefs.remove(_keySessionIdleMin);
    }
  }

  Future<int?> getStoredSessionIdleMinutes() async {
    final prefs = await _prefs;
    if (!prefs.containsKey(_keySessionIdleMin)) return null;
    return prefs.getInt(_keySessionIdleMin);
  }

  Future<String?> getToken() async {
    final prefs = await _prefs;
    return prefs.getString(_keyToken);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyUser);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Met à jour les champs utilisateur stockés localement (ex. après changement d’e-mail en profil admin).
  Future<void> patchStoredUser(Map<String, dynamic> updates) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyUser);
    if (raw == null) return;
    try {
      final cur = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      updates.forEach((k, v) {
        if (v != null) cur[k] = v;
      });
      await prefs.setString(_keyUser, jsonEncode(cur));
    } catch (_) {}
  }

  Future<void> logout() async {
    final prefs = await _prefs;
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
    await prefs.remove(_keySessionIdleMin);
  }

  Future<bool> get isLoggedIn async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<(bool, String?)> register({
    required String email,
    required String motDePasse,
    required String nom,
    required String role,
    String? telephone,
    String? adresse,
    String? nomEntreprise,
  }) async {
    final res = await ApiService().post('/auth/register', body: {
      'email': email,
      'mot_de_passe': motDePasse,
      'nom': nom,
      'role': role,
      ...?(telephone == null ? null : {'telephone': telephone}),
      ...?(adresse == null ? null : {'adresse': adresse}),
      ...?(nomEntreprise == null || nomEntreprise.trim().isEmpty
          ? null
          : {'nom_entreprise': nomEntreprise.trim()}),
    });
    if (res.statusCode == 201) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final token = data['token'] as String?;
      final user = data['user'] as Map<String, dynamic>?;
      if (token != null && user != null) {
        final idle = data['session_idle_minutes'];
        final idleM = idle is int ? idle : int.tryParse(idle?.toString() ?? '');
        await saveSession(token, user, sessionIdleMinutes: idleM);
        return (true, null);
      }
    }
    final msg = ApiService.errorMessage(res) ?? 'Erreur lors de l\'inscription';
    return (false, msg);
  }

  /// [needsTwoFactor] : mot de passe OK, saisir le code TOTP puis appeler [completeLogin2Fa].
  Future<
      ({
        bool success,
        String? message,
        bool needsTwoFactor,
        String? tempToken,
        Map<String, dynamic>? userPreview,
      })> login({
    required String email,
    required String motDePasse,
  }) async {
    final res = await ApiService().post('/auth/login', body: {
      'email': email,
      'mot_de_passe': motDePasse,
    });
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['two_factor_required'] == true) {
        return (
          success: false,
          message: null,
          needsTwoFactor: true,
          tempToken: data['temp_token'] as String?,
          userPreview: data['user'] is Map ? Map<String, dynamic>.from(data['user'] as Map) : null,
        );
      }
      final token = data['token'] as String?;
      final user = data['user'] as Map<String, dynamic>?;
      if (token != null && user != null) {
        final idle = data['session_idle_minutes'];
        final idleM = idle is int ? idle : int.tryParse(idle?.toString() ?? '');
        await saveSession(token, user, sessionIdleMinutes: idleM);
        return (
          success: true,
          message: null,
          needsTwoFactor: false,
          tempToken: null,
          userPreview: null,
        );
      }
    }
    final msg = ApiService.errorMessage(res) ?? 'Email ou mot de passe incorrect';
    return (
      success: false,
      message: msg,
      needsTwoFactor: false,
      tempToken: null,
      userPreview: null,
    );
  }

  Future<(bool success, String? message)> completeLogin2Fa({
    required String tempToken,
    required String code,
  }) async {
    final res = await ApiService().post('/auth/login/2fa', body: {
      'temp_token': tempToken,
      'code': code.trim(),
    });
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final token = data['token'] as String?;
      final user = data['user'] as Map<String, dynamic>?;
      if (token != null && user != null) {
        final idle = data['session_idle_minutes'];
        final idleM = idle is int ? idle : int.tryParse(idle?.toString() ?? '');
        await saveSession(token, user, sessionIdleMinutes: idleM);
        return (true, null);
      }
    }
    return (false, ApiService.errorMessage(res) ?? 'Code 2FA invalide');
  }

  /// Connexion / inscription via Google.
  /// Annulation → `ok: false, message: null` ; validation manuelle (201) → `pendingValidation: true`.
  /// Admin 2FA : `ok: false`, `twoFaTempToken` renseigné.
  Future<
      ({
        bool ok,
        String? message,
        bool pendingValidation,
        String? twoFaTempToken,
        Map<String, dynamic>? twoFaUser,
      })> loginWithGoogle({
    String? role,
  }) async {
    ({String? idToken, String? accessToken}) tokens;
    try {
      tokens = await GoogleAuthService.obtainGoogleTokens();
    } catch (e, st) {
      debugPrint('[AuthService] loginWithGoogle obtainGoogleTokens: $e\n$st');
      return (
        ok: false,
        message: _messageErreurGoogleSignIn(e),
        pendingValidation: false,
        twoFaTempToken: null,
        twoFaUser: null,
      );
    }
    final hasId = tokens.idToken != null && tokens.idToken!.isNotEmpty;
    final hasAt = tokens.accessToken != null && tokens.accessToken!.isNotEmpty;
    if (!hasId && !hasAt) {
      if (kIsWeb) {
        return (
          ok: false,
          message:
              'Connexion Google : aucun jeton après la fenêtre Google. Vérifiez que la popup '
              "n'est pas bloquée, la navigation non privée, et les origines OAuth pour localhost.",
          pendingValidation: false,
          twoFaTempToken: null,
          twoFaUser: null,
        );
      }
      return (
        ok: false,
        message: null,
        pendingValidation: false,
        twoFaTempToken: null,
        twoFaUser: null,
      );
    }
    final body = <String, dynamic>{};
    if (hasId) {
      body['id_token'] = tokens.idToken;
    }
    if (hasAt) {
      body['access_token'] = tokens.accessToken;
    }
    if (role != null && role.isNotEmpty) {
      body['role'] = role;
    }
    final res = await ApiService().post('/auth/google', body: body);
    Map<String, dynamic>? data;
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>?;
    } catch (_) {
      data = null;
    }
    if (res.statusCode == 201) {
      final msg = data?['message'] as String? ?? 'Compte créé. En attente de validation.';
      return (
        ok: false,
        message: msg,
        pendingValidation: true,
        twoFaTempToken: null,
        twoFaUser: null,
      );
    }
    if (res.statusCode == 200 && data?['success'] == true) {
      final inner = data!['data'] as Map<String, dynamic>?;
      if (inner?['two_factor_required'] == true) {
        final t = inner!['temp_token'] as String?;
        final u = inner['user'] is Map ? Map<String, dynamic>.from(inner['user'] as Map) : null;
        return (
          ok: false,
          message: null,
          pendingValidation: false,
          twoFaTempToken: t,
          twoFaUser: u,
        );
      }
      final token = inner?['token'] as String?;
      final user = inner?['user'] as Map<String, dynamic>?;
      if (token != null && user != null) {
        final idle = inner?['session_idle_minutes'];
        final idleM = idle is int ? idle : int.tryParse(idle?.toString() ?? '');
        await saveSession(token, user, sessionIdleMinutes: idleM);
        return (
          ok: true,
          message: null,
          pendingValidation: false,
          twoFaTempToken: null,
          twoFaUser: null,
        );
      }
    }
    final msg = ApiService.errorMessage(res) ?? 'Connexion Google impossible';
    return (
      ok: false,
      message: msg,
      pendingValidation: false,
      twoFaTempToken: null,
      twoFaUser: null,
    );
  }

  /// Demande de lien de réinitialisation (réponse générique côté API).
  Future<(bool ok, String? message)> forgotPassword(String email) async {
    final res = await ApiService().post(
      '/auth/forgot-password',
      body: {'email': email.trim().toLowerCase()},
    );
    if (res.statusCode == 200) return (true, null);
    return (false, ApiService.errorMessage(res));
  }

  Future<(bool ok, String? message)> resetPassword({
    required String token,
    required String motDePasse,
  }) async {
    final res = await ApiService().post(
      '/auth/reset-password',
      body: {'token': token, 'mot_de_passe': motDePasse},
    );
    if (res.statusCode == 200) return (true, null);
    return (false, ApiService.errorMessage(res));
  }
}
