import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:smartsolar/models/energy_data.dart';
import 'package:smartsolar/utils/theme.dart';

class EnergyFlowWidget extends StatefulWidget {
  final EnergyValues values;

  const EnergyFlowWidget({super.key, required this.values});

  @override
  State<EnergyFlowWidget> createState() => _EnergyFlowWidgetState();
}

class _EnergyFlowWidgetState extends State<EnergyFlowWidget>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _time = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (mounted) {
        setState(() {
          _time = elapsed.inMilliseconds / 2600.0;
        });
      }
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EnergyScene(progress: _time, values: widget.values);
  }
}

class EnergyScene extends StatelessWidget {
  final double progress;
  final EnergyValues values;

  const EnergyScene({super.key, required this.progress, required this.values});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final compact = width < 380;
        final points = ScenePoints(Size(width, height));

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: EnergyScenePainter(progress: progress, values: values),
              ),
            ),
            PositionedLabel(
              left: math.max(10, points.solarPanel.left - 2),
              top: points.solarPanel.top - (compact ? 70 : 82),
              child: MetricLabel(
                valueText: values.ldrValue.toString(),
                unit: 'LDR',
                label: 'Production',
                align: TextAlign.left,
                compact: compact,
                brightText: !values.isDayTime,
              ),
            ),
            PositionedLabel(
              left: points.houseRect.left + points.houseRect.width * 0.22 + 20,
              top: points.houseRect.top - (compact ? 54 : 68),
              child: MetricLabel(
                valueText: formatNumber(values.consumptionKw),
                unit: 'kW',
                label: 'Consumption',
                align: TextAlign.center,
                compact: compact,
                brightText: !values.isDayTime,
              ),
            ),
            PositionedLabel(
              right: math.max(12, width - points.gridPoleBase.dx - 25),
              top: points.gridPoleBase.dy - 190,
              child: MetricLabel(
                valueText: formatNumber(values.gridVoltage),
                unit: 'V',
                label: 'Grid Voltage',
                align: TextAlign.right,
                compact: compact,
                brightText: !values.isDayTime,
              ),
            ),
            Positioned(
              left: points.smartLoadInput.dx - 62,
              top: points.smartLoadInput.dy + 8,
              child: LoadLineLabel(
                text: '',
                color: AppTheme.primary,
                brightText: !values.isDayTime,
              ),
            ),
            Positioned(
              left: points.heavyLoadInput.dx + 12,
              top: points.heavyLoadInput.dy + 8,
              child: LoadLineLabel(
                text: '',
                color: values.heavyLoadOn
                    ? const Color(0xFF1E88E5)
                    : AppTheme.error,
                brightText: !values.isDayTime,
              ),
            ),
          ],
        );
      },
    );
  }
}

class PositionedLabel extends StatelessWidget {
  final double? left;
  final double? right;
  final double top;
  final Widget child;

  const PositionedLabel({
    super.key,
    this.left,
    this.right,
    required this.top,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(left: left, right: right, top: top, child: child);
  }
}

class MetricLabel extends StatelessWidget {
  final String valueText;
  final String unit;
  final String label;
  final TextAlign align;
  final bool compact;
  final bool brightText;

