class SpaceImageResponse {
  final int id;
  final String imageUrl;

  SpaceImageResponse({required this.id, required this.imageUrl});

  factory SpaceImageResponse.fromJson(Map<String, dynamic> json) {
    return SpaceImageResponse(
      id: (json['id'] as num).toInt(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
    );
  }
}
