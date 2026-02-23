import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../models/booking.dart';
import '../models/amenity.dart';
import '../models/space.dart';
import '../models/review.dart';

class AuthProvider with ChangeNotifier {
  UserResponse? user;

  final String baseUrl = "http://10.0.2.2:5245/api";  
  // 10.0.2.2 = localhost za Android emulator

  Future<void> login(String username, String password) async {
    final url = Uri.parse("$baseUrl/User/login");

    final request = UserLoginRequest(username: username, password: password);

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    print("URL → $url");
    print("REQUEST → ${request.toJson()}");
    print("STATUS → ${response.statusCode}");
    print("BODY → ${response.body}");

    if (response.statusCode == 200) {
      user = UserResponse.fromJson(jsonDecode(response.body));
      notifyListeners();
    } else {
      throw Exception("Invalid username or password");
    }
  }

   Future<void> register({
  required String firstName,
  required String lastName,
  required String email,
  required String username,
  required String password,
  required String phone,
  XFile? profileImage, // optional
}) async {
  var uri = Uri.parse('$baseUrl/User/register');

  var request = http.MultipartRequest('POST', uri);

  request.fields['FirstName'] = firstName;
  request.fields['LastName'] = lastName;
  request.fields['Email'] = email;
  request.fields['Username'] = username;
  request.fields['Password'] = password;
  request.fields['PhoneNumber'] = phone;
  request.fields['RoleId'] = '2';

  // ⚠️ Backend expects: ProfileImageUrl
  if (profileImage != null) {
    request.files.add(
      await http.MultipartFile.fromPath(
        'ProfileImageUrl',                       // <-- MUST MATCH BACKEND NAME
        profileImage.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );
  }

  var response = await request.send();
  var responseString = await response.stream.bytesToString();

  print("REGISTER STATUS → ${response.statusCode}");
  print("REGISTER RESPONSE → $responseString");

  if (response.statusCode == 201) {
    user = UserResponse.fromJson(jsonDecode(responseString));
    notifyListeners();
  } else {
    throw Exception(responseString);
  }
}

Future<ForgotPasswordResponse> forgotPassword(String email) async {
  final url = Uri.parse("$baseUrl/User/forgot-password");

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email}),
  );

  print("FORGOT URL → $url");
  print("FORGOT STATUS → ${response.statusCode}");
  print("FORGOT BODY → ${response.body}");

  if (response.statusCode == 200) {
    return ForgotPasswordResponse.fromJson(jsonDecode(response.body));
  } else {
    throw Exception("Forgot password failed (${response.statusCode})");
  }
}

Future<ForgotPasswordResponse> resetPassword({
  required String email,
  required String code,
  required String newPassword,
}) async {
  final url = Uri.parse("$baseUrl/User/reset-password");

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'resetCode': code,
      'newPassword': newPassword,
    }),
  );

  print("RESET URL → $url");
  print("RESET STATUS → ${response.statusCode}");
  print("RESET BODY → ${response.body}");

  // backend vraća 200 kad je success, 400 kad nije success (kod tebe u kontroleru)
  if (response.statusCode == 200 || response.statusCode == 400) {
    return ForgotPasswordResponse.fromJson(jsonDecode(response.body));
  } else {
    throw Exception("Reset password failed (${response.statusCode})");
  }
}

Future<List<BookingResponse>> getMyBookings() async {
  if (user == null) throw Exception("Not logged in");

  final url = Uri.parse("$baseUrl/Booking/user/${user!.id}");

  final response = await http.get(url, headers: {
    'Content-Type': 'application/json',
  });

  print("BOOKINGS URL → $url");
  print("BOOKINGS STATUS → ${response.statusCode}");
  print("BOOKINGS BODY → ${response.body}");

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);

    // Endpoint vraća List<BookingResponse>
    if (decoded is List) {
      return decoded
          .map((e) => BookingResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [];
  } else {
    throw Exception("Failed to load bookings (${response.statusCode})");
  }
}

Future<List<AmenityResponse>> getAmenities({
  String? name,
  int? amenityCategoryId,
}) async {
  final query = <String, String>{};

  if (name != null && name.trim().isNotEmpty) {
    query['Name'] = name.trim();
  }
  if (amenityCategoryId != null) {
    query['AmenityCategoryId'] = amenityCategoryId.toString();
  }

  final uri = Uri.parse("$baseUrl/Amenity").replace(queryParameters: query);

  final response = await http.get(uri, headers: {
    'Content-Type': 'application/json',
  });

  print("AMENITIES URL → $uri");
  print("AMENITIES STATUS → ${response.statusCode}");
  print("AMENITIES BODY → ${response.body}");

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);

