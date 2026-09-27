import 'package:flutter/material.dart';
import '../../../../models/sleep_data.dart';
import '../../../../theme/colors.dart';
import '../../../../utils/time_formatter.dart';
import '../../../../widgets/glass_card.dart';

class DailySleepScheduleChart extends StatelessWidget {
  final String? bedtime;
  final String? wakeTime;
  final double? sleepHours;
  final int deepSleepMins;
  final int lightSleepMins;
  final int remSleepMins;
  final int awakeMins;
  final List<SleepStageInterval> sleepStages;
  final VoidCallback? onTapDetails;

  const DailySleepScheduleChart({
    super.key,
    this.bedtime,
    this.wakeTime,
    this.sleepHours,
    this.deepSleepMins = 0,
    this.lightSleepMins = 0,
    this.remSleepMins = 0,
    this.awakeMins = 0,
    this.sleepStages = const [],
    this.onTapDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasData = (bedtime != null || wakeTime != null || (sleepHours != null && sleepHours! > 0));

    if (!hasData) {
      return _buildEmptyState(theme);
    }

    final bedtimeDisplay = TimeFormatter.formatTime(bedtime);
    final bedtime24 = TimeFormatter.format24h(bedtime);
    final wakeDisplay = TimeFormatter.formatTime(wakeTime);
    final wake24 = TimeFormatter.format24h(wakeTime);

    // Calculate total duration in minutes
    final totalStageMins = deepSleepMins + lightSleepMins + remSleepMins;
    final displayHours = sleepHours ?? (totalStageMins > 0 ? (totalStageMins / 60.0) : 0.0);
    final durationStr = totalStageMins > 0
        ? TimeFormatter.formatDurationMinutes(totalStageMins)
        : '${displayHours.toStringAsFixed(1)} hrs';

    return GlassCard(
      onTap: onTapDetails,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title and Total Sleep Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.nightlight_round, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'DAILY SLEEP & AWAKE SCHEDULE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryMuted.withValues(alpha: 0.3)),
                ),
                child: Text(
                  durationStr,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bedtime & Awake Hero Metrics Row
          Row(
            children: [
              Expanded(
                child: _buildTimeMetricBox(
                  theme: theme,
                  icon: Icons.bedtime_rounded,
                  iconColor: AppColors.primary,
                  label: 'BEDTIME',
                  timeStr: bedtimeDisplay,
                  time24Str: bedtime24,
                  subtitle: 'Fell Asleep',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeMetricBox(
                  theme: theme,
                  icon: Icons.wb_sunny_rounded,
                  iconColor: AppColors.momWarm,
                  label: 'AWAKE TIME',
                  timeStr: wakeDisplay,
                  time24Str: wake24,
                  subtitle: 'Woke Up',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Single-day Timeline Chart Visualizer
          _buildTimelineChart(context),
          const SizedBox(height: 14),

          // Stage Legend (if stage breakdown is available)
          if (deepSleepMins > 0 || lightSleepMins > 0 || remSleepMins > 0) ...[
            _buildStageLegend(theme),
            const SizedBox(height: 10),
          ],

          // Footer hint / insight
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 13, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _buildCircadianSummary(displayHours),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (onTapDetails != null) ...[
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textTertiary),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeMetricBox({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String timeStr,
    required String time24Str,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            timeStr,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                ),
              ),
              if (time24Str != '--' && time24Str != timeStr)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    time24Str,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineChart(BuildContext context) {
    final parsedBedtime = TimeFormatter.parseTime(bedtime);
    final parsedWake = TimeFormatter.parseTime(wakeTime);

    // Timeline spans from 8:00 PM (20:00) to 12:00 PM (12:00 next day) = 16 hours
    int windowStart = 480; // 20:00 = 8 PM
    int windowEnd = 1440; // 12:00 = 12 PM next day

    int bedMinutes = parsedBedtime != null
        ? TimeFormatter.toMinutesPastNoon(parsedBedtime.hour, parsedBedtime.minute)
        : 690; // default 23:30 (11:30 PM)

    int wakeMinutes = parsedWake != null
        ? TimeFormatter.toMinutesPastNoon(parsedWake.hour, parsedWake.minute)
        : 1150; // default 07:10 (7:10 AM)

    // Expand window dynamically if sleep started earlier or ended later
    if (bedMinutes < windowStart) {
      windowStart = (bedMinutes ~/ 60) * 60;
    }
    if (wakeMinutes > windowEnd) {
      windowEnd = ((wakeMinutes ~/ 60) + 1) * 60;
    }

    final totalWindowSpan = (windowEnd - windowStart).clamp(60, 1440);
    final leftRatio = ((bedMinutes - windowStart) / totalWindowSpan).clamp(0.0, 0.9);
    final widthRatio = ((wakeMinutes - bedMinutes) / totalWindowSpan).clamp(0.05, 1.0 - leftRatio);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final sleepLeft = totalWidth * leftRatio;
        final sleepWidth = totalWidth * widthRatio;

        return Column(
          children: [
            // Timeline bar container
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
              ),
              child: Stack(
                children: [
                  // Ambient Day/Night background guide
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0F172A).withValues(alpha: 0.7), // Night
                            const Color(0xFF1E293B).withValues(alpha: 0.5), // Deep Night
                            const Color(0xFF334155).withValues(alpha: 0.3), // Dawn
                            const Color(0xFF475569).withValues(alpha: 0.2), // Morning
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Illuminated Asleep Block
                  Positioned(
                    left: sleepLeft,
                    width: sleepWidth,
                    top: 5,
                    bottom: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: sleepStages.isNotEmpty
                            ? _buildSleepStageSegments()
                            : Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primaryMuted,
                                      AppColors.primary,
                                      AppColors.sleepLight,
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),

                  // Bedtime marker pin
                  Positioned(
                    left: (sleepLeft - 1).clamp(0.0, totalWidth - 3),
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.8),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Wake marker pin
                  Positioned(
                    left: (sleepLeft + sleepWidth - 1).clamp(0.0, totalWidth - 2),
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: AppColors.momWarm,
                        borderRadius: BorderRadius.circular(1),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.momWarm.withValues(alpha: 0.8),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Time axis tick marks
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAxisTick('8 PM', isNight: true),
                _buildAxisTick('11 PM', isNight: true),
                _buildAxisTick('2 AM', isNight: true),
                _buildAxisTick('5 AM', isNight: true),
                _buildAxisTick('8 AM', isNight: false),
                _buildAxisTick('11 AM', isNight: false),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSleepStageSegments() {
    return Row(
      children: sleepStages.map((stage) {
        Color color;
        switch (stage.stage.toLowerCase()) {
          case 'deep':
            color = AppColors.sleepDeep;
            break;
          case 'rem':
            color = AppColors.sleepREM;
            break;
          case 'awake':
            color = AppColors.sleepAwake;
            break;
          case 'light':
          default:
            color = AppColors.sleepLight;
            break;
        }

        final flex = stage.durationSecs.clamp(1, 86400);
        return Expanded(
          flex: flex,
          child: Container(
            color: color,
            height: double.infinity,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAxisTick(String label, {required bool isNight}) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: isNight ? AppColors.textTertiary : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildStageLegend(ThemeData theme) {
    final total = deepSleepMins + lightSleepMins + remSleepMins + awakeMins;
    final safeTotal = total > 0 ? total : 1;

    return Row(
      children: [
        _buildLegendItem('Deep', deepMins: deepSleepMins, pct: (deepSleepMins / safeTotal * 100).round(), color: AppColors.sleepDeep),
        const SizedBox(width: 8),
        _buildLegendItem('REM', deepMins: remSleepMins, pct: (remSleepMins / safeTotal * 100).round(), color: AppColors.sleepREM),
        const SizedBox(width: 8),
        _buildLegendItem('Light', deepMins: lightSleepMins, pct: (lightSleepMins / safeTotal * 100).round(), color: AppColors.sleepLight),
        if (awakeMins > 0) ...[
          const SizedBox(width: 8),
          _buildLegendItem('Awake', deepMins: awakeMins, pct: (awakeMins / safeTotal * 100).round(), color: AppColors.sleepAwake),
        ],
      ],
    );
  }

  Widget _buildLegendItem(String label, {required int deepMins, required int pct, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '$label ${deepMins}m',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildCircadianSummary(double hours) {
    if (hours >= 7.5) {
      return 'Consistent sleep window supports high nocturnal recovery & deep NREM phases.';
    } else if (hours >= 6.5) {
      return 'Solid sleep foundation. Aim for 7.5h tonight to repay accumulated debt.';
    } else {
      return 'Short sleep duration detected. Earlier wind-down recommended tonight.';
    }
  }

  Widget _buildEmptyState(ThemeData theme) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.nightlight_outlined, size: 36, color: AppColors.primaryMuted),
          const SizedBox(height: 10),
          Text(
            'NO SLEEP RECORDED TODAY',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sync Apple HealthKit or Garmin Connect to monitor your bedtime and wake schedule.',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
