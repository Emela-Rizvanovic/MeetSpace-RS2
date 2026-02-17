class AmenityResponse {
  final int id;
  final String name;
  final String? description;
  final int amenityCategoryId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AmenityResponse({
    required this.id,
    required this.name,
    required this.description,
    required this.amenityCategoryId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AmenityResponse.fromJson(Map<String, dynamic> json) {
    return AmenityResponse(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      amenityCategoryId: (json['amenityCategoryId'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'].toString()),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'].toString()),
    );
  }
}
