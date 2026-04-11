import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';
import 'download_io_stub.dart' if (dart.library.io) 'download_io.dart' as io_save;
import 'download_stub.dart' if (dart.library.html) 'download_web.dart';

/// Téléchargement CSV (Web : blob navigateur ; iOS/Android/Desktop : fichier).
class DownloadService {
  DownloadService._();

  static String _apiUrl(String pathAndQuery) {
    final p = pathAndQuery.startsWith('/') ? pathAndQuery : '/$pathAndQuery';
    return '$apiBaseUrl$apiPrefix$p';
  }

  /// GET authentifié puis enregistrement (réponse brute, headers backend conservés côté contenu).
  static Future<void> downloadCsvFromApi({
    required String apiPathAndQuery,
    required String token,
    required String fileName,
    BuildContext? context,
  }) async {
    final uri = Uri.parse(_apiUrl(apiPathAndQuery));
    final response = await http.get(
      uri,
      headers: {
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Accept': 'text/csv, text/plain, */*',
      },
    );

    if (response.statusCode != 200) {
      final msg = response.body.isNotEmpty ? response.body : 'HTTP ${response.statusCode}';
      throw Exception('Erreur export (${response.statusCode}): $msg');
    }

    final bytes = Uint8List.fromList(response.bodyBytes);
    if (context != null && !context.mounted) return;
    await saveCsvBytes(bytes: bytes, fileName: fileName, context: context);
  }

  /// CSV construit côté client (ex. liste entreprises sans route d’export API).
  static Future<void> downloadCsvFromString({
    required String csvContent,
    required String fileName,
    BuildContext? context,
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(csvContent));
    await saveCsvBytes(bytes: bytes, fileName: fileName, context: context);
  }

  static Future<void> saveCsvBytes({
    required Uint8List bytes,
    required String fileName,
    BuildContext? context,
  }) async {
    await saveBytes(
      bytes: bytes,
      fileName: fileName,
      mimeType: 'text/csv;charset=utf-8',
      context: context,
    );
  }

  static Future<void> saveBytes({
    required Uint8List bytes,
    required String fileName,
    String mimeType = 'application/octet-stream',
    BuildContext? context,
  }) async {
    if (kIsWeb) {
      downloadFileWeb(bytes, fileName, mimeType: mimeType);
      return;
    }

    final path = await io_save.saveCsvToDevice(bytes, fileName);
    if (context != null && context.mounted && path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Fichier enregistré : $path',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  static Future<void> downloadFileFromUrl({
    required String url,
    required String fileName,
    String mimeType = 'application/octet-stream',
    BuildContext? context,
    void Function(int received, int total)? onProgress,
  }) async {
    final dio = Dio();
    final response = await dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes, followRedirects: true),
      onReceiveProgress: onProgress,
    );
    final bytes = Uint8List.fromList(response.data ?? const <int>[]);
    if (bytes.isEmpty) {
      throw Exception('Téléchargement vide.');
    }
    await saveBytes(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
      context: context,
    );
  }

  /// GET binaire authentifié (ex. pièce jointe messagerie, URL signée expirée côté stockage).
  static Future<void> downloadFileFromAuthenticatedApi({
    required String apiPath,
    required String fileName,
    String mimeType = 'application/octet-stream',
    BuildContext? context,
    void Function(int received, int total)? onProgress,
  }) async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Connectez-vous pour télécharger le fichier.');
    }
    final base =
        apiBaseUrl.endsWith('/') ? apiBaseUrl.substring(0, apiBaseUrl.length - 1) : apiBaseUrl;
    final prefix = apiPrefix.startsWith('/') ? apiPrefix : '/$apiPrefix';
    final path = apiPath.startsWith('/') ? apiPath : '/$apiPath';
    final uri = '$base$prefix$path';

    final dio = Dio();
    final response = await dio.get<List<int>>(
      uri,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        headers: <String, dynamic>{
          'Authorization': 'Bearer $token',
          'Accept': '*/*',
        },
      ),
      onReceiveProgress: onProgress,
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur serveur (${response.statusCode}).');
    }
    final bytes = Uint8List.fromList(response.data ?? const <int>[]);
    if (bytes.isEmpty) {
      throw Exception('Téléchargement vide.');
    }
    await saveBytes(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
      context: context,
    );
  }

  static void showWebDownloadSnackBar(BuildContext context, String fileName) {
    if (!kIsWeb || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download_done_outlined, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$fileName — téléchargement lancé',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
