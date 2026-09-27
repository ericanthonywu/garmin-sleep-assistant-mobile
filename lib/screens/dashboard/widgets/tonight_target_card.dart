import 'package:flutter/material.dart';
import '../../../../models/sleep_recommendation.dart';
import '../../../../theme/colors.dart';
import '../../../../utils/time_formatter.dart';
import '../../../../widgets/glass_card.dart';

class TonightTargetCard extends StatelessWidget {
  final SleepRecommendation? recommendation;

  const TonightTargetCard({
    super.key,
    this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    if (recommendation == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final rec = recommendation!;

    Color statusColor;
    String statusLabel;

    switch (rec.adherenceStatus) {
      case 'advancing':
        statusColor = AppColors.success;
        statusLabel = 'STEPPING EARLIER';
        break;
      case 'achieved':
        statusColor = AppColors.primary;
        statusLabel = 'TARGET HIT';
        break;
      case 'regressing':
        statusColor = AppColors.warning;
        statusLabel = 'ADAPTING';
        break;
      case 'holding':
      default:
        statusColor = AppColors.primaryMuted;
        statusLabel = 'STABILIZING';
        break;
    }

    final recommendedBedtimeDisplay = TimeFormatter.formatTime(rec.recommendedBedtime);
    final latestCutoffDisplay = rec.latestBedtimeCutoff != null
        ? TimeFormatter.formatTime(rec.latestBedtimeCutoff)
        : TimeFormatter.formatTime('00:45');
    final targetWakeDisplay = rec.targetWakeTime != null
        ? TimeFormatter.formatTime(rec.targetWakeTime)
        : TimeFormatter.formatTime('07:30');
    final windDownDisplay = rec.windDownStart != null
        ? TimeFormatter.formatTime(rec.windDownStart)
        : null;

    return GlassCard(
      color: AppColors.surfaceElevated,
      borderColor: AppColors.primaryMuted.withValues(alpha: 0.35),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & Adherence Badge
          Row(
            children: [
              const Icon(Icons.hotel_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'CIRCADIAN SLEEP RECOMMENDATIONS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Primary Bedtime & Target Wake Row
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RECOMMENDED BEDTIME',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      recommendedBedtimeDisplay,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                        color: AppColors.textPrimary,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rec.shiftMinutes > 0
                          ? '${rec.shiftMinutes}m earlier shift from anchor'
                          : 'Aligned with circadian baseline',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.alarm_rounded, size: 14, color: AppColors.momWarm),
                          const SizedBox(width: 4),
                          Text(
                            'TARGET WAKE',
                            style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        targetWakeDisplay,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (windDownDisplay != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Wind-down: $windDownDisplay',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // HIGHLIGHTED BOX: LATEST PERMISSIBLE BEDTIME CUTOFF (CIRCADIAN CEILING)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.warning.withValues(alpha: 0.12),
                  AppColors.surfaceElevated,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.timer_off_rounded,
                        size: 16,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LATEST TIME TO SLEEP (CIRCADIAN CEILING)',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.warning,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const Text(
                            'Sleep science cutoff threshold',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      latestCutoffDisplay,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Sleeping past $latestCutoffDisplay triggers a circadian phase delay, elevates core nocturnal temperature, and drastically suppresses deep Slow-Wave Sleep (NREM 3). Lights out before this cutoff!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Guidance Note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rec.guidance,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
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
