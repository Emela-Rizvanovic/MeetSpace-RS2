import 'dart:convert';
import 'api_service.dart';

class BookingStatusService {
  final ApiService api;

  BookingStatusService(this.api);

  Future<Map<String, dynamic>> getPaged({
    int page = 0,
    int pageSize = 10,
    String? name,
    String? sortBy,
bool desc = false,
  }) async {
    final query = {
      "Page": page.toString(),
      "PageSize": pageSize.toString(),
    };

    if (name != null &&
        name.isNotEmpty) {
      query["Name"] = name;
    }

    if (sortBy != null && sortBy.isNotEmpty) {
  query["SortBy"] = sortBy;
  query["Desc"] = desc.toString();
}

    final response = await api.get(
      "BookingStatus",
      queryParameters: query,
    );

    if (response.statusCode != 200) {
      throw Exception(
          "Failed to load booking statuses");
    }

    return jsonDecode(response.body);
  }

  Future<void> insert(
    Map<String, dynamic> body,
  ) async {
    final response =
        await api.post(
      "BookingStatus",
      body,
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
          "Failed to add booking status");
    }
  }

  Future<void> update(
    int id,
    Map<String, dynamic> body,
  ) async {
    final response =
        await api.put(
      "BookingStatus/$id",
      body,
    );

    if (response.statusCode != 200) {
      throw Exception(
          "Failed to update booking status");
    }
  }

  Future<void> delete(int id) async {
    final response =
        await api.delete(
      "BookingStatus/$id",
    );

    if (response.statusCode != 200) {
      throw Exception(
          "Failed to delete booking status");
    }
  }
}