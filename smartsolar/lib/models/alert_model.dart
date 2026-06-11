import 'package:equatable/equatable.dart';

/// Alert priority levels
enum AlertPriority {
  low, // Informational alerts
  medium, // Warning alerts
  high, // Critical alerts that need immediate attention
}

/// Alert type categories
enum AlertType {
  info, // General information
  success, // Positive events (power restored, solar active)
  warning, // Caution events (low solar, high usage)
  danger, // Critical events (power outage, system offline)
}

/// Alert model representing system notifications and warnings
class AlertModel extends Equatable {
  final String id;
  final AlertType type;
  final AlertPriority priority;
  final String message;
  final String? details;
  final DateTime timestamp;
  final bool isRead;

  const AlertModel({
    required this.id,
    required this.type,
    required this.priority,
    required this.message,
    this.details,
    required this.timestamp,
    this.isRead = false,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    final alertId = json['id'];
    DateTime parsedTime = DateTime.now();

    if (alertId is num && alertId > 1000000000000) {
      parsedTime = DateTime.fromMillisecondsSinceEpoch(alertId.toInt());
    } else if (alertId is String) {
      final numericId = int.tryParse(alertId);
      if (numericId != null && numericId > 1000000000000) {
        parsedTime = DateTime.fromMillisecondsSinceEpoch(numericId);
      } else {
        parsedTime = json['timestamp'] != null
            ? _parseTimestamp(json['timestamp'], json['date'])
            : DateTime.now();
      }
    } else {
      parsedTime = json['timestamp'] != null
          ? _parseTimestamp(json['timestamp'], json['date'])
          : DateTime.now();
    }

    return AlertModel(
      id: alertId?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      type: _parseAlertType(json['type']),
      priority: _parseAlertPriority(json['priority']),
      message: json['message']?.toString() ?? 'Unknown alert',
      details: json['details']?.toString(),
      timestamp: parsedTime,
      isRead: _parseBool(json['isRead'] ?? json['read']),
    );
  }

  /// Convert AlertModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'priority': priority.name,
      'message': message,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
      'date': _formatDate(timestamp),
      'time': _formatTime(timestamp),
      'read': isRead,
    };
  }

  /// Create a copy with updated fields
  AlertModel copyWith({
    String? id,
    AlertType? type,
    AlertPriority? priority,
    String? message,
    String? details,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return AlertModel(
      id: id ?? this.id,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      message: message ?? this.message,
      details: details ?? this.details,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  /// Mark alert as read
  AlertModel markAsRead() {
    return copyWith(isRead: true);
  }

  /// Get icon based on alert type
  String get icon {
    switch (type) {
      case AlertType.info:
        return 'ℹ️';
      case AlertType.success:
        return '✅';
      case AlertType.warning:
        return '⚠️';
      case AlertType.danger:
        return '🔴';
    }
  }

  /// Get color code based on priority
  String get colorHex {
    switch (priority) {
      case AlertPriority.low:
        return '#3498DB'; // Blue
      case AlertPriority.medium:
        return '#F39C12'; // Orange
      case AlertPriority.high:
        return '#E74C3C'; // Red
    }
  }

  /// Get background color with opacity
  String get backgroundColorHex {
    switch (priority) {
      case AlertPriority.low:
        return '#3498DB20';
      case AlertPriority.medium:
        return '#F39C1220';
      case AlertPriority.high:
        return '#E74C3C20';
    }
  }

  /// Get formatted time string
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

  /// Get formatted date and time
  String get formattedDateTime => _formatDateTime(timestamp);

  /// Get priority display text
  String get priorityText {
    switch (priority) {
      case AlertPriority.low:
        return 'INFO';
      case AlertPriority.medium:
        return 'WARNING';
      case AlertPriority.high:
        return 'CRITICAL';
    }
  }

  @override
  List<Object?> get props =>
      [id, type, priority, message, details, timestamp, isRead];

  @override
  String toString() {
    return 'AlertModel(id: $id, type: $type, priority: $priority, message: $message, timestamp: $timestamp, isRead: $isRead)';
  }
}

/// Alert group for organizing alerts by date
class AlertGroup {
  final DateTime date;
  final List<AlertModel> alerts;

  AlertGroup({
    required this.date,
    required this.alerts,
  });

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final alertDate = DateTime(date.year, date.month, date.day);

    if (alertDate == today) {
      return 'Today';
    } else if (alertDate == yesterday) {
      return 'Yesterday';
    } else {
      return _formatDate(date);
    }
  }
}

/// Helper function to parse alert type from string
AlertType _parseAlertType(String? typeStr) {
  if (typeStr == null) return AlertType.info;

  switch (typeStr.toLowerCase()) {
    case 'success':
      return AlertType.success;
    case 'warning':
      return AlertType.warning;
    case 'danger':
    case 'error':
      return AlertType.danger;
    case 'info':
    default:
      return AlertType.info;
  }
}

/// Helper function to parse alert priority from string
AlertPriority _parseAlertPriority(String? priorityStr) {
  if (priorityStr == null) return AlertPriority.low;

  switch (priorityStr.toLowerCase()) {
    case 'high':
    case 'critical':
      return AlertPriority.high;
    case 'medium':
      return AlertPriority.medium;
    case 'low':
    default:
      return AlertPriority.low;
  }
}

bool _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
    return true;
  }
  if (normalized == 'false' || normalized == '0' || normalized == 'no') {
    return false;
  }
  return false;
}

/// Helper function to parse timestamp from server response
DateTime _parseTimestamp(dynamic timestamp, dynamic dateStr) {
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
    final numeric = int.tryParse(timestamp);
    if (numeric != null) {
      return DateTime.fromMillisecondsSinceEpoch(numeric);
    }
    try {
      return DateTime.parse(timestamp);
    } catch (e) {
      // Fallback to parsing date and time strings
    }
  }

  // Try to parse from date and time strings
  if (dateStr != null) {
    try {
      final timeStr = timestamp as String?;
      if (timeStr != null) {
        final dateParts = dateStr.toString().split('/');
        final timeParts = timeStr.split(':');

        if (dateParts.length >= 3 && timeParts.length >= 2) {
          final month = int.parse(dateParts[0]);
          final day = int.parse(dateParts[1]);
          final year = int.parse(dateParts[2]);
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;

          return DateTime(year, month, day, hour, minute, second);
        }
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
