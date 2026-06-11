import 'package:equatable/equatable.dart';

/// Daily statistics model for tracking energy usage, savings, and costs
class DailyStats extends Equatable {
  final String date;
  final double wapdaUsageHours;
  final double loadOnHours;
  final double solarSavingHours;
  final int totalSwitches;
  final double peakPower;
  final double avgVoltage;
  final double energyGenerated; // in Wh
  final double energyConsumed; // in Wh
  final String unitsConsumed; // in kWh
  final String unitsSaved; // in kWh
  final String costUsed; // in PKR
  final String costSaved; // in PKR
  final DateTime? lastWapdaOnTime;
  final DateTime? lastWapdaOffTime;
  final DateTime? lastLoadOnTime;
  final DateTime? lastLoadOffTime;

  const DailyStats({
    required this.date,
    required this.wapdaUsageHours,
    required this.loadOnHours,
    required this.solarSavingHours,
    required this.totalSwitches,
    required this.peakPower,
    required this.avgVoltage,
    required this.energyGenerated,
    required this.energyConsumed,
    required this.unitsConsumed,
    required this.unitsSaved,
    required this.costUsed,
    required this.costSaved,
    this.lastWapdaOnTime,
    this.lastWapdaOffTime,
    this.lastLoadOnTime,
    this.lastLoadOffTime,
  });