  const MetricLabel({
    super.key,
    required this.valueText,
    required this.unit,
    required this.label,
    required this.align,
    required this.compact,
    required this.brightText,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = brightText ? Colors.white : const Color(0xFF111827);
    final labelColor = brightText ? Colors.white70 : const Color(0xFF6A7D87);

    return Column(
      crossAxisAlignment: align == TextAlign.right
          ? CrossAxisAlignment.end
          : align == TextAlign.left
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        RichText(
          textAlign: align,
          text: TextSpan(
            children: [
              TextSpan(
                text: valueText,
                style: TextStyle(
                  fontSize: compact ? 22 : 28,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: valueColor,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  fontSize: compact ? 12 : 15,
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: align,
          style: TextStyle(
            fontSize: compact ? 12 : 16,
            color: labelColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class LoadLineLabel extends StatelessWidget {
  final String text;
  final Color color;
  final bool brightText;

  const LoadLineLabel({
    super.key,
    required this.text,
    required this.color,
    required this.brightText,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: brightText ? Colors.white.withValues(alpha: 0.86) : color,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class EnergyScenePainter extends CustomPainter {
  final double progress;
  final EnergyValues values;

  EnergyScenePainter({required this.progress, required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    final points = ScenePoints(size);
    _drawSky(canvas, size);
    _drawWeather(canvas, size, points);
    _drawLandscape(canvas, size, points);
    _drawSolarPanel(canvas, points.solarPanel);
    _drawHome(canvas, points.houseRect);
    _drawEnergyLines(canvas, size, points);
    _drawBattery(canvas, points.batteryRect);
    _drawGrid(canvas, points.gridPoleBase, points.groundY);
    _drawInverter(canvas, points.inverter);
  }

  void _drawSky(Canvas canvas, Size size) {
    final colors = !values.isDayTime
        ? const [Color(0xFF111827), Color(0xFF172554), Color(0xFF0F172A)]
        : values.isStormy
        ? const [Color(0xFF73889A), Color(0xFFAAB9C4), Color(0xFFC3D9C9)]
        : values.isSunny
        ? const [Color(0xFFE7F6FF), Color(0xFFFFFCF2), Color(0xFFC8E7D1)]
        : const [Color(0xFFDCEBF2), Color(0xFFF5FAF7), Color(0xFFC1D9C7)];

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
        stops: const [0, 0.6, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _drawWeather(Canvas canvas, Size size, ScenePoints points) {
    if (!values.isDayTime) {
      _drawMoon(canvas, Offset(size.width * 0.8, size.height * 0.14));
      _drawStars(canvas, size);
      _drawClouds(canvas, size);
      _drawShootingStars(canvas, size);
      return;
    }

    if (values.isSunny) {
      final sun = Offset(points.solarPanel.center.dx, size.height * 0.13);
      _drawSun(canvas, sun);
      _drawSunRaysToPanel(canvas, sun, points.solarPanel);
    } else {
      _drawClouds(canvas, size);
      if (values.isStormy) {
        _drawRain(canvas, size);
        _drawLightning(canvas, size);
      }
    }
  }

  void _drawSun(Canvas canvas, Offset center) {
    final intensity = values.sunIntensity;
    final pulse =
        0.78 + intensity * 0.24 + math.sin(progress * math.pi * 2) * 0.06;
    final glowRadius = 36 + intensity * 42;
    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(
                0xFFFFD54F,
              ).withValues(alpha: 0.12 + intensity * 0.48),
              const Color(0xFFFFD54F).withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: glowRadius * pulse),
          );
    canvas.drawCircle(center, glowRadius * pulse, glowPaint);
    canvas.drawCircle(
      center,
      16 + intensity * 10,
      Paint()..color = const Color(0xFFFFC107),
    );

    final rayPaint = Paint()
      ..color = const Color(
        0xFFFFB300,
      ).withValues(alpha: 0.22 + intensity * 0.58)
      ..strokeWidth = 1.6 + intensity * 2.1
      ..strokeCap = StrokeCap.round;
    final rayCount = 6 + (intensity * 8).round();
    for (int i = 0; i < rayCount; i++) {
      final angle = progress * math.pi * 2 + i * math.pi * 2 / rayCount;
      final start =
          center +
          Offset(
            math.cos(angle) * (25 + intensity * 9),
            math.sin(angle) * (25 + intensity * 9),
          );
      final end =
          center +
          Offset(
            math.cos(angle) * (36 + intensity * 19),
            math.sin(angle) * (36 + intensity * 19),
          );
      canvas.drawLine(start, end, rayPaint);
    }
  }

  void _drawSunRaysToPanel(Canvas canvas, Offset sun, Rect panel) {
    final intensity = values.sunIntensity;
    final paint = Paint()
      ..color = const Color(
        0xFFFFD166,
      ).withValues(alpha: 0.22 + intensity * 0.52)
      ..strokeWidth = 2.0 + intensity * 3.0
      ..strokeCap = StrokeCap.round;
    final rayCount = 4 + (intensity * 8).round();
    for (int i = 0; i < rayCount; i++) {
      final t = (i + 1) / (rayCount + 1);
      final target = Offset(
        panel.left + panel.width * t,
        panel.top +
            panel.height *
                (0.2 + 0.08 * math.sin(progress * intensity * 6 + i)),
      );
      final dashProgress = ((progress * intensity) + i * 0.16) % 1;
      final moving = Offset.lerp(sun, target, dashProgress)!;
      canvas.drawLine(sun, target, paint);
      canvas.drawCircle(
        moving,
        2.0 + intensity * 2.2,
        Paint()..color = const Color(0xFFFFF59D),
      );
    }
  }

  void _drawClouds(Canvas canvas, Size size) {
    final cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: values.isStormy ? 0.48 : 0.72);
    for (int i = 0; i < 4; i++) {
      final drift = ((progress * 0.4 + i * 0.23) % 1) * (size.width + 180) - 90;
      final y = size.height * (0.1 + i * 0.06);
      _drawCloud(canvas, Offset(drift, y), 0.75 + i * 0.12, cloudPaint);
    }
  }

  void _drawCloud(Canvas canvas, Offset origin, double scale, Paint paint) {
    canvas.drawCircle(
      origin + Offset(32 * scale, 22 * scale),
      23 * scale,
      paint,
    );
    canvas.drawCircle(
      origin + Offset(58 * scale, 14 * scale),
      30 * scale,
      paint,
    );
    canvas.drawCircle(
      origin + Offset(88 * scale, 24 * scale),
      22 * scale,
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          origin.dx + 20 * scale,
          origin.dy + 22 * scale,
          92 * scale,
          25 * scale,
        ),
        Radius.circular(18 * scale),
      ),
      paint,
    );
  }

  void _drawRain(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.55)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 34; i++) {
      final x = (i * 37 + progress * 180) % (size.width + 40) - 20;
      final y = (i * 53 + progress * 440) % (size.height * 0.62);
      canvas.drawLine(Offset(x, y), Offset(x - 8, y + 18), paint);
    }
  }

  void _drawLightning(Canvas canvas, Size size) {
    if (progress < 0.08 || (progress > 0.52 && progress < 0.59)) {
      final path = Path()
        ..moveTo(size.width * 0.66, size.height * 0.17)
        ..lineTo(size.width * 0.58, size.height * 0.3)
        ..lineTo(size.width * 0.63, size.height * 0.3)
        ..lineTo(size.width * 0.55, size.height * 0.45);
      final paint = Paint()
        ..color = const Color(0xFFFFF176)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, paint);
    }
  }

  void _drawShootingStars(Canvas canvas, Size size) {
    if (progress > 0.3 && progress < 0.6) {
      final t = (progress - 0.3) / 0.3; // 0.0 to 1.0
      final start = Offset(size.width * 0.8, size.height * 0.1);
      final end = start + const Offset(-150, 100);
      final currentPos = Offset.lerp(start, end, t)!;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: (1.0 - t) * 0.8)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(currentPos, currentPos + const Offset(15, -10), paint);
    }
  }

  void _drawMoon(Canvas canvas, Offset center) {
    canvas.drawCircle(
      center,
      28,
      Paint()..color = const Color(0xFFFFFDE7).withValues(alpha: 0.95),
    );
    canvas.drawCircle(
      center + const Offset(11, -8),
      26,
      Paint()..color = const Color(0xFF172554),
    );
  }

  void _drawStars(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (int i = 0; i < 44; i++) {
      final x = ((i * 73) % 100) / 100 * size.width;
      final y = ((i * 41) % 100) / 100 * size.height * 0.48;
      final alpha = 0.25 + 0.65 * ((math.sin(progress * 8 + i) + 1) / 2);
      paint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), 1.1 + (i % 3) * 0.45, paint);
    }
  }

  void _drawLandscape(Canvas canvas, Size size, ScenePoints points) {
    final hillPaint = Paint()
      ..color =
          (values.isDayTime ? const Color(0xFF9FD3B2) : const Color(0xFF1E5B52))
              .withValues(alpha: 0.84);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.63,
        points.groundY - 64,
        size.width * 0.3,
        96,
      ),
      hillPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.12,
        points.groundY - 42,
        size.width * 0.22,
        68,
      ),
      hillPaint,
    );

    final groundPaint = Paint()
      ..color = values.isDayTime
          ? const Color(0xFF74B88A)
          : const Color(0xFF255F51);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, points.groundY, size.width, 34),
        const Radius.circular(0),
      ),
      groundPaint,
    );
    canvas.drawLine(
      Offset(0, points.groundY),
      Offset(size.width, points.groundY),
      Paint()
        ..color = Colors.white.withValues(alpha: values.isDayTime ? 0.75 : 0.25)
        ..strokeWidth = 2,
    );

