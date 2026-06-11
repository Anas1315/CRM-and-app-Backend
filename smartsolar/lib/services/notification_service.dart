import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartsolar/models/alert_model.dart';

/// Notification service for handling local and push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _notificationsEnabled = true;

  // Notification channels for Android
  static const String _criticalChannelId = 'critical_alerts';
  static const String _powerChannelId = 'power_alerts';
  static const String _systemChannelId = 'system_alerts';
  static const String _dailyChannelId = 'daily_summary';

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Load notification preferences
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('desktop_notifications') ?? true;

    // Initialize settings for Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialize settings for iOS
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onNotificationTapBackground,
    );

    // Create notification channels for Android
    await _createNotificationChannels();

    _isInitialized = true;
    await requestPermission();
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return;

    // Critical alerts channel (high priority)
    const AndroidNotificationChannel criticalChannel =
        AndroidNotificationChannel(
          _criticalChannelId,
          'Critical Alerts',
          description: 'High priority alerts for emergencies',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        );
    await androidPlugin.createNotificationChannel(criticalChannel);

    // Power alerts channel (high priority)
    const AndroidNotificationChannel powerChannel = AndroidNotificationChannel(
      _powerChannelId,
      'Power Alerts',
      description: 'Grid and solar power notifications',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );
    await androidPlugin.createNotificationChannel(powerChannel);

    // System alerts channel (default priority)
    const AndroidNotificationChannel systemChannel = AndroidNotificationChannel(
      _systemChannelId,
      'System Alerts',
      description: 'System events and updates',
      importance: Importance.defaultImportance,
      enableVibration: false,
      playSound: true,
      showBadge: true,
    );
    await androidPlugin.createNotificationChannel(systemChannel);

    // Daily summary channel (low priority)
    const AndroidNotificationChannel dailyChannel = AndroidNotificationChannel(
      _dailyChannelId,
      'Daily Summary',
      description: 'Daily energy reports and summaries',
      importance: Importance.low,
      enableVibration: false,
      playSound: false,
      showBadge: true,
    );
    await androidPlugin.createNotificationChannel(dailyChannel);
  }

  /// Handle notification tap when app is in foreground
  void _onNotificationTap(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload != null) {
      _handleNotificationPayload(payload);
    }
  }

  /// Handle notification tap when app is in background
  @pragma('vm:entry-point')
  static void _onNotificationTapBackground(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload != null) {
      _handleBackgroundNotificationPayload(payload);
    }
  }

  /// Handle notification payload in foreground
  void _handleNotificationPayload(String payload) {
    // Parse payload and navigate to appropriate screen
    debugPrint('Notification tapped with payload: $payload');
  }

  /// Handle notification payload in background
  static void _handleBackgroundNotificationPayload(String payload) {
    // Handle background notification tap
    // This runs in a separate isolate
    debugPrint('Background notification tapped: $payload');
  }

  /// Request notification permissions
  Future<bool> requestPermission() async {
    if (!_notificationsEnabled) return false;

    try {
      final bool? androidResult = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

      final bool? result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return androidResult ?? result ?? true;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Show a notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    AlertPriority priority = AlertPriority.medium,
    String? channelId,
    bool? sound,
    bool? vibration,
  }) async {
    if (!_notificationsEnabled) return;
    final cleanTitle = _asciiSafe(title).trim();
    final cleanBody = _asciiSafe(body).trim();

    // Check if user wants this type of notification
    final shouldShow = await _shouldShowNotification(priority);
    if (!shouldShow) return;

    // Determine channel ID based on priority
    final String finalChannelId = channelId ?? _getChannelForPriority(priority);

    // Configure sound and vibration
    final bool enableSound = sound ?? _getSoundForPriority(priority);
    final bool enableVibration =
        vibration ?? _getVibrationForPriority(priority);

    // Android details
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          finalChannelId,
          _getChannelName(finalChannelId),
          channelDescription: _getChannelDescription(finalChannelId),
          importance: _getImportanceForPriority(priority),
          priority: _getAndroidPriorityForPriority(priority),
          enableVibration: enableVibration,
          vibrationPattern: enableVibration
              ? Int64List.fromList(_getVibrationPattern(priority))
              : null,
          playSound: enableSound,
          styleInformation: BigTextStyleInformation(body),
          visibility: NotificationVisibility.public,
          autoCancel: true,
          showWhen: true,
        );

    // iOS details
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Show the notification
    await _flutterLocalNotificationsPlugin.show(
      id,
      cleanTitle.isEmpty ? title : cleanTitle,
      cleanBody.isEmpty ? body : cleanBody,
      details,
      payload: payload,
    );
  }

  String _asciiSafe(String value) {
    return value.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
  }

  /// Show a critical alert notification (high priority)
  Future<void> showCriticalAlert({
    required String title,
    required String body,
    String? payload,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '⚠️ $title',
      body: body,
      payload: payload,
      priority: AlertPriority.high,
    );
  }

  /// Show a power alert notification
  Future<void> showPowerAlert({
    required String title,
    required String body,
    String? payload,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '🔌 $title',
      body: body,
      payload: payload,
      priority: AlertPriority.high,
    );
  }

  /// Show a system notification
  Future<void> showSystemNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '📱 $title',
      body: body,
      payload: payload,
      priority: AlertPriority.medium,
    );
  }

  /// Show a daily summary notification
  Future<void> showDailySummary({
    required String title,
    required String body,
    String? payload,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('daily_summary') ?? true;

    if (!enabled) return;

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '📊 $title',
      body: body,
      payload: payload,
      priority: AlertPriority.low,
      channelId: _dailyChannelId,
      sound: false,
      vibration: false,
    );
  }

  /// Show a custom styled notification with actions
  Future<void> showActionNotification({
    required int id,
    required String title,
    required String body,
    required List<NotificationAction> actions,
    String? payload,
    AlertPriority priority = AlertPriority.medium,
  }) async {
    if (!_notificationsEnabled) return;

    final bool shouldShow = await _shouldShowNotification(priority);
    if (!shouldShow) return;

    final String channelId = _getChannelForPriority(priority);

    // Create Android action buttons
    final List<AndroidNotificationAction> androidActions = actions.map((
      action,
    ) {
      return AndroidNotificationAction(
        action.id,
        action.title,
        showsUserInterface: true,
        cancelNotification: action.cancelNotification ?? true,
      );
    }).toList();

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channelId,
          _getChannelName(channelId),
          channelDescription: _getChannelDescription(channelId),
          importance: _getImportanceForPriority(priority),
          priority: _getAndroidPriorityForPriority(priority),
          actions: androidActions,
          styleInformation: BigTextStyleInformation(body),
          autoCancel: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Show a progress notification (e.g., for firmware update)
  Future<void> showProgressNotification({
    required int id,
    required String title,
    required String body,
    required int progress,
    int maxProgress = 100,
    bool indeterminate = false,
  }) async {
    if (!_notificationsEnabled) return;

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _systemChannelId,
          'System Alerts',
          channelDescription: 'System events and updates',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          onlyAlertOnce: true,
          showProgress: true,
          progress: progress,
          maxProgress: maxProgress,
          indeterminate: indeterminate,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(id, title, body, details);
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return _notificationsEnabled;
  }

  /// Enable/disable all notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('desktop_notifications', enabled);

    if (!enabled) {
      await cancelAllNotifications();
    }
  }

  /// Check if a specific type of notification is allowed
  Future<bool> _shouldShowNotification(AlertPriority priority) async {
    final prefs = await SharedPreferences.getInstance();

    switch (priority) {
      case AlertPriority.high:
        return prefs.getBool('critical_alerts') ?? true;
      case AlertPriority.medium:
        return prefs.getBool('power_alerts') ?? true;
      case AlertPriority.low:
        return prefs.getBool('system_alerts') ?? true;
    }
  }

  /// Get channel ID based on priority
  String _getChannelForPriority(AlertPriority priority) {
    switch (priority) {
      case AlertPriority.high:
        return _criticalChannelId;
      case AlertPriority.medium:
        return _powerChannelId;
      case AlertPriority.low:
        return _systemChannelId;
    }
  }

  /// Get channel name
  String _getChannelName(String channelId) {
    switch (channelId) {
      case _criticalChannelId:
        return 'Critical Alerts';
      case _powerChannelId:
        return 'Power Alerts';
      case _systemChannelId:
        return 'System Alerts';
      case _dailyChannelId:
        return 'Daily Summary';
      default:
        return 'General Notifications';
    }
  }

  /// Get channel description
  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case _criticalChannelId:
        return 'High priority alerts for emergencies';
      case _powerChannelId:
        return 'Grid and solar power notifications';
      case _systemChannelId:
        return 'System events and updates';
      case _dailyChannelId:
        return 'Daily energy reports and summaries';
      default:
        return 'General notifications';
    }
  }

  /// Get importance for priority (Android)
  Importance _getImportanceForPriority(AlertPriority priority) {
    switch (priority) {
      case AlertPriority.high:
        return Importance.max;
      case AlertPriority.medium:
        return Importance.high;
      case AlertPriority.low:
        return Importance.defaultImportance;
    }
  }

  /// Get Android priority for notification
  Priority _getAndroidPriorityForPriority(AlertPriority priority) {
    switch (priority) {
      case AlertPriority.high:
        return Priority.max;
      case AlertPriority.medium:
        return Priority.high;
      case AlertPriority.low:
        return Priority.defaultPriority;
    }
  }

  /// Get sound for priority
  bool _getSoundForPriority(AlertPriority priority) {
    switch (priority) {
      case AlertPriority.high:
        return true;
      case AlertPriority.medium:
        return true;
      case AlertPriority.low:
        return false;
    }
  }

  /// Get vibration for priority
  bool _getVibrationForPriority(AlertPriority priority) {
    switch (priority) {
      case AlertPriority.high:
        return true;
      case AlertPriority.medium:
        return true;
      case AlertPriority.low:
        return false;
    }
  }

  /// Get vibration pattern for priority
  List<int> _getVibrationPattern(AlertPriority priority) {
    switch (priority) {
      case AlertPriority.high:
        return [0, 500, 200, 500, 200, 1000];
      case AlertPriority.medium:
        return [0, 300, 100, 300];
      case AlertPriority.low:
        return [0, 200, 100, 200];
    }
  }
}

/// Notification action model for actionable notifications
class NotificationAction {
  final String id;
  final String title;
  final String? icon;
  final bool? cancelNotification;

  const NotificationAction({
    required this.id,
    required this.title,
    this.icon,
    this.cancelNotification,
  });
}

/// Helper extension for creating notifications from AlertModel
extension AlertModelNotification on AlertModel {
  Future<void> showAsNotification() async {
    final priorityString = priority == AlertPriority.high
        ? 'CRITICAL'
        : priority == AlertPriority.medium
        ? 'WARNING'
        : 'INFO';

    await NotificationService().showNotification(
      id: int.tryParse(id) ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title:
          '[$priorityString] ${message.length > 50 ? '${message.substring(0, 47)}...' : message}',
      body: details ?? message,
      payload: 'alert_$id',
      priority: priority,
    );
  }
}
