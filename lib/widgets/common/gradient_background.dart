import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';

/// Slowly drifting blurred color blobs — the "gradient mesh" behind every
/// screen. Pure custom-paint-free implementation (positioned radial gradients
/// inside an [AnimatedBuilder]) so it stays cheap on desktop and mobile.
class GradientBackground extends StatefulWidget {
  const GradientBackground({super.key, this.child});

  /// Optional foreground; when omitted the background can be layered behind a
  /// Scaffold body directly.
  final Widget? child;

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Blobs follow the user's accent choice when running inside AppScope.
    final accent = accentById(
      AppScope.maybeOf(context)?.settings.accentColor ?? appAccents.first.id,
    );
    final primary = isDark ? accent.seed.withValues(alpha: 0.75) : accent.primary;
    final green = isDark ? accent.secondaryBright : accent.secondary;

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: isDark ? AppColors.darkBackground : const Color(0xFFFAF8FD),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value * 2 * math.pi;
            return CustomPaint(
              painter: _MeshPainter(
                primary: primary,
                green: green,
                primaryOffset: Offset(
                  math.cos(t) * 0.18,
                  math.sin(t * 0.8) * 0.14,
                ),
                greenOffset: Offset(
                  math.sin(t * 0.7 + 1.3) * 0.16,
                  math.cos(t * 0.6 + 0.7) * 0.18,
                ),
                accentOffset: Offset(
                  math.cos(t * 0.5 + 2.6) * 0.12,
                  math.sin(t * 0.9 + 2.1) * 0.10,
                ),
                dark: isDark,
              ),
            );
          },
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _MeshPainter extends CustomPainter {
  _MeshPainter({
    required this.primary,
    required this.green,
    required this.primaryOffset,
    required this.greenOffset,
    required this.accentOffset,
    required this.dark,
  });

  final Color primary;
  final Color green;
  final Offset primaryOffset;
  final Offset greenOffset;
  final Offset accentOffset;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final base = dark ? 0.16 : 0.13;
    _blob(canvas, size, primary,
        Alignment(-0.7, -0.8).within(size) + primaryOffset, base + 0.04);
    _blob(canvas, size, green,
        Alignment(0.9, -0.4).within(size) + greenOffset, base);
    _blob(canvas, size, primary.withValues(alpha: 0.6),
        Alignment(0.1, 1.1).within(size) + accentOffset, base);
  }

  void _blob(Canvas canvas, Size size, Color color, Offset center,
      double strength) {
    final radius = size.shortestSide * 0.75;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: strength),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_MeshPainter oldDelegate) =>
      oldDelegate.primaryOffset != primaryOffset ||
      oldDelegate.greenOffset != greenOffset ||
      oldDelegate.accentOffset != accentOffset ||
      oldDelegate.primary != primary ||
      oldDelegate.green != green ||
      oldDelegate.dark != dark;
}

extension on Alignment {
  Offset within(Size size) =>
      Offset((x + 1) / 2 * size.width, (y + 1) / 2 * size.height);
}
