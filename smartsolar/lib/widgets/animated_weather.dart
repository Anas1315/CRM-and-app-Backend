import 'dart:math';
import 'package:flutter/material.dart';

/// Animated weather widget that displays different animations based on weather conditions
class AnimatedWeather extends StatefulWidget {
  final bool isDayTime;
  final bool isSunny;
  final int ldrValue;
  final double? width;
  final double? height;
  final bool showSolarPanel;

  const AnimatedWeather({
    super.key,
    required this.isDayTime,
    required this.isSunny,
    required this.ldrValue,
    this.width,
    this.height,
    this.showSolarPanel = true,
  });

  @override
  State<AnimatedWeather> createState() => _AnimatedWeatherState();
}

class _AnimatedWeatherState extends State<AnimatedWeather>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 200,
      decoration: BoxDecoration(
        gradient: _getBackgroundGradient(),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background effects
            _buildBackgroundEffects(),

            // Weather-specific animations
            if (!widget.isDayTime)
              _buildNightScene()
            else if (widget.isSunny)
              _buildSunnyScene()
            else
              _buildCloudyScene(),

            // Solar panel overlay
            if (widget.showSolarPanel) _buildSolarPanel(),

            // Overlay gradient for text readability
            _buildOverlayGradient(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundEffects() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _BackgroundPainter(
              isDayTime: widget.isDayTime,
              isSunny: widget.isSunny,
              animationValue: _controller.value,
              random: _random,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSunnyScene() {
    return Stack(
      children: [
        // Sun
        Positioned(
          top: 20,
          right: 20,
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 1.0, end: 1.1),
            duration: const Duration(seconds: 2),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.orange.shade300,
                        Colors.orange.shade600,
                      ],
                      stops: const [0.5, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.sunny,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Sun rays
        ...List.generate(12, (index) {
          final angle = (index * 30) * pi / 180;
          return Positioned(
            top: 60,
            right: 60,
            child: TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: Duration(seconds: 2 + index),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: angle,
                  child: Container(
                    width: 60 * value,
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.withValues(alpha: 0.8),
                          Colors.orange.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }),

        // Floating particles (dust/pollen)
        ...List.generate(15, (index) {
          return _AnimatedParticle(
            key: ValueKey('particle_$index'),
            startX: _random.nextDouble(),
            startY: _random.nextDouble(),
            duration: Duration(seconds: 5 + _random.nextInt(5)),
            color: Colors.white.withValues(alpha: 0.3),
            size: Size(
                2 + _random.nextDouble() * 3, 2 + _random.nextDouble() * 3),
          );
        }),
      ],
    );
  }

  Widget _buildCloudyScene() {
    return Stack(
      children: [
        // Weak sun behind clouds
        Positioned(
          top: 30,
          right: 30,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.orange.shade200.withValues(alpha: 0.6),
                  Colors.orange.shade400.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Clouds
        ...List.generate(4, (index) {
          return _AnimatedCloud(
            key: ValueKey('cloud_$index'),
            index: index,
            speed: 20 + index * 5,
            startOffset: -200 - index * 50,
            opacity: 0.7 - index * 0.1,
          );
        }),

        // Rain drops (if dark/cloudy)
        if (widget.ldrValue < 1200)
          ...List.generate(30, (index) {
            return _RainDrop(
              key: ValueKey('raindrop_$index'),
              delay: index * 0.1,
              duration: 0.8 + _random.nextDouble(),
              startX: _random.nextDouble(),
            );
          }),

        // Wind lines
        ...List.generate(5, (index) {
          return _WindLine(
            key: ValueKey('wind_$index'),
            index: index,
            duration: (3 + index).toDouble(),
            delay: index * 0.5,
          );
        }),
      ],
    );
  }

  Widget _buildNightScene() {
    return Stack(
      children: [
        // Moon
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Moon craters
                Positioned(
                  top: 15,
                  left: 15,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade300.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                Positioned(
                  top: 35,
                  left: 30,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade300.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 10,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade300.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Stars
        ...List.generate(50, (index) {
          return _Star(
            key: ValueKey('star_$index'),
            index: index,
            twinkleSpeed: 1 + _random.nextDouble() * 3,
            size: 1 + _random.nextDouble() * 2,
          );
        }),

        // Milky way / Nebula effect
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.purple.withValues(alpha: 0.2),
                  Colors.blue.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSolarPanel() {
    final isActive = widget.isDayTime && widget.isSunny;

    return Positioned(
      bottom: 10,
      left: 10,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 1.0, end: isActive ? 1.05 : 1.0),
        duration: const Duration(seconds: 2),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              width: 60,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade900,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive ? Colors.green : Colors.grey.shade700,
                  width: 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  // Solar panel grid - Fixed: proper list generation
                  ..._buildSolarPanelGrid(),

                  // Energy flow animation
                  if (isActive)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _EnergyFlowPainter(
                              animationValue: _controller.value,
                            ),
                          );
                        },
                      ),
                    ),

                  // Glow effect when active
                  if (isActive)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.green.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildSolarPanelGrid() {
    final cells = <Widget>[];
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        cells.add(
          Positioned(
            left: col * 20.0,
            top: row * 16.0,
            child: Container(
              width: 18,
              height: 14,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade600,
                  width: 0.5,
                ),
              ),
            ),
          ),
        );
      }
    }
    return cells;
  }

  Widget _buildOverlayGradient() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.3),
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient _getBackgroundGradient() {
    if (!widget.isDayTime) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0F172A),
          Color(0xFF1E1B4B),
          Colors.black,
        ],
      );
    } else if (widget.isSunny) {
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.blue.shade400,
          Colors.lightBlue.shade200,
          Colors.orange.shade100,
        ],
      );
    } else {
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.grey.shade600,
          Colors.grey.shade500,
          Colors.grey.shade400,
        ],
      );
    }
  }
}

