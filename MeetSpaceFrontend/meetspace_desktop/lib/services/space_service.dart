import 'dart:convert';
import '../models/space.dart';
import 'api_service.dart';
import 'dart:io';

class SpaceService {
  final ApiService api;

  SpaceService(this.api);

  Future<List<SpaceResponse>> getSpaces({
    String? name,
    int? facilityId,
    int? spaceTypeId,
    double? minPrice,
    double? maxPrice,
    int? minCapacity,
    int? maxCapacity,
  }) async {
    final query = <String, String>{};

    if (name != null && name.trim().isNotEmpty) {
      query['Name'] = name.trim();
    }
    if (facilityId != null) {
      query['FacilityId'] = facilityId.toString();
    }
    if (spaceTypeId != null) {
      query['SpaceTypeId'] = spaceTypeId.toString();
    }
    if (minPrice != null) {
      query['MinPrice'] = minPrice.toString();
    }
    if (maxPrice != null) {
      query['MaxPrice'] = maxPrice.toString();
    }
    if (minCapacity != null) {
      query['MinCapacity'] = minCapacity.toString();
    }
    if (maxCapacity != null) {
      query['MaxCapacity'] = maxCapacity.toString();
    }

    final response = await api.get(
      "Space",
      queryParameters: query.isEmpty ? null : query,
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        final items = decoded['items'];

        if (items is List) {
          return items
              .map((e) => SpaceResponse.fromJson(e))
              .toList();
        }
      }

      return [];
    }

    throw Exception("Failed to load spaces");
  }


Future<void> createSpace({
  required String name,
  required String description,
  required double price,
  required int capacity,
  required int facilityId,
  required int spaceTypeId,
  required List<File> images,
  required List<int> amenityIds, // 👈 NOVO
}) async {
  final fields = {
    "Name": name,
    "Description": description,
    "PricePerHour": price.toString(),
    "Capacity": capacity.toString(),
    "FacilityId": facilityId.toString(),
    "SpaceTypeId": spaceTypeId.toString(),
  };

  final response = await api.multipartPost(
    "Space",
    fields: fields,
    files: images,
    fileFieldName: "Images",
    listFields: {
      "AmenityIds": amenityIds, // 👈 KLJUČNO
    },
  );

  if (response.statusCode != 200) {
    throw Exception("Failed to create space");
  }
}


Future<void> updateSpace({
  required int id,
  required String name,
  required String description,
  required double price,
  required int capacity,
  required int facilityId,
  required int spaceTypeId,
  required List<int> amenityIds,
  List<File> newImages = const [], // opcionalno
  List<int> deleteImageIds = const [],
}) async {
  final fields = {
    "Name": name,
    "Description": description,
    "PricePerHour": price.toString(),
    "Capacity": capacity.toString(),
    "FacilityId": facilityId.toString(),
    "SpaceTypeId": spaceTypeId.toString(),
  };

  final response = await api.multipartPut(
    "Space/$id",
    fields: fields,
    files: newImages,
    fileFieldName: "NewImages", // 👈 BITNO (backend očekuje NewImages)
    listFields: {
      "AmenityIds": amenityIds,
      "DeleteImageIds": deleteImageIds,
    },
  );

  if (response.statusCode != 200) {
    throw Exception("Failed to update space");
  }
}

Future<void> deleteSpace(int id) async {
  final response = await api.delete("Space/$id");

  if (response.statusCode != 200) {
    throw Exception("Failed to delete space");
  }
}

}