// Tvoj backend vraća: { items: [...], totalCount: n }
if (decoded is Map<String, dynamic>) {
  final items = decoded['items'];

  if (items is List) {
    return items
        .map((e) => AmenityResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
return [];
  } else {
    throw Exception("Failed to load amenities (${response.statusCode})");
  }
}

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

  if (name != null && name.trim().isNotEmpty) query['Name'] = name.trim();
  if (facilityId != null) query['FacilityId'] = facilityId.toString();
  if (spaceTypeId != null) query['SpaceTypeId'] = spaceTypeId.toString();
  if (minPrice != null) query['MinPrice'] = minPrice.toString();
  if (maxPrice != null) query['MaxPrice'] = maxPrice.toString();
  if (minCapacity != null) query['MinCapacity'] = minCapacity.toString();
  if (maxCapacity != null) query['MaxCapacity'] = maxCapacity.toString();

  final uri = query.isEmpty
      ? Uri.parse("$baseUrl/Space")
      : Uri.parse("$baseUrl/Space").replace(queryParameters: query);

  final response = await http.get(uri, headers: {
    'Content-Type': 'application/json',
  });

  print("SPACES URL → $uri");
  print("SPACES STATUS → ${response.statusCode}");
  print("SPACES BODY → ${response.body}");

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);

    // backend vraća: { items: [...], totalCount: n }
    if (decoded is Map<String, dynamic>) {
      final items = decoded['items'];
      if (items is List) {
        return items
            .map((e) => SpaceResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    return [];
  } else {
    throw Exception("Failed to load spaces (${response.statusCode})");
  }
}

Future<void> addFavorite(int spaceId) async {
  if (user == null) throw Exception("Not logged in");

  final url = Uri.parse("$baseUrl/Favorite");

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'userId': user!.id,
      'spaceId': spaceId,
    }),
  );

  print("ADD FAVORITE STATUS → ${response.statusCode}");
  print("ADD FAVORITE BODY → ${response.body}");

  if (response.statusCode != 200 && response.statusCode != 204) {
    throw Exception("Failed to add favorite");
  }
}


Future<void> removeFavorite(int spaceId) async {
  if (user == null) throw Exception("Not logged in");

  final uri = Uri.parse("$baseUrl/Favorite").replace(
    queryParameters: {
      'userId': user!.id.toString(),
      'spaceId': spaceId.toString(),
    },
  );

  final response = await http.delete(uri);

  print("REMOVE FAVORITE URL → $uri");
  print("REMOVE FAVORITE STATUS → ${response.statusCode}");

  if (response.statusCode != 200 && response.statusCode != 204) {
    throw Exception("Failed to remove favorite");
  }
}



Future<List<SpaceResponse>> getFavoriteSpaces() async {
  if (user == null) throw Exception("Not logged in");

  final url = Uri.parse("$baseUrl/Favorite/user/${user!.id}");

  final response = await http.get(url);

  print("GET FAVORITES STATUS → ${response.statusCode}");
  print("GET FAVORITES BODY → ${response.body}");

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded
          .map((e) => SpaceResponse.fromJson(e))
          .toList();
    }
    return [];
  } else {
    throw Exception("Failed to load favorites");
  }
}

Future<void> updateProfile({
  required String firstName,
  required String lastName,
  required String username,
  required String email,
  required String phone,
  String? newPassword,
  XFile? profileImage,
}) async {
  if (user == null) throw Exception("Not logged in");

  final uri = Uri.parse("$baseUrl/User/${user!.id}");

  var request = http.MultipartRequest('PUT', uri);

  // TEXT FIELDS
  request.fields['FirstName'] = firstName;
  request.fields['LastName'] = lastName;
  request.fields['Username'] = username;
  request.fields['Email'] = email;
  request.fields['PhoneNumber'] = phone;

  // PASSWORD (only if entered)
  if (newPassword != null && newPassword.trim().isNotEmpty) {
    request.fields['Password'] = newPassword.trim();
  }

  // IMAGE (only if selected)
  if (profileImage != null) {
    request.files.add(
      await http.MultipartFile.fromPath(
        'ProfileImageUrl',
        profileImage.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );
  }

  var response = await request.send();
  var responseString = await response.stream.bytesToString();

  print("UPDATE PROFILE STATUS → ${response.statusCode}");
  print("UPDATE PROFILE BODY → $responseString");

  if (response.statusCode == 200) {
    user = UserResponse.fromJson(jsonDecode(responseString));
    notifyListeners();
  } else {
    throw Exception("Failed to update profile");
  }
}

Future<List<BookingResponse>> getBookingsForSpace(int spaceId) async {
  final url = Uri.parse("$baseUrl/Booking/space/$spaceId");

  final response = await http.get(url);

  print("SPACE BOOKINGS URL → $url");
  print("SPACE BOOKINGS STATUS → ${response.statusCode}");
  print("SPACE BOOKINGS BODY → ${response.body}");

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded
          .map((e) => BookingResponse.fromJson(e))
          .toList();
    }

    return [];
  } else {
    throw Exception("Failed to load space bookings");
  }
}

