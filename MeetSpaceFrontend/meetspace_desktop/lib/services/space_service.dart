import 'dart:convert';
import '../models/space.dart';
import 'api_service.dart';
import 'dart:io';
import '../models/paged_result.dart';

class SpaceService {
  final ApiService api;

  SpaceService(this.api);

Future<PagedResult<SpaceResponse>> getPaged({
    required int page,
  required int pageSize,
  String? name,
  int? facilityId,
  int? spaceTypeId,
  double? minPrice,
  double? maxPrice,
  int? minCapacity,
  int? maxCapacity,
  String? sortBy,
  bool desc = false,
}) async {
  final query = <String, String>{
    "page": page.toString(),
    "pageSize": pageSize.toString(),
  };

  if (name != null && name.isNotEmpty) query["Name"] = name;
  if (facilityId != null) query["FacilityId"] = facilityId.toString();
  if (spaceTypeId != null) query["SpaceTypeId"] = spaceTypeId.toString();
  if (minPrice != null) query["MinPrice"] = minPrice.toString();
if (maxPrice != null) query["MaxPrice"] = maxPrice.toString();
if (minCapacity != null) query["MinCapacity"] = minCapacity.toString();
if (maxCapacity != null) query["MaxCapacity"] = maxCapacity.toString();
  if (sortBy != null) query["SortBy"] = sortBy;
query["Desc"] = desc.toString();

  final response = await api.get("Space", queryParameters: query);

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);

    return PagedResult<SpaceResponse>.fromJson(
      decoded,
      (e) => SpaceResponse.fromJson(e),
    );
  }

  throw Exception("Failed to load paged spaces");
}

Future<void> createSpace({
  required String name,
  required String description,
  required double price,
  required int capacity,
  required int facilityId,
  required int spaceTypeId,
  required List<File> images,
  required List<int> amenityIds, 
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
      "AmenityIds": amenityIds, 
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
  List<File> newImages = const [],
  List<int> deleteImageIds = const [],
}) async {
  final fields = {
    "Name": name,
    "Description": description,
    "PricePerHour": price.toString(),
    "Capacity": capacity.toString(),
    "FacilityId": facilityId.toString(),
    "SpaceTypeId": spaceTypeId.toString(),
    
    "ReplaceAmenities": "true",
  };

  final response = await api.multipartPut(
    "Space/$id",
    fields: fields,
    files: newImages,
    fileFieldName: "NewImages", 
    listFields: {
      "AmenityIds": amenityIds,
      "DeleteImageIds": deleteImageIds,
    },
  );

  if (response.statusCode != 200) {
    throw Exception("Failed to update space");
  }
}

Future<String> deleteSpace(int id) async {
  final response = await api.delete("Space/$id");

  if (response.statusCode != 200) {
    throw Exception("Failed to remove space");
  }

  final getResponse = await api.get("Space/$id");

  if (getResponse.statusCode == 200 && getResponse.body.isNotEmpty) {
    final decoded = jsonDecode(getResponse.body);

    if (decoded is Map<String, dynamic> &&
        decoded['isActive'] == false) {
      return "deactivated";
    }
  }

  return "deleted";
}

}