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

    final startTime = sorted.first.startTime.toLocal();
    final endTime = sorted.last.endTime.toLocal();
    final totalDurationSecs = endTime.difference(startTime).inSeconds;
    final totalDurationMins = (totalDurationSecs / 60).round();

    // Identify Deep Sleep & Awake events
    final deepPeriods = sorted.where((s) => s.stage.toLowerCase() == 'deep').toList();
    final awakePeriods = sorted.where((s) => s.stage.toLowerCase() == 'awake').toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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

          // Main Chart Canvas with Y-axis labels
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
                      totalDurationSecs: totalDurationSecs > 0 ? totalDurationSecs : 1,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // X-AXIS TIME LABELS ROW (aligned with the chart canvas width)
          Padding(
            padding: const EdgeInsets.only(left: 56), // 48 width + 8 spacing of Y-axis
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('h:mm a').format(startTime),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w700),
                ),
                if (totalDurationMins > 120) ...[
                  Text(
                    DateFormat('h:mm a').format(startTime.add(Duration(minutes: (totalDurationMins * 0.25).round()))),
                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 9),
                  ),
                  Text(
                    DateFormat('h:mm a').format(startTime.add(Duration(minutes: (totalDurationMins * 0.50).round()))),
                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 9),
                  ),
                  Text(
                    DateFormat('h:mm a').format(startTime.add(Duration(minutes: (totalDurationMins * 0.75).round()))),
                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 9),
                  ),
                ],
                Text(
                  DateFormat('h:mm a').format(endTime),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // STAGE EVENT TIMELINE DETAILS: "At what time I enter deep, at what time I awake"
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'STAGE TRANSITION MILESTONES',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Deep Sleep Transitions
                if (deepPeriods.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.sleepDeep,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                                children: [
                                  const TextSpan(
                                    text: 'Entered Deep Sleep: ',
                                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                  ),
                                  TextSpan(
                                    text: DateFormat('h:mm a').format(deepPeriods.first.startTime.toLocal()),
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.sleepDeep),
                                  ),
                                  if (deepPeriods.length > 1)
                                    TextSpan(
                                      text: ' (Total ${deepPeriods.length} cycles)',
                                      style: const TextStyle(color: AppColors.textTertiary),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              deepPeriods.map((p) {
                                final s = DateFormat('h:mm a').format(p.startTime.toLocal());
                                final e = DateFormat('h:mm a').format(p.endTime.toLocal());
                                final dur = p.durationSecs ~/ 60;
                                return '$s - $e (${dur}m)';
                              }).join(' • '),
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Nocturnal Awakenings
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.sleepAwake,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                              children: [
                                const TextSpan(
                                  text: 'Awakenings / Night Interruptions: ',
                                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                ),
                                TextSpan(
                                  text: awakePeriods.isEmpty
                                      ? 'None (Continuous sleep)'
                                      : awakePeriods.map((p) {
                                          final s = DateFormat('h:mm a').format(p.startTime.toLocal());
                                          final dur = p.durationSecs ~/ 60;
                                          return '$s (${dur}m)';
                                        }).join(', '),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: awakePeriods.isEmpty ? AppColors.success : AppColors.sleepAwake,
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
                const SizedBox(height: 8),

                // Final Wake Up
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.momWarm,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                          children: [
                            const TextSpan(
                              text: 'Morning Wake-Up: ',
                              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            TextSpan(
                              text: DateFormat('h:mm a').format(endTime),
                              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.momWarm),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
      switch (stage.toLowerCase()) {
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
      switch (stage.toLowerCase()) {
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
      final startOffset = s.startTime.toLocal().difference(startTime).inSeconds;
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

      // Subtle fill down to bottom
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