    _drawTree(canvas, Offset(size.width * 0.04, points.groundY), 0.75);
    _drawTree(canvas, Offset(size.width * 0.96, points.groundY), 0.7);
  }

  void _drawTree(Canvas canvas, Offset base, double scale) {
    final trunk = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 4 * scale
      ..strokeCap = StrokeCap.round;
    final leaves = Paint()..color = const Color(0xFF4CAF50);
    canvas.drawLine(base, base - Offset(0, 42 * scale), trunk);
    canvas.drawCircle(base - Offset(0, 48 * scale), 14 * scale, leaves);
    canvas.drawCircle(
      base - Offset(10 * scale, 34 * scale),
      10 * scale,
      leaves,
    );
    canvas.drawCircle(
      base + Offset(10 * scale, -34 * scale),
      10 * scale,
      leaves,
    );
  }

  void _drawEnergyLines(Canvas canvas, Size size, ScenePoints points) {
    final groundY = points.groundY;
    final paths = [
      EnergyFlow(
        path: _polylinePath([
          points.solarToInverter - const Offset(38, -51),
          Offset(points.solarToInverter.dx - 38, groundY + 30),
          Offset(points.inverterSolarPort.dx, groundY + 30),
          points.inverterSolarPort,
        ]),
        color: AppTheme.primary,
        active: values.isDayTime,
        speed: values.sunIntensity,
      ),
      EnergyFlow(
        path: _polylinePath([
          points.batteryToInverter - const Offset(-29, 0),
          Offset(points.batteryToInverter.dx + 30, groundY + 38),
          Offset(points.inverterBatteryPort.dx, groundY + 38),
          points.inverterBatteryPort,
        ]),
        color: AppTheme.primary,
        active: true,
        reverse: true,
      ),
      EnergyFlow(
        path: _polylinePath([
          points.gridToInverter,
          Offset(points.gridToInverter.dx, groundY + 22),
          Offset(points.inverterGridPort.dx, groundY + 22),
          points.inverterGridPort,
        ]),
        color: values.wapdaLineActive ? AppTheme.primary : AppTheme.error,
        active: values.wapdaLineActive,
      ),
      EnergyFlow(
        path: _polylinePath([
          points.inverterSmartLoadPort,
          Offset(points.inverterSmartLoadPort.dx - 0, groundY - 9),
          Offset(points.smartLoadInput.dx + 1, groundY - 9),
          points.smartLoadInput,
        ]),
        color: AppTheme.primary,
        active: true,
      ),
      EnergyFlow(
        path: _polylinePath([
          points.inverterHeavyLoadPort,
          Offset(points.inverterHeavyLoadPort.dx, points.houseRect.bottom - 35),
          Offset(points.heavyLoadInput.dx - 50, points.houseRect.bottom - 35),
          points.heavyLoadInput - const Offset(10, 0),
        ]),
        color: values.heavyLoadOn ? const Color(0xFF1E88E5) : AppTheme.error,
        active: values.heavyLoadOn,
      ),
    ];

    for (final flow in paths) {
      final linePaint = Paint()
        ..color = flow.color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final sourceGlow = Paint()
        ..color = flow.color.withValues(alpha: flow.active ? 0.12 : 0.08)
        ..strokeWidth = 7
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(flow.path, sourceGlow);
      canvas.drawPath(flow.path, linePaint);
      if (flow.active) {
        _drawMovingDots(
          canvas,
          flow.path,
          flow.color,
          reverse: flow.reverse,
          speed: flow.speed,
        );
      }
    }
  }

