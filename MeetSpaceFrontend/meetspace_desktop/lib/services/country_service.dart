import 'dart:convert';
import 'api_service.dart';

class CountryService {
  final ApiService api;

  CountryService(this.api);

  Future<Map<String, dynamic>> getPaged({
    int page = 0,
    int pageSize = 10,
    String? name,
  }) async {
    final query = {
      "Page": page.toString(),
      "PageSize": pageSize.toString(),
    };

    if (name != null && name.isNotEmpty) {
      query["Name"] = name;
    }

    final response = await api.get(
      "Countries",
      queryParameters: query,
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load countries");
    }

    return jsonDecode(response.body);
  }

  Future<void> insert(Map<String, dynamic> body) async {
    final response =
        await api.post("Countries", body);

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception("Failed to add country");
    }
  }

  Future<void> update(
    int id,
    Map<String, dynamic> body,
  ) async {
    final response =
        await api.put("Countries/$id", body);

    if (response.statusCode != 200) {
      throw Exception("Failed to update country");
    }
  }

  Future<void> delete(int id) async {
    final response =
        await api.delete("Countries/$id");

    if (response.statusCode != 200) {
      throw Exception("Failed to delete country");
    }
  }
}