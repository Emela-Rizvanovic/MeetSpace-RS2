import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../main.dart';
import 'package:http_parser/http_parser.dart';

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
  Map<String, List<int>>? listFields, 
}) async {
  final uri = Uri.parse('$baseUrl/$endpoint');

  final request = http.MultipartRequest('POST', uri);

  if (token != null) {
    request.headers['Authorization'] = 'Bearer $token';
  }

  request.fields.addAll(fields);

if (listFields != null) {
  listFields.forEach((key, values) {
    for (int i = 0; i < values.length; i++) {
      request.fields["$key[$i]"] = values[i].toString();
    }
  });
}

  for (var file in files) {
    request.files.add(
     await http.MultipartFile.fromPath(
  fileFieldName,
  file.path,
  contentType: _imageContentType(file.path),
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

  if (token != null) {
    request.headers['Authorization'] = 'Bearer $token';
  }

  request.fields.addAll(fields);

  if (listFields != null) {
    listFields.forEach((key, values) {
      for (int i = 0; i < values.length; i++) {
        request.fields["$key[$i]"] = values[i].toString();
      }
    });
  }

  if (files != null) {
    for (var file in files) {
      request.files.add(
        await http.MultipartFile.fromPath(
  fileFieldName,
  file.path,
  contentType: _imageContentType(file.path),
),
      );
    }
  }

  final streamed = await request.send();

final response =
    await http.Response.fromStream(streamed);

_handleUnauthorized(response);

return response;
}

MediaType _imageContentType(String path) {
  final lower = path.toLowerCase();

  if (lower.endsWith('.png')) {
    return MediaType('image', 'png');
  }

  if (lower.endsWith('.webp')) {
    return MediaType('image', 'webp');
  }

  return MediaType('image', 'jpeg');
}

}