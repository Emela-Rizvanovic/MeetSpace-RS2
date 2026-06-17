import 'package:signalr_netcore/signalr_client.dart';

class SignalRService {
  HubConnection? _connection;

 Future<void> connect({
  required String token,
  required String apiBaseUrl,
  required Function(Map<String, dynamic>) onMessage,
}) async {
  final hubUrl = apiBaseUrl.replaceFirst(
    RegExp(r'/api/?$'),
    '/notificationHub',
  );

  _connection = HubConnectionBuilder()
      .withUrl(
        hubUrl,
        options: HttpConnectionOptions(
          accessTokenFactory: () async => token,
        ),
      )
      .withAutomaticReconnect()
      .build();

   _connection!.on("ReceiveNotification", (arguments) {
  if (arguments != null && arguments.isNotEmpty) {
    try {
      final raw = arguments[0];
      final data = Map<String, dynamic>.from(raw as Map);
      onMessage(data);
    } catch (_) {
  return;
}
  }
});

    await _connection!.start();
  }

  Future<void> disconnect() async {
    await _connection?.stop();
  }
}