import 'space_image.dart';
import 'amenity.dart';

class SpaceResponse {
  final int id;
  final String name;
  final String description;
  final double pricePerHour;
  final int capacity;
  final int facilityId;
  final String? facilityName;
  final String? facilityAddress;
  final int spaceTypeId;
  final bool isActive;
final DateTime? archivedAt;
  final String? spaceTypeName;
  final List<SpaceImageResponse> images;
  final List<AmenityResponse> amenities;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double averageRating;
  final int totalReviews;

  SpaceResponse({
    required this.id,
    required this.name,
    required this.description,
    required this.pricePerHour,
    required this.capacity,
    required this.facilityId,
    required this.facilityName,
    required this.facilityAddress,
    required this.spaceTypeId,
    required this.isActive,
required this.archivedAt,
    required this.spaceTypeName,
    required this.images,
    required this.amenities,
    required this.createdAt,
    required this.updatedAt,
    required this.averageRating,
    required this.totalReviews,
  });

  factory SpaceResponse.fromJson(Map<String, dynamic> json) {
    final imgs = json['images'];
    final ams = json['amenities'];

    return SpaceResponse(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      pricePerHour: (json['pricePerHour'] as num).toDouble(),
      capacity: (json['capacity'] as num).toInt(),
      facilityId: (json['facilityId'] as num).toInt(),
      facilityName: json['facilityName']?.toString(),
      facilityAddress: json['facilityAddress']?.toString(),
      spaceTypeId: (json['spaceTypeId'] as num).toInt(),
      isActive: json['isActive'] as bool? ?? true,
archivedAt: json['archivedAt'] == null
    ? null
    : DateTime.parse(json['archivedAt'].toString()),
      spaceTypeName: json['spaceTypeName']?.toString(),
      images: imgs is List
          ? imgs
              .map((e) => SpaceImageResponse.fromJson(e as Map<String, dynamic>))
              .toList()
          : <SpaceImageResponse>[],
           amenities: ams is List
          ? ams
              .map((e) => AmenityResponse.fromJson(e as Map<String, dynamic>))
              .toList()
          : <AmenityResponse>[],
      createdAt: DateTime.parse(json['createdAt'].toString()),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'].toString()),
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
    );
  }

  String get firstImageOrEmpty =>
      images.isNotEmpty ? images.first.imageUrl.trim() : '';
}
