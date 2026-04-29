import 'dart:convert';
import '../models/revenue.dart';
import 'api_service.dart';

class RevenueService {
  final ApiService api;

  RevenueService(this.api);

  /// 🔹 LAST 3 TRANSACTIONS
  Future<List<RevenueResponse>> getLatest() async {
    final response = await api.get("Revenue/latest");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded
            .map((e) => RevenueResponse.fromJson(e))
            .toList();
      }
    }

    throw Exception("Failed to load latest revenue");
  }

  /// 🔹 ALL TRANSACTIONS (za future "See full history")
  Future<List<RevenueResponse>> getAll() async {
    final response = await api.get("Revenue/all");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded
            .map((e) => RevenueResponse.fromJson(e))
            .toList();
      }
    }

    throw Exception("Failed to load revenue history");
  }

  /// 🔹 TOTAL REVENUE
  Future<double> getTotal() async {
    final response = await api.get("Revenue/total");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return (decoded as num).toDouble();
    }

    throw Exception("Failed to load total revenue");
  }
}