import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:smartsolar/services/auth_service.dart';
import 'package:smartsolar/utils/constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  late io.Socket socket;
  final Map<String, List<Function>> _listeners = {};
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final token = await AuthService().getToken();

    socket = io.io(
      Constants.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .setTimeout(Constants.timeout.inMilliseconds)
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1200)
          .setReconnectionDelayMax(2500)
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      debugPrint('Socket connected');
      _notify('connect', null);
    });

    socket.onDisconnect((_) {
      debugPrint('Socket disconnected');
      _notify('disconnect', null);
    });

    socket.on('data-update', (data) {
      _notify('data-update', data);
    });

    socket.on('daily-stats', (data) {
      _notify('daily-stats', data);
    });

    socket.on('system-status', (data) {
      _notify('system-status', data);
    });

    socket.on('new-event', (data) {
      _notify('new-event', data);
    });

    socket.on('new-alert', (data) {
      _notify('new-alert', data);
    });

    socket.on('command-sent', (data) {
      _notify('command-sent', data);
    });

    socket.on('last-seen', (data) {
      _notify('last-seen', data);
    });

    socket.on('hourly-data', (data) {
      _notify('hourly-data', data);
    });

    _isInitialized = true;
  }

  void on(String event, Function callback) {
    if (!_listeners.containsKey(event)) {
      _listeners[event] = [];
    }
    _listeners[event]!.add(callback);
  }

  void off(String event, Function callback) {
    if (_listeners.containsKey(event)) {
      _listeners[event]!.remove(callback);
    }
  }

  void _notify(String event, dynamic data) {
    if (_listeners.containsKey(event)) {
      for (var callback in _listeners[event]!) {
        callback(data);
      }
    }
  }

  void disconnect() {
    if (_isInitialized) {
      socket.disconnect();
    }
  }

  void reconnect() {
    if (_isInitialized) {
      socket.disconnect();
      _isInitialized = false;
      initialize();
    }
  }
}
