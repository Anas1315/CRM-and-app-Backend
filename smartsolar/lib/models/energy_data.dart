class EnergyData {
  final double voltage;
  final double current;
  final double power;
  final int ldrValue;
  final bool wapdaAvailable;
  final bool isSunny;
  final bool isDayTime;
  final bool wapdaRelayState;
  final bool heavyLoadState;
  final bool wapdaAutoMode;
  final bool heavyLoadAutoMode;
  final int currentHour;
  final DateTime lastUpdate;
  final bool esp32Online;

  EnergyData({
    required this.voltage,
    required this.current,
    required this.power,
    required this.ldrValue,
    required this.wapdaAvailable,
    required this.isSunny,
    required this.isDayTime,
    required this.wapdaRelayState,
    required this.heavyLoadState,
    required this.wapdaAutoMode,
    required this.heavyLoadAutoMode,
    required this.currentHour,
    required this.lastUpdate,
    required this.esp32Online,
  });

  factory EnergyData.fromJson(Map<String, dynamic> json) {
    return EnergyData(
      voltage: _toDouble(json['voltage']),
      current: _toDouble(json['current']),
      power: _toDouble(json['power']),
      ldrValue: _toInt(json['ldrValue']),
      wapdaAvailable: _toBool(json['wapdaAvailable']),
      isSunny: _toBool(json['isSunny']),
      isDayTime: _toBool(json['isDayTime'], fallback: true),
      wapdaRelayState: _toBool(json['wapdaRelayState']),
      heavyLoadState: _toBool(json['heavyLoadState']),
      wapdaAutoMode: _toBool(json['wapdaAutoMode'], fallback: true),
      heavyLoadAutoMode: _toBool(json['heavyLoadAutoMode'], fallback: true),
      currentHour: _toInt(json['currentHour'], fallback: 12),
      lastUpdate: _toDateTime(json['lastUpdate']),
      esp32Online: _toBool(json['esp32Online']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voltage': voltage,
      'current': current,
      'power': power,
      'ldrValue': ldrValue,
      'wapdaAvailable': wapdaAvailable,
      'isSunny': isSunny,
      'isDayTime': isDayTime,
      'wapdaRelayState': wapdaRelayState,
      'heavyLoadState': heavyLoadState,
      'wapdaAutoMode': wapdaAutoMode,
      'heavyLoadAutoMode': heavyLoadAutoMode,
      'currentHour': currentHour,
      'lastUpdate': lastUpdate.millisecondsSinceEpoch,
      'esp32Online': esp32Online,
    };
  }

  EnergyData copyWith({
    double? voltage,
    double? current,
    double? power,
    int? ldrValue,
    bool? wapdaAvailable,
    bool? isSunny,
    bool? isDayTime,
    bool? wapdaRelayState,
    bool? heavyLoadState,
    bool? wapdaAutoMode,
    bool? heavyLoadAutoMode,
    int? currentHour,
    DateTime? lastUpdate,
    bool? esp32Online,
  }) {
    return EnergyData(
      voltage: voltage ?? this.voltage,
      current: current ?? this.current,
      power: power ?? this.power,
      ldrValue: ldrValue ?? this.ldrValue,
      wapdaAvailable: wapdaAvailable ?? this.wapdaAvailable,
      isSunny: isSunny ?? this.isSunny,
      isDayTime: isDayTime ?? this.isDayTime,
      wapdaRelayState: wapdaRelayState ?? this.wapdaRelayState,
      heavyLoadState: heavyLoadState ?? this.heavyLoadState,
      wapdaAutoMode: wapdaAutoMode ?? this.wapdaAutoMode,
      heavyLoadAutoMode: heavyLoadAutoMode ?? this.heavyLoadAutoMode,
      currentHour: currentHour ?? this.currentHour,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      esp32Online: esp32Online ?? this.esp32Online,
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _toBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
    return true;
  }
  if (normalized == 'false' || normalized == '0' || normalized == 'no') {
    return false;
  }
  return fallback;
}

DateTime _toDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is String) {
    final numeric = int.tryParse(value);
    if (numeric != null) {
      return DateTime.fromMillisecondsSinceEpoch(numeric);
    }
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  return DateTime.now();
}

class HourlyData {
  final int hour;
  final double voltage;
  final double current;
  final double power;
  final int ldrValue;

  HourlyData({
    required this.hour,
    required this.voltage,
    required this.current,
    required this.power,
    required this.ldrValue,
  });

  factory HourlyData.fromJson(Map<String, dynamic> json) {
    return HourlyData(
      hour: _toInt(json['hour']),
      voltage: _toDouble(json['voltage']),
      current: _toDouble(json['current']),
      power: _toDouble(json['power']),
      ldrValue: _toInt(json['ldrValue']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'voltage': voltage,
      'current': current,
      'power': power,
      'ldrValue': ldrValue,
    };
  }
}
