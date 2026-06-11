import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:smartsolar/utils/theme.dart';
import 'package:smartsolar/widgets/energy_flow_widget.dart';

class WhlEnergyFlowWidget extends StatefulWidget {
  final EnergyValues values;

  const WhlEnergyFlowWidget({super.key, required this.values});

  @override
  State<WhlEnergyFlowWidget> createState() => _WhlEnergyFlowWidgetState();
}

class _WhlEnergyFlowWidgetState extends State<WhlEnergyFlowWidget>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _time = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (mounted) {
        setState(() {
          _time = elapsed.inMilliseconds / 2800.0;
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
    return WhlEnergyScene(progress: _time, values: widget.values);
  }
}

class WhlEnergyScene extends StatelessWidget {
  final double progress;
  final EnergyValues values;

  const WhlEnergyScene({
    super.key,
    required this.progress,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final scene = WhlSceneLayout(Size(width, height));

        final double solarRadius = 40 * scene.S;
        final bool homeLoadOn = values.heavyLoadOn;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Custom Paint for Background, House, Grid Tower, and Lines
            Positioned.fill(
              child: CustomPaint(
                painter: WhlScenePainter(
                  progress: progress,
                  values: values,
                  isDark: isDark,
                  layout: scene,
                ),
              ),
            ),

            // 1. Home Load Status Bubble (replaces solar production / Home WAPDA bubble)
            Positioned(
              left: scene.solarBubble.dx + 70 - solarRadius,
              top: scene.solarBubble.dy - solarRadius,
              child: Container(
                width: solarRadius * 2,
                height: solarRadius * 2,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: homeLoadOn ? AppTheme.accent : AppTheme.error,
                    width: 3 * scene.S,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (homeLoadOn ? AppTheme.accent : AppTheme.error)
                          .withValues(alpha: isDark ? 0.3 : 0.15),
                      blurRadius: 10 * scene.S,
                      spreadRadius: 1.5 * scene.S,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Home',
                        style: TextStyle(
                          fontSize: 10 * scene.S,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppTheme.textSecondary
                              : AppTheme.textMuted,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'Load',
                        style: TextStyle(
                          fontSize: 10 * scene.S,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppTheme.textSecondary
                              : AppTheme.textMuted,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        homeLoadOn ? 'ON' : 'OFF',
                        style: TextStyle(
                          fontSize: 16 * scene.S,
                          fontWeight: FontWeight.w900,
                          color: homeLoadOn ? AppTheme.accent : AppTheme.error,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class WhlScenePainter extends CustomPainter {
  final double progress;
  final EnergyValues values;
  final bool isDark;
  final WhlSceneLayout layout;

  WhlScenePainter({
    required this.progress,
    required this.values,
    required this.isDark,
    required this.layout,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawSkyGradient(canvas, size);
    if (values.isDayTime) {
      _drawSunAndRays(canvas, size);
    } else {
      _drawNightSky(canvas, size);
    }
    _drawClouds(canvas, size);
    _drawLandscape(canvas, size);
    _drawHouseOutline(canvas);
    _drawSolarPanels(canvas);
    if (values.isDayTime) {
      _drawSunAndRays(canvas, size);
    }
    _drawDoorAndWindow(canvas);
    _drawInverter(canvas);
    _drawGridTower(canvas);
    _drawBattery(canvas);
    _drawRoadAndTraffic(canvas, size);
    _drawEnergyLines(canvas);
  }

  void _drawSkyGradient(Canvas canvas, Size size) {
    // Use values.isDayTime (from ESP32/RTC) for sky color, NOT isDark (app theme)
    final List<Color> colors;
    if (!values.isDayTime) {
      // Night sky — always dark regardless of app theme
      colors = const [Color(0xFF030B0D), Color(0xFF071518), Color(0xFF0F2528)];
    } else if (isDark) {
      // Daytime but dark theme — muted teal sky
      colors = const [Color(0xFF0D3B3E), Color(0xFF0F4A4D), Color(0xFF0F2528)];
    } else {
      // Daytime light theme — bright cyan sky
      colors = const [Color(0xFF80DEEA), Color(0xFFE0F7FA), Colors.white];
    }

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Offset.zero & Size(size.width, layout.groundY));

    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, layout.groundY), paint);
  }

  void _drawClouds(Canvas canvas, Size size) {
    final cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.08 : 0.65);

    // Render 3 drifting clouds in the sky
    for (int i = 0; i < 3; i++) {
      final drift =
          ((progress * 0.12 + i * 0.35) % 1) * (size.width + 120 * layout.S) -
          60 * layout.S;
      final y = size.height * (0.04 + i * 0.06);
      final scale = (0.45 + i * 0.12) * layout.S;
      _drawSingleCloud(canvas, Offset(drift, y), scale, cloudPaint);
    }
  }

  void _drawSingleCloud(
    Canvas canvas,
    Offset origin,
    double scale,
    Paint paint,
  ) {
    canvas.drawCircle(
      origin + Offset(20 * scale, 15 * scale),
      15 * scale,
      paint,
    );
    canvas.drawCircle(
      origin + Offset(38 * scale, 10 * scale),
      20 * scale,
      paint,
    );
    canvas.drawCircle(
      origin + Offset(58 * scale, 15 * scale),
      14 * scale,
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          origin.dx + 10 * scale,
          origin.dy + 15 * scale,
          60 * scale,
          15 * scale,
        ),
        Radius.circular(10 * scale),
      ),
      paint,
    );
  }

  void _drawLandscape(Canvas canvas, Size size) {
    // Draw underground section
    final undergroundColors = isDark
        ? const [Color(0xFF071518), Color(0xFF030B0D)]
        : const [Color(0xFFF3F4F6), Color(0xFFE5E7EB)];

    final undergroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: undergroundColors,
      ).createShader(Rect.fromLTRB(0, layout.groundY, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTRB(0, layout.groundY, size.width, size.height),
      undergroundPaint,
    );

    // Draw horizon line
    final linePaint = Paint()
      ..color = isDark ? const Color(0xFF1E3A3A) : const Color(0xFFB0BEC5)
      ..strokeWidth = 1.8 * layout.S;

    canvas.drawLine(
      Offset(0, layout.groundY),
      Offset(size.width, layout.groundY),
      linePaint,
    );

    // Realistic trees on the horizon
    final treePositions = [
      layout.houseX - 24.0 * layout.S,
      layout.houseX - 10.0 * layout.S,
      layout.houseX + layout.houseWidth + 15.0 * layout.S,
      layout.houseX + layout.houseWidth + 28.0 * layout.S,
      layout.towerX - 22.0 * layout.S,
      layout.towerX + 22.0 * layout.S,
    ];
    final treeScales = [1.2, 0.95, 1.35, 1.05, 1.15, 0.9];

    for (int i = 0; i < treePositions.length; i++) {
      _drawRealisticTree(
        canvas,
        treePositions[i],
        layout.groundY,
        treeScales[i],
      );
    }

    // Grass blades along the horizon
    _drawGrass(canvas, size);
  }

  void _drawRealisticTree(
    Canvas canvas,
    double x,
    double groundY,
    double scale,
  ) {
    final s = scale * layout.S;

    // 1. Trunk
    final trunkPaint = Paint()
      ..color = isDark ? const Color(0xFF2D1B10) : const Color(0xFF5C4033)
      ..style = PaintingStyle.fill;

    final trunkWidth = 3.6 * s;
    final trunkHeight = 15.0 * s;
    final trunkRect = Rect.fromLTWH(
      x - trunkWidth / 2,
      groundY - trunkHeight,
      trunkWidth,
      trunkHeight,
    );
    canvas.drawRect(trunkRect, trunkPaint);

    // 2. Canopy layers (draw three overlapping circles of leaves in nice greens/teal/forest greens)
    final mainGreen = isDark
        ? const Color(0xFF0F766E)
        : const Color(0xFF107B4F);
    final darkGreen = isDark
        ? const Color(0xFF115E59)
        : const Color(0xFF0C5C3A);
    final brightGreen = isDark
        ? const Color(0xFF14B8A6)
        : const Color(0xFF1EA068);

    // Layer 1 (Bottom, largest)
    final r1 = 11.0 * s;
    final cy1 = groundY - trunkHeight - 2 * s;
    canvas.drawCircle(
      Offset(x, cy1),
      r1,
      Paint()
        ..color = darkGreen
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(x - 1.5 * s, cy1),
      r1 * 0.9,
      Paint()
        ..color = mainGreen
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(x + 1.5 * s, cy1 - 1 * s),
      r1 * 0.65,
      Paint()
        ..color = brightGreen
        ..style = PaintingStyle.fill,
    );

    // Layer 2 (Middle)
    final r2 = 8.5 * s;
    final cy2 = cy1 - 8.5 * s;
    canvas.drawCircle(
      Offset(x, cy2),
      r2,
      Paint()
        ..color = darkGreen
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(x - 1.2 * s, cy2),
      r2 * 0.9,
      Paint()
        ..color = mainGreen
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(x + 1.2 * s, cy2 - 0.8 * s),
      r2 * 0.65,
      Paint()
        ..color = brightGreen
        ..style = PaintingStyle.fill,
    );

    // Layer 3 (Top, smallest)
    final r3 = 6.5 * s;
    final cy3 = cy2 - 6.5 * s;
    canvas.drawCircle(
      Offset(x, cy3),
      r3,
      Paint()
        ..color = mainGreen
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(x + 1 * s, cy3 - 0.5 * s),
      r3 * 0.65,
      Paint()
        ..color = brightGreen
        ..style = PaintingStyle.fill,
    );
  }

  void _drawGrass(Canvas canvas, Size size) {
    final grassColor = isDark
        ? const Color(0xFF064E3B)
        : const Color(0xFF16A34A);
    final grassPaint = Paint()
      ..color = grassColor
      ..strokeWidth = 1.2 * layout.S
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final highlightPaint = Paint()
      ..color = isDark
          ? const Color(0xFF065F46).withValues(alpha: 0.7)
          : const Color(0xFF4ADE80).withValues(alpha: 0.8)
      ..strokeWidth = 0.8 * layout.S
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const spacing = 7.0;
    final groundY = layout.groundY;
    var x = 0.0;
    var i = 0;
    while (x < size.width) {
      final phase = (i % 5);
      final h = (5 + phase * 1.5) * layout.S;
      final lean = (phase - 2) * 1.8 * layout.S;

      canvas.drawLine(
        Offset(x, groundY),
        Offset(x - 1.5 * layout.S + lean, groundY - h),
        grassPaint,
      );
      canvas.drawLine(
        Offset(x + 2.5 * layout.S, groundY),
        Offset(x + 2.5 * layout.S + lean * 0.4, groundY - h * 1.25),
        highlightPaint,
      );
      canvas.drawLine(
        Offset(x + 5.0 * layout.S, groundY),
        Offset(x + 5.0 * layout.S + lean, groundY - h * 0.85),
        grassPaint,
      );

      x += spacing * layout.S;
      i++;
    }
  }

  void _drawHouseOutline(Canvas canvas) {
    final strokeColor = isDark
        ? AppTheme.primaryLight.withValues(alpha: 0.5)
        : const Color(0xFF263238);

    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 1.8 * layout.S
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    // 1. Front Wall (facing us on the left/center)
    final frontPath = Path()
      ..moveTo(layout.houseX, layout.groundY)
      ..lineTo(layout.houseX, layout.groundY - layout.wallHeight)
      ..lineTo(
        layout.houseX + layout.frontWidth,
        layout.groundY - layout.wallHeight,
      )
      ..lineTo(layout.houseX + layout.frontWidth, layout.groundY)
      ..close();

    canvas.drawPath(
      frontPath,
      Paint()
        ..color = isDark ? AppTheme.cardDark : Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(frontPath, strokePaint);

    // 2. Side Wall (Gable End facing right)
    final sidePath = Path()
      ..moveTo(layout.houseX + layout.frontWidth, layout.groundY)
      ..lineTo(
        layout.houseX + layout.frontWidth,
        layout.groundY - layout.wallHeight,
      )
      ..lineTo(
        layout.houseX + layout.frontWidth + layout.sideWidth * 0.5,
        layout.groundY - layout.houseHeight,
      )
      ..lineTo(
        layout.houseX + layout.houseWidth,
        layout.groundY - layout.wallHeight * 0.88,
      )
      ..lineTo(layout.houseX + layout.houseWidth, layout.groundY)
      ..close();

    // Use a slightly darker color for side wall to create realistic 3D shadowing
    final sideBgColor = isDark
        ? const Color(0xFF0F1E21)
        : const Color(0xFFF1F5F9);
    canvas.drawPath(
      sidePath,
      Paint()
        ..color = sideBgColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(sidePath, strokePaint);
  }

  void _drawSolarPanels(Canvas canvas) {
    // Front roof slope is a parallelogram slanted towards us
    final strokeColor = isDark
        ? AppTheme.primaryLight.withValues(alpha: 0.5)
        : const Color(0xFF263238);

    final p1 = Offset(
      layout.houseX + layout.sideWidth * 0.5,
      layout.groundY - layout.houseHeight,
    );
    final p2 = Offset(
      layout.houseX + layout.frontWidth + layout.sideWidth * 0.5,
      layout.groundY - layout.houseHeight,
    );
    final p3 = Offset(
      layout.houseX + layout.frontWidth,
      layout.groundY - layout.wallHeight,
    );
    final p4 = Offset(layout.houseX, layout.groundY - layout.wallHeight);

    final roofPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();

    // Draw dark slate roof tiles
    canvas.drawPath(
      roofPath,
      Paint()
        ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFF475569)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      roofPath,
      Paint()
        ..color = strokeColor
        ..strokeWidth = 1.8 * layout.S
        ..style = PaintingStyle.stroke,
    );

    // Draw the solar panel array on this front roof slope
    // It's a slightly inset parallelogram
    final t1 = layout.solarT1;
    final t2 = layout.solarT2;
    final t3 = layout.solarT3;
    final t4 = layout.solarT4;

    final panelPath = Path()
      ..moveTo(t1.dx, t1.dy)
      ..lineTo(t2.dx, t2.dy)
      ..lineTo(t3.dx, t3.dy)
      ..lineTo(t4.dx, t4.dy)
      ..close();

    canvas.drawPath(
      panelPath,
      Paint()
        ..color = const Color(0xFF0F172A)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      panelPath,
      Paint()
        ..color = const Color(0xFF64748B)
        ..strokeWidth = 1.2 * layout.S
        ..style = PaintingStyle.stroke,
    );

    // Grid cell lines inside the panel (3 horizontal segments, 4 vertical segments)
    final gridPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 1.0 * layout.S;

    // Horizontal dividers
    for (int i = 1; i <= 2; i++) {
      final ratio = i / 3.0;
      final start = Offset.lerp(t1, t4, ratio)!;
      final end = Offset.lerp(t2, t3, ratio)!;
      canvas.drawLine(start, end, gridPaint);
    }

    // Slanted vertical dividers
    for (int i = 1; i <= 3; i++) {
      final ratio = i / 4.0;
      final start = Offset.lerp(t1, t2, ratio)!;
      final end = Offset.lerp(t4, t3, ratio)!;
      canvas.drawLine(start, end, gridPaint);
    }
  }

  void _drawDoorAndWindow(Canvas canvas) {
    final strokeColor = isDark
        ? AppTheme.primaryLight.withValues(alpha: 0.5)
        : const Color(0xFF263238);

    final linePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 1.4 * layout.S
      ..style = PaintingStyle.stroke;

    // 1. Door
    canvas.drawRect(layout.doorRect, linePaint);
    // Door knob (moved to the left side of the door now)
    canvas.drawCircle(
      Offset(
        layout.doorRect.left + 3 * layout.S,
        layout.doorRect.top + layout.doorRect.height / 2,
      ),
      1.2 * layout.S,
      Paint()..color = strokeColor,
    );

    // 2. Window (with glowing lightbulb)
    final bool isBulbGlowing =
        values.heavyLoadOn && (values.isDayTime || values.wapdaLineActive);
    final winBgColor = isBulbGlowing
        ? const Color(0xFFFEF08A).withValues(alpha: 0.8)
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFECEFF1));

    canvas.drawRect(
      layout.windowRect,
      Paint()
        ..color = winBgColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(layout.windowRect, linePaint);

    // Small bulb hanging in window
    final bulbCenter = Offset(
      layout.windowRect.center.dx,
      layout.windowRect.top + 8 * layout.S,
    );
    final bulbPaint = Paint()
      ..color = isBulbGlowing
          ? const Color(0xFFFACC15)
          : const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;

    if (isBulbGlowing) {
      canvas.drawCircle(
        bulbCenter,
        8 * layout.S,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  const Color(0xFFFACC15).withValues(alpha: 0.35),
                  const Color(0xFFFACC15).withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromCircle(center: bulbCenter, radius: 8 * layout.S),
              ),
      );
    }

    canvas.drawCircle(bulbCenter, 3.0 * layout.S, bulbPaint);
    canvas.drawRect(
      Rect.fromCenter(
        center: bulbCenter + Offset(0, 3 * layout.S),
        width: 2.0 * layout.S,
        height: 2.5 * layout.S,
      ),
      Paint()..color = const Color(0xFF475569),
    );
  }

  void _drawInverter(Canvas canvas) {
    final strokeColor = isDark
        ? AppTheme.primaryLight.withValues(alpha: 0.5)
        : const Color(0xFF263238);

    // Make the inverter vertical and sleek, width frontWidth * 0.24, height wallHeight * 0.38
    final rect = Rect.fromCenter(
      center: layout.inverter,
      width: layout.frontWidth * 0.24,
      height: layout.wallHeight * 0.38,
    );

    // Background of inverter (premium clean white/gray box)
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(4 * layout.S)),
      Paint()
        ..color = isDark ? const Color(0xFF1E293B) : Colors.white
        ..style = PaintingStyle.fill,
    );

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(4 * layout.S)),
      Paint()
        ..color = strokeColor
        ..strokeWidth = 1.4 * layout.S
        ..style = PaintingStyle.stroke,
    );

