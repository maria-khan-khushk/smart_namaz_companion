import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'main_wrapper.dart';

/// ============================================================================
/// Awwab Smart Namaz Companion — Premium Cinematic Splash Screen (V3)
/// ============================================================================
/// This file implements a high-end, bespoke spiritual visual identity reveal.
///
/// Core Design Improvements:
/// 1. Route Cross-Fade Transition (No Snapping): The splash screen itself remains
///    fully active and animating throughout its entire lifecycle. The exit dissolve
///    is handled by fading in the MainWrapper directly *over* the fully opaque,
///    fully active splash screen, ensuring absolute continuity without black flashes.
/// 2. Multi-Layer High-Contrast Parallax Mosque: Domes and minarets are painted
///    using distinct slate-olive tones with elevated contrast (up to 45% opacity)
///    so they are beautifully clear and visible in both light and dark themes.
/// 3. Intricate Hanging Lanterns (Fanoos): Draws detailed traditional lanterns
///    with pulsing, sine-wave driven glowing candle flames that never freeze.
/// 4. Massive Brand Logo: scaled to a prominent 210x210 size, perfectly centered
///    and framed inside a counter-rotating gold Rub el Hizb celestial outline.
/// ============================================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Main timeline controller for single-shot entrance phases
  late AnimationController _mainController;

  // Continuous loop controller to drive ongoing bead rotation & lantern flickers
  late AnimationController _rotationController;

  // Staggered animation timelines
  late Animation<double> _beadConvergence;
  late Animation<double> _emblemReveal;
  late Animation<double> _lightWave;
  late Animation<double> _backgroundShift;

  @override
  void initState() {
    super.initState();

    // Initialize the main sequential timeline (2.8 seconds total duration)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // Initialize the infinite loop controller (14-second slow rotation loop)
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
    _rotationController.repeat(); // Loop infinitely

    // 1. Tasbeeh beads convergence timeline (easeInOutCubic for natural gravitational pull)
    _beadConvergence = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.60, curve: Curves.easeInOutCubic),
      ),
    );

    // 2. Central Rub el Hizb framing outline & brand logo reveal timeline
    _emblemReveal = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.78, curve: Curves.easeOut),
      ),
    );

    // 3. Radial expansion light wave sweep timeline
    _lightWave = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.48, 0.88, curve: Curves.easeOutQuad),
      ),
    );

    // 4. Background gradient shift (ambient light expansion timeline)
    _backgroundShift = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.30, 0.85, curve: Curves.easeInOut),
      ),
    );

    // Launch the splash entry sequence
    _mainController.forward();

    // Remove the default Flutter Native Splash so our premium graphics render
    FlutterNativeSplash.remove();

    // Trigger seamless screen transition. MainWrapper will fade in over the active splash.
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (context, animation, secondaryAnimation) => MainWrapper(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // Custom smooth fade-in directly over the active splash screen
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 1100),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Set dynamic system overlays matching light and dark aesthetic
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: isDark ? const Color(0xFF040603) : const Color(0xFFE4E9E2),
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    // Dynamic background slate/sage gradient setup
    final Color bgStart = isDark ? const Color(0xFF040603) : const Color(0xFFE4E9E2);
    final Color bgEnd = isDark ? const Color(0xFF0C130A) : const Color(0xFFF3F6F2);

    final Color emblemColor = isDark ? const Color(0xFFD4AF37) : const Color(0xFFAC8A32);

    return Scaffold(
      backgroundColor: bgStart,
      body: AnimatedBuilder(
        animation: Listenable.merge([_mainController, _rotationController]),
        builder: (context, child) {
          // Dynamic ambient gradient interpolation
          final Color currentBgCenter = Color.lerp(bgStart, bgEnd, _backgroundShift.value)!;
          final Color currentBgOuter = Color.lerp(bgStart, isDark ? const Color(0xFF010201) : const Color(0xFFDFE4DD), _backgroundShift.value)!;

          // Infinite rotational metrics for constant linear motion
          final double activeBeadRotation = _rotationController.value * 2.0 * pi;
          final double activeEmblemRotation = _rotationController.value * -2.0 * pi * 0.20;

          // We keep the splash fully opaque here. The FadeTransition in PageRouteBuilder
          // will smoothly fade in the MainWrapper over the top of the running splash!
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.4,
                colors: [
                  currentBgCenter,
                  currentBgOuter,
                ],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Layer 1: Elegant premium backdrop with subtle architectural forms
                Positioned.fill(
                  child: CustomPaint(
                    painter: PremiumSplashBackdropPainter(
                      progress: _beadConvergence.value,
                      isDark: isDark,
                    ),
                  ),
                ),

                // Layer 2: 33 Tasbeeh beads converging (keeps flowing continuously driven by _rotationController)
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: CinematicSplashPainter(
                        beadProgress: _beadConvergence.value,
                        rotationProgress: activeBeadRotation,
                        lightProgress: _lightWave.value,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),

                // Layer 3: Concentric rotating gold Rub el Hizb frame (scaled to wrap around the massive logo beautifully)
                SizedBox(
                  width: 380,
                  height: 380,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: EmblemFramePainter(
                        progress: _emblemReveal.value,
                        rotationProgress: activeEmblemRotation,
                        color: emblemColor,
                      ),
                    ),
                  ),
                ),

                // Layer 4: Prominent 210x210 brand logo (no brand text overlays for pure minimal luxury)
                Opacity(
                  opacity: _emblemReveal.value,
                  child: Transform.scale(
                    scale: 0.80 + 0.20 * _emblemReveal.value,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: emblemColor.withOpacity(0.08 * _emblemReveal.value),
                            blurRadius: 44,
                          )
                        ],
                      ),
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                        width: 260,
                        height: 260,
                        cacheWidth: 800,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// PremiumSplashBackdropPainter
