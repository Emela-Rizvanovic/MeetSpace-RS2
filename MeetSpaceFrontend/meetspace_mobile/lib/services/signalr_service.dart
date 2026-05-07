import 'package:signalr_netcore/signalr_client.dart';

class SignalRService {
  HubConnection? _connection;

  Future<void> connect(String token, Function(Map<String, dynamic>) onMessage) async {
    _connection = HubConnectionBuilder()
        .withUrl(
          "http://10.0.2.2:5245/notificationHub", 
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
          ),
        )
        .withAutomaticReconnect()
        .build();

   _connection!.on("ReceiveNotification", (arguments) {
    print("EVENT RECEIVED");
  if (arguments != null && arguments.isNotEmpty) {
    try {
      final raw = arguments[0];
      final data = Map<String, dynamic>.from(raw as Map);
      onMessage(data);
    } catch (e) {
      print("SignalR parse error: $e");
    }
  }
});

    await _connection!.start();

    print("SIGNALR CONNECTED");
  }

  Future<void> disconnect() async {
    await _connection?.stop();
  }
}