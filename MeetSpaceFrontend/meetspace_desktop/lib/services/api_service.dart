import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;
  final String? token;

  ApiService({
    required this.baseUrl,
    required this.token,
  });

  Map<String, String> _headers({bool isJson = true}) {
    final headers = <String, String>{};

    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<http.Response> get(
  String endpoint, {
  Map<String, String>? queryParameters,
}) {
  final uri = Uri.parse('$baseUrl/$endpoint')
      .replace(queryParameters: queryParameters);

  return http.get(
    uri,
    headers: _headers(),
  );
}

  Future<http.Response> post(String endpoint, dynamic body) {
    return http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: _headers(),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> put(String endpoint, dynamic body) {
    return http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: _headers(),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> delete(String endpoint) {
    return http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: _headers(),
    );
  }
}