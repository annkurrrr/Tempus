import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A large, animated circular timer display showing HH:MM:SS.
class TimerDisplay extends StatelessWidget {
  final Duration elapsed;
  final bool isRunning;

  const TimerDisplay({
    super.key,
    required this.elapsed,
    required this.isRunning,
  });

  String _format(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final c = TempusColors.of(context);
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: isRunning
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.25),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ]
                  : [],
            ),
          ),
          // Progress ring
          CustomPaint(
            size: const Size(240, 240),
            painter: _RingPainter(
              progress: (elapsed.inSeconds % 60) / 60.0,
              isRunning: isRunning,
              trackColor: c.surfaceLighter,
            ),
          ),
          // Inner circle with time text
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.cardBg,
              border: Border.all(
                color: isRunning
                    ? AppTheme.primary.withValues(alpha: 0.3)
                    : c.surfaceLighter,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _format(elapsed),
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 3,
                  color: isRunning ? AppTheme.primary : c.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints a single-arc progress ring around the timer.
class _RingPainter extends CustomPainter {
  final double progress;
  final bool isRunning;
  final Color trackColor;

  _RingPainter({
    required this.progress,
    required this.isRunning,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.width / 2;

    // Track (dim ring)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, trackPaint);

    if (!isRunning && progress == 0) return;

    // Progress arc
    final arcPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: const [
          AppTheme.primaryDark,
          AppTheme.primary,
          AppTheme.accent,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.isRunning != isRunning ||
      old.trackColor != trackColor;
}
