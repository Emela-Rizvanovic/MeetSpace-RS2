import 'dart:convert';
import '../models/review.dart';
import 'api_service.dart';

class ReviewService {
  final ApiService api;

  ReviewService(this.api);

  Future<List<ReviewResponse>> getReviewsBySpace(int spaceId) async {
    final response = await api.get("Review/space/$spaceId");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded
            .map((e) => ReviewResponse.fromJson(e))
            .toList();
      }
    }

    throw Exception("Failed to load reviews");
  }

  Future<Map<String, dynamic>> getReviewSummary(int spaceId) async {
    final response =
        await api.get("Review/space/$spaceId/summary");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Failed to load summary");
  }

  Future<void> createReview(Map<String, dynamic> body) async {
    final response = await api.post("Review", body);

if (response.statusCode == 200 || response.statusCode == 201) {
  return;
}

String message = "Failed to leave a review";

try {
  final decoded = jsonDecode(response.body);

  if (decoded is Map && decoded.containsKey("message")) {
    message = decoded["message"];
  } else if (decoded is String) {
    message = decoded;
  }
} catch (_) {
  message = response.body;
}

throw Exception(message);
  }

  Future<void> updateReview(
      int reviewId, Map<String, dynamic> body) async {
    final response =
        await api.put("Review/$reviewId", body);

    if (response.statusCode != 200) {
      throw Exception("Failed to update review");
    }
  }

  Future<void> deleteReview(int reviewId) async {
    final response =
        await api.delete("Review/$reviewId");

    if (response.statusCode != 200 &&
        response.statusCode != 204) {
      throw Exception("Failed to delete review");
    }
  }
}