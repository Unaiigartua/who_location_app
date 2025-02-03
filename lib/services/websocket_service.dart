import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:who_location_app/config/app_config.dart';

class WebSocketService {
  static WebSocketService? current;
  late IO.Socket socket;

  // Service for managing WebSocket connections and handling events.

  void connect(String token, {void Function(dynamic)? onNotificationReceived}) {
    // Connect to the WebSocket server using the provided token.
    socket = IO.io(AppConfig.wsBaseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'auth': {'token': 'Bearer $token'},
      'autoConnect': false,
    });
    WebSocketService.current = this;
    debugPrint("Connecting to WebSocket server: " + socket.toString());
    socket.on('connect', (_) {
      print("Connected to WebSocket server");
    });
    socket.on('task_updates', (data) {
      print("Task update received: $data");
    });
    socket.on('task_notification', (data) {
      if (onNotificationReceived != null) {
        onNotificationReceived(data);
      }
    });
    socket.on('disconnect', (_) => print("Disconnected from WebSocket server"));
    socket.connect();
  }

  void disconnect() {
    socket.disconnect();
    if (WebSocketService.current == this) {
      WebSocketService.current = null;
    }
    // Disconnect from the WebSocket server and clear the current instance.
  }
}
