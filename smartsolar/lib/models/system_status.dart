import 'package:equatable/equatable.dart';

/// System operational modes
enum SystemMode {
  normal, // Normal operation
  solar, // Solar power active
  backup, // Running on grid backup
  warning, // System warning
  noPower, // No power available
  offline, // System offline
  maintenance, // Maintenance mode
}

/// System health status
enum SystemHealth {
  excellent, // 90-100% - Perfect operation
  good, // 70-89% - Good operation
  fair, // 50-69% - Some issues
  poor, // 30-49% - Multiple issues
  critical, // 0-29% - Critical issues
}

/// Component status
enum ComponentStatus {
  online, // Component is working
  offline, // Component is down
  warning, // Component has issues
  unknown, // Status unknown
}

/// System status model representing overall system state
class SystemStatus extends Equatable {
  final SystemMode mode;
  final String message;
  final String color;
  final String icon;
  final DateTime timestamp;
  final double healthScore; // 0-100
  final SystemHealth health;
  final String? details;
  final Map<String, ComponentStatus>? components;

  const SystemStatus({
    required this.mode,
    required this.message,
    required this.color,
    required this.icon,
    required this.timestamp,
    required this.healthScore,
    required this.health,
    this.details,
    this.components,
  });

  /// Factory constructor for creating a SystemStatus from JSON
  factory SystemStatus.fromJson(Map<String, dynamic> json) {
    final mode = _parseSystemMode(json['status'] ?? json['mode']);
    final healthScore = _parseHealthScore(json);

    return SystemStatus(
      mode: mode,
      message: json['message'] ?? _getDefaultMessage(mode),
      color: json['color'] ?? _getDefaultColor(mode),
      icon: json['icon'] ?? _getDefaultIcon(mode),
      timestamp: _parseTimestamp(json['timestamp']),
      healthScore: healthScore,
      health: _getHealthFromScore(healthScore),
      details: json['details'],
      components: _parseComponents(json['components']),
    );
  }

  /// Convert SystemStatus to JSON
  Map<String, dynamic> toJson() {
    return {
      'status': mode.name,
      'mode': mode.name,
      'message': message,
      'color': color,
      'icon': icon,
      'timestamp': timestamp.toIso8601String(),
      'healthScore': healthScore,
      'health': health.name,
      'details': details,
      'components': _componentsToJson(components),
    };
  }

  /// Create a normal system status
  factory SystemStatus.normal() {
    return SystemStatus(
      mode: SystemMode.normal,
      message: 'System Operating Normally',
      color: '#2ECC71',
      icon: 'check_circle',
      timestamp: DateTime.now(),
      healthScore: 95,
      health: SystemHealth.excellent,
    );
  }

  /// Create a solar active status
  factory SystemStatus.solarActive() {
    return SystemStatus(
      mode: SystemMode.solar,
      message: 'Solar Power Active',
      color: '#F39C12',
      icon: 'sunny',
      timestamp: DateTime.now(),
      healthScore: 98,
      health: SystemHealth.excellent,
    );
  }

  /// Create a backup mode status
  factory SystemStatus.backup() {
    return SystemStatus(
      mode: SystemMode.backup,
      message: 'Running on Grid Backup',
      color: '#F39C12',
      icon: 'electrical_services',
      timestamp: DateTime.now(),
      healthScore: 75,
      health: SystemHealth.good,
    );
  }

  /// Create a warning status
  factory SystemStatus.warning(String message) {
    return SystemStatus(
      mode: SystemMode.warning,
      message: message,
      color: '#F39C12',
      icon: 'warning',
      timestamp: DateTime.now(),
      healthScore: 50,
      health: SystemHealth.fair,
      details: message,
    );
  }

  /// Create a no power status
  factory SystemStatus.noPower() {
    return SystemStatus(
      mode: SystemMode.noPower,
      message: 'No Power Available',
      color: '#E74C3C',
      icon: 'power_off',
      timestamp: DateTime.now(),
      healthScore: 20,
      health: SystemHealth.critical,
    );
  }

