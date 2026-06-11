import 'package:equatable/equatable.dart';

/// Event types for system events and user actions
enum EventType {
  info, // General information events
  success, // Successful operations
  warning, // Warning events that need attention
  danger, // Critical events/errors
}

/// Event category for grouping
enum EventCategory {
  system, // System related events (startup, shutdown, etc.)
  power, // Power related events (grid, solar, outage)
  relay, // Relay control events (ON/OFF)
  mode, // Mode change events
  command, // User command events
  sensor, // Sensor related events
  connection, // Connection events (WiFi, ESP32)
  alert, // Alert triggered events
}

/// Event model for tracking system history and user actions
class EventModel extends Equatable {
  final String id;
  final EventType type;
  final EventCategory category;
  final String message;
  final String details;
  final DateTime timestamp;
  final String? source; // e.g., 'USER', 'AUTO', 'ESP32', 'SERVER'
  final Map<String, dynamic>? metadata;

  const EventModel({
    required this.id,
    required this.type,
    required this.category,
    required this.message,
    required this.details,
    required this.timestamp,
    this.source,
    this.metadata,
  });

  /// Factory constructor for creating an EventModel from JSON
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      type: _parseEventType(json['type']),
      category: _parseEventCategory(json['category'] ?? json['type']),
      message: json['message'] ?? 'Unknown event',
      details: json['details'] ?? '',
      timestamp: _parseTimestamp(json['timestamp'], json['date'], json['time']),
      source: json['source'],
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  /// Convert EventModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'category': category.name,
      'message': message,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
      'date': _formatDate(timestamp),
      'time': _formatTime(timestamp),
      'source': source,
      'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  EventModel copyWith({
    String? id,
    EventType? type,
    EventCategory? category,
    String? message,
    String? details,
    DateTime? timestamp,
    String? source,
    Map<String, dynamic>? metadata,
  }) {
    return EventModel(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      message: message ?? this.message,
      details: details ?? this.details,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get icon based on event type
  String get icon {
    switch (type) {
      case EventType.info:
        return 'ℹ️';
      case EventType.success:
        return '✅';
      case EventType.warning:
        return '⚠️';
      case EventType.danger:
        return '🔴';
    }
  }

  /// Get color code based on event type
  String get colorHex {
    switch (type) {
      case EventType.info:
        return '#3498DB'; // Blue
      case EventType.success:
        return '#2ECC71'; // Green
      case EventType.warning:
        return '#F39C12'; // Orange
      case EventType.danger:
        return '#E74C3C'; // Red
    }
  }

  /// Get background color with opacity
  String get backgroundColorHex {
    switch (type) {
      case EventType.info:
        return '#3498DB20';
      case EventType.success:
        return '#2ECC7120';
      case EventType.warning:
        return '#F39C1220';
      case EventType.danger:
        return '#E74C3C20';
    }
  }

  /// Get formatted time string (relative)
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return _formatDateTime(timestamp);
    }
  }

  /// Get absolute formatted date and time
  String get formattedDateTime => _formatDateTime(timestamp);

  /// Get formatted date only
  String get formattedDate => _formatDate(timestamp);

  /// Get formatted time only
  String get formattedTimeOnly => _formatTime(timestamp);

  /// Get short message (truncated if too long)
  String get shortMessage {
    if (message.length <= 50) return message;
    return '${message.substring(0, 47)}...';
  }

  /// Get category display name
  String get categoryDisplayName {
    switch (category) {
      case EventCategory.system:
        return 'System';
      case EventCategory.power:
        return 'Power';
      case EventCategory.relay:
        return 'Relay';
      case EventCategory.mode:
        return 'Mode';
      case EventCategory.command:
        return 'Command';
      case EventCategory.sensor:
        return 'Sensor';
      case EventCategory.connection:
        return 'Connection';
      case EventCategory.alert:
        return 'Alert';
    }
  }

  /// Get source display name
  String get sourceDisplayName {
    switch (source?.toLowerCase()) {
      case 'user':
        return '👤 User';
      case 'auto':
        return '🤖 Auto';
      case 'esp32':
        return '📡 ESP32';
      case 'server':
        return '🖥️ Server';
      default:
        return '⚙️ System';
    }
  }

  /// Get priority level (0-3, 3 being highest)
  int get priority {
    switch (type) {
      case EventType.danger:
        return 3;
      case EventType.warning:
        return 2;
      case EventType.success:
        return 1;
      case EventType.info:
        return 0;
    }
  }

  /// Check if event is recent (within last hour)
  bool get isRecent {
    final difference = DateTime.now().difference(timestamp);
    return difference.inMinutes < 60;
  }

  /// Check if event is from today
  bool get isToday {
    final now = DateTime.now();
    return timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
  }

  @override
  List<Object?> get props => [
        id,
        type,
        category,
        message,
        details,
        timestamp,
        source,
        metadata,
      ];

  @override
  String toString() {
    return 'EventModel(id: $id, type: $type, category: $category, '
        'message: $message, timestamp: $timestamp, source: $source)';
  }
}

