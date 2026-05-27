import 'dart:convert';
import 'api_service.dart';

class PaymentStatusService {
  final ApiService api;

  PaymentStatusService(this.api);

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
      "PaymentStatus",
      queryParameters: query,
    );

    if (response.statusCode != 200) {
      throw Exception(
          "Failed to load payment statuses");
    }

    return jsonDecode(response.body);
  }

  Future<void> insert(
    Map<String, dynamic> body,
  ) async {
    final response =
        await api.post(
      "PaymentStatus",
      body,
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
          "Failed to add payment status");
    }
  }

  Future<void> update(
    int id,
    Map<String, dynamic> body,
  ) async {
    final response =
        await api.put(
      "PaymentStatus/$id",
      body,
    );

    if (response.statusCode != 200) {
      throw Exception(
          "Failed to update payment status");
    }
  }

  Future<void> delete(int id) async {
    final response =
        await api.delete(
      "PaymentStatus/$id",
    );

    if (response.statusCode != 200) {
      throw Exception(
          "Failed to delete payment status");
    }
  }
}