    // 1. Sleek Top Glass Screen Panel (dark grey rounded rect)
    final screenRect = Rect.fromLTWH(
      rect.left + 2.5 * layout.S,
      rect.top + 3 * layout.S,
      rect.width - 5 * layout.S,
      rect.height * 0.3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(screenRect, Radius.circular(2.5 * layout.S)),
      Paint()..color = const Color(0xFF0F172A),
    );

    // Glowing LED status indicator inside the screen panel
    // A small glowing green LED if active, otherwise orange or blue
    final ledCenter = Offset(
      screenRect.left + 6 * layout.S,
      screenRect.center.dy,
    );
    final ledPaint = Paint()
      ..color = values.wapdaLineActive ? AppTheme.success : AppTheme.error
      ..style = PaintingStyle.fill;

    // Led glow
    canvas.drawCircle(
      ledCenter,
      3.5 * layout.S,
      Paint()
        ..color = (values.wapdaLineActive ? AppTheme.success : AppTheme.error)
            .withValues(alpha: 0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0 * layout.S),
    );
    canvas.drawCircle(ledCenter, 1.5 * layout.S, ledPaint);

    // Tiny digital graphic wave next to the LED
    final wavePaint = Paint()
      ..color = AppTheme.success.withValues(alpha: 0.8)
      ..strokeWidth = 0.8 * layout.S
      ..style = PaintingStyle.stroke;
    final wavePath = Path()
      ..moveTo(
        screenRect.left + 10 * layout.S,
        screenRect.center.dy + 2 * layout.S,
      )
      ..lineTo(
        screenRect.left + 15 * layout.S,
        screenRect.center.dy - 2 * layout.S,
      )
      ..lineTo(
        screenRect.left + 20 * layout.S,
        screenRect.center.dy + 2 * layout.S,
      )
      ..lineTo(
        screenRect.left + 23 * layout.S,
        screenRect.center.dy - 2 * layout.S,
      );
    canvas.drawPath(wavePath, wavePaint);

