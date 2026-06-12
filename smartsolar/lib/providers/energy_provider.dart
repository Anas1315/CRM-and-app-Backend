import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:smartsolar/models/alert_model.dart';
import 'package:smartsolar/models/daily_stats.dart';
import 'package:smartsolar/models/energy_data.dart';
import 'package:smartsolar/services/api_service.dart';
import 'package:smartsolar/services/notification_service.dart';
import 'package:smartsolar/services/socket_service.dart';

class EnergyProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();

  EnergyData? _currentData;
  DailyStats? _dailyStats;
  List<HourlyData> _hourlyData = [];
  List<dynamic> _events = [];
  List<dynamic> _alerts = [];
  bool _isLoading = true;
  String _connectionStatus = 'connecting';
  String _systemStatusMessage = 'System Normal';
  String _userMode = 'HOME';
  String _currentTemp = '--°C';
  Timer? _pollingTimer;

  EnergyData? get currentData => _currentData;
  DailyStats? get dailyStats => _dailyStats;
  List<HourlyData> get hourlyData => _hourlyData;
  List<dynamic> get events => _events;
  List<dynamic> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String get connectionStatus => _connectionStatus;
  String get systemStatusMessage => _systemStatusMessage;
  String get userMode => _userMode;
  String get currentTemp => _currentTemp;

  EnergyProvider({bool autoConnect = true}) {
    _currentData = _fallbackData();
    _dailyStats = DailyStats.empty();
    _isLoading = false;
    if (autoConnect) {
      Future<void>.microtask(_init);
    }
  }

  Future<void> _init() async {
    _registerSocketListeners();
    fetchWeather();
    await Future.wait([
      loadAllData(showLoading: false),
      _socketService.initialize().catchError((error) {
        debugPrint('Socket initialization failed: $error');
      }),
    ]);

    // Fallback polling since backend sockets might not be connected
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      loadAllData(showLoading: false);
    });
  }

  Future<void> loadAllData({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final results = await Future.wait([
        _apiService.getStatus(),
        _apiService.getDailyStats(),
        _apiService.getHourlyData(),
        _apiService.getEvents(),
        _apiService.getAlerts(),
      ]);

      _currentData = results[0] as EnergyData;
      _dailyStats = results[1] as DailyStats;
      _hourlyData = results[2] as List<HourlyData>;

      final newEvents = results[3] as List<dynamic>;
      if (_events.isNotEmpty) {
        for (var evt in newEvents) {
          if (evt is Map && evt['id'] != null) {
            final evtId = evt['id'].toString();
            final isOld = _events.any(
              (oldEvt) => oldEvt is Map && oldEvt['id']?.toString() == evtId,
            );
            if (!isOld) {
              final title = evt['title']?.toString() ?? 'System Event';
              final message = evt['message']?.toString() ?? '';
              final type = evt['type']?.toString().toLowerCase() ?? 'info';

              if (type == 'danger') {
                NotificationService().showCriticalAlert(
                  title: title,
                  body: message,
                );
              } else if (type == 'warning') {
                NotificationService().showNotification(
                  id:
                      int.tryParse(evtId) ??
                      DateTime.now().millisecondsSinceEpoch ~/ 1000,
                  title: '⚠️ $title',
                  body: message,
                  priority: AlertPriority.medium,
                );
              } else if (type == 'success') {
                NotificationService().showNotification(
                  id:
                      int.tryParse(evtId) ??
                      DateTime.now().millisecondsSinceEpoch ~/ 1000,
                  title: '✅ $title',
                  body: message,
                  priority: AlertPriority.medium,
                );
              } else {
                NotificationService().showSystemNotification(
                  title: title,
                  body: message,
                );
              }
            }
          }
        }
      }
      _events = newEvents;

      final newAlerts = results[4] as List<dynamic>;
      if (_alerts.isNotEmpty) {
        for (var alertData in newAlerts) {
          if (alertData is Map && alertData['id'] != null) {
            final alertId = alertData['id'].toString();
            final isOld = _alerts.any(
              (oldAlert) =>
                  oldAlert is Map && oldAlert['id']?.toString() == alertId,
            );
            if (!isOld) {
              final alert = AlertModel.fromJson(
                Map<String, dynamic>.from(alertData),
              );
              alert.showAsNotification();
            }
          }
        }
      }
      _alerts = newAlerts;
      _connectionStatus = 'connected';
    } catch (e) {
      _connectionStatus = 'error';
      debugPrint('Error loading data: $e');
      _currentData ??= _fallbackData();
      _dailyStats ??= DailyStats.empty();
    } finally {
      _isLoading = false;
      notifyListeners();
      _updateHomeWidget();
      _checkUnreadAlerts();
    }
  }

  void _checkUnreadAlerts() {
    final unreadCount = _alerts.where((a) {
      if (a is! Map) return false;
      return !(a['isRead'] ?? a['read'] ?? false);
    }).length;

    if (unreadCount > 0) {
      NotificationService().showNotification(
        id: 999,
        title: 'Unread Alerts',
        body: 'You have $unreadCount unread alerts in your dashboard.',
        priority: AlertPriority.medium,
      );
    }
  }

  Future<void> fetchWeather() async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=33.68&longitude=73.04&current_weather=true',
        ),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _currentTemp = '${data['current_weather']['temperature'].round()}°C';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Weather fetch failed: $e');
    }
  }

  Future<bool> sendCommand(String type, int value) async {
    final previousData = _currentData;
    final previousMode = _userMode;
    _applyCommandState(type, value);

    // Show immediate notification
    String cmdTitle = 'Command Sent';
    String cmdBody = '';
    if (type == 'WAPDA_MODE') {
      cmdBody = value == 1
          ? 'Home WAPDA set to Automatic'
          : 'Home WAPDA set to Manual';
    } else if (type == 'WAPDA_RELAY') {
      cmdBody = value == 1
          ? 'Turn Home WAPDA ON command sent'
          : 'Turn Home WAPDA OFF command sent';
    } else if (type == 'HEAVY_LOAD_MODE') {
      cmdBody = value == 1
          ? 'Heavy Load set to Automatic'
          : 'Heavy Load set to Manual';
    } else if (type == 'HEAVY_LOAD') {
      cmdBody = value == 1
          ? 'Turn Heavy Load ON command sent'
          : 'Turn Heavy Load OFF command sent';
    } else {
      cmdBody = '$type command sent';
    }

    NotificationService().showSystemNotification(
      title: cmdTitle,
      body: cmdBody,
    );

    final success = await _apiService.sendCommand(type, value);
    if (!success) {
      _currentData = previousData;
      _userMode = previousMode;
      notifyListeners();

      NotificationService().showCriticalAlert(
        title: 'Command Failed',
        body: 'Failed to send command to controller.',
      );
    }
    return success;
  }

  Future<bool> sendCommandPayload(String type, Object value) async {
    final success = await _apiService.sendCommandPayload(type, value);
    return success;
  }

  void _applyCommandState(String type, int value) {
    if (type == 'WAPDA_RELAY' && _currentData != null) {
      _currentData = _currentData!.copyWith(wapdaRelayState: value == 1);
    } else if (type == 'HEAVY_LOAD' && _currentData != null) {
      _currentData = _currentData!.copyWith(heavyLoadState: value == 1);
    } else if (type == 'WAPDA_MODE' && _currentData != null) {
      final automatic = value == 1;
      _currentData = _currentData!.copyWith(
        wapdaAutoMode: automatic,
        wapdaRelayState: automatic
            ? (_currentData!.isDayTime ? false : _currentData!.wapdaAvailable)
            : _currentData!.wapdaRelayState,
      );
    } else if (type == 'HEAVY_LOAD_MODE' && _currentData != null) {
      final automatic = value == 1;
      _currentData = _currentData!.copyWith(
        heavyLoadAutoMode: automatic,
        heavyLoadState: automatic
            ? (_currentData!.isDayTime ? true : _currentData!.wapdaAvailable)
            : _currentData!.heavyLoadState,
      );
    } else if (type == 'USER_MODE') {
      _userMode = _getModeName(value);
    }
    notifyListeners();
  }

  String _getModeName(int value) {
    switch (value) {
      case 1:
        return 'HOME';
      case 2:
        return 'SAVING';
      case 3:
        return 'PERFORMANCE';
      default:
        return 'HOME';
    }
  }

  Future<bool> clearHistory() async {
    final success = await _apiService.clearEvents();
    if (success) {
      _events = [];
      _alerts = [];
      notifyListeners();
    }
    return success;
  }

  void markAlertRead(String id) {
    _alerts = _alerts.map((alert) {
      if (alert is! Map) return alert;
      final copy = Map<String, dynamic>.from(alert);
      if (copy['id']?.toString() == id) {
        copy['isRead'] = true;
      }
      return copy;
    }).toList();
    notifyListeners();
    _apiService.markAlertRead(id);
  }

  void markAllAlertsAsRead() {
    _alerts = _alerts.map((alert) {
      if (alert is! Map) return alert;
      final copy = Map<String, dynamic>.from(alert);
      copy['isRead'] = true;
      return copy;
    }).toList();
    notifyListeners();
    _apiService.markAlertsRead();
  }

  void dismissAlert(String id) {
    _alerts = _alerts.where((alert) {
      if (alert is! Map) return true;
      return alert['id']?.toString() != id;
    }).toList();
    notifyListeners();
    _apiService.markAlertRead(
      id,
    ); // Dismissing is also treated as read/acknowledged
  }

  void clearAlerts() {
    _alerts = [];
    notifyListeners();
    _apiService.clearEvents();
  }

  void refresh() {
    loadAllData();
  }

  void _registerSocketListeners() {
    _socketService.on('data-update', (data) {
      if (data is Map) {
        _currentData = EnergyData.fromJson(Map<String, dynamic>.from(data));
        _isLoading = false;
        notifyListeners();
        _updateHomeWidget();
      }
    });

    _socketService.on('daily-stats', (data) {
      if (data is Map) {
        _dailyStats = DailyStats.fromJson(Map<String, dynamic>.from(data));
        notifyListeners();
      }
    });

    _socketService.on('hourly-data', (data) {
      if (data is List) {
        _hourlyData = data
            .whereType<Map>()
            .map((item) => HourlyData.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        notifyListeners();
      }
    });

    _socketService.on('system-status', (data) {
      if (data is Map) {
        _systemStatusMessage = data['message'] ?? 'System Normal';
        notifyListeners();
      }
    });

    _socketService.on('new-event', (data) {
      if (data != null) {
        _events.insert(0, data);
        if (_events.length > 100) _events.removeLast();
        notifyListeners();

        if (data is Map) {
          final type = data['type']?.toString().toLowerCase();
          final message = data['message']?.toString() ?? 'System event';
          final title = type == 'danger' ? 'Critical Alert' : 'System Event';

          if (type == 'danger') {
            NotificationService().showCriticalAlert(
              title: title,
              body: message,
            );
          } else if (type == 'warning') {
            NotificationService().showNotification(
              id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              title: '⚠️ Warning',
              body: message,
              priority: AlertPriority.medium,
            );
          } else {
            NotificationService().showSystemNotification(
              title: title,
              body: message,
            );
          }
        }
      }
    });

    _socketService.on('new-alert', (data) {
      if (data != null) {
        _alerts.insert(0, data);
        if (_alerts.length > 50) _alerts.removeLast();
        notifyListeners();

        if (data is Map) {
          final alert = AlertModel.fromJson(Map<String, dynamic>.from(data));
          alert.showAsNotification();
        }
      }
    });

    _socketService.on('connect', (_) {
      _connectionStatus = 'connected';
      notifyListeners();
    });

    _socketService.on('disconnect', (_) {
      _connectionStatus = 'disconnected';
      notifyListeners();
    });
  }

  EnergyData _fallbackData() {
    return EnergyData(
      voltage: 220,
      current: 2.1,
      power: 456000,
      ldrValue: 2200,
      wapdaAvailable: true,
      isSunny: true,
      isDayTime: true,
      wapdaRelayState: true,
      heavyLoadState: true,
      wapdaAutoMode: true,
      heavyLoadAutoMode: true,
      currentHour: DateTime.now().hour,
      lastUpdate: DateTime.now(),
      esp32Online: false,
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _socketService.disconnect();
    super.dispose();
  }

  Future<void> _updateHomeWidget() async {
    if (_currentData == null) return;

    try {
      final powerKw = (_currentData!.power / 1000).toStringAsFixed(1);
      final status = _currentData!.esp32Online ? 'Connected' : 'Offline';

      await HomeWidget.saveWidgetData<String>('powerKw', '$powerKw kW');
      await HomeWidget.saveWidgetData<String>('status', status);
      await HomeWidget.updateWidget(
        name: 'EnergyWidgetProvider',
        androidName: 'EnergyWidgetProvider',
      );
    } catch (e) {
      debugPrint('HomeWidget update failed (expected if Android Home Widget is not fully configured): $e');
    }
  }
}