  /// Factory constructor for creating a DailyStats from JSON
  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      date: json['date'] ?? _getCurrentDate(),
      wapdaUsageHours: _parseDouble(json['wapdaUsageHours']),
      loadOnHours: _parseDouble(json['loadOnHours']),
      solarSavingHours: _parseDouble(json['solarSavingHours']),
      totalSwitches: json['totalSwitches'] ?? 0,
      peakPower: _parseDouble(json['peakPower']),
      avgVoltage: _parseDouble(json['avgVoltage'], defaultValue: 220.0),
      energyGenerated: _parseDouble(json['energyGenerated']),
      energyConsumed: _parseDouble(json['energyConsumed']),
      unitsConsumed: json['unitsConsumed']?.toString() ?? '0',
      unitsSaved: json['unitsSaved']?.toString() ?? '0',
      costUsed: json['costUsed']?.toString() ?? '0',
      costSaved: json['costSaved']?.toString() ?? '0',
      lastWapdaOnTime: _parseDateTime(json['lastWapdaOnTime']),
      lastWapdaOffTime: _parseDateTime(json['lastWapdaOffTime']),
      lastLoadOnTime: _parseDateTime(json['lastLoadOnTime']),
      lastLoadOffTime: _parseDateTime(json['lastLoadOffTime']),
    );
  }

  /// Convert DailyStats to JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'wapdaUsageHours': wapdaUsageHours,
      'loadOnHours': loadOnHours,
      'solarSavingHours': solarSavingHours,
      'totalSwitches': totalSwitches,
      'peakPower': peakPower,
      'avgVoltage': avgVoltage,
      'energyGenerated': energyGenerated,
      'energyConsumed': energyConsumed,
      'unitsConsumed': unitsConsumed,
      'unitsSaved': unitsSaved,
      'costUsed': costUsed,
      'costSaved': costSaved,
      'lastWapdaOnTime': lastWapdaOnTime?.toIso8601String(),
      'lastWapdaOffTime': lastWapdaOffTime?.toIso8601String(),
      'lastLoadOnTime': lastLoadOnTime?.toIso8601String(),
      'lastLoadOffTime': lastLoadOffTime?.toIso8601String(),
    };
  }

  /// Create an empty/initial daily stats
  factory DailyStats.empty() {
    return DailyStats(
      date: _getCurrentDate(),
      wapdaUsageHours: 0,
      loadOnHours: 0,
      solarSavingHours: 0,
      totalSwitches: 0,
      peakPower: 0,
      avgVoltage: 220,
      energyGenerated: 0,
      energyConsumed: 0,
      unitsConsumed: '0',
      unitsSaved: '0',
      costUsed: '0',
      costSaved: '0',
    );
  }

  /// Create a copy with updated fields
  DailyStats copyWith({
    String? date,
    double? wapdaUsageHours,
    double? loadOnHours,
    double? solarSavingHours,
    int? totalSwitches,
    double? peakPower,
    double? avgVoltage,
    double? energyGenerated,
    double? energyConsumed,
    String? unitsConsumed,
    String? unitsSaved,
    String? costUsed,
    String? costSaved,
    DateTime? lastWapdaOnTime,
    DateTime? lastWapdaOffTime,
    DateTime? lastLoadOnTime,
    DateTime? lastLoadOffTime,
  }) {
    return DailyStats(
      date: date ?? this.date,
      wapdaUsageHours: wapdaUsageHours ?? this.wapdaUsageHours,
      loadOnHours: loadOnHours ?? this.loadOnHours,
      solarSavingHours: solarSavingHours ?? this.solarSavingHours,
      totalSwitches: totalSwitches ?? this.totalSwitches,
      peakPower: peakPower ?? this.peakPower,
      avgVoltage: avgVoltage ?? this.avgVoltage,
      energyGenerated: energyGenerated ?? this.energyGenerated,
      energyConsumed: energyConsumed ?? this.energyConsumed,
      unitsConsumed: unitsConsumed ?? this.unitsConsumed,
      unitsSaved: unitsSaved ?? this.unitsSaved,
      costUsed: costUsed ?? this.costUsed,
      costSaved: costSaved ?? this.costSaved,
      lastWapdaOnTime: lastWapdaOnTime ?? this.lastWapdaOnTime,
      lastWapdaOffTime: lastWapdaOffTime ?? this.lastWapdaOffTime,
      lastLoadOnTime: lastLoadOnTime ?? this.lastLoadOnTime,
      lastLoadOffTime: lastLoadOffTime ?? this.lastLoadOffTime,
    );
  }

  /// Get total hours tracked
  double get totalHours => wapdaUsageHours + solarSavingHours;

  /// Get solar percentage of total usage
  double get solarPercentage {
    if (totalHours == 0) return 0;
    return (solarSavingHours / totalHours) * 100;
  }

  /// Get grid percentage of total usage
  double get gridPercentage {
    if (totalHours == 0) return 0;
    return (wapdaUsageHours / totalHours) * 100;
  }

  /// Get energy generated in kWh (from Wh)
  double get energyGeneratedKWh => energyGenerated / 1000;

  /// Get energy consumed in kWh (from Wh)
  double get energyConsumedKWh => energyConsumed / 1000;

  /// Get units consumed as double
  double get unitsConsumedDouble => double.tryParse(unitsConsumed) ?? 0;

  /// Get units saved as double
  double get unitsSavedDouble => double.tryParse(unitsSaved) ?? 0;

  /// Get cost used as double
  double get costUsedDouble => double.tryParse(costUsed) ?? 0;

  /// Get cost saved as double
  double get costSavedDouble => double.tryParse(costSaved) ?? 0;

  /// Get total cost (used + saved)
  double get totalCost => costUsedDouble + costSavedDouble;

  /// Get total units (consumed + saved)
  double get totalUnits => unitsConsumedDouble + unitsSavedDouble;

  /// Check if stats are from today
  bool get isToday {
    final today = _getCurrentDate();
    return date == today;
  }

  /// Get formatted date for display
  String get formattedDate {
    try {
      final parts = date.split('/');
      if (parts.length == 3) {
        final month = parts[0];
        final day = parts[1];
        final year = parts[2];
        return '$month/$day/$year';
      }
    } catch (e) {
      return date;
    }
    return date;
  }

  /// Get readable date (e.g., "Monday, January 1, 2024")
  String get readableDate {
    try {
      final parts = date.split('/');
      if (parts.length == 3) {
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final datetime = DateTime(year, month, day);

        final weekdays = [
          'Sunday',
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday'
        ];
        final months = [
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

        return '${weekdays[datetime.weekday % 7]}, ${months[month - 1]} $day, $year';
      }
    } catch (e) {
      return date;
    }
    return date;
  }

  /// Get efficiency score (0-100) based on solar usage
  int get efficiencyScore {
    if (totalHours == 0) return 50;
    return (solarPercentage * 0.8).round().clamp(0, 100);
  }

  /// Get savings compared to using grid only
  double get savingsComparedToGrid {
    final totalUnitsIfNoSolar = (energyConsumedKWh + energyGeneratedKWh);
    final costIfNoSolar = totalUnitsIfNoSolar * 30; // 30 PKR per unit
    return costIfNoSolar - costUsedDouble;
  }

  /// Get CO2 saved in kg (approx 0.4 kg CO2 per kWh saved)
  double get co2SavedKg => unitsSavedDouble * 0.4;

  /// Get equivalent trees planted (approx 0.03 trees per 100 kWh)
  double get equivalentTrees => unitsSavedDouble * 0.0003;

  /// Get summary text for sharing
  String get shareSummary {
    return '''
📊 Energy Summary - $readableDate

⚡ Grid Usage: ${wapdaUsageHours.toStringAsFixed(1)} hours
☀️ Solar Savings: ${solarSavingHours.toStringAsFixed(1)} hours
🔌 Total Units Consumed: $unitsConsumed kWh
💚 Units Saved: $unitsSaved kWh
💰 Cost Used: ₨$costUsed
💸 Cost Saved: ₨$costSaved
🌱 CO2 Saved: ${co2SavedKg.toStringAsFixed(1)} kg

Smart Energy Controller
''';
  }

  @override
  List<Object?> get props => [
        date,
        wapdaUsageHours,
        loadOnHours,
        solarSavingHours,
        totalSwitches,
        peakPower,
        avgVoltage,
        energyGenerated,
        energyConsumed,
        unitsConsumed,
        unitsSaved,
        costUsed,
        costSaved,
        lastWapdaOnTime,
        lastWapdaOffTime,
        lastLoadOnTime,
        lastLoadOffTime,
      ];

  @override
  String toString() {
    return 'DailyStats(date: $date, wapdaUsageHours: $wapdaUsageHours, '
        'loadOnHours: $loadOnHours, solarSavingHours: $solarSavingHours, '
        'unitsConsumed: $unitsConsumed, unitsSaved: $unitsSaved, '
        'costUsed: $costUsed, costSaved: $costSaved)';
  }
}

