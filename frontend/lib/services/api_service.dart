import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  String get _base => apiBaseUrl + apiPrefix;

  Future<Map<String, String>> _headers({bool withAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth) {
      final token = await AuthService().getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<http.Response> get(String path, {bool useAuth = false}) async {
    return http.get(
      Uri.parse(_base + path),
      headers: await _headers(withAuth: useAuth),
    );
  }

  Future<http.Response> post(
    String path, {
    Object? body,
    bool useAuth = false,
  }) async {
    return http.post(
      Uri.parse(_base + path),
      headers: await _headers(withAuth: useAuth),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> patch(
    String path, {
    Object? body,
    bool useAuth = true,
  }) async {
    return http.patch(
      Uri.parse(_base + path),
      headers: await _headers(withAuth: useAuth),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> put(
    String path, {
    Object? body,
    bool useAuth = true,
  }) async {
    return http.put(
      Uri.parse(_base + path),
      headers: await _headers(withAuth: useAuth),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> delete(
    String path, {
    bool useAuth = true,
    Object? body,
  }) async {
    return http.delete(
      Uri.parse(_base + path),
      headers: await _headers(withAuth: useAuth),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  /// Upload multipart (ex. CV) — champ fichier attendu : `file`
  /// [contentType] : ex. `image/jpeg` en minuscules (évite image/PNG rejeté par certains backends).
  Future<http.StreamedResponse> postMultipart(
    String path, {
    required List<int> fileBytes,
    required String filename,
    String fieldName = 'file',
    bool useAuth = true,
    MediaType? contentType,
  }) async {
    final uri = Uri.parse(_base + path);
    final request = http.MultipartRequest('POST', uri);
    final token = await AuthService().getToken();
    if (useAuth && token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(
      http.MultipartFile.fromBytes(
        fieldName,
        fileBytes,
        filename: filename,
        contentType: contentType,
      ),
    );
    return request.send();
  }

  /// Multipart avec champs texte + fichier optionnel (ex. bannière admin).
  Future<http.StreamedResponse> postMultipartForm(
    String path, {
    required Map<String, String> fields,
    List<int>? fileBytes,
    String fileFieldName = 'image',
    String? filename,
    MediaType? fileContentType,
    bool useAuth = true,
  }) async {
    final uri = Uri.parse(_base + path);
    final request = http.MultipartRequest('POST', uri);
    final token = await AuthService().getToken();
    if (useAuth && token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.fields.addAll(fields);
    if (fileBytes != null && filename != null && filename.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          fileFieldName,
          fileBytes,
          filename: filename,
          contentType: fileContentType,
        ),
      );
    }
    return request.send();
  }

  /// Multipart avec plusieurs fichiers optionnels (ex. ressources Parcours Carrière).
  Future<http.StreamedResponse> postMultipartFormMulti(
    String path, {
    required Map<String, String> fields,
    Map<String, ({List<int> bytes, String filename, MediaType? contentType})>? files,
    bool useAuth = true,
  }) async {
    final uri = Uri.parse(_base + path);
    final request = http.MultipartRequest('POST', uri);
    final token = await AuthService().getToken();
    if (useAuth && token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.fields.addAll(fields);
    for (final e in (files ?? {}).entries) {
      request.files.add(
        http.MultipartFile.fromBytes(
          e.key,
          e.value.bytes,
          filename: e.value.filename,
          contentType: e.value.contentType,
        ),
      );
    }
    return request.send();
  }

  static String? errorMessage(http.Response response) {
    try {
      final map = jsonDecode(response.body) as Map<String, dynamic>?;
      return map?['message'] as String?;
    } catch (_) {
      return null;
    }
  }
}