    // 2. Horizontal Metallic Heat-Sink Vents/Lines at the bottom
    final ventsPaint = Paint()
      ..color = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)
      ..strokeWidth = 1.0 * layout.S
      ..strokeCap = StrokeCap.round;

    final startY = rect.top + rect.height * 0.5;
    final spacing = 4.0 * layout.S;
    for (int i = 0; i < 4; i++) {
      final y = startY + i * spacing;
      canvas.drawLine(
        Offset(rect.left + 5 * layout.S, y),
        Offset(rect.right - 5 * layout.S, y),
        ventsPaint,
      );
    }
  }

  void _drawGridTower(Canvas canvas) {
    final strokeColor = isDark
        ? AppTheme.primaryLight.withValues(alpha: 0.5)
        : const Color(0xFF263238);

    final towerPaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 1.4 * layout.S
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final groundY = layout.groundY;
    final tx = layout.towerX;
    final topY = layout.towerTopY;

    // Outer legs
    canvas.drawLine(
      Offset(tx - 10 * layout.S, groundY),
      Offset(tx - 3 * layout.S, topY),
      towerPaint,
    );
    canvas.drawLine(
      Offset(tx + 10 * layout.S, groundY),
      Offset(tx + 3 * layout.S, topY),
      towerPaint,
    );

    // Horizontal struts
    final strutsY = [
      groundY - (groundY - topY) * 0.33,
      groundY - (groundY - topY) * 0.66,
      topY,
    ];

    for (final sy in strutsY) {
      final ratio = (groundY - sy) / (groundY - topY);
      final w = (10.0 - ratio * 7.0) * layout.S;
      canvas.drawLine(Offset(tx - w, sy), Offset(tx + w, sy), towerPaint);
    }

    // Diagonal X cross struts
    canvas.drawLine(
      Offset(tx - 10 * layout.S, groundY),
      Offset(tx + 7.7 * layout.S, strutsY[0]),
      towerPaint,
    );
    canvas.drawLine(
      Offset(tx + 10 * layout.S, groundY),
      Offset(tx - 7.7 * layout.S, strutsY[0]),
      towerPaint,
    );

    canvas.drawLine(
      Offset(tx - 7.7 * layout.S, strutsY[0]),
      Offset(tx + 5.4 * layout.S, strutsY[1]),
      towerPaint,
    );
    canvas.drawLine(
      Offset(tx + 7.7 * layout.S, strutsY[0]),
      Offset(tx - 5.4 * layout.S, strutsY[1]),
      towerPaint,
    );

    canvas.drawLine(
      Offset(tx - 5.4 * layout.S, strutsY[1]),
      Offset(tx + 3.0 * layout.S, strutsY[2]),
      towerPaint,
    );
    canvas.drawLine(
      Offset(tx + 5.4 * layout.S, strutsY[1]),
      Offset(tx - 3.0 * layout.S, strutsY[2]),
      towerPaint,
    );

    // Top cross-arms
    canvas.drawLine(
      Offset(tx - 15 * layout.S, topY + 6 * layout.S),
      Offset(tx + 15 * layout.S, topY + 6 * layout.S),
      towerPaint,
    );
    canvas.drawLine(
      Offset(tx - 11 * layout.S, topY + 16 * layout.S),
      Offset(tx + 11 * layout.S, topY + 16 * layout.S),
      towerPaint,
    );

    // Two small indicator lights (left and right of the pole/tower) that turn green when WAPDA available
    final bool mainGridOn = values.wapdaAvailable;
    final Color indicatorColor = mainGridOn
        ? const Color(0xFF00C853)
        : const Color(0xFFD50000);
    final indicatorPaint = Paint()
      ..color = indicatorColor
      ..style = PaintingStyle.fill;

    // Left light
    canvas.drawCircle(
      Offset(tx - 15 * layout.S, topY + 6 * layout.S),
      3.0 * layout.S,
      indicatorPaint,
    );
    // Left light glow
    canvas.drawCircle(
      Offset(tx - 15 * layout.S, topY + 6 * layout.S),
      6.0 * layout.S,
      Paint()
        ..color = indicatorColor.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0 * layout.S),
    );

    // Right light
    canvas.drawCircle(
      Offset(tx + 15 * layout.S, topY + 6 * layout.S),
      3.0 * layout.S,
      indicatorPaint,
    );
    // Right light glow
    canvas.drawCircle(
      Offset(tx + 15 * layout.S, topY + 6 * layout.S),
      6.0 * layout.S,
      Paint()
        ..color = indicatorColor.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0 * layout.S),
    );
  }

  void _drawBattery(Canvas canvas) {
    final rect = layout.batteryRect;

    // Body
    final body = RRect.fromRectAndRadius(rect, Radius.circular(4 * layout.S));
    canvas.drawRRect(
      body,
      Paint()
        ..color = isDark ? AppTheme.cardDarkAlt : Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      body,
      Paint()
        ..color = AppTheme.success
        ..strokeWidth = 1.8 * layout.S
        ..style = PaintingStyle.stroke,
    );

    // Cap
    canvas.drawRect(
      Rect.fromLTWH(
        rect.left + 8 * layout.S,
        rect.top - 2.5 * layout.S,
        rect.width - 16 * layout.S,
        3.5 * layout.S,
      ),
      Paint()..color = AppTheme.success,
    );

    // Charging level
    final fillRatio = (0.55 + (values.ldrValue / 4000) * 0.35).clamp(0.2, 0.95);
    final fillHeight = (rect.height - 6 * layout.S) * fillRatio;
    final fillRect = Rect.fromLTWH(
      rect.left + 2.5 * layout.S,
      rect.bottom - 2.5 * layout.S - fillHeight,
      rect.width - 5 * layout.S,
      fillHeight,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(fillRect, Radius.circular(1.5 * layout.S)),
      Paint()..color = AppTheme.success.withValues(alpha: 0.85),
    );

    // Lightning bolt icon
    final boltPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final bc = rect.center;
    final bS = layout.S;
    final boltPath = Path()
      ..moveTo(bc.dx + 1.0 * bS, bc.dy - 6.5 * bS)
      ..lineTo(bc.dx - 3.5 * bS, bc.dy + 1.0 * bS)
      ..lineTo(bc.dx - 1.0 * bS, bc.dy + 1.0 * bS)
      ..lineTo(bc.dx - 1.8 * bS, bc.dy + 6.5 * bS)
      ..lineTo(bc.dx + 3.5 * bS, bc.dy - 1.0 * bS)
      ..lineTo(bc.dx + 1.0 * bS, bc.dy - 1.0 * bS)
      ..close();

    canvas.drawPath(boltPath, boltPaint);
  }

  void _drawSunAndRays(Canvas canvas, Size size) {
    // Sun on the LEFT side of the screen so rays fall onto the solar panel
    final sunCenter = Offset(size.width * 0.12, 40 * layout.S);
    final sunRadius = 24 * layout.S;

    // 1. Draw Sun Glow
    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFFFD166).withValues(alpha: 0.35),
              const Color(0xFFFFD166).withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(center: sunCenter, radius: sunRadius * 2.6),
          );
    canvas.drawCircle(sunCenter, sunRadius * 2.6, glowPaint);

    // 2. Draw Sun Body
    final sunPaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(sunCenter, sunRadius, sunPaint);

    // 3. Draw Rays falling directly on the solar panel
    final rayPaint = Paint()
      ..color = const Color(0xFFFFD166).withValues(alpha: 0.68)
      ..strokeWidth = 2.4 * layout.S
      ..strokeCap = StrokeCap.round;

    final targets = [
      layout.solarT1,
      layout.solarTopMiddle,
      layout.solarBottomMiddle,
      layout.solarCenter,
      layout.solarT2,
    ];

    for (int i = 0; i < targets.length; i++) {
      final target = targets[i];
      canvas.drawLine(sunCenter, target, rayPaint);

      // Draw animated photon dots traveling from sun to panel
      final t = (progress + i * 0.33) % 1.0;
      final pos = Offset.lerp(sunCenter, target, t)!;
      canvas.drawCircle(
        pos,
        5.2 * layout.S,
        Paint()..color = const Color(0xFFFFD166).withValues(alpha: 0.42),
      );
      canvas.drawCircle(
        pos,
        1.8 * layout.S,
        Paint()..color = const Color(0xFFFFF59D),
      );
    }
  }

  void _drawNightSky(Canvas canvas, Size size) {
    // 1. Draw Star Blinking
    final starPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 28; i++) {
      final x = ((i * 127) % 100) / 100 * size.width;
      final y = ((i * 79) % 100) / 100 * (layout.groundY - 50 * layout.S);

      // Avoid drawing stars over the moon area to keep it clean
      if ((x - size.width * 0.78).abs() < 40 && y < 100) continue;

      final alpha =
          0.2 + 0.8 * ((math.sin(progress * 2 * math.pi * 1.5 + i) + 1) / 2);
      starPaint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(
        Offset(x, y),
        1.0 + (i % 3) * 0.4 * layout.S,
        starPaint,
      );
    }

    // 2. Draw Moon (with crescent effect via Path subtraction)
    final moonCenter = Offset(size.width * 0.78, 55 * layout.S);
    final moonRadius = 18 * layout.S;

    // Moon Glow
    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFFFFDE7).withValues(alpha: 0.25),
              const Color(0xFFFFFDE7).withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(center: moonCenter, radius: moonRadius * 2.2),
          );
    canvas.drawCircle(moonCenter, moonRadius * 2.2, glowPaint);

    final Path moonPath = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: moonCenter, radius: moonRadius)),
      Path()..addOval(
        Rect.fromCircle(
          center: moonCenter + Offset(6 * layout.S, -4 * layout.S),
          radius: moonRadius,
        ),
      ),
    );

    final moonPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [Color(0xFFFFFDE7), Color(0xFFFFF9C4)],
      ).createShader(Rect.fromCircle(center: moonCenter, radius: moonRadius))
      ..style = PaintingStyle.fill;

    canvas.drawPath(moonPath, moonPaint);

    // 3. Draw Shooting Star
    final double starProgress = (progress * 2.0) % 2.0;
    if (starProgress > 0.4 && starProgress < 0.9) {
      final t = (starProgress - 0.4) / 0.5;
      final start = Offset(size.width * 0.65, 30 * layout.S);
      final end = start + Offset(-100 * layout.S, 70 * layout.S);
      final currentPos = Offset.lerp(start, end, t)!;

      final tailPaint = Paint()
        ..color = Colors.white.withValues(alpha: (1.0 - t) * 0.7)
        ..strokeWidth = 1.5 * layout.S
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        currentPos,
        currentPos + Offset(12 * layout.S, -8 * layout.S),
        tailPaint,
      );
      canvas.drawCircle(
        currentPos,
        1.2 * layout.S,
        Paint()..color = Colors.white,
      );
    }
  }

  void _drawEnergyLines(Canvas canvas) {
    // Heavy Load line is active depending on time of day and WAPDA availability
    final bool heavyLoadActiveLine = values.isDayTime
        ? values.heavyLoadOn
        : (values.heavyLoadOn && values.wapdaAvailable);
    final Color heavyLoadColor = heavyLoadActiveLine
        ? AppTheme.accent
        : AppTheme.error;

    // 1. Path: Solar Panel Bottom Middle -> Inverter
    final solarToInverter = Path()
      ..moveTo(layout.solarBottomMiddle.dx, layout.solarBottomMiddle.dy)
      // 1. drop slightly for cable realism
      ..lineTo(layout.solarBottomMiddle.dx, layout.solarBottomMiddle.dy + 17)
      // 2. move horizontally toward inverter
      ..lineTo(layout.inverter.dx, layout.solarBottomMiddle.dy + 17)
      // 3. go up into inverter entry point
      ..lineTo(
        layout.inverter.dx,
        layout.inverter.dy - layout.wallHeight * 0.19,
      );

    // 2. Path: Inverter -> Battery (straight vertical line)
    final inverterBottom = Offset(
      layout.inverter.dx,
      layout.inverter.dy + layout.wallHeight * 0.19,
    );
    final batteryTop = Offset(
      layout.batteryRect.center.dx,
      layout.batteryRect.top - 2.5 * layout.S,
    );

    final inverterToBattery = Path()
      ..moveTo(inverterBottom.dx, inverterBottom.dy);

    // 1. go down from inverter
    final midY1 = inverterBottom.dy + 30 * layout.S;

    // 2. first horizontal route (right)
    final midX = (inverterBottom.dx + batteryTop.dx) / 2;

    inverterToBattery
      ..lineTo(inverterBottom.dx, midY1)
      ..lineTo(midX + 52, midY1)
      // 3. go up
      ..lineTo(midX + 52, batteryTop.dy - 10 * layout.S)
      // 4. go right
      ..lineTo(batteryTop.dx, batteryTop.dy - 10 * layout.S)
      // 5. final drop into battery top
      ..lineTo(batteryTop.dx, batteryTop.dy);

    // 3. Horizontal Main Grid Path (representing the external high voltage lines on the pole)
    final mainGridPath = Path()
      ..moveTo(0, layout.towerTopY + 16 * layout.S)
      ..lineTo(layout.towerX, layout.towerTopY + 16 * layout.S);

    // 4. Combined Home WAPDA Path (Ground-level from tower base to house, then up to inverter)
    final towerBase = Offset(layout.towerX + 5 * layout.S, layout.groundY + 5);
    final inverterEntry = Offset(
      layout.inverter.dx - layout.frontWidth * 0.12,
      layout.inverter.dy,
    );

    final combinedGridPath = Path()
      ..moveTo(towerBase.dx - 6, towerBase.dy - 4)
      // 1. small drop (optional, gives natural cable sag)
      ..lineTo(towerBase.dx - 6, towerBase.dy + 10)
      // 2. go horizontally toward inverter direction
      ..lineTo(inverterEntry.dx + 4 * layout.S, towerBase.dy + 10)
      // 3. turn upward toward inverter
      ..lineTo(inverterEntry.dx + 4 * layout.S, inverterEntry.dy + 18)
      // 4. final connection into inverter
      ..lineTo(inverterEntry.dx + 5, inverterEntry.dy + 18);

    // 5. Path: Inverter -> Lightbulb Window (COMPLETELY ORTHOGONAL to the hanging bulb)
    final inverterExit = Offset(
      layout.inverter.dx + layout.frontWidth * 0.12,
      layout.inverter.dy,
    );
    final bulbCenter = Offset(
      layout.windowRect.center.dx,
      layout.windowRect.top + 8 * layout.S,
    );

    final inverterToLight = Path()
      ..moveTo(inverterExit.dx, inverterExit.dy)
      ..lineTo(bulbCenter.dx, inverterExit.dy)
      ..lineTo(bulbCenter.dx, bulbCenter.dy);

    // ---- Paint options ----
    final greenStroke = Paint()
      ..color = AppTheme.success
      ..strokeWidth = 2.0 * layout.S
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final greenGlow = Paint()
      ..color = AppTheme.success.withValues(alpha: 0.15)
      ..strokeWidth = 5.0 * layout.S
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Main Grid stroke: Blue when available, Red when unavailable
    final bool mainGridOn = values.wapdaAvailable;
    final Color mainGridColor = mainGridOn
        ? const Color(0xFF2196F3)
        : const Color(0xFFEF4444);

    final mainGridStroke = Paint()
      ..color = mainGridColor
      ..strokeWidth = 2.0 * layout.S
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final mainGridGlow = Paint()
      ..color = mainGridColor.withValues(alpha: 0.18)
      ..strokeWidth = 5.0 * layout.S
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Home WAPDA stroke: Orange when active, Red when inactive
    final bool homeWapdaActive = values.wapdaLineActive;
    final Color homeWapdaColor = homeWapdaActive
        ? AppTheme.accent
        : AppTheme.error;

    final homeWapdaStroke = Paint()
      ..color = homeWapdaColor
      ..strokeWidth = 2.0 * layout.S
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final homeWapdaGlow = Paint()
      ..color = homeWapdaColor.withValues(alpha: 0.18)
      ..strokeWidth = 5.0 * layout.S
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Heavy load stroke
    final heavyLoadStroke = Paint()
      ..color = heavyLoadColor
      ..strokeWidth = 2.0 * layout.S
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final heavyLoadGlow = Paint()
      ..color = heavyLoadColor.withValues(alpha: 0.18)
      ..strokeWidth = 5.0 * layout.S
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // ---- Draw static pipelines ----
    canvas.drawPath(solarToInverter, greenGlow);
    canvas.drawPath(solarToInverter, greenStroke);

    canvas.drawPath(inverterToBattery, greenGlow);
    canvas.drawPath(inverterToBattery, greenStroke);

    canvas.drawPath(mainGridPath, mainGridGlow);
    canvas.drawPath(mainGridPath, mainGridStroke);

    canvas.drawPath(combinedGridPath, homeWapdaGlow);
    canvas.drawPath(combinedGridPath, homeWapdaStroke);

    canvas.drawPath(inverterToLight, heavyLoadGlow);
    canvas.drawPath(inverterToLight, heavyLoadStroke);

    // ---- Draw animated flow dots ----
    if (values.isDayTime) {
      _drawFlowDot(canvas, solarToInverter, AppTheme.success, speed: 1.2);
    }

    if (values.isDayTime && values.productionKw > 0.1) {
      _drawFlowDot(canvas, inverterToBattery, AppTheme.success, speed: 1.0);
    }

    if (mainGridOn) {
      _drawFlowDot(canvas, mainGridPath, const Color(0xFF00E5FF), speed: 0.95);
    }

    if (homeWapdaActive) {
      _drawFlowDot(canvas, combinedGridPath, AppTheme.accent, speed: 0.95);
    }

    if (heavyLoadActiveLine) {
      _drawFlowDot(canvas, inverterToLight, AppTheme.accent, speed: 1.1);
    }
  }

  void _drawFlowDot(
    Canvas canvas,
    Path path,
    Color color, {
    double speed = 1.0,
  }) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final dotPaint = Paint()..color = color;
    final outerPaint = Paint()..color = color.withValues(alpha: 0.25);

    for (final metric in metrics) {
      final t = (progress * speed) % 1.0;
      final tangent = metric.getTangentForOffset(metric.length * t);
      if (tangent != null) {
        canvas.drawCircle(tangent.position, 5.0 * layout.S, outerPaint);
        canvas.drawCircle(tangent.position, 2.6 * layout.S, dotPaint);
      }

      final t2 = (t - 0.28) % 1.0;
      final tangent2 = metric.getTangentForOffset(metric.length * t2);
      if (tangent2 != null) {
        canvas.drawCircle(
          tangent2.position,
          3.8 * layout.S,
          Paint()..color = color.withValues(alpha: 0.15),
        );
        canvas.drawCircle(
          tangent2.position,
          1.8 * layout.S,
          Paint()..color = color.withValues(alpha: 0.7),
        );
      }
    }
  }

  void _drawRoadAndTraffic(Canvas canvas, Size size) {
    final s = layout.S;
    final sceneTop = size.height - 85 * s;
    final sceneBottom = size.height;

    final topFootpathTop = sceneTop;
    final topFootpathBottom = sceneTop + 14 * s;

    final asphaltTop = topFootpathBottom;
    final asphaltBottom = sceneBottom - 14 * s;

    final bottomFootpathTop = asphaltBottom;
    final bottomFootpathBottom = sceneBottom;

    final midY = asphaltTop + (asphaltBottom - asphaltTop) / 2;

    // 1. Draw Footpaths
    final sidewalkPaint = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)
      ..style = PaintingStyle.fill;

    // Top & Bottom Footpaths
    canvas.drawRect(
      Rect.fromLTRB(0, topFootpathTop, size.width, topFootpathBottom),
      sidewalkPaint,
    );
    canvas.drawRect(
      Rect.fromLTRB(0, bottomFootpathTop, size.width, bottomFootpathBottom),
      sidewalkPaint,
    );

    // Footpath cracks
    final crackPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFF94A3B8)
      ..strokeWidth = 1.0 * s;
    for (double x = 0; x < size.width; x += 40 * s) {
      canvas.drawLine(
        Offset(x, topFootpathTop),
        Offset(x, topFootpathBottom),
        crackPaint,
      );
      canvas.drawLine(
        Offset(x, bottomFootpathTop),
        Offset(x, bottomFootpathBottom),
        crackPaint,
      );
    }

    // Add foreground tree on left side near the top footpath
    _drawRealisticTree(canvas, 30 * s, topFootpathTop + 4 * s, 0.7);

    // 2. Draw Asphalt
    final roadPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFF475569)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(0, asphaltTop, size.width, asphaltBottom),
      roadPaint,
    );

    // 3. Draw Road Divider Bollards at midY
    final medianPaint = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(0, midY - 2.5 * s, size.width, midY + 2.5 * s),
      medianPaint,
    );

    final yellowPaint = Paint()..color = const Color(0xFFFFD166);
    final blackPaint = Paint()..color = const Color(0xFF1E293B);
    for (double x = 10 * s; x < size.width + 20 * s; x += 35 * s) {
      final bRect = Rect.fromCenter(
        center: Offset(x, midY),
        width: 6 * s,
        height: 5 * s,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bRect, Radius.circular(1 * s)),
        yellowPaint,
      );
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, midY), width: 2 * s, height: 5 * s),
        blackPaint,
      );
    }

    // SLOW DOWN PROGRESS for smoother traffic flow
    final slowProgress = (progress * 0.4) % 1.0;

    // 4. Draw People on footpaths
    // Top footpath: Person 1 walking right to left (top)
    final p1X = (size.width + 20 * s) - slowProgress * (size.width + 40 * s);
    final p1Y = topFootpathBottom - 2 * s;
    _drawWalkingPerson(
      canvas,
      Offset(p1X, p1Y),
      scale: 0.9,
      isLeftToRight: false,
      walkSpeed: 6.0,
    );

    // Bottom footpath: Person 2 walking left to right (bottom)
    final p2X = -20 * s + slowProgress * (size.width + 40 * s);
    final p2Y = bottomFootpathBottom - 2 * s;
    _drawWalkingPerson(
      canvas,
      Offset(p2X, p2Y),
      scale: 1.0,
      isLeftToRight: true,
      walkSpeed: 6.0,
    );

    // 5. Draw Vehicles
    // Top Road Lane (Right to Left)
    final car1X = (size.width + 40 * s) - slowProgress * (size.width + 80 * s);
    final car1Y = asphaltTop + 14 * s;
    _drawCar(
      canvas,
      Offset(car1X, car1Y),
      color: const Color(0xFFEF4444),
      isLeftToRight: false,
    );

    final bike1Progress = (slowProgress + 0.35) % 1.0;
    final bike1X =
        (size.width + 30 * s) - bike1Progress * (size.width + 60 * s);
    final bike1Y = asphaltTop + 8 * s;
    _drawBike(
      canvas,
      Offset(bike1X, bike1Y),
      color: const Color(0xFF10B981),
      isLeftToRight: false,
    );

    // Bottom Road Lane (Left to Right)
    final car2X = -40 * s + slowProgress * (size.width + 80 * s);
    final car2Y = midY + 16 * s;
    _drawCar(
      canvas,
      Offset(car2X, car2Y),
      color: const Color(0xFF0EA5E9),
      isLeftToRight: true,
    );

    final bike2Progress = (slowProgress + 0.4) % 1.0;
    final bike2X = -30 * s + bike2Progress * (size.width + 60 * s);
    final bike2Y = midY + 10 * s;
    _drawBike(
      canvas,
      Offset(bike2X, bike2Y),
      color: const Color(0xFFF59E0B),
      isLeftToRight: true,
    );
  }

  void _drawWalkingPerson(
    Canvas canvas,
    Offset feetBase, {
    double scale = 1.0,
    required bool isLeftToRight,
    double walkSpeed = 3.0,
  }) {
    final s = scale * layout.S;
    final headRadius = 2.2 * s;
    final bodyHeight = 7.0 * s;
    final limbLength = 5.0 * s;

    final personColor = isDark ? Colors.white70 : const Color(0xFF334155);
    final paint = Paint()
      ..color = personColor
      ..strokeWidth = 1.2 * s
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = personColor
      ..style = PaintingStyle.fill;

    final legHeight = 5.0 * s;
    final hipY = feetBase.dy - legHeight;
    final neckY = hipY - bodyHeight;
    final headY = neckY - headRadius - 0.5 * s;

    // Draw Head
    canvas.drawCircle(Offset(feetBase.dx, headY), headRadius, fillPaint);

    // Draw Torso
    canvas.drawLine(
      Offset(feetBase.dx, neckY),
      Offset(feetBase.dx, hipY),
      paint,
    );

    // Swing math
    final swing = math.sin(progress * 2 * math.pi * walkSpeed);

    // Legs
    final leftLegAngle = swing * 0.45;
    final rightLegAngle = -swing * 0.45;

    final leftFootX = feetBase.dx + math.sin(leftLegAngle) * limbLength;
    final leftFootY = hipY + math.cos(leftLegAngle) * limbLength;
    canvas.drawLine(
      Offset(feetBase.dx, hipY),
      Offset(leftFootX, leftFootY),
      paint,
    );

    final rightFootX = feetBase.dx + math.sin(rightLegAngle) * limbLength;
    final rightFootY = hipY + math.cos(rightLegAngle) * limbLength;
    canvas.drawLine(
      Offset(feetBase.dx, hipY),
      Offset(rightFootX, rightFootY),
      paint,
    );

    // Arms
    final leftArmAngle = -swing * 0.4;
    final rightArmAngle = swing * 0.4;

    final leftHandX = feetBase.dx + math.sin(leftArmAngle) * limbLength * 0.8;
    final leftHandY =
        neckY + 1.5 * s + math.cos(leftArmAngle) * limbLength * 0.8;
    canvas.drawLine(
      Offset(feetBase.dx, neckY + 1.5 * s),
      Offset(leftHandX, leftHandY),
      paint,
    );

    final rightHandX = feetBase.dx + math.sin(rightArmAngle) * limbLength * 0.8;
    final rightHandY =
        neckY + 1.5 * s + math.cos(rightArmAngle) * limbLength * 0.8;
    canvas.drawLine(
      Offset(feetBase.dx, neckY + 1.5 * s),
      Offset(rightHandX, rightHandY),
      paint,
    );
  }

  void _drawCar(
    Canvas canvas,
    Offset center, {
    required Color color,
    required bool isLeftToRight,
  }) {
    final s = layout.S;
    final w = 22.0 * s;
    final h = 7.5 * s;

    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Body
    final bodyRect = Rect.fromCenter(center: center, width: w, height: h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(2 * s)),
      bodyPaint,
    );

    // Cabin
    final cabinW = w * 0.6;
    final cabinH = h * 0.8;
    final cabinCenter = Offset(
      center.dx + (isLeftToRight ? -1.5 * s : 1.5 * s),
      center.dy - h / 2 - cabinH / 2 + 0.8 * s,
    );
    final cabinRect = Rect.fromCenter(
      center: cabinCenter,
      width: cabinW,
      height: cabinH,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(cabinRect, Radius.circular(2.5 * s)),
      Paint()
        ..color = isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B)
        ..style = PaintingStyle.fill,
    );

    // Windows
    final windowPaint = Paint()
      ..color = const Color(0xFFE2E8F0).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    final windowW = cabinW * 0.4;
    final windowH = cabinH * 0.6;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cabinCenter.dx - cabinW * 0.23, cabinCenter.dy),
        width: windowW,
        height: windowH,
      ),
      windowPaint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cabinCenter.dx + cabinW * 0.23, cabinCenter.dy),
        width: windowW,
        height: windowH,
      ),
      windowPaint,
    );

    // Wheels
    final wheelRadius = 2.4 * s;
    final wheelY = center.dy + h / 2 - 0.5 * s;
    final wheelPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    final hubPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;

    final wheelOffset = w * 0.28;
    final w1 = Offset(center.dx - wheelOffset, wheelY);
    final w2 = Offset(center.dx + wheelOffset, wheelY);

    canvas.drawCircle(w1, wheelRadius, wheelPaint);
    canvas.drawCircle(w1, wheelRadius * 0.45, hubPaint);

    canvas.drawCircle(w2, wheelRadius, wheelPaint);
    canvas.drawCircle(w2, wheelRadius * 0.45, hubPaint);

    // Lights
    final lightRadius = 1.0 * s;
    final headlightPaint = Paint()
      ..color = const Color(0xFFFFFD74)
      ..style = PaintingStyle.fill;
    final taillightPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;

    final leftLightX = center.dx - w / 2;
    final rightLightX = center.dx + w / 2;
    final lightY = center.dy - 1.2 * s;

    if (isLeftToRight) {
      canvas.drawCircle(
        Offset(leftLightX, lightY),
        lightRadius,
        taillightPaint,
      );
      canvas.drawCircle(
        Offset(rightLightX, lightY),
        lightRadius,
        headlightPaint,
      );

      if (!values.isDayTime) {
        final beamPath = Path()
          ..moveTo(rightLightX, lightY)
          ..lineTo(rightLightX + 35 * s, lightY - 12 * s)
          ..lineTo(rightLightX + 35 * s, lightY + 12 * s)
          ..close();
        canvas.drawPath(
          beamPath,
          Paint()
            ..shader =
                LinearGradient(
                  colors: [
                    const Color(0xFFFFFD74).withValues(alpha: 0.35),
                    const Color(0xFFFFFD74).withValues(alpha: 0),
                  ],
                ).createShader(
                  Rect.fromLTRB(
                    rightLightX,
                    lightY - 12 * s,
                    rightLightX + 35 * s,
                    lightY + 12 * s,
                  ),
                ),
        );
      }
    } else {
      canvas.drawCircle(
        Offset(leftLightX, lightY),
        lightRadius,
        headlightPaint,
      );
      canvas.drawCircle(
        Offset(rightLightX, lightY),
        lightRadius,
        taillightPaint,
      );

      if (!values.isDayTime) {
        final beamPath = Path()
          ..moveTo(leftLightX, lightY)
          ..lineTo(leftLightX - 35 * s, lightY - 12 * s)
          ..lineTo(leftLightX - 35 * s, lightY + 12 * s)
          ..close();
        canvas.drawPath(
          beamPath,
          Paint()
            ..shader =
                LinearGradient(
                  colors: [
                    const Color(0xFFFFFD74).withValues(alpha: 0.35),
                    const Color(0xFFFFFD74).withValues(alpha: 0),
                  ],
                ).createShader(
                  Rect.fromLTRB(
                    leftLightX - 35 * s,
                    lightY - 12 * s,
                    leftLightX,
                    lightY + 12 * s,
                  ),
                ),
        );
      }
    }
  }

  void _drawBike(
    Canvas canvas,
    Offset center, {
    required Color color,
    required bool isLeftToRight,
  }) {
    final s = layout.S;
    final dir = isLeftToRight ? 1.0 : -1.0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2 * s
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final wheelRadius = 2.0 * s;
    final w1 = Offset(
      center.dx - dir * 4.0 * s,
      center.dy + 1.0 * s,
    ); // back wheel
    final w2 = Offset(
      center.dx + dir * 4.0 * s,
      center.dy + 1.0 * s,
    ); // front wheel

    final wheelPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * s;
    canvas.drawCircle(w1, wheelRadius, wheelPaint);
    canvas.drawCircle(w2, wheelRadius, wheelPaint);

    // Frame nodes
    final seat = Offset(center.dx - dir * 1.5 * s, center.dy - 2.5 * s);
    final pedal = Offset(center.dx + dir * 1.0 * s, center.dy + 1.0 * s);
    final handle = Offset(center.dx + dir * 3.0 * s, center.dy - 3.0 * s);

    canvas.drawLine(w1, seat, paint);
    canvas.drawLine(seat, pedal, paint);
    canvas.drawLine(pedal, handle, paint);
    canvas.drawLine(handle, w2, paint);
    canvas.drawLine(
      seat,
      Offset(center.dx + dir * 2.0 * s, center.dy - 3.0 * s),
      paint,
    ); // top bar

    // Rider
    final riderColor = isDark ? Colors.white70 : const Color(0xFF334155);
    final riderStroke = Paint()
      ..color = riderColor
      ..strokeWidth = 1.2 * s
      ..strokeCap = StrokeCap.round;

    final head = Offset(center.dx - dir * 1.0 * s, center.dy - 5.5 * s);
    canvas.drawCircle(
      head,
      1.5 * s,
      Paint()
        ..color = riderColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawLine(
      Offset(head.dx, head.dy + 1.5 * s),
      seat,
      riderStroke,
    ); // Body
    canvas.drawLine(
      Offset(head.dx, head.dy + 2.0 * s),
      handle,
      riderStroke,
    ); // Arms

    // Legs (pedaling animation)
    final pedalProgress = (progress * 5.0) % 1.0;
    final pedalAngle = pedalProgress * 2 * math.pi;
    final pedalX = pedal.dx + dir * math.cos(pedalAngle) * 1.0 * s;
    final pedalY = pedal.dy + math.sin(pedalAngle) * 1.0 * s;
    canvas.drawLine(seat, Offset(pedalX, pedalY), riderStroke);
  }

  @override
  bool shouldRepaint(WhlScenePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.values != values ||
        oldDelegate.isDark != isDark;
  }
}

