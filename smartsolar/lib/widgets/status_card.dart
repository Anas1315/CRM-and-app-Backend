import 'package:flutter/material.dart';
import 'package:smartsolar/utils/theme.dart';

class StatusCard extends StatelessWidget {
  final String systemStatus;
  final bool isOnline;
  final bool isDayTime;
  final bool isSunny;
  final int ldrValue;

  const StatusCard({
    super.key,
    required this.systemStatus,
    required this.isOnline,
    required this.isDayTime,
    required this.isSunny,
    required this.ldrValue,
  });

  @override
  Widget build(BuildContext context) {
    String statusMessage = systemStatus;
    Color statusColor = AppTheme.success;
    IconData statusIcon = Icons.check_circle;

    if (!isOnline) {
      statusMessage = 'System Offline';
      statusColor = AppTheme.error;
      statusIcon = Icons.wifi_off;
    } else if (systemStatus.contains('OFFLINE')) {
      statusColor = AppTheme.error;
      statusIcon = Icons.signal_wifi_off;
    } else if (systemStatus.contains('SOLAR')) {
      statusColor = AppTheme.warning;
      statusIcon = Icons.sunny;
    } else if (systemStatus.contains('BACKUP')) {
      statusColor = AppTheme.warning;
      statusIcon = Icons.battery_alert;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.2),
            statusColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SYSTEM STATUS',
                      style: TextStyle(fontSize: 11, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusMessage,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOnline ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (isOnline && isDayTime) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildWeatherInfo(
                    'Solar Intensity',
                    ldrValue,
                    isSunny ? 'Sunny' : 'Cloudy',
                    isSunny ? Icons.sunny : Icons.cloud,
                  ),
                ),
                Expanded(
                  child: _buildWeatherInfo(
                    'Time Period',
                    isDayTime ? 1 : 0,
                    isDayTime ? 'Day Time' : 'Night Time',
                    Icons.access_time,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeatherInfo(
    String label,
    int value,
    String status,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                status,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
