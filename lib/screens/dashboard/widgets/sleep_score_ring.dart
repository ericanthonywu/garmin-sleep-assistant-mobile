import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';

class SleepScoreRing extends StatelessWidget {
  final int? score;
  final String? sleepDuration;
  final String? verdict;

  const SleepScoreRing({
    super.key,
    this.score,
    this.sleepDuration,
    this.verdict,
  });

  @override
  Widget build(BuildContext context) {
    final displayScore = score ?? 0;
    final color = AppColors.sleepScoreColor(score);
    final theme = Theme.of(context);

    return SizedBox(
      width: 170,
      height: 170,
      child: CustomPaint(
        painter: _RingPainter(
          progress: score != null ? (displayScore / 100).clamp(0.0, 1.0) : 0.0,
          color: color,
          backgroundColor: AppColors.border.withValues(alpha: 0.5),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score != null ? '$score' : '--',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 44,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'SLEEP SCORE',
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  fontSize: 10,
                  color: AppColors.textTertiary,
                ),
              ),
              if (sleepDuration != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    sleepDuration!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 11.0;

    // Track circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      // Progress sweep arc
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}
