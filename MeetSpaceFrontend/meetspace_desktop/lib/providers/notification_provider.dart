import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_notification.dart';
import '../services/api_service.dart';
import '../services/signalr_service.dart';
import '../widgets/notification_dialog.dart';

class NotificationProvider with ChangeNotifier {
  final SignalRService _signalR = SignalRService();

  bool _connected = false;
  bool _connecting = false;
  List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => _notifications;

  int get unreadCount =>
      _notifications.where((item) => !item.isRead).length;

  Future<void> loadNotifications({
    required String baseUrl,
    required String token,
  }) async {
    try {
      final api = ApiService(
        baseUrl: baseUrl,
        token: token,
      );

      final response = await api.get("notifications");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;

        _notifications = data
            .map((item) => AppNotification.fromJson(item))
            .toList();

        notifyListeners();
      }
    } catch (_) {
      return;
    }
  }

  Future<void> markAllAsRead({
    required String baseUrl,
    required String token,
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
          .map((item) => item.copyWith(isRead: true))
          .toList();

      notifyListeners();
    } catch (_) {
      return;
    }
  }

  Future<void> markAsRead({
    required String baseUrl,
    required String token,
    required int notificationId,
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
            (item) => item.id == notificationId
                ? item.copyWith(isRead: true)
                : item,
          )
          .toList();

      notifyListeners();
    } catch (_) {
      return;
    }
  }

  Future<void> connect({
  required String baseUrl,
  required String token,
  required GlobalKey<NavigatorState> navigatorKey,
}) async {
  if (_connected || _connecting) return;

  _connecting = true;

  await loadNotifications(
      baseUrl: baseUrl,
      token: token,
    );

    final hubUrl = baseUrl.replaceFirst('/api', '/notificationHub');

    await _signalR.connect(
      hubUrl: hubUrl,
      token: token,
      onMessage: (data) {
        final context = navigatorKey.currentContext;

        final notification = AppNotification(
  id: data["id"] ?? 0,
  title: data["title"] ?? "Notification",
  message: data["message"] ?? "",
  isRead: data["isRead"] ?? false,
  createdAt: DateTime.now(),
  notificationType: data["type"]?.toString(),
);

if (_notifications.any((item) => item.id == notification.id)) {
  return;
}

_notifications.insert(0, notification);
notifyListeners();

        if (context == null) return;

        final date = data["date"]?.toString() ?? "";
        String formattedDate = "";

        if (date.isNotEmpty) {
          formattedDate = DateFormat(
            'dd MMM yyyy - HH:mm',
          ).format(DateTime.parse(date));
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => NotificationDialog(
            title: notification.title,
            message: formattedDate.isEmpty
                ? notification.message
                : "${notification.message}\n\n$formattedDate",
            isWarning: notification.title
                .toLowerCase()
                .contains("cancel"),
          ),
        );
      },
    );

    _connected = true;
_connecting = false;
  }

 Future<void> disconnect() async {
  await _signalR.disconnect();
  _connected = false;
  _connecting = false;
}
}