  /// Create an offline status
  factory SystemStatus.offline() {
    return SystemStatus(
      mode: SystemMode.offline,
      message: 'System Offline',
      color: '#E74C3C',
      icon: 'wifi_off',
      timestamp: DateTime.now(),
      healthScore: 0,
      health: SystemHealth.critical,
    );
  }

  /// Create a maintenance status
  factory SystemStatus.maintenance() {
    return SystemStatus(
      mode: SystemMode.maintenance,
      message: 'System Under Maintenance',
      color: '#3498DB',
      icon: 'construction',
      timestamp: DateTime.now(),
      healthScore: 100,
      health: SystemHealth.excellent,
    );
  }

  /// Create a copy with updated fields
  SystemStatus copyWith({
    SystemMode? mode,
    String? message,
    String? color,
    String? icon,
    DateTime? timestamp,
    double? healthScore,
    SystemHealth? health,
    String? details,
    Map<String, ComponentStatus>? components,
  }) {
    return SystemStatus(
      mode: mode ?? this.mode,
      message: message ?? this.message,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      timestamp: timestamp ?? this.timestamp,
      healthScore: healthScore ?? this.healthScore,
      health: health ?? this.health,
      details: details ?? this.details,
      components: components ?? this.components,
    );
  }

  /// Check if system is online and operational
  bool get isOnline => mode != SystemMode.offline && mode != SystemMode.noPower;

  /// Check if system is in warning state
  bool get hasWarning =>
      mode == SystemMode.warning || mode == SystemMode.backup;

  /// Check if system has critical issues
  bool get isCritical =>
      mode == SystemMode.noPower || mode == SystemMode.offline;

  /// Check if solar power is active
  bool get isSolarActive => mode == SystemMode.solar;

  /// Get priority level (0-3, 3 being highest)
  int get priority {
    switch (mode) {
      case SystemMode.offline:
      case SystemMode.noPower:
        return 3;
      case SystemMode.warning:
        return 2;
      case SystemMode.backup:
        return 1;
      case SystemMode.normal:
      case SystemMode.solar:
      case SystemMode.maintenance:
        return 0;
    }
  }

  /// Get status badge text
  String get badgeText {
    switch (mode) {
      case SystemMode.normal:
        return 'OPERATIONAL';
      case SystemMode.solar:
        return 'SOLAR MODE';
      case SystemMode.backup:
        return 'BACKUP MODE';
      case SystemMode.warning:
        return 'WARNING';
      case SystemMode.noPower:
        return 'NO POWER';
      case SystemMode.offline:
        return 'OFFLINE';
      case SystemMode.maintenance:
        return 'MAINTENANCE';
    }
  }

  /// Get health percentage as integer
  int get healthPercent => healthScore.round();

  /// Get health description
  String get healthDescription {
    switch (health) {
      case SystemHealth.excellent:
        return 'All systems operating perfectly';
      case SystemHealth.good:
        return 'System operating with minor issues';
      case SystemHealth.fair:
        return 'Some systems need attention';
      case SystemHealth.poor:
        return 'Multiple systems experiencing issues';
      case SystemHealth.critical:
        return 'Critical system failure detected';
    }
  }

  /// Get material icon data for Flutter
  String get materialIcon {
    switch (icon) {
      case 'sunny':
        return 'Icons.sunny';
      case 'check_circle':
        return 'Icons.check_circle';
      case 'warning':
        return 'Icons.warning';
      case 'power_off':
        return 'Icons.power_off';
      case 'wifi_off':
        return 'Icons.wifi_off';
      case 'construction':
        return 'Icons.construction';
      case 'electrical_services':
        return 'Icons.electrical_services';
      default:
        return 'Icons.settings';
    }
  }

  /// Get color as Flutter Color compatible hex
  int get colorValue {
    return int.parse(color.replaceFirst('#', '0xFF'));
  }

  @override
  List<Object?> get props => [
        mode,
        message,
        color,
        icon,
        timestamp,
        healthScore,
        health,
        details,
        components,
      ];

