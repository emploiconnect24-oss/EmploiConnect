import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../core/utils/web_favicon.dart';

class AppConfigProvider extends ChangeNotifier {
  String _logoUrl = '';
  String _faviconUrl = '';
  String _messageMaintenance = '';
  bool _maintenanceActive = false;
  Map<String, String> _footer = const {
    'footer_email': 'contact@example.com',
    'footer_telephone': '+224 620 00 00 00',
    'footer_adresse': 'Conakry, Guinée',
    'footer_tagline': 'Plateforme intelligente de l\'emploi',
    'footer_linkedin': '',
    'footer_facebook': '',
    'footer_twitter': '',
    'footer_instagram': '',
    'footer_whatsapp': '',
  };
  List<Map<String, dynamic>> _bannieres = const [];

  String get logoUrl => _logoUrl;
  String get faviconUrl => _faviconUrl;
  String get messageMaintenanceText => _messageMaintenance;
  bool get modeMaintenanceActif => _maintenanceActive;
  Map<String, String> get footer => _footer;
  List<Map<String, dynamic>> get bannieres => _bannieres;

  Future<void> reload() async {
    try {
      final fallbackGeneral = http.Response('{"success":false,"data":{}}', 200);
      final fallbackFooter = http.Response('{"success":false,"data":{}}', 200);
      final fallbackBannieres = http.Response('{"success":false,"data":[]}', 200);

      final results = await Future.wait([
        http
            .get(Uri.parse('$apiBaseUrl$apiPrefix/config/general'))
            .timeout(const Duration(seconds: 5))
            .catchError((_) => fallbackGeneral),
        http
            .get(Uri.parse('$apiBaseUrl$apiPrefix/config/footer'))
            .timeout(const Duration(seconds: 5))
            .catchError((_) => fallbackFooter),
        http
            .get(Uri.parse('$apiBaseUrl$apiPrefix/bannieres'))
            .timeout(const Duration(seconds: 5))
            .catchError((_) => fallbackBannieres),
      ]);

      _applyGeneralResponse(results[0]);
      _applyFooterResponse(results[1]);
      _applyBannieresResponse(results[2]);
    } catch (e) {
      debugPrint('[AppConfigProvider] Erreur chargement: $e');
    } finally {
      notifyListeners();
    }
  }

  void updateLogo(String url) {
    _logoUrl = url.trim();
    notifyListeners();
  }

  Future<void> updateFavicon(String url) async {
    _faviconUrl = url.trim();
    await applyWebFavicon(_faviconUrl);
    notifyListeners();
  }

  void updateFooter(Map<String, String> values) {
    _footer = {..._footer, ...values};
    notifyListeners();
  }

  void updateMaintenance(bool active, String message) {
    _maintenanceActive = active;
    _messageMaintenance = message;
    notifyListeners();
  }

  void _applyGeneralResponse(http.Response res) {
    try {
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && map['data'] is Map) {
        final data = map['data'] as Map;
        _logoUrl = data['logo_url']?.toString() ?? _logoUrl;
        _faviconUrl = data['favicon_url']?.toString() ?? _faviconUrl;
        applyWebFavicon(_faviconUrl);
        final raw = data['mode_maintenance']?.toString().toLowerCase() ?? '';
        _maintenanceActive = raw == 'true' || raw == '1';
        _messageMaintenance = data['message_maintenance']?.toString() ?? '';
      } else if (res.statusCode == 503 && map['maintenance'] == true) {
        _maintenanceActive = true;
        _messageMaintenance = map['message']?.toString() ?? '';
      }
    } catch (_) {
      // ignore network errors
    }
  }

  void _applyFooterResponse(http.Response res) {
    try {
      if (res.statusCode == 200) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        final data = map['data'];
        if (data is Map) {
          _footer = data.map(
            (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
          );
        }
      }
    } catch (_) {
      // ignore network errors
    }
  }

  void _applyBannieresResponse(http.Response res) {
    try {
      if (res.statusCode == 200) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        final data = map['data'];
        if (data is List) {
          _bannieres = data
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      }
    } catch (_) {
      // ignore network errors
    }
  }
}
