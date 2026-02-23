class ReviewResponse {
  final int id;
  final int userId;
  final String? userName;
  final int spaceId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ReviewResponse({
    required this.id,
    required this.userId,
    required this.userName,
    required this.spaceId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    return ReviewResponse(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      userName: json['userName']?.toString(),
      spaceId: (json['spaceId'] as num).toInt(),
      rating: (json['rating'] as num).toInt(),
      comment: json['comment']?.toString(),
      createdAt: DateTime.parse(json['createdAt'].toString()),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'].toString()),
    );
  }
}