/// Event group for organizing events by date
class EventGroup {
  final DateTime date;
  final List<EventModel> events;

  EventGroup({
    required this.date,
    required this.events,
  });

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final eventDate = DateTime(date.year, date.month, date.day);

    if (eventDate == today) {
      return 'Today';
    } else if (eventDate == yesterday) {
      return 'Yesterday';
    } else {
      return _formatDate(date);
    }
  }

  String get readableDate {
    const weekdays = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return '${weekdays[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  int get eventCount => events.length;

  int get highPriorityCount => events.where((e) => e.priority >= 2).length;
}

/// Helper class for filtering events
class EventFilter {
  final EventType? type;
  final EventCategory? category;
  final String? source;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;

  const EventFilter({
    this.type,
    this.category,
    this.source,
    this.startDate,
    this.endDate,
    this.searchQuery,
  });

  bool matches(EventModel event) {
    if (type != null && event.type != type) {
      return false;
    }
    if (category != null && event.category != category) {
      return false;
    }
    if (source != null &&
        event.source?.toLowerCase() != source?.toLowerCase()) {
      return false;
    }
    if (startDate != null && event.timestamp.isBefore(startDate!)) {
      return false;
    }
    if (endDate != null && event.timestamp.isAfter(endDate!)) {
      return false;
    }
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      return event.message.toLowerCase().contains(query) ||
          event.details.toLowerCase().contains(query);
    }
    return true;
  }

  EventFilter copyWith({
    EventType? type,
    EventCategory? category,
    String? source,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) {
    return EventFilter(
      type: type ?? this.type,
      category: category ?? this.category,
      source: source ?? this.source,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get isEmpty =>
      type == null &&
      category == null &&
      source == null &&
      startDate == null &&
      endDate == null &&
      (searchQuery == null || searchQuery!.isEmpty);
}

/// Helper function to create common system events
class EventFactory {
  /// Create a power outage event
  static EventModel powerOutage(
      {String? source, Map<String, dynamic>? metadata}) {
    return EventModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: EventType.danger,
      category: EventCategory.power,
      message: 'Grid Power Outage',
      details: 'WAPDA power is unavailable. Switching to solar/battery backup.',
      timestamp: DateTime.now(),
      source: source ?? 'AUTO',
      metadata: metadata,
    );
  }

  /// Create a power restored event
  static EventModel powerRestored(
      {String? source, Map<String, dynamic>? metadata}) {
    return EventModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: EventType.success,
      category: EventCategory.power,
      message: 'Grid Power Restored',
      details: 'WAPDA power is now available. System back to normal operation.',
      timestamp: DateTime.now(),
      source: source ?? 'AUTO',
      metadata: metadata,
    );
  }

  /// Create a solar active event
  static EventModel solarActive(
      {String? source, Map<String, dynamic>? metadata}) {
    return EventModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: EventType.success,
      category: EventCategory.power,
      message: 'Solar Power Active',
      details: 'Bright sunlight detected. Running on solar power.',
      timestamp: DateTime.now(),
      source: source ?? 'AUTO',
      metadata: metadata,
    );
  }

  /// Create a relay state change event
  static EventModel relayStateChange({
    required String relayName,
    required bool state,
    String? source,
    Map<String, dynamic>? metadata,
  }) {
    return EventModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: state ? EventType.info : EventType.warning,
      category: EventCategory.relay,
      message: '$relayName Relay Turned ${state ? "ON" : "OFF"}',
      details: 'Relay state changed by ${source ?? "system"}',
      timestamp: DateTime.now(),
      source: source,
      metadata: metadata,
    );
  }

  /// Create a mode change event
  static EventModel modeChange({
    required String oldMode,
    required String newMode,
    String? source,
    Map<String, dynamic>? metadata,
  }) {
    return EventModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: EventType.info,
      category: EventCategory.mode,
      message: 'System Mode Changed',
      details: 'Changed from $oldMode to $newMode mode',
      timestamp: DateTime.now(),
      source: source ?? 'USER',
      metadata: metadata,
    );
  }

  /// Create a command event
  static EventModel commandExecuted({
    required String command,
    required String value,
    String? source,
    Map<String, dynamic>? metadata,
  }) {
    return EventModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: EventType.info,
      category: EventCategory.command,
      message: 'Command Executed',
      details: '$command = $value',
      timestamp: DateTime.now(),
      source: source ?? 'USER',
      metadata: metadata,
    );
  }

  /// Create a connection event
  static EventModel connectionEvent({
    required bool connected,
    required String device,
    String? source,
    Map<String, dynamic>? metadata,
  }) {
    return EventModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: connected ? EventType.success : EventType.danger,
      category: EventCategory.connection,
      message: connected ? '$device Connected' : '$device Disconnected',
      details: connected
          ? 'Successfully connected to $device'
          : 'Lost connection to $device',
      timestamp: DateTime.now(),
      source: source ?? 'SYSTEM',
      metadata: metadata,
    );
  }
}

