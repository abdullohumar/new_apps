import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Error dari API. [errors] berisi pesan per field saat validasi gagal (422).
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.errors = const {}});

  final String message;
  final int? statusCode;
  final Map<String, String> errors;

  @override
  String toString() => message;
}

class ApiResponse {
  ApiResponse(this.data, this.meta);

  final dynamic data;
  final Map<String, dynamic>? meta;

  bool get hasNext => meta?['has_next'] == true;
}

/// Satu-satunya tempat yang berbicara HTTP dengan News API.
class ApiClient {
  ApiClient._();
  static final instance = ApiClient._();

  static const baseUrl = 'https://knlhpjkhujzjyzrmxfjj.supabase.co/functions/v1/api';

  final _http = http.Client();

  Future<ApiResponse> get(String path, {Map<String, Object?> query = const {}}) =>
      _send('GET', path, query: query);

  Future<ApiResponse> post(String path, Map<String, Object?> body, {String? apiKey}) =>
      _send('POST', path, body: body, apiKey: apiKey);

  Future<ApiResponse> put(String path, Map<String, Object?> body, {String? apiKey}) =>
      _send('PUT', path, body: body, apiKey: apiKey);

  Future<ApiResponse> delete(String path, {String? apiKey}) => _send('DELETE', path, apiKey: apiKey);

  Future<ApiResponse> _send(
    String method,
    String path, {
    Map<String, Object?> query = const {},
    Map<String, Object?>? body,
    String? apiKey,
  }) async {
    final params = {
      for (final e in query.entries)
        if (e.value != null && '${e.value}'.isNotEmpty) e.key: '${e.value}',
    };
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params.isEmpty ? null : params);

    final request = http.Request(method, uri)..headers['Accept'] = 'application/json';
    if (apiKey != null) request.headers['x-api-key'] = apiKey;
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response res;
    try {
      res = await _http.send(request).then(http.Response.fromStream).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw ApiException('Koneksi terlalu lama. Coba lagi.');
    } catch (_) {
      throw ApiException('Tidak bisa terhubung. Periksa koneksi internetmu.');
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Respons server tidak valid.', statusCode: res.statusCode);
    }

    if (res.statusCode >= 400 || json['success'] != true) {
      throw ApiException(
        json['message'] as String? ?? 'Terjadi kesalahan (${res.statusCode}).',
        statusCode: res.statusCode,
        errors: (json['errors'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? const {},
      );
    }
    return ApiResponse(json['data'], json['meta'] as Map<String, dynamic>?);
  }
}
