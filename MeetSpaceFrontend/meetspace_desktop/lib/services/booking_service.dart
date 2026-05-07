import 'dart:convert';
import '../models/booking.dart';
import 'api_service.dart';
import '../models/paged_result.dart';

class BookingService {
  final ApiService api;

  BookingService(this.api);

  Future<List<BookingResponse>> getMyBookings(int userId) async {
    final response = await api.get("Booking/user/$userId");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded
            .map((e) => BookingResponse.fromJson(e))
            .toList();
      }
    }

    throw Exception("Failed to load bookings");
  }

  Future<List<BookingResponse>> getBookingsForSpace(int spaceId) async {
    final response = await api.get("Booking/space/$spaceId");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded
            .map((e) => BookingResponse.fromJson(e))
            .toList();
      }
    }

    throw Exception("Failed to load space bookings");
  }

  Future<void> createBooking(Map<String, dynamic> body) async {
    final response = await api.post("Booking", body);

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception("Booking failed");
    }
  }

  Future<List<BookingResponse>> getAll() async {
  final response = await api.get("Booking");

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);

    final items = decoded['items'] as List;

    return items.map((e) => BookingResponse.fromJson(e)).toList();
  }

  throw Exception("Failed to load bookings");
}

Future<PagedResult<BookingResponse>> getPaged({
  required int page,
  required int pageSize,
}) async {
  final response = await api.get(
    "Booking?page=$page&pageSize=$pageSize",
  );

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);

    return PagedResult<BookingResponse>.fromJson(
      decoded,
      (e) => BookingResponse.fromJson(e),
    );
  }

  throw Exception("Failed to load paged bookings");
}

Future<void> approve(int id) async {
  print("➡️ APPROVE request for booking $id");

  final response = await api.put("Booking/$id/approve", {});

  print("⬅️ RESPONSE: ${response.statusCode}");

  if (response.statusCode != 200) {
    print("❌ ERROR BODY: ${response.body}");
    throw Exception("Approve failed");
  }
}

Future<void> reject(int id) async {
  print("➡️ REJECT request for booking $id");

  final response = await api.put("Booking/$id/reject", {});

  print("⬅️ RESPONSE: ${response.statusCode}");

  if (response.statusCode != 200) {
    print("❌ ERROR BODY: ${response.body}");
    throw Exception("Reject failed");
  }
}


Future<void> rejectWithReason(int id, String reason) async {
  print("➡️ REJECT request with reason for booking $id");

  final response = await api.put(
    "Booking/$id/reject",
    {"reason": reason},
  );

  print("⬅️ RESPONSE: ${response.statusCode}");

  if (response.statusCode != 200) {
    print("❌ ERROR BODY: ${response.body}");
    throw Exception("Reject failed");
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
  print("➡️ REMINDER request for booking $id");

  final response = await api.post(
    "Booking/$id/send-reminder",
    {},
  );

  print("⬅️ RESPONSE: ${response.statusCode}");

  if (response.statusCode != 200) {
    print("❌ ERROR BODY: ${response.body}");
    throw Exception("Reminder failed");
  }
}

}