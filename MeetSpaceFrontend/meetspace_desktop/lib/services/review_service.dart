import 'dart:convert';
import '../models/review.dart';
import 'api_service.dart';
import '../models/paged_result.dart';

class ReviewService {
  final ApiService api;

  ReviewService(this.api);

  Future<void> deleteReview(int reviewId) async {
    final response =
        await api.delete("Review/$reviewId");

    if (response.statusCode != 200 &&
        response.statusCode != 204) {
      throw Exception("Failed to delete review");
    }
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
  query["MinRating"] = rating.toString();
  query["MaxRating"] = rating.toString();
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