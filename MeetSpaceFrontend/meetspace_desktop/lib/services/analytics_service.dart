import 'dart:convert';

import '../models/space_demand.dart';
import '../models/space_demand_period.dart';
import 'api_service.dart';

class AnalyticsService {
  final ApiService api;

  AnalyticsService(this.api);

  Future<List<SpaceDemand>> getSpaceDemand({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final query = <String, String>{};
    if (fromDate != null) query['fromDate'] = _dateOnly(fromDate);
    if (toDate != null) query['toDate'] = _dateOnly(toDate);

    final response = await api.get(
      'Analytics/spaces',
      queryParameters: query.isEmpty ? null : query,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load demand analysis (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((row) => SpaceDemand.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<SpaceDemandPeriod>> getSpaceDemandPeriods({
    required String spaceCode,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final query = <String, String>{'spaceCode': spaceCode};
    if (fromDate != null) query['fromDate'] = _dateOnly(fromDate);
    if (toDate != null) query['toDate'] = _dateOnly(toDate);

    final response = await api.get(
      'Analytics/space-periods',
      queryParameters: query,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load peak demand periods (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((row) => SpaceDemandPeriod.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