  @override
  String toString() {
    return 'SystemStatus(mode: $mode, message: $message, '
        'healthScore: $healthScore, timestamp: $timestamp)';
  }
}

/// Component status for tracking individual system parts
class SystemComponent {
  final String name;
  final ComponentStatus status;
  final String? message;
  final DateTime lastUpdated;

  const SystemComponent({
    required this.name,
    required this.status,
    this.message,
    required this.lastUpdated,
  });

  factory SystemComponent.fromJson(Map<String, dynamic> json) {
    return SystemComponent(
      name: json['name'] ?? 'Unknown',
      status: _parseComponentStatus(json['status']),
      message: json['message'],
      lastUpdated: _parseTimestamp(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'status': status.name,
      'message': message,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  bool get isOnline => status == ComponentStatus.online;
  bool get hasWarning => status == ComponentStatus.warning;
  String get statusText {
    switch (status) {
      case ComponentStatus.online:
        return 'Online';
      case ComponentStatus.offline:
        return 'Offline';
      case ComponentStatus.warning:
        return 'Warning';
      case ComponentStatus.unknown:
        return 'Unknown';
    }
  }

  String get statusColor {
    switch (status) {
      case ComponentStatus.online:
        return '#2ECC71';
      case ComponentStatus.offline:
        return '#E74C3C';
      case ComponentStatus.warning:
        return '#F39C12';
      case ComponentStatus.unknown:
        return '#95A5A6';
    }
  }

  SystemComponent copyWith({
    String? name,
    ComponentStatus? status,
    String? message,
    DateTime? lastUpdated,
  }) {
    return SystemComponent(
      name: name ?? this.name,
      status: status ?? this.status,
      message: message ?? this.message,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Helper class for system status history
class SystemStatusHistory {
  final List<SystemStatus> history;
  final DateTime startDate;
  final DateTime endDate;

  SystemStatusHistory({
    required this.history,
    required this.startDate,
    required this.endDate,
  });

  double get averageHealth {
    if (history.isEmpty) return 0;
    return history.fold(0.0, (sum, status) => sum + status.healthScore) /
        history.length;
  }

  Map<SystemMode, int> get modeDistribution {
    final distribution = <SystemMode, int>{};
    for (final status in history) {
      distribution[status.mode] = (distribution[status.mode] ?? 0) + 1;
    }
    return distribution;
  }

  Duration get totalUptime {
    Duration uptime = Duration.zero;
    DateTime? lastOnlineStart;

    for (final status in history) {
      if (status.isOnline && lastOnlineStart == null) {
        lastOnlineStart = status.timestamp;
      } else if (!status.isOnline && lastOnlineStart != null) {
        uptime += status.timestamp.difference(lastOnlineStart);
        lastOnlineStart = null;
      }
    }

    if (lastOnlineStart != null) {
      uptime += DateTime.now().difference(lastOnlineStart);
    }

    return uptime;
  }

  double get uptimePercentage {
    final totalDuration = endDate.difference(startDate);
    if (totalDuration.inSeconds == 0) return 100;
    return (totalUptime.inSeconds / totalDuration.inSeconds) * 100;
  }
}

/// Helper function to parse system mode from string
SystemMode _parseSystemMode(String? modeStr) {
  if (modeStr == null) return SystemMode.normal;

  switch (modeStr.toLowerCase()) {
    case 'solar':
    case 'solar active':
    case 'solar_power_active':
      return SystemMode.solar;
    case 'backup':
    case 'grid backup':
      return SystemMode.backup;
    case 'warning':
    case 'system warning':
      return SystemMode.warning;
    case 'no_power':
    case 'no power':
    case 'no_power_available':
      return SystemMode.noPower;
    case 'offline':
    case 'system offline':
      return SystemMode.offline;
    case 'maintenance':
    case 'maintenance mode':
      return SystemMode.maintenance;
    case 'normal':
    default:
      return SystemMode.normal;
  }
}

/// Helper function to parse component status from string
ComponentStatus _parseComponentStatus(String? statusStr) {
  if (statusStr == null) return ComponentStatus.unknown;

  switch (statusStr.toLowerCase()) {
    case 'online':
      return ComponentStatus.online;
    case 'offline':
      return ComponentStatus.offline;
    case 'warning':
      return ComponentStatus.warning;
    default:
      return ComponentStatus.unknown;
  }
}

/// Get default message for system mode
String _getDefaultMessage(SystemMode mode) {
  switch (mode) {
    case SystemMode.normal:
      return 'System Operating Normally';
    case SystemMode.solar:
      return 'Solar Power Active';
    case SystemMode.backup:
      return 'Running on Grid Backup';
    case SystemMode.warning:
      return 'System Warning';
    case SystemMode.noPower:
      return 'No Power Available';
    case SystemMode.offline:
      return 'System Offline';
    case SystemMode.maintenance:
      return 'System Under Maintenance';
  }
}

/// Get default color for system mode
String _getDefaultColor(SystemMode mode) {
  switch (mode) {
    case SystemMode.normal:
    case SystemMode.solar:
      return '#2ECC71';
    case SystemMode.backup:
    case SystemMode.warning:
      return '#F39C12';
    case SystemMode.noPower:
    case SystemMode.offline:
      return '#E74C3C';
    case SystemMode.maintenance:
      return '#3498DB';
  }
}

/// Get default icon for system mode
String _getDefaultIcon(SystemMode mode) {
  switch (mode) {
    case SystemMode.normal:
      return 'check_circle';
    case SystemMode.solar:
      return 'sunny';
    case SystemMode.backup:
      return 'electrical_services';
    case SystemMode.warning:
      return 'warning';
    case SystemMode.noPower:
      return 'power_off';
    case SystemMode.offline:
      return 'wifi_off';
    case SystemMode.maintenance:
      return 'construction';
  }
}

/// Calculate health score from JSON
double _parseHealthScore(Map<String, dynamic> json) {
  if (json['healthScore'] != null) {
    return (json['healthScore'] as num).toDouble();
  }

  // Calculate based on status if no health score provided
  final mode = _parseSystemMode(json['status'] ?? json['mode']);
  switch (mode) {
    case SystemMode.solar:
      return 98;
    case SystemMode.normal:
      return 95;
    case SystemMode.backup:
      return 75;
    case SystemMode.warning:
      return 50;
    case SystemMode.noPower:
      return 20;
    case SystemMode.offline:
      return 0;
    case SystemMode.maintenance:
      return 100;
  }
}

/// Get health from score
SystemHealth _getHealthFromScore(double score) {
  if (score >= 90) return SystemHealth.excellent;
  if (score >= 70) return SystemHealth.good;
  if (score >= 50) return SystemHealth.fair;
  if (score >= 30) return SystemHealth.poor;
  return SystemHealth.critical;
}

/// Parse timestamp from various formats
DateTime _parseTimestamp(dynamic timestamp) {
  if (timestamp == null) return DateTime.now();
  if (timestamp is DateTime) return timestamp;
  if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
  if (timestamp is String) {
    try {
      return DateTime.parse(timestamp);
    } catch (e) {
      return DateTime.now();
    }
  }
  return DateTime.now();
}

/// Parse components from JSON
Map<String, ComponentStatus>? _parseComponents(dynamic components) {
  if (components == null) return null;

  final result = <String, ComponentStatus>{};

  if (components is Map) {
    components.forEach((key, value) {
      if (value is String) {
        result[key.toString()] = _parseComponentStatus(value);
      } else if (value is Map && value['status'] != null) {
        result[key.toString()] = _parseComponentStatus(value['status']);
      }
    });
  }

  return result.isEmpty ? null : result;
}

/// Convert components to JSON
Map<String, String>? _componentsToJson(
    Map<String, ComponentStatus>? components) {
  if (components == null) return null;

  final result = <String, String>{};
  components.forEach((key, value) {
    result[key] = value.name;
  });
  return result;
}
