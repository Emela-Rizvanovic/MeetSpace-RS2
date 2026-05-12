import 'dart:convert';
import 'api_service.dart';

class CityService {
  final ApiService api;

  CityService(this.api);

  Future<Map<String, dynamic>> getPaged({
    int page = 0,
    int pageSize = 10,
    String? name,
    int? countryId,
  }) async {
    final query = {
      "Page": page.toString(),
      "PageSize": pageSize.toString(),
    };

    if (name != null && name.isNotEmpty) {
      query["Name"] = name;
    }

    if (countryId != null) {
      query["CountryId"] =
          countryId.toString();
    }

    final response = await api.get(
      "Cities",
      queryParameters: query,
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load cities");
    }

    return jsonDecode(response.body);
  }

  Future<void> insert(
    Map<String, dynamic> body,
  ) async {
    final response =
        await api.post("Cities", body);

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception("Failed to add city");
    }
  }

  Future<void> update(
    int id,
    Map<String, dynamic> body,
  ) async {
    final response =
        await api.put("Cities/$id", body);

    if (response.statusCode != 200) {
      throw Exception("Failed to update city");
    }
  }

  Future<void> delete(int id) async {
    final response =
        await api.delete("Cities/$id");

    if (response.statusCode != 200) {
      throw Exception("Failed to delete city");
    }
  }
}