class WhlSceneLayout {
  final Size size;
  final double S; // scale factor

  WhlSceneLayout(this.size) : S = (size.height / 360.0).clamp(0.68, 1.25);

  double get groundY => size.height - 110 * S;
  double get houseWidth => size.width * 0.54;
  double get frontWidth => houseWidth * 0.72;
  double get sideWidth => houseWidth * 0.28;
  double get wallHeight => 75 * S;
  double get houseHeight => 125 * S;

  // SWAPPED: House on the right, Tower on the left
  double get houseX => size.width * 0.38;
  double get towerX => size.width * 0.16;

  double get houseY => groundY;

  // Circles / bubbles positions
  Offset get solarBubble => Offset(
    houseX + frontWidth * 0.5 + sideWidth * 0.5,
    groundY - houseHeight - 55 * S,
  );
  Offset get gridBubble => Offset(towerX, towerTopY - 42 * S);

  // Mirrored: Inverter is on the left of front wall, Door on the right
  // Moved inverter slightly left (from 0.25 to 0.18)
  Offset get inverter =>
      Offset(houseX + frontWidth * 0.18, groundY - wallHeight * 0.45);

  // Window coordinates (in middle)
  double get windowWidth => frontWidth * 0.24;
  double get windowHeight => wallHeight * 0.44;
  Rect get windowRect => Rect.fromLTWH(
    houseX + frontWidth * 0.44,
    groundY - wallHeight * 0.76,
    windowWidth,
    windowHeight,
  );

