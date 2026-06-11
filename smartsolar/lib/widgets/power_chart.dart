import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smartsolar/models/energy_data.dart';

class PowerChart extends StatelessWidget {
  final List<HourlyData> hourlyData;
  final Color? lineColor;
  final String title;
  final bool weeklyView;
  final String chartStyle;
  final int selectedDayIndex;
  final ValueChanged<int>? onDaySelected;

  const PowerChart({
    super.key,
    required this.hourlyData,
    this.lineColor,
    this.title = 'Power Usage',
    this.weeklyView = false,
    this.chartStyle = 'Line',
    this.selectedDayIndex = 0,
    this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (hourlyData.isEmpty) {
      return const Center(
        child: Text('No data available', style: TextStyle(color: Colors.grey)),
      );
    }

    final color = lineColor ?? Theme.of(context).primaryColor;
    final spots = hourlyData.asMap().entries.map((entry) {
      return FlSpot(entry.value.hour.toDouble(), entry.value.power / 1000);
    }).toList();

    final maxPower = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final maxY = _niceMaxY(maxPower);
    final yInterval = maxY <= 1 ? 0.25 : maxY / 4;

    return Column(
      children: [
        if (weeklyView) ...[
          _WeekdayHeader(
            selectedIndex: selectedDayIndex,
            onSelected: onDaySelected,
          ),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: chartStyle == 'Bar'
              ? BarChart(_barChartData(color, spots, maxY, yInterval))
              : LineChart(
                  _lineChartData(
                    color,
                    spots,
                    maxY,
                    yInterval,
                    fillArea: chartStyle == 'Area',
                  ),
                ),
        ),
      ],
    );
  }

  LineChartData _lineChartData(
    Color color,
    List<FlSpot> spots,
    double maxY,
    double yInterval, {
    required bool fillArea,
  }) {
    return LineChartData(
      gridData: _gridData(yInterval),
      titlesData: _titlesData(),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: weeklyView),
          belowBarData: BarAreaData(
            show: fillArea,
            color: color.withValues(alpha: 0.16),
          ),
        ),
      ],
      minX: 0,
      maxX: 23,
      minY: 0,
      maxY: maxY,
    );
  }

  BarChartData _barChartData(
    Color color,
    List<FlSpot> spots,
    double maxY,
    double yInterval,
  ) {
    return BarChartData(
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem(
              '${group.x.toInt().toString().padLeft(2, '0')}:00\n',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: '${rod.toY.toStringAsFixed(1)} kW',
                  style: const TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      gridData: _gridData(yInterval),
      titlesData: _titlesData(),
      borderData: FlBorderData(show: false),
      minY: 0,
      maxY: maxY,
      barGroups: spots.map((spot) {
        return BarChartGroupData(
          x: spot.x.toInt(),
          barRods: [
            BarChartRodData(
              toY: spot.y,
              width: weeklyView ? 16 : 5,
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(5),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  FlGridData _gridData(double interval) {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: interval,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: Colors.grey.withValues(alpha: 0.2),
          strokeWidth: 1,
        );
      },
    );
  }

  FlTitlesData _titlesData() {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: 6,
          getTitlesWidget: (value, meta) {
            if (value > 23) return const SizedBox.shrink();
            final label = '${value.toInt().toString().padLeft(2, '0')}:00';
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 44,
          getTitlesWidget: (value, meta) {
            if (value == 0 && meta.min != value) return const SizedBox();
            return Text(
              '${value.toStringAsFixed(value >= 10 ? 0 : 1)} kW',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            );
          },
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  double _niceMaxY(double value) {
    if (value <= 0.25) return 0.25;
    if (value <= 0.5) return 0.5;
    if (value <= 1) return 1;
    if (value <= 2) return 2;
    if (value <= 5) return 5;
    return ((value / 5).ceil() * 5).toDouble();
  }
}

class _WeekdayHeader extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  const _WeekdayHeader({required this.selectedIndex, this.onSelected});

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final todayIndex = DateTime.now().weekday - 1;

    return Row(
      children: List.generate(_days.length, (index) {
        final active = index == selectedIndex;
        final isToday = index == todayIndex;
        return Expanded(
          child: Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onSelected?.call(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.14)
                      : Colors.transparent,
                  border: Border.all(
                    color: isToday
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.35)
                        : Colors.transparent,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _days[index],
                  style: TextStyle(
                    color: active
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