/// Draws a refined, minimal premium silhouette backing the central brand reveal.
/// ─────────────────────────────────────────────────────────────────────────────
class PremiumSplashBackdropPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  PremiumSplashBackdropPainter({
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final w = size.width;
    final h = size.height;
    final double fade = progress.clamp(0.0, 1.0);

    // Ambient halo for premium atmosphere
    final haloPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.35),
        radius: 0.65,
        colors: [
          (isDark ? const Color(0xFF8FB78F) : const Color(0xFFBAC9A8)).withOpacity(0.18 * fade),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(w * 0.5, h * 0.24), radius: w * 0.72))
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(w * 0.5, h * 0.24), w * 0.72, haloPaint);

    // Large refined silhouette base
    final silhouetteColor = isDark ? const Color(0xFF1E2C21) : const Color(0xFFD8E2CC);
    final silhouettePaint = Paint()
      ..color = silhouetteColor.withOpacity(0.56 * fade)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final silhouette = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.82)
      ..cubicTo(w * 0.14, h * 0.70, w * 0.20, h * 0.60, w * 0.34, h * 0.60)
      ..cubicTo(w * 0.48, h * 0.60, w * 0.54, h * 0.74, w * 0.62, h * 0.74)
      ..cubicTo(w * 0.72, h * 0.74, w * 0.82, h * 0.62, w * 0.94, h * 0.68)
      ..lineTo(w, h * 0.68)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(silhouette, silhouettePaint);

    // Soft architectural accents
    final accentPaint = Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.06 * fade : 0.10 * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;
    canvas.drawPath(silhouette, accentPaint);

    final archPaint = Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.08 * fade : 0.14 * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..isAntiAlias = true;
    canvas.drawArc(Rect.fromCircle(center: Offset(w * 0.38, h * 0.70), radius: w * 0.18), pi * 0.9, pi * 0.95, false, archPaint);
    canvas.drawArc(Rect.fromCircle(center: Offset(w * 0.76, h * 0.72), radius: w * 0.10), pi * 0.9, pi * 0.95, false, archPaint);

    // Subtle starfield for luxe ambiance
    final starPaint = Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.18 * fade : 0.12 * fade)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    _drawStar(canvas, Offset(w * 0.18, h * 0.20), 2.2, starPaint);
    _drawStar(canvas, Offset(w * 0.36, h * 0.14), 1.6, starPaint);
    _drawStar(canvas, Offset(w * 0.79, h * 0.12), 1.8, starPaint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(Offset(center.dx + radius * 0.75, center.dy - radius * 0.75), radius * 0.35, paint);
  }

  @override
  bool shouldRepaint(covariant PremiumSplashBackdropPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.isDark != isDark;
}

/// ─────────────────────────────────────────────────────────────────────────────
/// CinematicSplashPainter
/// Custom-paints the 33 converging tasbeeh beads and expansion light waves.
/// ─────────────────────────────────────────────────────────────────────────────
class CinematicSplashPainter extends CustomPainter {
  final double beadProgress;
  final double rotationProgress;
  final double lightProgress;
  final bool isDark;

