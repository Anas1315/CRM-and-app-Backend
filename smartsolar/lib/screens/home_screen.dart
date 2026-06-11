import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsolar/providers/auth_provider.dart';
import 'package:smartsolar/providers/energy_provider.dart';
import 'package:smartsolar/screens/profile_screen.dart';
import 'package:smartsolar/utils/theme.dart';
import 'package:smartsolar/widgets/energy_flow_widget.dart';
import 'package:smartsolar/widgets/whl_energy_flow_widget.dart';
import 'package:smartsolar/widgets/wifi_provisioning_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EnergyProvider>();
    final data = provider.currentData;
    // WiFi icon: shows app→backend connectivity (not ESP32 device status)
    final isOnline = provider.connectionStatus == 'connected';
    final values = EnergyValues.fromData(data);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGridConnected =
        data?.wapdaAvailable == true && data?.wapdaRelayState == true;

    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final isWapdaOnly = user?.isWapdaOnly ?? false;
    final isMediumSolar = user?.isMediumSolar ?? false;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    AppTheme.darkerBg,
                    AppTheme.darkBg,
                    AppTheme.cardDarkAlt,
                  ]
                : const [
                    AppTheme.lightCream,
                    AppTheme.lightBg,
                    AppTheme.lightSky,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _TopStatusBar(
                isOnline: isOnline,
                isDayTime: values.isDayTime,
                isSunny: values.isSunny,
                isStormy: values.isStormy,
              ),
              Expanded(
                child: isWapdaOnly
                    ? _WapdaHeavyLoadDashboard(
                        values: values,
                        isOnline: isOnline,
                        isDark: isDark,
                        provider: provider,
                      )
                    : isMediumSolar
                    ? _MediumSolarTelemetryDashboard(
                        values: values,
                        isOnline: isOnline,
                        isDark: isDark,
                        provider: provider,
                      )
                    : Transform.translate(
                        offset: const Offset(0, -5),
                        child: EnergyFlowWidget(values: values),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 9),
                child: Text(
                  'Last update:   ${values.lastUpdateText}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.textLight
                        : AppTheme.textMuted.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!isWapdaOnly && !isMediumSolar)
                _BottomSummaryCards(
                  gridStatus: isGridConnected ? 'ON' : 'OFF',
                  gridConnected: isGridConnected,
                  powerKw: values.powerKw,
                ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomSummaryCards extends StatelessWidget {
  final String gridStatus;
  final bool gridConnected;
  final double powerKw;

  const _BottomSummaryCards({
    required this.gridStatus,
    required this.gridConnected,
    required this.powerKw,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              title: 'WAPDA:',
              value: gridStatus,
              valueColor: gridConnected ? AppTheme.success : AppTheme.error,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: _SummaryCard(
              title: 'Power Today:',
              value: '${powerKw.toStringAsFixed(2)} kW',
              valueColor: isDark ? AppTheme.sunGlow : AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppTheme.textDark;
    final cardGradient = isDark
        ? const [AppTheme.cardDarkAlt, AppTheme.cardDark]
        : const [Colors.white, AppTheme.lightSurfaceTint];

    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cardGradient,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? AppTheme.primaryLight.withValues(alpha: 0.10)
              : AppTheme.primary.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppTheme.primaryDark).withValues(
              alpha: isDark ? 0.30 : 0.13,
            ),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          if (!isDark)
            BoxShadow(
              color: AppTheme.sunGlow.withValues(alpha: 0.16),
              blurRadius: 26,
              offset: const Offset(-10, -8),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: valueColor,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopStatusBar extends StatefulWidget {
  final bool isOnline;
  final bool isDayTime;
  final bool isSunny;
  final bool isStormy;

  const _TopStatusBar({
    required this.isOnline,
    required this.isDayTime,
    required this.isSunny,
    required this.isStormy,
  });

  @override
  State<_TopStatusBar> createState() => _TopStatusBarState();
}

class _TopStatusBarState extends State<_TopStatusBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _profileController;

  @override
  void initState() {
    super.initState();
    _profileController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _profileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textLight : AppTheme.textMuted;
    final authProvider = context.watch<AuthProvider>();
    final email = authProvider.user?.email ?? 'U';
    final firstLetter = email.isNotEmpty ? email[0].toUpperCase() : 'U';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Wifi Status Button
          Expanded(
            flex: 2,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (context) => const WifiProvisioningDialog(),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi,
                    color: widget.isOnline
                        ? AppTheme.primary
                        : const Color(0xFF9E9E9E),
                    size: 20,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      widget.isOnline ? 'Connected' : 'Disconnected',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.isOnline
                            ? (isDark
                                  ? AppTheme.primaryLight
                                  : AppTheme.primaryDark)
                            : textColor,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: widget.isOnline
                            ? Colors.transparent
                            : textColor.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center: Weather Chip
          Expanded(
            flex: 3,
            child: Center(
              child: _WeatherChip(
                isDayTime: widget.isDayTime,
                isSunny: widget.isSunny,
                isStormy: widget.isStormy,
              ),
            ),
          ),

          // Right: Animated Profile Icon
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                child: Transform.translate(
                  offset: const Offset(40, 0), // Move 8 pixels right
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1.10).animate(
                      CurvedAnimation(
                        parent: _profileController,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          firstLetter,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherChip extends StatelessWidget {
  final bool isDayTime;
  final bool isSunny;
  final bool isStormy;

  const _WeatherChip({
    required this.isDayTime,
    required this.isSunny,
    required this.isStormy,
  });

  @override
  Widget build(BuildContext context) {
    final temp = context.watch<EnergyProvider>().currentTemp;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icon = !isDayTime
        ? Icons.nightlight_round
        : isStormy
        ? Icons.thunderstorm
        : isSunny
        ? Icons.wb_sunny
        : Icons.cloud;
    final iconColor = !isDayTime
        ? const Color(0xFFFFF8E1)
        : isStormy
        ? AppTheme.secondary
        : isSunny
        ? AppTheme.accent
        : AppTheme.info;

    return Container(
      constraints: const BoxConstraints(minWidth: 74),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.primaryLight.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? AppTheme.primaryLight.withValues(alpha: 0.18)
              : AppTheme.sunGlow.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 6),
          Text(
            isStormy ? 'Storm' : temp,
            style: TextStyle(
              fontSize: isStormy ? 13 : 17,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _WapdaHeavyLoadDashboard extends StatefulWidget {
  final EnergyValues values;
  final bool isOnline;
  final bool isDark;
  final EnergyProvider provider;

  const _WapdaHeavyLoadDashboard({
    required this.values,
    required this.isOnline,
    required this.isDark,
    required this.provider,
  });

  @override
  State<_WapdaHeavyLoadDashboard> createState() =>
      _WapdaHeavyLoadDashboardState();
}

class _WapdaHeavyLoadDashboardState extends State<_WapdaHeavyLoadDashboard> {
  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final data = widget.provider.currentData;
    final wapdaActive = data?.wapdaRelayState ?? false;
    final wapdaAvailable = data?.wapdaAvailable ?? false;


    return Column(
      children: [
        const SizedBox(height: 12),
        // Main Animated illustration
        Expanded(child: WhlEnergyFlowWidget(values: widget.values)),

        // Bottom Status Cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _buildStatusCard(
                  title: 'Grid Status:',
                  value: wapdaAvailable ? 'Available' : 'OFF',
                  valueColor: wapdaAvailable ? AppTheme.success : AppTheme.error,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusCard(
                  title: 'Home WAPDA:',
                  value: wapdaActive ? 'ON' : 'OFF',
                  valueColor: wapdaActive ? AppTheme.accent : AppTheme.error,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String value,
    required Color valueColor,
    required bool isDark,
  }) {
    final background = isDark ? AppTheme.cardDarkAlt : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? AppTheme.primaryLight.withValues(alpha: 0.1)
              : AppTheme.primary.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppTheme.primaryDark).withValues(
              alpha: isDark ? 0.2 : 0.05,
            ),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? AppTheme.textSecondary : AppTheme.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MediumSolarTelemetryDashboard extends StatelessWidget {
  final EnergyValues values;
  final bool isOnline;
  final bool isDark;
  final EnergyProvider provider;

  const _MediumSolarTelemetryDashboard({
    required this.values,
    required this.isOnline,
    required this.isDark,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark
        ? AppTheme.cardDark
        : Colors.white.withValues(alpha: 0.85);
    final borderCol = isDark
        ? AppTheme.primaryLight.withValues(alpha: 0.12)
        : AppTheme.primary.withValues(alpha: 0.08);
    final textCol = isDark ? Colors.white : AppTheme.textDark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solar Telemetry Hub',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Grid & Generation Telemetry SKU-MSS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.15,
            children: [
              _buildTelemetryGauge(
                icon: Icons.wb_sunny,
                label: 'Solar Gen',
                value: '${values.ldrValue} LDR',
                color: AppTheme.sunGlow,
                bgColor: cardBg,
                borderCol: borderCol,
                textCol: textCol,
              ),
              _buildTelemetryGauge(
                icon: Icons.home,
                label: 'Home Load',
                value: '${values.consumptionKw.toStringAsFixed(2)} kW',
                color: const Color(0xFF00BFA5),
                bgColor: cardBg,
                borderCol: borderCol,
                textCol: textCol,
              ),
              _buildTelemetryGauge(
                icon: Icons.bolt,
                label: 'Grid Voltage',
                value: '${values.gridVoltage} V',
                color: const Color(0xFF3B82F6),
                bgColor: cardBg,
                borderCol: borderCol,
                textCol: textCol,
              ),
              _buildTelemetryGauge(
                icon: Icons.device_thermostat,
                label: 'Temperature',
                value: provider.currentTemp,
                color: const Color(0xFFFF7043),
                bgColor: cardBg,
                borderCol: borderCol,
                textCol: textCol,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderCol, width: 1.5),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hardware Diagnostic Logs',
                  style: TextStyle(
                    color: textCol,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDiagnosticRow('System Frequency', '50.02 Hz', true),
                _buildDiagnosticRow('Smart Load Switch', 'OFF', false),
                _buildDiagnosticRow('OTA Update Mode', 'Auto Enabled', true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticRow(String label, String value, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: status ? const Color(0xFF00BFA5) : AppTheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryGauge({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    required Color borderCol,
    required Color textCol,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: textCol,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