// ========== CUSTOM PAINTERS ==========

class _BackgroundPainter extends CustomPainter {
  final bool isDayTime;
  final bool isSunny;
  final double animationValue;
  final Random random;

  _BackgroundPainter({
    required this.isDayTime,
    required this.isSunny,
    required this.animationValue,
    required this.random,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isDayTime) {
      // Draw twinkling stars
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3 + animationValue * 0.3);

      for (int i = 0; i < 100; i++) {
        final x = (random.nextDouble() * size.width);
        final y = (random.nextDouble() * size.height);
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    } else if (!isSunny) {
      // Draw clouds
      final paint = Paint()..color = Colors.white.withValues(alpha: 0.2);

      for (int i = 0; i < 5; i++) {
        final x = (random.nextDouble() * size.width);
        final y = (random.nextDouble() * size.height * 0.5);
        canvas.drawCircle(Offset(x, y), 30 + random.nextDouble() * 20, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _EnergyFlowPainter extends CustomPainter {
  final double animationValue;

  _EnergyFlowPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final startX = size.width * animationValue;

    path.moveTo(startX, 0);
    path.lineTo(startX + 10, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ========== ANIMATED PARTICLES ==========

class _AnimatedParticle extends StatefulWidget {
  final double startX;
  final double startY;
  final Duration duration;
  final Color color;
  final Size size;

  const _AnimatedParticle({
    super.key,
    required this.startX,
    required this.startY,
    required this.duration,
    required this.color,
    required this.size,
  });

  @override
  State<_AnimatedParticle> createState() => _AnimatedParticleState();
}

class _AnimatedParticleState extends State<_AnimatedParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _xAnimation;
  late Animation<double> _yAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    _xAnimation = Tween<double>(
      begin: widget.startX,
      end: widget.startX + 0.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _yAnimation = Tween<double>(
      begin: widget.startY,
      end: widget.startY - 0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: MediaQuery.of(context).size.width * _xAnimation.value,
          top: MediaQuery.of(context).size.height * 0.5 * _yAnimation.value,
          child: Container(
            width: widget.size.width,
            height: widget.size.height,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}

// ========== ANIMATED CLOUD ==========

class _AnimatedCloud extends StatefulWidget {
  final int index;
  final double speed;
  final double startOffset;
  final double opacity;

  const _AnimatedCloud({
    super.key,
    required this.index,
    required this.speed,
    required this.startOffset,
    required this.opacity,
  });

  @override
  State<_AnimatedCloud> createState() => _AnimatedCloudState();
}

class _AnimatedCloudState extends State<_AnimatedCloud>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.speed.toInt()),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Calculate position using controller value instead of separate animation
        final position =
            widget.startOffset + (_controller.value * (screenWidth + 400));
        return Positioned(
          left: position,
          top: 20.0 + widget.index * 40,
          child: Opacity(
            opacity: widget.opacity,
            child: Container(
              width: 120,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 20,
                    top: -20,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    top: -10,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ========== RAIN DROP ==========

class _RainDrop extends StatefulWidget {
  final double delay;
  final double duration;
  final double startX;

  const _RainDrop({
    super.key,
    required this.delay,
    required this.duration,
    required this.startX,
  });

  @override
  State<_RainDrop> createState() => _RainDropState();
}

class _RainDropState extends State<_RainDrop>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _yAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (widget.duration * 1000).toInt()),
    );

    _yAnimation = Tween<double>(begin: -20, end: 400).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _opacityAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: MediaQuery.of(context).size.width * widget.startX,
          top: _yAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: 2,
              height: 15,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withValues(alpha: 0.8),
                    Colors.blue.withValues(alpha: 0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ========== WIND LINE ==========

class _WindLine extends StatefulWidget {
  final int index;
  final double duration;
  final double delay;

  const _WindLine({
    super.key,
    required this.index,
    required this.duration,
    required this.delay,
  });

  @override
  State<_WindLine> createState() => _WindLineState();
}

class _WindLineState extends State<_WindLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _xAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.duration.toInt()),
    );

    _xAnimation = Tween<double>(begin: -100, end: 500).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    Future.delayed(Duration(seconds: widget.delay.toInt()), () {
      if (mounted) _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _xAnimation,
      builder: (context, child) {
        return Positioned(
          left: _xAnimation.value,
          top: 50.0 + widget.index * 30,
          child: Container(
            width: 60,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.5),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ========== STAR ==========

class _Star extends StatefulWidget {
  final int index;
  final double twinkleSpeed;
  final double size;

  const _Star({
    super.key,
    required this.index,
    required this.twinkleSpeed,
    required this.size,
  });

  @override
  State<_Star> createState() => _StarState();
}

class _StarState extends State<_Star> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.twinkleSpeed.toInt().clamp(1, 10)),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final random = Random(widget.index);

    return Positioned(
      left: random.nextDouble() * MediaQuery.of(context).size.width,
      top: random.nextDouble() * 200,
      child: AnimatedBuilder(
        animation: _opacityAnimation,
        builder: (context, child) {
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: _opacityAnimation.value),
              boxShadow: [
                BoxShadow(
                  color: Colors.white
                      .withValues(alpha: _opacityAnimation.value * 0.5),
                  blurRadius: 2,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
