import 'dart:convert';
import '../models/user.dart';
import 'api_service.dart';
import '../models/paged_result.dart';

class UserService {
  final ApiService api;
  final String baseUrl;

  UserService({
    required this.api,
    required this.baseUrl,
  });

Future<PagedResult<UserResponse>> getPaged({
  required int page,
  required int pageSize,
  String? search,
  String? sortBy,
  bool? desc,
}) async {
  final query = <String, String>{
    "page": page.toString(),
    "pageSize": pageSize.toString(),
  };

  if (search != null && search.isNotEmpty) {
  query["Name"] = search;  
}

  if (sortBy != null) {
    query["SortBy"] = sortBy;
  }

  if (desc != null) {
    query["Desc"] = desc.toString();
  }

  final response = await api.get(
    "User",
    queryParameters: query,
  );

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);

    return PagedResult<UserResponse>.fromJson(
      decoded,
      (e) => UserResponse.fromJson(e),
    );
  }

  throw Exception("Failed to load paged users");
}

Future<UserResponse> updateUserAdmin({
  required int userId,
  required String firstName,
  required String lastName,
  required String username,
  required String email,
  required String phone,
  required bool isActive,
  int? roleId,
  String? newPassword,
}) async {
  final fields = {
    "FirstName": firstName,
    "LastName": lastName,
    "Username": username,
    "Email": email,
    "PhoneNumber": phone,
    "IsActive": isActive.toString(),
  };

  if (roleId != null) {
    fields["RoleId"] = roleId.toString();
  }

  if (newPassword != null && newPassword.trim().isNotEmpty) {
  fields["Password"] = newPassword.trim();
}

  final response = await api.multipartPut(
    "User/$userId",
    fields: fields,
  );

  if (response.statusCode == 200) {
    return UserResponse.fromJson(jsonDecode(response.body));
  }

  throw Exception("Failed to update user");
}
}