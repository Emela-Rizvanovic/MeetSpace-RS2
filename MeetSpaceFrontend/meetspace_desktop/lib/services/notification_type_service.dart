import 'dart:convert';
import 'api_service.dart';

class NotificationTypeService {
  final ApiService api;

  NotificationTypeService(this.api);

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

    if (name != null && name.isNotEmpty) {
      query["Name"] = name;
    }

    if (sortBy != null && sortBy.isNotEmpty) {
      query["SortBy"] = sortBy;
      query["Desc"] = desc.toString();
    }

    final response = await api.get(
      "NotificationType",
      queryParameters: query,
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load notification types");
    }

    return jsonDecode(response.body);
  }

  Future<void> insert(
    Map<String, dynamic> body,
  ) async {
    final response = await api.post(
      "NotificationType",
      body,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Failed to add notification type");
    }
  }

  Future<void> update(
    int id,
    Map<String, dynamic> body,
  ) async {
    final response = await api.put(
      "NotificationType/$id",
      body,
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update notification type");
    }
  }

  Future<void> delete(int id) async {
    final response = await api.delete(
      "NotificationType/$id",
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete notification type");
    }
  }
}