import 'dart:convert';
import '../models/space.dart';
import 'api_service.dart';

class RecommendationService {
  final ApiService api;

  RecommendationService(this.api);

  Future<List<SpaceResponse>> getRecommendedSpaces() async {
  final response = await api.get("Recommendations");

  if (response.statusCode == 200) {
    if (response.body.isEmpty) return [];

    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded
          .map((e) => SpaceResponse.fromJson(e))
          .toList();
    }

    return [];
  }

  throw Exception("Failed to load recommendations");
}

  Future<void> markClicked(int spaceId) async {
  await api.post("Recommendations/$spaceId/click", {});
}
}