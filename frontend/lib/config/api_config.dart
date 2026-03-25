import 'package:flutter/foundation.dart';

/// URL de base de l'API backend EmploiConnect.
String get apiBaseUrl {
  if (kIsWeb) {
    return 'http://localhost:3000';
  }
  return 'http://10.0.2.2:3000';
}

const String apiPrefix = '/api';
