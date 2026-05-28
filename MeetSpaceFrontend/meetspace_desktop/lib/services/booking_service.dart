import 'dart:convert';
import '../models/booking.dart';
import 'api_service.dart';
import '../models/paged_result.dart';

class BookingService {
  final ApiService api;

  BookingService(this.api);

Future<PagedResult<BookingResponse>> getPaged({
  required int page,
  required int pageSize,
  String? name,
  bool? isUpcoming,
  int? bookingStatusId,
}) async {

  final query = {
    "Page": page.toString(),
    "PageSize": pageSize.toString(),
  };

  if (name != null &&
      name.isNotEmpty) {
    query["Name"] = name;
  }

if (isUpcoming != null) {
  query["IsUpcoming"] =
      isUpcoming.toString();
}

if (bookingStatusId != null) {
  query["BookingStatusId"] =
      bookingStatusId.toString();
}

  final response = await api.get(
    "Booking",
    queryParameters: query,
  );

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);

    return PagedResult<BookingResponse>.fromJson(
      decoded,
      (e) => BookingResponse.fromJson(e),
    );
  }

  throw Exception(
      "Failed to load paged bookings");
}

Future<void> approve(int id) async {
  final response = await api.put("Booking/$id/approve", {});

  if (response.statusCode != 200) {
    throw Exception("Approve failed");
  }
}

Future<void> rejectWithReason(int id, String reason) async {

  final response = await api.put(
    "Booking/$id/reject",
    {"reason": reason},
  );

  if (response.statusCode != 200) {
    throw Exception("Reject failed");
  }
}

Future<void> cancelWithReason(int id, String reason) async {
  final response = await api.put(
    "Booking/$id/cancel",
    {"reason": reason},
  );

  if (response.statusCode != 200) {
    throw Exception("Cancel failed");
  }
}

Future<bool> checkConflict({
  required int spaceId,
  required DateTime start,
  required DateTime end,
  int? ignoreId,
}) async {
  final response = await api.get(
    "Booking/check-conflict?spaceId=$spaceId&start=$start&end=$end&ignoreId=$ignoreId",
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['hasConflict'];
  }

  throw Exception("Conflict check failed");
}

Future<List<BookingResponse>> getBookingsByUser(int userId) async {
  final response = await api.get("Booking/user/$userId");

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded
          .map((e) => BookingResponse.fromJson(e))
          .toList();
    }

    return [];
  }

  throw Exception("Failed to load user bookings");
}

Future<void> sendReminder(int id) async {

  final response = await api.post(
    "Booking/$id/send-reminder",
    {},
  );

  if (response.statusCode != 200) {
    throw Exception("Reminder failed");
  }
}

}