/// Helper function to parse event type from string
EventType _parseEventType(String? typeStr) {
  if (typeStr == null) return EventType.info;

  switch (typeStr.toLowerCase()) {
    case 'success':
      return EventType.success;
    case 'warning':
      return EventType.warning;
    case 'danger':
    case 'error':
      return EventType.danger;
    case 'info':
    default:
      return EventType.info;
  }
}

/// Helper function to parse event category from string
EventCategory _parseEventCategory(String? categoryStr) {
  if (categoryStr == null) return EventCategory.system;

  switch (categoryStr.toLowerCase()) {
    case 'power':
      return EventCategory.power;
    case 'relay':
      return EventCategory.relay;
    case 'mode':
      return EventCategory.mode;
    case 'command':
      return EventCategory.command;
    case 'sensor':
      return EventCategory.sensor;
    case 'connection':
      return EventCategory.connection;
    case 'alert':
      return EventCategory.alert;
    case 'system':
    default:
      return EventCategory.system;
  }
}

/// Helper function to parse timestamp from server response
DateTime _parseTimestamp(dynamic timestamp, dynamic dateStr, dynamic timeStr) {
  // If timestamp is already a DateTime
  if (timestamp is DateTime) {
    return timestamp;
  }

  // If timestamp is a number (milliseconds)
  if (timestamp is num) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
  }

  // If timestamp is a string
  if (timestamp is String) {
    try {
      return DateTime.parse(timestamp);
    } catch (e) {
      // Fallback to parsing date and time strings
    }
  }

  // Try to parse from date and time strings
  if (dateStr != null && timeStr != null) {
    try {
      final dateParts = dateStr.toString().split('/');
      final timeParts = timeStr.toString().split(':');

      if (dateParts.length >= 3 && timeParts.length >= 2) {
        final month = int.parse(dateParts[0]);
        final day = int.parse(dateParts[1]);
        final year = int.parse(dateParts[2]);
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;

        return DateTime(year, month, day, hour, minute, second);
      }
    } catch (e) {
      // Fallback to current time
    }
  }

  return DateTime.now();
}

/// Format date as MM/DD/YYYY
String _formatDate(DateTime date) {
  return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
}

/// Format time as HH:MM:SS AM/PM
String _formatTime(DateTime time) {
  final hour12 = time.hour % 12;
  final hour = hour12 == 0 ? 12 : hour12;
  final minute = time.minute.toString().padLeft(2, '0');
  final second = time.second.toString().padLeft(2, '0');
  final ampm = time.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute:$second $ampm';
}

/// Format date and time together
String _formatDateTime(DateTime datetime) {
  return '${_formatDate(datetime)} ${_formatTime(datetime)}';
}