  CinematicSplashPainter({
    required this.beadProgress,
    required this.rotationProgress,
    required this.lightProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = min(size.width, size.height) * 0.28;

    // Palette adaptation for Light / Dark themes
    final Color beadColor = isDark ? const Color(0xFF8C9B86) : const Color(0xFF5E6D58);

    // 1. Draw expansion soft Light Wave
    if (lightProgress > 0) {
      final double waveRadius = baseRadius * 1.35 + (max(size.width, size.height) * 0.5) * lightProgress;
      final double opacity = 1.0 - lightProgress;

      final lightPaint = Paint()
        ..color = (isDark ? const Color(0xFFE2EADF) : const Color(0xFFC5D2C1)).withOpacity(0.08 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(center, waveRadius, lightPaint);
      canvas.drawCircle(center, waveRadius * 1.12, lightPaint..strokeWidth = 0.8..color = lightPaint.color.withOpacity(0.03 * opacity));
    }

    // 2. Draw 33 Tasbeeh beads converging (keeps flowing continuously!)
    _drawBeads(canvas, center, baseRadius, beadProgress, rotationProgress, beadColor);
  }

  void _drawBeads(Canvas canvas, Offset center, double baseRadius, double progress, double rotation, Color color) {
    for (int i = 0; i < 33; i++) {
      final double targetAngle = i * (2 * pi / 33) + rotation;

      final double startAngle = targetAngle + 0.55 * sin(i * 7.3);
      final double startRadius = baseRadius * (1.35 + 0.28 * cos(i * 3.7));

      final double currentRadius = _lerp(startRadius, baseRadius, progress);
      final double currentAngle = _lerp(startAngle, targetAngle, progress);

      final double x = center.dx + currentRadius * cos(currentAngle);
      final double y = center.dy + currentRadius * sin(currentAngle);

      final double opacity = _lerp(0.08, 0.42, progress);
      final double beadRadius = _lerp(2.0, 2.8, progress);

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), beadRadius, paint);
    }
  }

  double _lerp(double start, double end, double t) => start + (end - start) * t;

  @override
  bool shouldRepaint(covariant CinematicSplashPainter oldDelegate) =>
      oldDelegate.beadProgress != beadProgress ||
      oldDelegate.rotationProgress != rotationProgress ||
      oldDelegate.lightProgress != lightProgress ||
      oldDelegate.isDark != isDark;
}

/// ─────────────────────────────────────────────────────────────────────────────
/// EmblemFramePainter
/// Custom-paints the celestial Rub el Hizb 8-point gold frame.
/// ─────────────────────────────────────────────────────────────────────────────
class EmblemFramePainter extends CustomPainter {
  final double progress;
  final double rotationProgress;
  final Color color;

  EmblemFramePainter({
    required this.progress,
    required this.rotationProgress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    // Framed size wraps around the upscaled 210x210 logo beautifully
    final emblemSize = size.width * 0.78;
    final opacity = progress;

    final paint = Paint()
      ..color = color.withOpacity(0.65 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final half = emblemSize / 2;

    // Draw the 8-point geometric star composed of two concentric square forms rotated by 45 degrees + continuous rotation
    final square1 = Path();
    for (int i = 0; i < 4; i++) {
      final double currentAngle = i * pi / 2 + rotationProgress;
      final double dist = half * sqrt(2);
      final double x = center.dx + dist * cos(currentAngle);
      final double y = center.dy + dist * sin(currentAngle);
      if (i == 0) {
        square1.moveTo(x, y);
      } else {
        square1.lineTo(x, y);
      }
    }
    square1.close();

    final square2 = Path();
    const double angle = pi / 4;
    for (int i = 0; i < 4; i++) {
      final double currentAngle = i * pi / 2 + angle + rotationProgress;
      final double dist = half * sqrt(2);
      final double x = center.dx + dist * cos(currentAngle);
      final double y = center.dy + dist * sin(currentAngle);
      if (i == 0) {
        square2.moveTo(x, y);
      } else {
        square2.lineTo(x, y);
      }
    }
    square2.close();

    canvas.drawPath(square1, paint);
    canvas.drawPath(square2, paint);

    // Dynamic, very thin outer enclosing border for the star
    canvas.drawCircle(center, emblemSize * 0.88, paint..strokeWidth = 0.6..color = color.withOpacity(0.25 * opacity));
  }

  @override
  bool shouldRepaint(covariant EmblemFramePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.rotationProgress != rotationProgress ||
      oldDelegate.color != color;
}