  Path _polylinePath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    return path;
  }

  void _drawMovingDots(
    Canvas canvas,
    Path path,
    Color color, {
    bool reverse = false,
    double speed = 1.0,
  }) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final dotPaint = Paint()..color = color.withValues(alpha: 0.95);
    for (final metric in metrics) {
      for (int i = 0; i < 3; i++) {
        double t = ((progress * speed) + i * 0.34) % 1;
        if (reverse) t = 1.0 - t;
        final tangent = metric.getTangentForOffset(metric.length * t);
        if (tangent == null) continue;
        canvas.drawCircle(tangent.position, 3.4, dotPaint);
        canvas.drawCircle(
          tangent.position,
          6.5,
          Paint()..color = color.withValues(alpha: 0.11),
        );
      }
    }
  }

  void _drawSolarPanel(Canvas canvas, Rect rect) {
    final pole = Paint()
      ..color = const Color(0xFF455A64)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      rect.bottomCenter,
      rect.bottomCenter + const Offset(0, 34),
      pole,
    );
    canvas.drawLine(
      rect.bottomCenter + const Offset(-22, 34),
      rect.bottomCenter + const Offset(22, 34),
      pole,
    );

    final panelPath = Path()
      ..moveTo(rect.left, rect.top + rect.height * 0.12)
      ..lineTo(rect.right - 8, rect.top)
      ..lineTo(rect.right, rect.bottom - rect.height * 0.14)
      ..lineTo(rect.left + 9, rect.bottom)
      ..close();
    canvas.drawShadow(
      panelPath,
      Colors.black.withValues(alpha: 0.18),
      6,
      false,
    );
    canvas.drawPath(panelPath, Paint()..color = const Color(0xFF1E3A4A));

    final gridPaint = Paint()
      ..color = AppTheme.primaryLight.withValues(alpha: 0.74)
      ..strokeWidth = 1;
    for (int i = 1; i < 4; i++) {
      final x = rect.left + rect.width * i / 4;
      canvas.drawLine(
        Offset(x, rect.top + 3),
        Offset(x + 7, rect.bottom - 4),
        gridPaint,
      );
    }
    for (int i = 1; i < 3; i++) {
      final y = rect.top + rect.height * i / 3;
      canvas.drawLine(
        Offset(rect.left + 5, y + 5),
        Offset(rect.right - 5, y),
        gridPaint,
      );
    }
  }

  void _drawHome(Canvas canvas, Rect rect) {
    final wallPaint = Paint()..color = const Color(0xFFF0F7F4);
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.08);
    canvas.drawOval(
      Rect.fromLTWH(rect.left + 8, rect.bottom - 7, rect.width - 12, 18),
      shadowPaint,
    );

    final body = Rect.fromLTWH(
      rect.left + rect.width * 0.18,
      rect.top + rect.height * 0.34,
      rect.width * 0.5,
      rect.height * 0.66,
    );
    canvas.drawRect(body, wallPaint);

    final roof = Path()
      ..moveTo(rect.left + rect.width * 0.1, rect.top + rect.height * 0.36)
      ..lineTo(rect.left + rect.width * 0.47, rect.top + rect.height * 0.02)
      ..lineTo(rect.left + rect.width * 0.76, rect.top + rect.height * 0.36)
      ..close();
    canvas.drawPath(roof, Paint()..color = AppTheme.primaryDark);

    final sideRect = Rect.fromLTRB(
      rect.left + rect.width * 0.62,
      rect.top + rect.height * 0.52,
      rect.left + rect.width * 0.86,
      rect.bottom,
    );
    final side = Path()
      ..moveTo(sideRect.left, sideRect.top)
      ..lineTo(sideRect.right, sideRect.top)
      ..lineTo(sideRect.right, sideRect.bottom)
      ..lineTo(sideRect.left, sideRect.bottom)
      ..close();
    canvas.drawPath(side, wallPaint);

    final sideRoof = Path()
      ..moveTo(rect.left + rect.width * 0.58, rect.top + rect.height * 0.5)
      ..lineTo(rect.left + rect.width * 0.72, rect.top + rect.height * 0.36)
      ..lineTo(rect.left + rect.width * 0.91, rect.top + rect.height * 0.5)
      ..lineTo(rect.left + rect.width * 0.86, rect.top + rect.height * 0.56)
      ..lineTo(rect.left + rect.width * 0.72, rect.top + rect.height * 0.44)
      ..lineTo(rect.left + rect.width * 0.62, rect.top + rect.height * 0.56)
      ..close();
    canvas.drawPath(sideRoof, Paint()..color = AppTheme.primaryDark);

    final window = Paint()..color = AppTheme.sunGlow;
    _drawWindow(
      canvas,
      Rect.fromLTWH(body.left + 18, body.top + 26, 14, 30),
      window,
    );
    _drawWindow(
      canvas,
      Rect.fromLTWH(body.left + 46, body.top + 26, 14, 30),
      window,
    );
    _drawWindow(
      canvas,
      Rect.fromLTWH(sideRect.left + 24, sideRect.top + 38, 16, 26),
      window,
    );

    final acRect = Rect.fromLTWH(rect.right - 35, rect.bottom - 45, 24, 18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(acRect, const Radius.circular(2)),
      Paint()..color = const Color(0xFFCFD8DC),
    );
    canvas.drawRect(
      Rect.fromLTWH(acRect.left + 4, acRect.top + 4, 16, 10),
      Paint()..color = const Color(0xFF90A4AE),
    );
    // AC Fan
    canvas.drawCircle(
      Offset(acRect.left + 8, acRect.top + 9),
      6,
      Paint()
        ..color = const Color(0xFF546E7A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(acRect.right - 10, acRect.top + 5 + i * 4),
        Offset(acRect.right - 4, acRect.top + 5 + i * 4),
        Paint()
          ..color = const Color(0xFF546E7A)
          ..strokeWidth = 1,
      );
    }
  }

  void _drawWindow(Canvas canvas, Rect rect, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      paint,
    );
    canvas.drawLine(
      rect.centerLeft,
      rect.centerRight,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
    canvas.drawLine(
      rect.topCenter,
      rect.bottomCenter,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  void _drawBattery(Canvas canvas, Rect rect) {
    final body = RRect.fromRectAndRadius(rect, const Radius.circular(7));
    canvas.drawRRect(body, Paint()..color = const Color(0xFFECEFF1));
    canvas.drawRRect(
      body,
      Paint()
        ..color = const Color(0xFF78909C)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.left + 8, rect.top - 4, rect.width - 16, 5),
      Paint()..color = const Color(0xFF455A64),
    );
    for (int i = 0; i < 4; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            rect.left + 10 + i * 10,
            rect.top + 12,
            7,
            rect.height - 22,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = AppTheme.primary,
      );
    }
  }

  void _drawGrid(Canvas canvas, Offset base, double groundY) {
    final polePaint = Paint()
      ..color = const Color(0xFF37474F)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final wirePaint = Paint()
      ..color = const Color(0xFF455A64)
      ..strokeWidth = 1.6;
    final top = base - const Offset(0, 116);
    canvas.drawLine(base, top, polePaint);
    canvas.drawLine(
      top + const Offset(-24, 12),
      top + const Offset(24, 12),
      polePaint,
    );
    canvas.drawLine(
      top + const Offset(-20, 12),
      top + const Offset(-45, 26),
      wirePaint,
    );
    canvas.drawLine(
      top + const Offset(20, 12),
      top + const Offset(45, 26),
      wirePaint,
    );
    canvas.drawLine(
      top + const Offset(-14, 0),
      top + const Offset(14, 0),
      wirePaint,
    );
    final Color indicatorColor = values.wapdaAvailable ? const Color(0xFF00C853) : const Color(0xFFD50000);
    final indicatorPaint = Paint()
      ..color = indicatorColor
      ..style = PaintingStyle.fill;
    
    // Left light
    canvas.drawCircle(
      top + const Offset(-18, 12),
      3.0,
      indicatorPaint,
    );
    canvas.drawCircle(
      top + const Offset(-18, 12),
      6.0,
      Paint()
        ..color = indicatorColor.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
    );

    // Right light
    canvas.drawCircle(
      top + const Offset(18, 12),
      3.0,
      indicatorPaint,
    );
    canvas.drawCircle(
      top + const Offset(18, 12),
      6.0,
      Paint()
        ..color = indicatorColor.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
    );
  }

  void _drawInverter(Canvas canvas, Offset center) {
    final rect = Rect.fromCenter(center: center, width: 54, height: 70);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()
        ..color = const Color(0xFF263238)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.left + 11, rect.top + 17, rect.width - 22, 28),
      Paint()..color = const Color(0xFF455A64),
    );
    canvas.drawCircle(
      center + const Offset(0, 18),
      5,
      Paint()..color = AppTheme.primary,
    );
  }

  @override
  bool shouldRepaint(EnergyScenePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.values != values;
  }
}

