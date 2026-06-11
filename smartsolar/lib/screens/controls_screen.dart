import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartsolar/providers/energy_provider.dart';
import 'package:smartsolar/utils/theme.dart';

class ControlsScreen extends StatefulWidget {
  const ControlsScreen({super.key});

  @override
  State<ControlsScreen> createState() => _ControlsScreenState();
}

class _ControlsScreenState extends State<ControlsScreen> {
  bool _showWapdaTimeControl = false;
  TimeOfDay _dayStart = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _dayEnd = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadWapdaTimes();
  }

  Future<void> _loadWapdaTimes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dayStart = _parseTime(prefs.getString('wapda_day_start')) ?? _dayStart;
      _dayEnd = _parseTime(prefs.getString('wapda_day_end')) ?? _dayEnd;
    });
  }

  @override
  Widget build(BuildContext context) {
    final energyProvider = Provider.of<EnergyProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppTheme.textDark;
    final data = energyProvider.currentData;
    final wapdaAutoMode = data?.wapdaAutoMode ?? true;
    final wapdaAvailable = data?.wapdaAvailable ?? false;
    final heavyLoadAutoMode = data?.heavyLoadAutoMode ?? true;
    final heavyLoadOn = data?.heavyLoadState ?? false;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: titleColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Grid & Load Control',
          style: TextStyle(color: titleColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 20),

              // Wapda Grid Control
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [AppTheme.cardDarkAlt, AppTheme.cardDark]
                        : const [Colors.white, AppTheme.lightSurfaceTint],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? AppTheme.primaryLight.withValues(alpha: 0.12)
                        : Colors.white,
                    width: 2,
                  ),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Home WAPDA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        _buildStatusDot(wapdaAvailable),
                        const SizedBox(width: 8),
                        Text(
                          wapdaAvailable ? 'Available' : 'Unavailable',
                          style: TextStyle(
                            color: wapdaAvailable
                                ? const Color(0xFF00BFA5)
                                : const Color(0xFFE53935),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Operation Mode',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildModeToggle(
                      autoMode: wapdaAutoMode,
                      onManual: () =>
                          energyProvider.sendCommand('WAPDA_MODE', 0),
                      onAutomatic: () =>
                          energyProvider.sendCommand('WAPDA_MODE', 1),
                    ),
                    if (!wapdaAutoMode) ...[
                      const SizedBox(height: 16),
                      _buildManualSwitch(
                        title: 'Home WAPDA',
                        icon: Icons.electrical_services,
                        value: data?.wapdaRelayState ?? false,
                        onChanged: (value) => energyProvider.sendCommand(
                          'WAPDA_RELAY',
                          value ? 1 : 0,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      _buildAutoModeNote(
                        icon: Icons.bolt,
                        title: 'Automatic Home WAPDA control is active',
                        subtitle: 'The controller will switch Home WAPDA as needed.',
                      ),
                    ],
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _buildAnimatedSettingsButton(),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _showWapdaTimeControl
                          ? Padding(
                              key: const ValueKey('wapda-time-card'),
                              padding: const EdgeInsets.only(top: 14),
                              child: _buildWapdaTimeCard(energyProvider),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Heavy Load Management
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [AppTheme.cardDarkAlt, AppTheme.cardDark]
                        : const [Colors.white, AppTheme.lightSurfaceTint],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? AppTheme.primaryLight.withValues(alpha: 0.12)
                        : Colors.white,
                    width: 2,
                  ),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Heavy Load Management',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Operation Mode',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildModeToggle(
                      autoMode: heavyLoadAutoMode,
                      onManual: () =>
                          energyProvider.sendCommand('HEAVY_LOAD_MODE', 0),
                      onAutomatic: () =>
                          energyProvider.sendCommand('HEAVY_LOAD_MODE', 1),
                    ),
                    if (!heavyLoadAutoMode) ...[
                      const SizedBox(height: 16),
                      _buildManualSwitch(
                        title: 'Heavy Load',
                        icon: Icons.ev_station,
                        value: heavyLoadOn,
                        onChanged: (value) => energyProvider.sendCommand(
                          'HEAVY_LOAD',
                          value ? 1 : 0,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      _buildAutoModeNote(
                        icon: Icons.ev_station,
                        title: 'Automatic heavy load control is active',
                        subtitle:
                            'The controller will manage heavy load switching.',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDot(bool active) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF00C853) : const Color(0xFFE53935),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (active ? const Color(0xFF00C853) : const Color(0xFFE53935))
                .withValues(alpha: 0.35),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSettingsButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        setState(() => _showWapdaTimeControl = !_showWapdaTimeControl);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _showWapdaTimeControl
              ? AppTheme.primary.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _showWapdaTimeControl ? 0.5 : 0),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              builder: (context, turns, child) {
                return Transform.rotate(
                  angle: turns * 2 * 3.1415926535,
                  child: child,
                );
              },
              child: const Icon(Icons.settings, size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'Schedule',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWapdaTimeCard(EnergyProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WAPDA Control Time',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTimePickerTile(
                  label: 'Day start at',
                  value: _dayStart,
                  onTap: () => _pickTime(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTimePickerTile(
                  label: 'Day end at',
                  value: _dayEnd,
                  onTap: () => _pickTime(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _sendWapdaSchedule(provider),
              icon: const Icon(Icons.send, size: 18),
              label: const Text('Send to ESP32'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerTile({
    required String label,
    required TimeOfDay value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: AppTheme.primary),
                const SizedBox(width: 6),
                Text(
                  value.format(context),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime(bool start) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _dayStart : _dayEnd,
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _dayStart = picked;
      } else {
        _dayEnd = picked;
      }
    });
  }

  Future<void> _sendWapdaSchedule(EnergyProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    final start = _formatTime(_dayStart);
    final end = _formatTime(_dayEnd);
    await prefs.setString('wapda_day_start', start);
    await prefs.setString('wapda_day_end', end);
    final success = await provider.sendCommandPayload('WAPDA_TIME', {
      'dayStart': start,
      'dayEnd': end,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'WAPDA time sent to ESP32' : 'Could not send WAPDA time',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Widget _buildModeToggle({
    required bool autoMode,
    required VoidCallback onManual,
    required VoidCallback onAutomatic,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeOption(
              label: 'Manual',
              selected: !autoMode,
              onTap: onManual,
            ),
          ),
          Expanded(
            child: _buildModeOption(
              label: 'Automatic',
              selected: autoMode,
              onTap: onAutomatic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? (isDark
                    ? AppTheme.primaryLight.withValues(alpha: 0.12)
                    : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? (isDark ? Colors.white : AppTheme.textDark)
                  : (isDark ? AppTheme.textLight : AppTheme.textMuted),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAutoModeNote({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.primaryLight.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.textLight : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualSwitch({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.primaryLight.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: isDark ? AppTheme.textLight : AppTheme.textMuted),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: value
                  ? AppTheme.primary
                  : (isDark ? AppTheme.cardDarkAlt : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: value
                    ? Colors.transparent
                    : (isDark
                          ? AppTheme.primaryLight.withValues(alpha: 0.14)
                          : Colors.grey.shade300),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => onChanged(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    child: Text(
                      'Off',
                      style: TextStyle(
                        color: value
                            ? Colors.white70
                            : (isDark ? Colors.white : AppTheme.textDark),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => onChanged(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: value
                        ? BoxDecoration(
                            color: isDark
                                ? AppTheme.primaryLight
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ],
                          )
                        : null,
                    alignment: Alignment.center,
                    child: Text(
                      'On',
                      style: TextStyle(
                        color: value
                            ? AppTheme.primary
                            : (isDark
                                  ? AppTheme.textLight
                                  : AppTheme.textMuted),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
