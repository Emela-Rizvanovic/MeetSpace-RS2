import 'dart:convert';
import '../models/space.dart';
import 'api_service.dart';

class SpaceService {
  final ApiService api;

  SpaceService(this.api);

  Future<List<SpaceResponse>> getSpaces({
    String? name,
    int? facilityId,
    int? spaceTypeId,
    double? minPrice,
    double? maxPrice,
    int? minCapacity,
    int? maxCapacity,
  }) async {
    final query = <String, String>{};

    if (name != null && name.trim().isNotEmpty) {
      query['Name'] = name.trim();
    }
    if (facilityId != null) {
      query['FacilityId'] = facilityId.toString();
    }
    if (spaceTypeId != null) {
      query['SpaceTypeId'] = spaceTypeId.toString();
    }
    if (minPrice != null) {
      query['MinPrice'] = minPrice.toString();
    }
    if (maxPrice != null) {
      query['MaxPrice'] = maxPrice.toString();
    }
    if (minCapacity != null) {
      query['MinCapacity'] = minCapacity.toString();
    }
    if (maxCapacity != null) {
      query['MaxCapacity'] = maxCapacity.toString();
    }

    final response = await api.get(
      "Space",
      queryParameters: query.isEmpty ? null : query,
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        final items = decoded['items'];

        if (items is List) {
          return items
              .map((e) => SpaceResponse.fromJson(e))
              .toList();
        }
      }

      return [];
    }

    throw Exception("Failed to load spaces");
  }
}