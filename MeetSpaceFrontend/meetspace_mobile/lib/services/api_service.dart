import 'dart:convert';
import 'package:http/http.dart' as http;
import '../main.dart';

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

  void _handleUnauthorized(http.Response response) {
  if (response.statusCode == 401) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }
}

  Future<http.Response> get(
  String endpoint, {
  Map<String, String>? queryParameters,
}) async {
  final uri = Uri.parse('$baseUrl/$endpoint')
      .replace(queryParameters: queryParameters);

 final response = await http.get(
  uri,
  headers: _headers(),
);

_handleUnauthorized(response);

return response;
}

  Future<http.Response> post(String endpoint, dynamic body) async {
  final response = await http.post(
    Uri.parse('$baseUrl/$endpoint'),
    headers: _headers(),
    body: jsonEncode(body),
  );

  _handleUnauthorized(response);

  return response;
  }

  Future<http.Response> put(String endpoint, dynamic body) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: _headers(),
      body: jsonEncode(body),
    );

    _handleUnauthorized(response);

  return response;
  }

  Future<http.Response> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: _headers(),
    );

    _handleUnauthorized(response);

  return response;
  }
}