/// Helper class for weekly statistics aggregation
class WeeklyStats {
  final DateTime startDate;
  final DateTime endDate;
  final List<DailyStats> dailyStats;

  WeeklyStats({
    required this.startDate,
    required this.endDate,
    required this.dailyStats,
  });

  double get totalWapdaUsageHours =>
      dailyStats.fold(0.0, (sum, day) => sum + day.wapdaUsageHours);

  double get totalSolarSavingHours =>
      dailyStats.fold(0.0, (sum, day) => sum + day.solarSavingHours);

  double get totalLoadOnHours =>
      dailyStats.fold(0.0, (sum, day) => sum + day.loadOnHours);

  double get totalUnitsConsumed =>
      dailyStats.fold(0.0, (sum, day) => sum + day.unitsConsumedDouble);

  double get totalUnitsSaved =>
      dailyStats.fold(0.0, (sum, day) => sum + day.unitsSavedDouble);

  double get totalCostUsed =>
      dailyStats.fold(0.0, (sum, day) => sum + day.costUsedDouble);

  double get totalCostSaved =>
      dailyStats.fold(0.0, (sum, day) => sum + day.costSavedDouble);

  double get averageDailyPower =>
      dailyStats.fold(0.0, (sum, day) => sum + day.peakPower) /
      dailyStats.length;

  double get solarPercentage =>
      totalWapdaUsageHours + totalSolarSavingHours == 0
          ? 0
          : (totalSolarSavingHours /
                  (totalWapdaUsageHours + totalSolarSavingHours)) *
              100;

  String get formattedDateRange {
    return '${_formatShortDate(startDate)} - ${_formatShortDate(endDate)}';
  }
}

/// Helper class for monthly statistics aggregation
class MonthlyStats {
  final int year;
  final int month;
  final List<DailyStats> dailyStats;

  MonthlyStats({
    required this.year,
    required this.month,
    required this.dailyStats,
  });

  String get monthName {
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
    return months[month - 1];
  }

  double get totalWapdaUsageHours =>
      dailyStats.fold(0.0, (sum, day) => sum + day.wapdaUsageHours);

  double get totalSolarSavingHours =>
      dailyStats.fold(0.0, (sum, day) => sum + day.solarSavingHours);

  double get totalUnitsConsumed =>
      dailyStats.fold(0.0, (sum, day) => sum + day.unitsConsumedDouble);

  double get totalUnitsSaved =>
      dailyStats.fold(0.0, (sum, day) => sum + day.unitsSavedDouble);

  double get totalCostUsed =>
      dailyStats.fold(0.0, (sum, day) => sum + day.costUsedDouble);

  double get totalCostSaved =>
      dailyStats.fold(0.0, (sum, day) => sum + day.costSavedDouble);

  double get averageDailyPower {
    if (dailyStats.isEmpty) return 0;
    return dailyStats.fold(0.0, (sum, day) => sum + day.peakPower) /
        dailyStats.length;
  }

  double get solarPercentage =>
      totalWapdaUsageHours + totalSolarSavingHours == 0
          ? 0
          : (totalSolarSavingHours /
                  (totalWapdaUsageHours + totalSolarSavingHours)) *
              100;
}

/// Helper function to parse double from dynamic value
double _parseDouble(dynamic value, {double defaultValue = 0.0}) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Helper function to parse DateTime from dynamic value
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (e) {
      return null;
    }
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  return null;
}

/// Helper function to get current date in MM/DD/YYYY format
String _getCurrentDate() {
  final now = DateTime.now();
  return '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}';
}

/// Helper function to format short date
String _formatShortDate(DateTime date) {
  return '${date.month}/${date.day}';
}
