import 'dart:convert';
import '../models/space.dart';
import 'api_service.dart';

class FavoriteService {
  final ApiService api;

  FavoriteService(this.api);

  Future<void> addFavorite(int spaceId) async {
    final response = await api.post(
      "Favorite",
      {"spaceId": spaceId},
    );

    if (response.statusCode != 200 &&
        response.statusCode != 204) {
      throw Exception("Failed to add favorite");
    }
  }

  Future<void> removeFavorite(int userId, int spaceId) async {
    final response = await api.delete(
      "Favorite?userId=$userId&spaceId=$spaceId",
    );

    if (response.statusCode != 200 &&
        response.statusCode != 204) {
      throw Exception("Failed to remove favorite");
    }
  }

  Future<List<SpaceResponse>> getFavoriteSpaces(int userId) async {
    final response =
        await api.get("Favorite/user/$userId");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded
            .map((e) => SpaceResponse.fromJson(e))
            .toList();
      }
    }

    throw Exception("Failed to load favorites");
  }
}