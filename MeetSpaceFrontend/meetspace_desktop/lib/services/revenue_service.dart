import 'dart:convert';
import '../models/revenue.dart';
import 'api_service.dart';
import '../models/paged_result.dart';

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

  Future<PagedResult<RevenueResponse>> getPaged({
  required int page,
  required int pageSize,
  String? search,
  DateTime? from,
  DateTime? to,
  String? sortBy,
  bool desc = false,
}) async {
  final query = <String, String>{
    "page": page.toString(),
    "pageSize": pageSize.toString(),
  };

 if (search != null && search.trim().isNotEmpty) {
  query["Name"] = search.trim();  
} 

  if (from != null) {
    query["FromDate"] = from.toIso8601String();
  }

  if (to != null) {
    query["ToDate"] = to.toIso8601String();
  }

  if (sortBy != null) {
    query["SortBy"] = sortBy;
    query["Desc"] = desc.toString();
  }

  final response = await api.get(
    "Revenue",
    queryParameters: query,
  );

print(query);
  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);

    return PagedResult<RevenueResponse>.fromJson(
      decoded,
      (e) => RevenueResponse.fromJson(e),
    );
  }

  throw Exception("Failed to load paged revenue");
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