class ScenePoints {
  final Size size;

  ScenePoints(this.size);

  bool get isCompact => size.width < 380;
  double get groundY => size.height - 120;
  double get sourceY => groundY - 78;
  double get sourceBusY => groundY + 34;
  double get loadBusY => groundY + 12;

  Offset get inverter => Offset(size.width * 0.42, groundY + 58);
  Rect get solarPanel => Rect.fromCenter(
    center: Offset(size.width * 0.13, sourceY + 16),
    width: isCompact ? 72 : 84,
    height: isCompact ? 38 : 44,
  );
  Rect get batteryRect => Rect.fromCenter(
    center: Offset(size.width * 0.72, sourceY + 26),
    width: isCompact ? 50 : 58,
    height: isCompact ? 38 : 44,
  );
  Offset get gridPoleBase => Offset(size.width * 0.9, groundY);
  Rect get houseRect => Rect.fromCenter(
    center: Offset(size.width * 0.42, groundY - 76),
    width: isCompact ? 162 : 194,
    height: isCompact ? 120 : 142,
  );
  Offset get solarToInverter =>
      Offset(solarPanel.right - 4, solarPanel.center.dy + 8);
  Offset get inverterSolarPort => inverter + const Offset(-25, -14);
  Offset get inverterGridPort => inverter + const Offset(25, -8);
  Offset get inverterBatteryPort => inverter + const Offset(25, 18);
  Offset get inverterSmartLoadPort => inverter + const Offset(-12, 35);
  Offset get inverterHeavyLoadPort => inverter + const Offset(12, 35);
  Offset get batteryToInverter =>
      Offset(batteryRect.left + 2, batteryRect.center.dy + 12);
  Offset get batteryToInverterRight =>
      Offset(batteryRect.right - 2, batteryRect.bottom - 4);
  Offset get gridToInverter => Offset(gridPoleBase.dx, groundY);
  Offset get smartLoadInput => Offset(
    houseRect.center.dx - houseRect.width * 0.18,
    houseRect.bottom - 4,
  );
  Offset get heavyLoadInput =>
      Offset(houseRect.right - 23, houseRect.bottom - 36);
}

