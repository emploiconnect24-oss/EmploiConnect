import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _auth = AuthService();

  String? _token;
  Map<String, dynamic>? _user;
  bool _sessionLoaded = false;
  Timer? _sessionTimer;
  DateTime _lastActivity = DateTime.now();

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  String? get role => _user?['role'] as String?;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  bool get sessionLoaded => _sessionLoaded;

  void _cancelSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  DateTime? _tokenExpiryLocal(String? token) {
    if (token == null || token.isEmpty) return null;
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      var payload = parts[1];
      final pad = 4 - payload.length % 4;
      if (pad != 4) payload += '=' * pad;
      final normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      final map = jsonDecode(utf8.decode(base64.decode(normalized))) as Map<String, dynamic>;
      final exp = map['exp'];
      if (exp is num) {
        return DateTime.fromMillisecondsSinceEpoch((exp.toDouble() * 1000).round(), isUtc: true).toLocal();
      }
    } catch (_) {}
    return null;
  }

  Future<void> _tickSession() async {
    if (_token == null || _token!.isEmpty) return;
    final idleMin = await _auth.getStoredSessionIdleMinutes();
    if (idleMin != null && idleMin > 0) {
      if (DateTime.now().difference(_lastActivity) > Duration(minutes: idleMin)) {
        await logout();
        return;
      }
    }
    final exp = _tokenExpiryLocal(_token);
    if (exp != null && DateTime.now().isAfter(exp)) {
      await logout();
    }
  }

  void touchSessionActivity() {
    _lastActivity = DateTime.now();
  }

  Future<void> loadSession() async {
    _cancelSessionTimer();
    _token = await _auth.getToken();
    _user = await _auth.getUser();
    _sessionLoaded = true;
    _lastActivity = DateTime.now();
    if (isLoggedIn) {
      _sessionTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        unawaited(_tickSession());
      });
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _cancelSessionTimer();
    await _auth.logout();
    _token = null;
    _user = null;
    notifyListeners();
  }

  Future<
      ({
        bool success,
        String? message,
        bool needsTwoFactor,
        String? tempToken,
        Map<String, dynamic>? userPreview,
      })> login({required String email, required String motDePasse}) async {
    final r = await _auth.login(email: email, motDePasse: motDePasse);
    if (r.success) await loadSession();
    return r;
  }

  Future<(bool ok, String? message)> completeLogin2Fa({
    required String tempToken,
    required String code,
  }) async {
    final (ok, msg) = await _auth.completeLogin2Fa(tempToken: tempToken, code: code);
    if (ok) await loadSession();
    return (ok, msg);
  }

  /// [role] : uniquement à l’inscription (register). À la connexion (login), laisser `null` : le rôle vient de la BDD.
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
    final r = await _auth.loginWithGoogle(role: role);
    if (r.ok) await loadSession();
    return r;
  }

  /// Après login / register réussi : [HomeShellScreen] lit le rôle en session et affiche candidat, recruteur ou admin.
  void navigateToAuthenticatedHome(BuildContext context) {
    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
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
    final (ok, msg) = await _auth.register(
      email: email,
      motDePasse: motDePasse,
      nom: nom,
      role: role,
      telephone: telephone,
      adresse: adresse,
      nomEntreprise: nomEntreprise,
    );
    if (ok) await loadSession();
    return (ok, msg);
  }
}
