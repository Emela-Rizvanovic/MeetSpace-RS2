import 'dart:convert';
import 'api_service.dart';

class FacilityService {
  final ApiService api;

  FacilityService(this.api);

  Future<Map<String, dynamic>> getPaged({
    int page = 0,
    int pageSize = 10,
    String? name,
    int? cityId,
  }) async {
    final query = {
      "Page": page.toString(),
      "PageSize": pageSize.toString(),
    };

    if (name != null &&
        name.isNotEmpty) {
      query["Name"] = name;
    }

    if (cityId != null) {
      query["CityId"] =
          cityId.toString();
    }

    final response = await api.get(
      "Facility",
      queryParameters: query,
    );

    if (response.statusCode != 200) {
      throw Exception(
          "Failed to load facilities");
    }

    return jsonDecode(response.body);
  }

  Future<void> insert(
    Map<String, dynamic> body,
  ) async {
    final response =
        await api.post("Facility", body);

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
          "Failed to add facility");
    }
  }

  Future<void> update(
    int id,
    Map<String, dynamic> body,
  ) async {
    final response =
        await api.put(
      "Facility/$id",
      body,
    );

    if (response.statusCode != 200) {
      throw Exception(
          "Failed to update facility");
    }
  }

  Future<void> delete(int id) async {
    final response =
        await api.delete(
      "Facility/$id",
    );

    if (response.statusCode != 200) {
      throw Exception(
          "Failed to delete facility");
    }
  }
}