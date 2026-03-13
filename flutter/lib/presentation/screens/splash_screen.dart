import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../navigation/main_shell.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _textFade;
  late Animation<double> _ringAnim;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _scaleAnim = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.0, 0.45, curve: Curves.easeIn)),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.55, 1.0, curve: Curves.easeIn)),
    );

    _ringAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.3, 0.85, curve: Curves.easeOut)),
    );

    _ctrl.forward();

    Timer(const Duration(milliseconds: 2600), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainShell(),
            transitionDuration: const Duration(milliseconds: 500),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoSize = size.width * 0.52;

    return Scaffold(
      backgroundColor: kBgColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Radial glow background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _fadeAnim,
              builder: (_, __) => CustomPaint(
                painter: _GlowPainter(_fadeAnim.value),
              ),
            ),
          ),

          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo area: rings + icon
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) {
                    return FadeTransition(
                      opacity: _fadeAnim,
                      child: ScaleTransition(
                        scale: _scaleAnim,
                        child: SizedBox(
                          width: logoSize + 40,
                          height: logoSize + 40,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer pulsing ring
                              CustomPaint(
                                size: Size(logoSize + 40, logoSize + 40),
                                painter: _RingPainter(
                                  progress: _ringAnim.value,
                                  color: kProfitColor.withValues(alpha: 0.15),
                                  strokeWidth: 2,
                                ),
                              ),
                              // Inner ring
                              CustomPaint(
                                size: Size(logoSize + 10, logoSize + 10),
                                painter: _RingPainter(
                                  progress: _ringAnim.value,
                                  color: kProfitColor.withValues(alpha: 0.35),
                                  strokeWidth: 1.5,
                                ),
                              ),
                              // Logo circle
                              Container(
                                width: logoSize,
                                height: logoSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(0xFF1E3A2F),
                                      kSurfaceColor,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kProfitColor.withValues(alpha: 0.3),
                                      blurRadius: 40,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                  border: Border.all(
                                    color: kProfitColor.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: const _BitcoinLogo(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 36),

                // Text block
                FadeTransition(
                  opacity: _textFade,
                  child: Column(
                    children: [
                      // "CryptoBot" title with gradient
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF00D4AA), Color(0xFF00A87A)],
                        ).createShader(bounds),
                        child: const Text(
                          'CryptoBot',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Automated Crypto Trading',
                        style: TextStyle(
                          color: kTextSecondary.withValues(alpha: 0.75),
                          fontSize: 13,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '— Dev by Tayyab —',
                        style: TextStyle(
                          color: kProfitColor.withValues(alpha: 0.55),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: size.height * 0.1),

                // Progress bar
                FadeTransition(
                  opacity: _textFade,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 56,
                        height: 2,
                        child: LinearProgressIndicator(
                          backgroundColor: kDividerColor,
                          color: kProfitColor,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Initializing…',
                        style: TextStyle(
                          color: kTextSecondary.withValues(alpha: 0.4),
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
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

// ─── Bitcoin ₿ icon drawn purely in Flutter ────────────────────────────────
class _BitcoinLogo extends StatelessWidget {
  const _BitcoinLogo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer hex-like glow shape
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kProfitColor.withValues(alpha: 0.08),
            ),
          ),
          // ₿ symbol
          const Text(
            '₿',
            style: TextStyle(
              color: kProfitColor,
              fontSize: 62,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Radial background glow ────────────────────────────────────────────────
class _GlowPainter extends CustomPainter {
  final double opacity;
  _GlowPainter(this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.38;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00D4AA).withValues(alpha: 0.08 * opacity),
          kBgColor.withValues(alpha: 0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(
          center: Offset(cx, cy), radius: size.width * 0.65));

    canvas.drawCircle(Offset(cx, cy), size.width * 0.65, paint);
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.opacity != opacity;
}

// ─── Animated arc ring ─────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  _RingPainter(
      {required this.progress,
      required this.color,
      required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(
        strokeWidth, strokeWidth, size.width - strokeWidth * 2, size.height - strokeWidth * 2);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
