import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartsolar/models/alert_model.dart';
import 'package:smartsolar/providers/energy_provider.dart';
import 'package:smartsolar/services/notification_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with TickerProviderStateMixin {
  late AnimationController _bellController;

  // Notification Settings
  bool _desktopNotifications = true;
  bool _criticalAlerts = true;
  bool _powerAlerts = true;
  bool _systemAlerts = true;
  bool _dailySummary = true;

  @override
  void initState() {
    super.initState();
    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _loadNotificationSettings();
  }

  @override
  void dispose() {
    _bellController.dispose();
    super.dispose();
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _desktopNotifications = prefs.getBool('desktop_notifications') ?? true;
      _criticalAlerts = prefs.getBool('critical_alerts') ?? true;
      _powerAlerts = prefs.getBool('power_alerts') ?? true;
      _systemAlerts = prefs.getBool('system_alerts') ?? true;
      _dailySummary = prefs.getBool('daily_summary') ?? true;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is int) await prefs.setInt(key, value);
    if (value is double) await prefs.setDouble(key, value);
    if (value is String) await prefs.setString(key, value);
  }

  void _showNotificationSettingsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notification Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('App Notifications'),
                      subtitle: const Text(
                        'Show system notifications on your mobile device',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _desktopNotifications,
                      onChanged: (v) {
                        setStateSheet(() {
                          _desktopNotifications = v;
                          _criticalAlerts = v;
                          _powerAlerts = v;
                          _systemAlerts = v;
                          _dailySummary = v;
                        });
                        setState(() {
                          _desktopNotifications = v;
                          _criticalAlerts = v;
                          _powerAlerts = v;
                          _systemAlerts = v;
                          _dailySummary = v;
                        });
                        _saveSetting('desktop_notifications', v);
                        _saveSetting('critical_alerts', v);
                        _saveSetting('power_alerts', v);
                        _saveSetting('system_alerts', v);
                        _saveSetting('daily_summary', v);
                        if (v) NotificationService().requestPermission();
                      },
                      activeThumbColor: Theme.of(context).primaryColor,
                    ),
                    const Divider(),
                    const Text(
                      'Alert Types',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Critical Alerts'),
                      subtitle: const Text(
                        'Power outages, system failures',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _criticalAlerts,
                      onChanged: _desktopNotifications
                          ? (v) {
                              setStateSheet(() => _criticalAlerts = v);
                              setState(() => _criticalAlerts = v);
                              _saveSetting('critical_alerts', v);
                            }
                          : null,
                      activeThumbColor: Theme.of(context).primaryColor,
                    ),
                    SwitchListTile(
                      title: const Text('Power Alerts'),
                      subtitle: const Text(
                        'Grid status, solar availability',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _powerAlerts,
                      onChanged: _desktopNotifications
                          ? (v) {
                              setStateSheet(() => _powerAlerts = v);
                              setState(() => _powerAlerts = v);
                              _saveSetting('power_alerts', v);
                            }
                          : null,
                      activeThumbColor: Theme.of(context).primaryColor,
                    ),
                    SwitchListTile(
                      title: const Text('System Alerts'),
                      subtitle: const Text(
                        'Updates, maintenance, commands',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _systemAlerts,
                      onChanged: _desktopNotifications
                          ? (v) {
                              setStateSheet(() => _systemAlerts = v);
                              setState(() => _systemAlerts = v);
                              _saveSetting('system_alerts', v);
                            }
                          : null,
                      activeThumbColor: Theme.of(context).primaryColor,
                    ),
                    SwitchListTile(
                      title: const Text('Daily Summary'),
                      subtitle: const Text(
                        'Receive daily energy reports',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _dailySummary,
                      onChanged: _desktopNotifications
                          ? (v) {
                              setStateSheet(() => _dailySummary = v);
                              setState(() => _dailySummary = v);
                              _saveSetting('daily_summary', v);
                            }
                          : null,
                      activeThumbColor: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final energyProvider = Provider.of<EnergyProvider>(context);
    final alerts = energyProvider.alerts;

    // Parse alerts to AlertModel objects
    final alertModels = alerts
        .whereType<Map>()
        .map((alert) => AlertModel.fromJson(Map<String, dynamic>.from(alert)))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: RotationTransition(
              turns: Tween(begin: -0.05, end: 0.05).animate(_bellController),
              child: const Icon(
                Icons.notifications_active,
                color: Colors.orange,
              ),
            ),
            onPressed: _showNotificationSettingsSheet,
          ),
          IconButton(
            icon: RotationTransition(
              turns: Tween(begin: -0.05, end: 0.05).animate(_bellController),
              child: const Icon(Icons.delete_forever, color: Colors.red),
            ),
            onPressed: _confirmClearAll,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => energyProvider.loadAllData(showLoading: false),
                child: alertModels.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: _buildEmptyState(true),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: alertModels.length,
                        itemBuilder: (context, index) {
                          final alert = alertModels[index];
                          return TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutBack, // Bubble pop effect
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: child,
                              );
                            },
                            child: _buildAlertCard(alert, energyProvider),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== ALERT CARD ==========

  Widget _buildAlertCard(AlertModel alert, EnergyProvider provider) {
    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Dismiss Alert'),
            content: const Text('Are you sure you want to dismiss this alert?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        provider.dismissAlert(alert.id);
        _showSnackBar('Alert dismissed');
      },
      child: InkWell(
        onTap: () => _showAlertDetails(alert, provider),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getPriorityColor(alert.priority).withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(alert.priority),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    alert.priorityText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getPriorityColor(alert.priority),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!alert.isRead)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    alert.formattedTime,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                alert.message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (alert.details != null && alert.details!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  alert.details!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (alert.priority == AlertPriority.high) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showQuickActions(alert),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('TAKE ACTION'),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showAlertDetails(alert, provider),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('DETAILS'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== EMPTY STATE ==========

  Widget _buildEmptyState(bool isUnread) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isUnread ? Icons.notifications_none : Icons.notifications_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isUnread ? 'No unread alerts' : 'No alerts in history',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isUnread
                ? 'All caught up! No new notifications.'
                : 'Alert history will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              final provider = Provider.of<EnergyProvider>(
                context,
                listen: false,
              );
              provider.loadAllData();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  // ========== DIALOGS & SHEETS ==========

  void _showAlertDetails(AlertModel alert, EnergyProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(
                            alert.priority,
                          ).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          alert.priority == AlertPriority.high
                              ? Icons.error
                              : alert.priority == AlertPriority.medium
                              ? Icons.warning
                              : Icons.info,
                          color: _getPriorityColor(alert.priority),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.priorityText,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _getPriorityColor(alert.priority),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alert.message,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            'Time',
                            alert.formattedDateTime,
                            Icons.access_time,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            'Priority',
                            alert.priorityText,
                            Icons.priority_high,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            'Type',
                            alert.type.toString().split('.').last.toUpperCase(),
                            Icons.category,
                          ),
                          if (alert.details != null) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              'Details',
                              alert.details!,
                              Icons.description,
                              isLongText: true,
                            ),
                          ],
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            'Status',
                            alert.isRead ? 'Read' : 'Unread',
                            Icons.mark_email_read,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              if (!alert.isRead) ...[
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      provider.markAlertRead(alert.id);
                                      Navigator.pop(context);
                                      _showSnackBar('Marked as read');
                                    },
                                    icon: const Icon(Icons.mark_email_read),
                                    label: const Text('Mark as Read'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Close'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    bool isLongText = false,
  }) {
    return Row(
      crossAxisAlignment: isLongText
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  void _showQuickActions(AlertModel alert) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.electrical_services,
                  color: Colors.orange,
                ),
                title: const Text('Check Grid Status'),
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Navigating to Controls...');
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_backup_restore),
                title: const Text('Reset System'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmReset();
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_off),
                title: const Text('Mute Similar Alerts'),
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Similar alerts muted for 1 hour');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Alerts'),
        content: const Text(
          'Are you sure you want to clear all alerts? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final provider = Provider.of<EnergyProvider>(
                context,
                listen: false,
              );
              provider.clearAlerts();
              _showSnackBar('All alerts cleared');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset System'),
        content: const Text(
          'Are you sure you want to reset the system? This will restart all services.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final provider = Provider.of<EnergyProvider>(
                context,
                listen: false,
              );
              provider.sendCommand('RESET', 1);
              _showSnackBar('System reset command sent');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  // ========== HELPERS ==========

  Color _getPriorityColor(AlertPriority priority) {
    switch (priority) {
      case AlertPriority.high:
        return Colors.red;
      case AlertPriority.medium:
        return Colors.orange;
      case AlertPriority.low:
        return Colors.blue;
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
