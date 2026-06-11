import 'package:intl/intl.dart';

/// Utility class for formatting values throughout the app
class Formatters {
  /// Format voltage value
  static String formatVoltage(double voltage) {
    return '${voltage.toStringAsFixed(1)} V';
  }

  /// Format current value
  static String formatCurrent(double current) {
    return '${current.toStringAsFixed(2)} A';
  }

  /// Format power value
  static String formatPower(double power) {
    if (power >= 1000) {
      return '${(power / 1000).toStringAsFixed(2)} kW';
    }
    return '${power.toStringAsFixed(1)} W';
  }

  /// Format energy value in kWh
  static String formatEnergy(double energyWh) {
    final kWh = energyWh / 1000;
    return '${kWh.toStringAsFixed(2)} kWh';
  }

  /// Format cost in PKR
  static String formatCost(double cost) {
    return '₨${cost.toStringAsFixed(2)}';
  }

  /// Format hours
  static String formatHours(double hours) {
    if (hours < 1) {
      return '${(hours * 60).toStringAsFixed(0)} min';
    }
    return '${hours.toStringAsFixed(1)} hrs';
  }

  /// Format LDR value
  static String formatLdr(int ldrValue) {
    if (ldrValue > 1800) return 'Bright';
    if (ldrValue > 1200) return 'Moderate';
    return 'Dark';
  }

  /// Format percentage
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  /// Format date
  static String formatDate(DateTime date) {
    return DateFormat('MM/dd/yyyy').format(date);
  }

  /// Format time
  static String formatTime(DateTime time) {
    return DateFormat('h:mm:ss a').format(time);
  }

  /// Format date and time
  static String formatDateTime(DateTime datetime) {
    return DateFormat('MM/dd/yyyy h:mm a').format(datetime);
  }

  /// Format relative time (e.g., "5 min ago")
  static String formatRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(time);
  }

  /// Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  /// Format CO2 savings
  static String formatCO2(double kg) {
    return '${kg.toStringAsFixed(1)} kg CO₂';
  }
}
