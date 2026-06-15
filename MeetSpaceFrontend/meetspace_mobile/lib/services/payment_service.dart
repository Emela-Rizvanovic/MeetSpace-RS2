import 'dart:convert';
import 'api_service.dart';

class PaymentService {
  final ApiService api;

  PaymentService(this.api);

Future<Map<String, dynamic>> createPaymentIntent({
  required int spaceId,
  required DateTime startTime,
  required DateTime endTime,
  required List<Map<String, dynamic>> amenities,
}) async {
  final body = {
    "spaceId": spaceId,
    "startTime": startTime.toIso8601String(),
    "endTime": endTime.toIso8601String(),
    "amenities": amenities,
    "currency": "bam"
  };

    final response = await api.post("Payment/create-intent", body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Failed to create payment intent");
  }

  Future<Map<String, dynamic>> confirmPayment({
    required int spaceId,
    required DateTime startTime,
    required DateTime endTime,
    required int paymentIntentId,
    required List<Map<String, dynamic>> amenities,
  }) async {
    final body = {
      "spaceId": spaceId,
      "startTime": startTime.toIso8601String(),
      "endTime": endTime.toIso8601String(),
      "paymentIntentId": paymentIntentId,
      "amenities": amenities
    };

    final response = await api.post("Payment/confirm", body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Payment confirmation failed");
  }

Future<Map<String, dynamic>> createPaypalOrder({
  required int spaceId,
  required DateTime startTime,
  required DateTime endTime,
  required List<Map<String, dynamic>> amenities,
}) async {
  final body = {
    "spaceId": spaceId,
    "startTime": startTime.toIso8601String(),
    "endTime": endTime.toIso8601String(),
    "amenities": amenities
  };

  final response = await api.post("PayPal/create-order", body);

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }

  throw Exception("Failed to create PayPal order");
}

Future<void> capturePaypalOrder({
  required String orderId,
  required int spaceId,
  required DateTime startTime,
  required DateTime endTime,
  required List<Map<String, dynamic>> amenities,
}) async {
  final body = {
    "orderId": orderId,
    "spaceId": spaceId,
    "startTime": startTime.toIso8601String(),
    "endTime": endTime.toIso8601String(),
    "amenities": amenities
  };

  final response = await api.post("PayPal/capture", body);

  if (response.statusCode != 200) {
    throw Exception("PayPal capture failed");
  }
}

}