Future<void> createBooking({
  required int spaceId,
  required DateTime startTime,
  required DateTime endTime,
  required List<Map<String, dynamic>> amenities,
}) async {
  if (user == null) {
    throw Exception("Not logged in");
  }

  final url = Uri.parse("$baseUrl/Booking");

  final body = {
    "spaceId": spaceId,
    "userId": user!.id,
    "bookingStatusId": 1, // 1 = Pending (pretpostavka)
    "startTime": startTime.toIso8601String(),
    "endTime": endTime.toIso8601String(),
    "amenities": amenities,
  };

  print("CREATE BOOKING URL → $url");
  print("CREATE BOOKING BODY → $body");

  final response = await http.post(
    url,
    headers: {
      "Content-Type": "application/json",
    },
    body: jsonEncode(body),
  );

  print("CREATE BOOKING STATUS → ${response.statusCode}");
  print("CREATE BOOKING BODY → ${response.body}");

  if (response.statusCode != 200 &&
      response.statusCode != 201) {
    throw Exception(
        "Booking failed (${response.statusCode})");
  }
}

Future<List<ReviewResponse>> getReviewsBySpace(int spaceId) async {
  final uri = Uri.parse("$baseUrl/Review/space/$spaceId");

  final response = await http.get(uri);

  print("REVIEWS URL → $uri");
  print("REVIEWS STATUS → ${response.statusCode}");
  print("REVIEWS BODY → ${response.body}");

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded
          .map((e) => ReviewResponse.fromJson(e))
          .toList();
    }

    return [];
  } else {
    throw Exception("Failed to load reviews");
  }
}

Future<void> createReview({
  required int spaceId,
  required int rating,
  String? comment,
}) async {
  if (user == null) throw Exception("Not logged in");

  final url = Uri.parse("$baseUrl/Review");

  final body = {
    "spaceId": spaceId,
    "userId": user!.id,
    "rating": rating,
    "comment": comment ?? "",
  };

  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(body),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
  return;
} else {
  throw Exception(response.body);
}
}


Future<void> updateReview({
  required int reviewId,
  required int rating,
  String? comment,
}) async {
  if (user == null) throw Exception("Not logged in");

  final url = Uri.parse("$baseUrl/Review/$reviewId");

  final body = {
    "rating": rating,
    "comment": comment ?? "",
  };

  final response = await http.put(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(body),
  );

  print("UPDATE REVIEW STATUS → ${response.statusCode}");
  print("UPDATE REVIEW BODY → ${response.body}");

  if (response.statusCode == 200) {
    return;
  } else {
    throw Exception(response.body);
  }
}


Future<Map<String, dynamic>> getReviewSummary(int spaceId) async {
  final url = Uri.parse("$baseUrl/Review/space/$spaceId/summary");

  final response = await http.get(url);

  print("SUMMARY STATUS → ${response.statusCode}");
  print("SUMMARY BODY → ${response.body}");

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load summary");
  }
}

Future<void> deleteReview(int reviewId) async {
  if (user == null) throw Exception("Not logged in");

  final url = Uri.parse("$baseUrl/Review/$reviewId");

  final response = await http.delete(url);

  print("DELETE REVIEW STATUS → ${response.statusCode}");
  print("DELETE REVIEW BODY → ${response.body}");

  if (response.statusCode != 200 &&
      response.statusCode != 204) {
    throw Exception("Failed to delete review");
  }
}



}

class ForgotPasswordResponse {
  final bool success;
  final String message;

  ForgotPasswordResponse({required this.success, required this.message});

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
    );
  }
}
