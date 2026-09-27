import 'package:flutter/material.dart';
import '../../../../models/sleep_recommendation.dart';
import '../../../../theme/colors.dart';
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

    return GlassCard(
      color: AppColors.surfaceElevated,
      borderColor: AppColors.primaryMuted.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bedtime_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'MAMA\'S TONIGHT BEDTIME TARGET',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
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
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rec.recommendedBedtime,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 32,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    rec.shiftMinutes > 0
                        ? '${rec.shiftMinutes} min earlier than your baseline'
                        : 'Aligned with your current anchor',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (rec.windDownStart != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.wb_twilight_rounded, size: 16, color: AppColors.momWarm),
                      const SizedBox(height: 4),
                      Text(
                        'WIND-DOWN',
                        style: theme.textTheme.labelSmall?.copyWith(fontSize: 8),
                      ),
                      Text(
                        rec.windDownStart!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
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