  // Door coordinates (on right)
  Rect get doorRect => Rect.fromLTWH(
    houseX + frontWidth * 0.74,
    groundY - wallHeight * 0.76,
    frontWidth * 0.22,
    wallHeight * 0.76,
  );

  // Electric tower details
  double get towerHeight => 110 * S;
  double get towerTopY => groundY - towerHeight;

  // Battery underground details (directly under inverter)
  Rect get batteryRect => Rect.fromCenter(
    center: Offset(inverter.dx + 159, groundY - 28 * S),
    width: 32 * S,
    height: 46 * S,
  );

  // Solar panel coordinates for mapping paths (Restricted to the right side of the roof slope)
  Offset get solarT1 {
    final p1 = Offset(houseX + sideWidth * .5, groundY - houseHeight);
    final p2 = Offset(
      houseX + frontWidth + sideWidth * 0.5,
      groundY - houseHeight,
    );
    final midTop = Offset.lerp(p1, p2, 0.48)!;
    return Offset(midTop.dx - 55 * S, midTop.dy + 4 * S);
  }

  Offset get solarT2 {
    final p2 = Offset(
      houseX + frontWidth + sideWidth * 0.5,
      groundY - houseHeight,
    );
    return Offset(p2.dx - 8 * S, p2.dy + 4 * S);
  }

  Offset get solarT3 {
    final p3 = Offset(houseX + frontWidth, groundY - wallHeight);
    return Offset(p3.dx - 4 * S, p3.dy - 4 * S);
  }

  Offset get solarT4 {
    final p3 = Offset(houseX + frontWidth, groundY - wallHeight);
    final p4 = Offset(houseX, groundY - wallHeight);
    final midBottom = Offset.lerp(p4, p3, 0.48)!;
    return Offset(midBottom.dx - 50 * S, midBottom.dy - 4 * S);
  }

  Offset get solarBottomMiddle =>
      Offset((solarT3.dx + solarT4.dx) / 2, (solarT3.dy + solarT4.dy) / 2);

  Offset get solarTopMiddle => Offset(
    (solarT1.dx + solarT2.dx) / 2 + 30 * S,
    (solarT1.dy + solarT2.dy) / 2,
  );

  Offset get solarCenter => Offset(
    (solarTopMiddle.dx + solarBottomMiddle.dx) / 2,
    (solarTopMiddle.dy + solarBottomMiddle.dy) / 2,
  );
}
