import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/signalr_service.dart';
import '../widgets/notification_dialog.dart';

class NotificationProvider with ChangeNotifier {
  final SignalRService _signalR = SignalRService();

  bool _connected = false;

  Future<void> connect({
    required String token,
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    if (_connected) return;

    await _signalR.connect(token, (data) {
      final context = navigatorKey.currentContext;

      if (context == null) return;

      final title = data["title"] ?? "Notification";
      final space = data["space"] ?? "";
      final date = data["date"] ?? "";
      final reason = data["reason"];

      String formattedDate = "";

      if (date.toString().isNotEmpty) {
        final parsedDate = DateTime.parse(date);

        formattedDate =
            DateFormat('dd MMM yyyy • HH:mm').format(parsedDate);
      }

      String message = "";

      if (title.contains("approved")) {
        message =
            "Your reservation for $space has been approved.\n\n$formattedDate";

      } else if (title.contains("rejected")) {
        message =
            "Unfortunately, your reservation for $space was rejected.\n\n$formattedDate";

        if (reason != null && reason.toString().isNotEmpty) {
          message += "\n\nReason:\n$reason";
        }

      } else if (title.contains("Upcoming")) {
        message =
            "Don't forget! You have a reservation at $space.\n\n$formattedDate";

      } else {
        message = "You have a new notification.";
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => NotificationDialog(
          title: title,
          message: message,
          isRejected: title.contains("rejected"),
        ),
      );
    });

    _connected = true;
  }
}