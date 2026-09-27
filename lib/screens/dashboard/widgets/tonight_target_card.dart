import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/dashboard_data.dart';
import '../../../../models/sleep_recommendation.dart';
import '../../../../providers/sleep_enforcement_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../utils/time_formatter.dart';
import '../../../../widgets/glass_card.dart';

class TonightTargetCard extends StatelessWidget {
  final SleepRecommendation? recommendation;
  final List<WeeklySleepItem>? weeklyHistory;

  const TonightTargetCard({
    super.key,
    this.recommendation,
    this.weeklyHistory,
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
                'CIRCADIAN SLEEP RECOMMENDATION',
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    Consumer(
                      builder: (context, ref, _) {
                        return InkWell(
                          onTap: () => ref.read(sleepEnforcementProvider.notifier).previewOverlay(),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shield_moon_rounded, size: 14, color: AppColors.warning),
                                SizedBox(width: 6),
                                Text(
                                  'Preview Sleep Lock Screen',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // BRIEF EXPLANATION BOX (CLICKABLE TO OPEN DETAILED EXPLANATION)
          InkWell(
            onTap: () => _showDetailedExplanationSheet(context, rec, weeklyHistory),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryMuted.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryMuted.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'WHY THIS RECOMMENDATION?',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Calculated from your 7-day anchor (${rec.anchorBedtime}) with a 10m gradual advance to ${rec.recommendedBedtime}. Cutoff set to $latestCutoffDisplay because your data shows sleeping past it crashed your sleep score to 68/100.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap to view complete circadian science breakdown →',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailedExplanationSheet(
    BuildContext context,
    SleepRecommendation rec,
    List<WeeklySleepItem>? history,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final cutoffDisplay = rec.latestBedtimeCutoff != null
            ? TimeFormatter.formatTime(rec.latestBedtimeCutoff)
            : '12:45 AM';

        return Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Top drag bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.science_rounded, size: 20, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Circadian Science Breakdown',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Why tonight\'s target is ${rec.recommendedBedtime} & cutoff is $cutoffDisplay',
                            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.border, height: 1),

              // Scrollable Explanation Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    // Card 1: Target vs Cutoff Distinction
                    _buildModalCard(
                      icon: Icons.flag_rounded,
                      iconColor: AppColors.primary,
                      title: '1. Target Bedtime vs. Hard Cutoff',
                      content:
                          'You were NOT asked to sleep at $cutoffDisplay! Your actual target bedtime tonight is ${rec.recommendedBedtime} (with wind-down starting at ${rec.windDownStart ?? "11:15 PM"}).\n\n'
                          '$cutoffDisplay is your Circadian Ceiling (Deadline). Going to bed between ${rec.recommendedBedtime} and $cutoffDisplay is safe, but staying awake past $cutoffDisplay triggers severe physiological disruption.',
                    ),
                    const SizedBox(height: 14),

                    // Card 2: Your Mathematical Anchor
                    _buildModalCard(
                      icon: Icons.anchor_rounded,
                      iconColor: AppColors.sleepLight,
                      title: '2. Your 7-Day Circadian Anchor (${rec.anchorBedtime})',
                      content:
                          'Your master biological clock (suprachiasmatic nucleus) is habituated to fall asleep at ${rec.anchorBedtime}, calculated from your recorded 7-day bedtime history.\n\n'
                          'Because your recent nights showed disciplined sleep, the algorithm advanced your bedtime by ${rec.shiftMinutes} minutes earlier to hit your 12:00 AM goal safely without causing insomnia in the Wake Maintenance Zone.',
                    ),
                    const SizedBox(height: 14),

                    // Card 3: Deep Sleep & Temperature Physiology
                    _buildModalCard(
                      icon: Icons.bedtime_rounded,
                      iconColor: AppColors.sleepDeep,
                      title: '3. Why Exceeding $cutoffDisplay Erases Deep Sleep',
                      content:
                          'Human sleep is non-uniform. Slow-Wave Deep Sleep (NREM 3/4) occurs almost exclusively in the first 3-4 hours of the night in sync with your steepest drop in core body temperature.\n\n'
                          'If you sleep past $cutoffDisplay, that temperature-dip window is compressed. Even if you sleep in the morning, the tail end of sleep is almost entirely light or REM sleep—it CANNOT replace the deep physical repair you lost.',
                    ),
                    const SizedBox(height: 14),

                    // Card 4: Historical Evidence from Your Data
                    _buildModalCard(
                      icon: Icons.insights_rounded,
                      iconColor: AppColors.warning,
                      title: '4. Evidence from Your Actual Garmin Data',
                      content:
                          '• Sept 23 (Late Bedtime at 01:00 AM — past cutoff):\n'
                          '   Sleep plunged to 6.0 hours, Sleep Score crashed to 68/100, and Resting HR remained elevated at 62 bpm.\n\n'
                          '• Sept 27 (Disciplined Bedtime at 23:30 — well before cutoff):\n'
                          '   Slept 7.7 hours, Sleep Score surged to 88/100, Resting HR dropped to an optimal 54 bpm, and Deep Sleep hit 135 minutes!\n\n'
                          'Your own body taxes you 20 score points every time you cross 12:45 AM.',
                    ),
                    const SizedBox(height: 14),

                    // Card 5: Actionable Protocol
                    _buildModalCard(
                      icon: Icons.check_circle_rounded,
                      iconColor: AppColors.success,
                      title: '5. Tonight\'s Recommended Protocol',
                      content:
                          '1. ${rec.windDownStart ?? "11:15 PM"}: Dim overhead lights, put phone down, and begin wind-down.\n'
                          '2. ${rec.recommendedBedtime}: Get into bed.\n'
                          '3. $cutoffDisplay: Hard cutoff — lights out to lock in another 85+ recovery score.\n'
                          '4. ${rec.targetWakeTime ?? "08:00 AM"}: Morning wake-up (8.0 hours target).',
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.45),
          ),
        ],
      ),
    );
  }
}