class EnergyFlow {
  final Path path;
  final Color color;
  final bool active;
  final bool reverse;
  final double speed;

  const EnergyFlow({
    required this.path,
    required this.color,
    required this.active,
    this.reverse = false,
    this.speed = 1.0,
  });
}

class EnergyValues {
  final double powerKw;
  final double productionKw;
  final double consumptionKw;
  final double batteryKw;
  final double gridKw;
  final int ldrValue;
  final double gridVoltage;
  final double sunIntensity;
  final bool isDayTime;
  final bool isSunny;
  final bool isStormy;
  final bool wapdaLineActive;
  final bool wapdaAvailable;
  final bool heavyLoadOn;
  final String lastUpdateText;

  const EnergyValues({
    required this.powerKw,
    required this.productionKw,
    required this.consumptionKw,
    required this.batteryKw,
    required this.gridKw,
    required this.ldrValue,
    required this.gridVoltage,
    required this.sunIntensity,
    required this.isDayTime,
    required this.isSunny,
    required this.isStormy,
    required this.wapdaLineActive,
    required this.wapdaAvailable,
    required this.heavyLoadOn,
    required this.lastUpdateText,
  });

  factory EnergyValues.fromData(EnergyData? data) {
    final powerKw = data == null ? 0.0 : math.max<double>(0, data.power / 1000);
    final hasPower = powerKw > 0;
    final gridActive = data == null
        ? false
        : data.wapdaAvailable && data.wapdaRelayState;
    final heavyLoad = data == null ? false : data.heavyLoadState;
    final ldr = data?.ldrValue ?? 0;
    final isDayTime = data?.isDayTime ?? true;
    final isSunny = isDayTime && (data?.isSunny ?? true);
    final sunIntensity = isDayTime
        ? (ldr <= 0 ? 0.75 : (ldr / 3000).clamp(0.08, 1.0).toDouble())
        : 0.0;
    final formatter = DateFormat('yyyy/MM/dd HH:mm:ss');

    return EnergyValues(
      powerKw: powerKw,
      productionKw: powerKw,
      consumptionKw: data == null ? 0.0 : powerKw,
      batteryKw: data == null
          ? 0.0
          : hasPower
          ? powerKw * (heavyLoad ? 0.42 : 0.24)
          : 0,
      gridKw: data == null
          ? 0.0
          : gridActive
          ? math.max(0.0, powerKw * 0.48)
          : 0,
      ldrValue: ldr,
      gridVoltage: data?.voltage ?? 0.0,
      sunIntensity: sunIntensity,
      isDayTime: isDayTime,
      isSunny: isSunny,
      isStormy: isDayTime && !isSunny && ldr < 1200,
      wapdaLineActive: gridActive,
      wapdaAvailable: data?.wapdaAvailable ?? false,
      heavyLoadOn: heavyLoad,
      lastUpdateText: data == null
          ? 'Waiting for data...'
          : '${formatter.format(data.lastUpdate.toLocal())} local',
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EnergyValues &&
        powerKw == other.powerKw &&
        productionKw == other.productionKw &&
        consumptionKw == other.consumptionKw &&
        batteryKw == other.batteryKw &&
        gridKw == other.gridKw &&
        ldrValue == other.ldrValue &&
        gridVoltage == other.gridVoltage &&
        sunIntensity == other.sunIntensity &&
        isDayTime == other.isDayTime &&
        isSunny == other.isSunny &&
        isStormy == other.isStormy &&
        wapdaLineActive == other.wapdaLineActive &&
        wapdaAvailable == other.wapdaAvailable &&
        heavyLoadOn == other.heavyLoadOn &&
        lastUpdateText == other.lastUpdateText;
  }

  @override
  int get hashCode => Object.hash(
    powerKw,
    productionKw,
    consumptionKw,
    batteryKw,
    gridKw,
    ldrValue,
    gridVoltage,
    sunIntensity,
    isDayTime,
    isSunny,
    isStormy,
    wapdaLineActive,
    wapdaAvailable,
    heavyLoadOn,
    lastUpdateText,
  );
}

String formatNumber(double value) {
  if (value >= 100 || value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}
