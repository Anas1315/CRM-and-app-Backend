import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartsolar/models/daily_stats.dart';
import 'package:smartsolar/models/energy_data.dart';
import 'package:smartsolar/providers/energy_provider.dart';
import 'package:smartsolar/utils/theme.dart';
import 'package:smartsolar/widgets/power_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedDayIndex = DateTime.now().weekday - 1;
  String _chartStyle = 'Line';
  bool _showChartSettings = false;

  @override
  void initState() {
    super.initState();
    _loadChartStyle();
  }

  Future<void> _loadChartStyle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _chartStyle = prefs.getString('chart_style') ?? 'Line');
  }

  @override
  Widget build(BuildContext context) {
    final energyProvider = Provider.of<EnergyProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.textLight : AppTheme.textMuted;
    final stats = energyProvider.dailyStats ?? DailyStats.empty();
    final chartData = _chartDataForDay(
      _selectedDayIndex,
      energyProvider.hourlyData,
      energyProvider.currentData,
      stats,
    );

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: titleColor, size: 20),
          onPressed: () {},
        ),
        title: Text(
          'Power Over Time',
          style: TextStyle(color: titleColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildChartSettingsButton(),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Power Over Time',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select a day to inspect hourly power',
                            style: TextStyle(fontSize: 13, color: mutedColor),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _chartStyle,
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: _showChartSettings
                      ? Padding(
                          key: const ValueKey('chart-settings'),
                          padding: const EdgeInsets.only(top: 14),
                          child: _buildChartStyleCard(),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 300,
                  child: PowerChart(
                    hourlyData: chartData,
                    lineColor: AppTheme.primary,
                    title: 'Power Over Time',
                    weeklyView: true,
                    selectedDayIndex: _selectedDayIndex,
                    onDaySelected: (index) {
                      setState(() => _selectedDayIndex = index);
                    },
                    chartStyle: _chartStyle,
                  ),
                ),
                const SizedBox(height: 22),
                _StatLine(
                  label: 'Peak',
                  value:
                      '${_kw(stats.peakPower, energyProvider.currentData?.power).toStringAsFixed(1)} kW',
                  color: AppTheme.primary,
                ),
                _StatLine(
                  label: 'Used',
                  value: '${stats.unitsConsumedDouble.toStringAsFixed(1)} kWh',
                  color: const Color(0xFF1E88E5),
                ),
                _StatLine(
                  label: 'Saved',
                  value: '${stats.unitsSavedDouble.toStringAsFixed(1)} kWh',
                  color: const Color(0xFF00BFA5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartSettingsButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => setState(() => _showChartSettings = !_showChartSettings),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: _showChartSettings
              ? AppTheme.primary.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppTheme.cardShadow,
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: _showChartSettings ? 0.5 : 0),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          builder: (context, turns, child) {
            return Transform.rotate(angle: turns * 6.283185307, child: child);
          },
          child: const Icon(Icons.settings, color: AppTheme.primary),
        ),
      ),
    );
  }

  Widget _buildChartStyleCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FBFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: ['Line', 'Bar', 'Area'].map((style) {
          final selected = style == _chartStyle;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _setChartStyle(style),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      style,
                      style: TextStyle(
                        color: selected ? AppTheme.primary : Colors.black54,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _setChartStyle(String style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chart_style', style);
    setState(() => _chartStyle = style);
  }

  List<HourlyData> _chartDataForDay(
    int dayIndex,
    List<HourlyData> hourlyData,
    EnergyData? data,
    DailyStats stats,
  ) {
    final todayIndex = DateTime.now().weekday - 1;
    if (dayIndex == todayIndex && hourlyData.isNotEmpty) {
      return [...hourlyData]..sort((a, b) => a.hour.compareTo(b.hour));
    }

    final currentHour = DateTime.now().hour;
    final livePower = data?.power ?? stats.peakPower;
    return List.generate(24, (hour) {
      final isFutureToday = dayIndex == todayIndex && hour > currentHour;
      final curve = (0.35 + (hour >= 7 && hour <= 20 ? 0.65 : 0.12));
      return HourlyData(
        hour: hour,
        voltage: data?.voltage ?? stats.avgVoltage,
        current: data?.current ?? 0,
        power: isFutureToday ? 0 : livePower * curve,
        ldrValue: data?.ldrValue ?? 0,
      );
    });
  }

  double _kw(double statPower, double? livePower) {
    final power = statPower > 0 ? statPower : livePower ?? 0;
    return power / 1000;
  }
}

class _StatLine extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatLine({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppTheme.textLight : AppTheme.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
