import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/sleep_data.dart';
import '../../../../theme/colors.dart';
import '../../../../widgets/glass_card.dart';

class HypnogramChart extends StatelessWidget {
  final List<SleepStageInterval> stages;

  const HypnogramChart({
    super.key,
    required this.stages,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (stages.isEmpty) {
      return GlassCard(
        child: SizedBox(
          height: 160,
          child: Center(
            child: Text(
              'No granular sleep stage intervals recorded for last night.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final sorted = List<SleepStageInterval>.from(stages)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final startTime = sorted.first.startTime;
    final endTime = sorted.last.endTime;
    final totalDuration = endTime.difference(startTime).inSeconds;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SLEEP HYPNOGRAM (STAGES)',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '${DateFormat('h:mm a').format(startTime)} - ${DateFormat('h:mm a').format(endTime)}',
                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: Row(
              children: [
                // Y-axis labels
                const SizedBox(
                  width: 48,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Awake', style: TextStyle(color: AppColors.sleepAwake, fontSize: 10, fontWeight: FontWeight.w600)),
                      Text('REM', style: TextStyle(color: AppColors.sleepREM, fontSize: 10, fontWeight: FontWeight.w600)),
                      Text('Light', style: TextStyle(color: AppColors.sleepLight, fontSize: 10, fontWeight: FontWeight.w600)),
                      Text('Deep', style: TextStyle(color: AppColors.sleepDeep, fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Custom drawn hypnogram timeline
                Expanded(
                  child: CustomPaint(
                    painter: _HypnogramPainter(
                      stages: sorted,
                      startTime: startTime,
                      totalDurationSecs: totalDuration > 0 ? totalDuration : 1,
                    ),
                    child: const SizedBox.expand(),
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

class _HypnogramPainter extends CustomPainter {
  final List<SleepStageInterval> stages;
  final DateTime startTime;
  final int totalDurationSecs;

  _HypnogramPainter({
    required this.stages,
    required this.startTime,
    required this.totalDurationSecs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (stages.isEmpty) return;

    // Y coordinates for each stage (top to bottom)
    final yAwake = size.height * 0.08;
    final yRem = size.height * 0.38;
    final yLight = size.height * 0.68;
    final yDeep = size.height * 0.95;

    double getY(String stage) {
      switch (stage) {
        case 'awake':
          return yAwake;
        case 'rem':
          return yRem;
        case 'light':
          return yLight;
        case 'deep':
          return yDeep;
        default:
          return yLight;
      }
    }

    Color getColor(String stage) {
      switch (stage) {
        case 'awake':
          return AppColors.sleepAwake;
        case 'rem':
          return AppColors.sleepREM;
        case 'light':
          return AppColors.sleepLight;
        case 'deep':
          return AppColors.sleepDeep;
        default:
          return AppColors.sleepLight;
      }
    }

    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final y in [yAwake, yRem, yLight, yDeep]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw hypnogram blocks and step transitions
    Offset? prevPoint;

    for (final s in stages) {
      final startOffset = s.startTime.difference(startTime).inSeconds;
      final x1 = (startOffset / totalDurationSecs * size.width).clamp(0.0, size.width);
      final x2 = ((startOffset + s.durationSecs) / totalDurationSecs * size.width).clamp(0.0, size.width);
      final y = getY(s.stage);
      final color = getColor(s.stage);

      // Connect from previous stage vertically if not first
      if (prevPoint != null) {
        final transitionPaint = Paint()
          ..color = AppColors.textTertiary.withValues(alpha: 0.6)
          ..strokeWidth = 1.5;
        canvas.drawLine(prevPoint, Offset(x1, y), transitionPaint);
      }

      // Draw horizontal stage interval segment
      final segmentPaint = Paint()
        ..color = color
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(x1, y), Offset(x2, y), segmentPaint);

      // Subtle fill down
      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTRB(x1, y, x2, size.height), fillPaint);

      prevPoint = Offset(x2, y);
    }
  }

  @override
  bool shouldRepaint(covariant _HypnogramPainter old) => true;
}
