import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';
import '../../../../widgets/glass_card.dart';

class SleepStageBar extends StatelessWidget {
  final int deepMins;
  final int lightMins;
  final int remMins;
  final int awakeMins;

  const SleepStageBar({
    super.key,
    required this.deepMins,
    required this.lightMins,
    required this.remMins,
    required this.awakeMins,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = deepMins + lightMins + remMins + awakeMins;
    final safeTotal = total > 0 ? total : 1;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SLEEP STAGES BREAKDOWN',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),

          // Horizontal multi-colored progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  if (deepMins > 0)
                    Expanded(
                      flex: deepMins,
                      child: Container(color: AppColors.sleepDeep),
                    ),
                  if (lightMins > 0)
                    Expanded(
                      flex: lightMins,
                      child: Container(color: AppColors.sleepLight),
                    ),
                  if (remMins > 0)
                    Expanded(
                      flex: remMins,
                      child: Container(color: AppColors.sleepREM),
                    ),
                  if (awakeMins > 0)
                    Expanded(
                      flex: awakeMins,
                      child: Container(color: AppColors.sleepAwake),
                    ),
                  if (total == 0)
                    Expanded(
                      child: Container(color: AppColors.surfaceElevated),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4-stage stats breakdown
          Row(
            children: [
              Expanded(
                child: _buildStageStat(
                  label: 'Deep',
                  mins: deepMins,
                  pct: (deepMins / safeTotal * 100).round(),
                  color: AppColors.sleepDeep,
                  isOptimal: deepMins >= 60,
                ),
              ),
              Expanded(
                child: _buildStageStat(
                  label: 'Light',
                  mins: lightMins,
                  pct: (lightMins / safeTotal * 100).round(),
                  color: AppColors.sleepLight,
                ),
              ),
              Expanded(
                child: _buildStageStat(
                  label: 'REM',
                  mins: remMins,
                  pct: (remMins / safeTotal * 100).round(),
                  color: AppColors.sleepREM,
                  isOptimal: remMins >= 90,
                ),
              ),
              Expanded(
                child: _buildStageStat(
                  label: 'Awake',
                  mins: awakeMins,
                  pct: (awakeMins / safeTotal * 100).round(),
                  color: AppColors.sleepAwake,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStageStat({
    required String label,
    required int mins,
    required int pct,
    required Color color,
    bool? isOptimal,
  }) {
    final hoursPart = mins ~/ 60;
    final minsPart = mins % 60;
    final timeStr = hoursPart > 0 ? '${hoursPart}h ${minsPart}m' : '${minsPart}m';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          timeStr,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
        ),
        Text(
          '$pct%',
          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
        ),
      ],
    );
  }
}
