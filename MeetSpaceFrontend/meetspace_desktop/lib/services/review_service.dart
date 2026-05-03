import 'dart:convert';
import '../models/review.dart';
import 'api_service.dart';
import '../models/paged_result.dart';

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

  Future<List<ReviewResponse>> getAllReviews() async {
  final response = await api.get("Review");

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);

    if (decoded is Map && decoded.containsKey("items")) {
      return (decoded["items"] as List)
          .map((e) => ReviewResponse.fromJson(e))
          .toList();
    }
  }

  throw Exception("Failed to load reviews");
}

Future<PagedResult<ReviewResponse>> getPaged({
  required int page,
  required int pageSize,
  String? search,
  int? rating,
  String? sortBy,
  bool desc = false,
}) async {
  final query = <String, String>{
    "page": page.toString(),
    "pageSize": pageSize.toString(),
    "desc": desc.toString(),
  };

  if (search != null && search.isNotEmpty) {
  query["Name"] = search;  
}

  if (rating != null) {
    query["Rating"] = rating.toString();
  }

  if (sortBy != null) {
    query["SortBy"] = sortBy;
  }

  final response = await api.get("Review", queryParameters: query);

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);

    return PagedResult<ReviewResponse>.fromJson(
      decoded,
      (e) => ReviewResponse.fromJson(e),
    );
  }

  throw Exception("Failed to load paged reviews");
}
}