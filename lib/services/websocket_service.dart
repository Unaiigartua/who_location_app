import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:who_location_app/config/app_config.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:who_location_app/providers/task_provider.dart';
import 'package:who_location_app/services/navigation_service.dart';

class WebSocketService {
  static WebSocketService? current;
  late io.Socket socket;

  // Service for managing WebSocket connections and handling events.

  void connect(String token, {void Function(dynamic)? onNotificationReceived}) {
    socket = io.io(AppConfig.wsBaseUrl, {
      'transports': ['websocket'],
      'auth': {'token': 'Bearer $token'},
      'autoConnect': true,
      'forceNew': true,
    });

    WebSocketService.current = this;

    socket.onConnect((_) {
      debugPrint('[WS] WebSocket Connected');
      debugPrint('[WS] Socket ID: ${socket.id}');
    });

    socket.onDisconnect((_) {
      debugPrint('[WS] WebSocket Disconnected');
    });

    socket.onError((error) {
      debugPrint('[WS] WebSocket Error: $error');
    });

    socket.on('task_notification', (data) {
      // debugPrint('[WS] Raw notification received: ${_formatData(data)}');

      if (data != null && data is Map<String, dynamic>) {
        final notification = {
          'notification': {
            'message': data['message'],
            'type': data['type'] ?? 'task_update',
            'users': data['user_id'],
          }
        };

        // debugPrint('[WS] Processed notification: ${_formatData(notification)}');

        if (onNotificationReceived != null) {
          onNotificationReceived(notification);
          final context = navigatorKey.currentContext;
          if (context != null) {
            context.read<TaskProvider>().loadTasks();
          }
        }
      } else {
        // debugPrint('[WS] Invalid notification format received');
      }
    });
  }

  void disconnect() {
    socket.disconnect();
    if (WebSocketService.current == this) {
      WebSocketService.current = null;
    }
  }

  void emit(String event, dynamic data) {
    socket.emit(event, data);
  }

  void on(String event, Function(dynamic) handler) {
    socket.on(event, handler);
  }

  String _formatData(dynamic data) {
    const encoder = JsonEncoder.withIndent('  ');
    try {
      return encoder.convert(data);
    } catch (e) {
      return data.toString();
    }
  }
}
