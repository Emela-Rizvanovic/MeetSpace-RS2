import 'dart:convert';
import '../models/amenity.dart';
import 'api_service.dart';

class AmenityService {
  final ApiService api;

  AmenityService(this.api);

  Future<List<AmenityResponse>> getAmenities({
    String? name,
    int? amenityCategoryId,
  }) async {
    final query = <String, String>{};

    if (name != null && name.trim().isNotEmpty) {
      query['Name'] = name.trim();
    }

    if (amenityCategoryId != null) {
      query['AmenityCategoryId'] =
          amenityCategoryId.toString();
    }

    final response = await api.get(
      "Amenity",
      queryParameters: query.isEmpty ? null : query,
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        final items = decoded['items'];

        if (items is List) {
          return items
              .map((e) => AmenityResponse.fromJson(e))
              .toList();
        }
      }

      return [];
    }

    throw Exception("Failed to load amenities");
  }

  Future<void> deleteAmenity(int id) async {
  final response = await api.delete("Amenity/$id");

  if (response.statusCode != 200 &&
      response.statusCode != 204) {
    throw Exception("Failed to delete amenity");
  }
}
}