import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
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

Future<http.Response> multipartPost(
  String endpoint, {
  required Map<String, String> fields,
  required List<File> files,
  required String fileFieldName,
  Map<String, List<int>>? listFields, // 👈 NOVO
}) async {
  final uri = Uri.parse('$baseUrl/$endpoint');

  final request = http.MultipartRequest('POST', uri);

  if (token != null) {
    request.headers['Authorization'] = 'Bearer $token';
  }

  /// fields
  request.fields.addAll(fields);

  /// LIST FIELDS (npr AmenityIds)
if (listFields != null) {
  listFields.forEach((key, values) {
    for (int i = 0; i < values.length; i++) {
      request.fields["$key[$i]"] = values[i].toString();
    }
  });
}

  /// files
  for (var file in files) {
    request.files.add(
      await http.MultipartFile.fromPath(
        fileFieldName,
        file.path,
      ),
    );
  }

  final streamed = await request.send();

final response =
    await http.Response.fromStream(streamed);

_handleUnauthorized(response);

return response;
}


Future<http.Response> multipartPut(
  String url, {
  required Map<String, String> fields,
  List<File>? files,
  String fileFieldName = "NewImages",
  Map<String, List<int>>? listFields,
}) async {
  final uri = Uri.parse("$baseUrl/$url");

  final request = http.MultipartRequest("PUT", uri);

  /// ❗ SAMO AUTH HEADER (bez Content-Type)
  if (token != null) {
    request.headers['Authorization'] = 'Bearer $token';
  }

  /// fields
  request.fields.addAll(fields);

  /// LIST FIELDS (ISTO KAO POST!)
  if (listFields != null) {
    listFields.forEach((key, values) {
      for (int i = 0; i < values.length; i++) {
        request.fields["$key[$i]"] = values[i].toString();
      }
    });
  }

  /// FILES
  if (files != null) {
    for (var file in files) {
      request.files.add(
        await http.MultipartFile.fromPath(fileFieldName, file.path),
      );
    }
  }

  final streamed = await request.send();

final response =
    await http.Response.fromStream(streamed);

_handleUnauthorized(response);

return response;
}

}