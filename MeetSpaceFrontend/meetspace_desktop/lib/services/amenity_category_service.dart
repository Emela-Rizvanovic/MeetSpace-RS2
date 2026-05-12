import 'dart:convert';
import 'api_service.dart';

class AmenityCategoryService {
  final ApiService api;

  AmenityCategoryService(this.api);

  Future<Map<String, dynamic>> getPaged({
    int page = 0,
    int pageSize = 10,
    String? name,
  }) async {
    final query = {
      "Page": page.toString(),
      "PageSize": pageSize.toString(),
    };

    if (name != null &&
        name.isNotEmpty) {
      query["Name"] = name;
    }

    final response = await api.get(
      "AmenityCategory",
      queryParameters: query,
    );

    if (response.statusCode != 200) {
      throw Exception(
          "Failed to load amenity categories");
    }

    return jsonDecode(response.body);
  }

  Future<void> insert(
    Map<String, dynamic> body,
  ) async {
    final response =
        await api.post(
      "AmenityCategory",
      body,
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
          "Failed to add amenity category");
    }
  }

  Future<void> update(
    int id,
    Map<String, dynamic> body,
  ) async {
    final response =
        await api.put(
      "AmenityCategory/$id",
      body,
    );

    if (response.statusCode != 200) {
      throw Exception(
          "Failed to update amenity category");
    }
  }

  Future<void> delete(int id) async {
    final response =
        await api.delete(
      "AmenityCategory/$id",
    );

    if (response.statusCode != 200) {
      throw Exception(
          "Failed to delete amenity category");
    }
  }
}