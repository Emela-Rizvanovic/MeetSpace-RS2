import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_notification.dart';
import '../services/api_service.dart';
import '../services/signalr_service.dart';
import '../widgets/notification_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider with ChangeNotifier {
  final SignalRService _signalR = SignalRService();

  bool _connected = false;

  List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => _notifications;

  int get unreadCount =>
      _notifications.where((x) => !x.isRead).length;

  bool _notificationsEnabled = true;

bool get notificationsEnabled =>
    _notificationsEnabled;

  Future<void> loadNotifications({
    required String token,
    required int userId,
    required String baseUrl,
  }) async {
    try {
      final api = ApiService(
  baseUrl: baseUrl,
  token: token,
);

      final response = await api.get(
        "notifications",
        queryParameters: {
          "userId": userId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;

        _notifications = data
            .map((e) => AppNotification.fromJson(e))
            .toList();

        notifyListeners();
      }
    } catch (e) {
    }
  }

  Future<void> loadNotificationPreference() async {
  final prefs = await SharedPreferences.getInstance();

  _notificationsEnabled =
      prefs.getBool('notifications_enabled') ?? true;

  notifyListeners();
}

Future<void> setNotificationsEnabled(bool value) async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setBool(
    'notifications_enabled',
    value,
  );

  _notificationsEnabled = value;

  notifyListeners();

  if (!value) {
    await _signalR.disconnect();
    _connected = false;
  }
}

  Future<void> markAllAsRead({
  required String token,
  required int userId,
  required String baseUrl,
}) async {
    try {
      final api = ApiService(
  baseUrl: baseUrl,
  token: token,
);

      await api.put(
        "notifications/mark-all-read",
        {},
      );

      _notifications = _notifications
          .map((e) => e.copyWith(isRead: true))
          .toList();

      notifyListeners();
    } catch (_) {
  return;
}
  }

  Future<void> markAsRead({
  required String token,
  required int notificationId,
  required String baseUrl,
}) async {
  try {
    final api = ApiService(
  baseUrl: baseUrl,
  token: token,
);

    await api.put(
      "notifications/$notificationId/mark-read",
      {},
    );

    _notifications = _notifications
        .map(
          (e) => e.id == notificationId
              ? e.copyWith(isRead: true)
              : e,
        )
        .toList();

    notifyListeners();
  } catch (_) {
    return;
  }
}

  Future<void> connect({
    required String token,
    required int userId,
    required GlobalKey<NavigatorState> navigatorKey,
    required String baseUrl,
  }) async {

    await loadNotificationPreference();

if (!_notificationsEnabled) {
  return;
}

    if (_connected) return;

    await loadNotifications(
  token: token,
  userId: userId,
  baseUrl: baseUrl,
);

    await _signalR.connect(
  token: token,
  apiBaseUrl: baseUrl,
  onMessage: (data) {
      final context = navigatorKey.currentContext;

      if (context == null) return;

      final title = data["title"] ?? "Notification";
      final message = data["message"] ?? "";
      final date = data["date"] ?? "";

      String formattedDate = "";

      if (date.toString().isNotEmpty) {
        final parsedDate = DateTime.parse(date);

        formattedDate =
            DateFormat('dd MMM yyyy • HH:mm').format(parsedDate);
      }

      final notification = AppNotification(
        id: data["id"] ?? 0,
        title: title,
        message: message,
        isRead: false,
        createdAt: DateTime.now(),
      );

      _notifications.insert(0, notification);

      notifyListeners();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => NotificationDialog(
          title: title,
          message: "$message\n\n$formattedDate",
          isRejected:
              title.toString().toLowerCase().contains("rejected"),
        ),
      );
    });

    _connected = true;
  }
}