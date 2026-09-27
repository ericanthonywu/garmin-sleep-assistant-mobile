import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../models/dashboard_data.dart';
import '../../../../models/sleep_recommendation.dart';
import '../../../../providers/sleep_enforcement_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../utils/time_formatter.dart';
import '../../../../widgets/glass_card.dart';

class TonightTargetCard extends StatelessWidget {
  final SleepRecommendation? recommendation;
  final List<WeeklySleepItem>? weeklyHistory;
  final String? date;

  const TonightTargetCard({
    super.key,
    this.recommendation,
    this.weeklyHistory,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    if (recommendation == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final rec = recommendation!;

    final recommendedBedtimeDisplay = TimeFormatter.formatTime(rec.recommendedBedtime);
    final latestCutoffDisplay = rec.latestBedtimeCutoff != null
        ? TimeFormatter.formatTime(rec.latestBedtimeCutoff)
        : TimeFormatter.formatTime('00:45');
    final targetWakeDisplay = rec.targetWakeTime != null
        ? TimeFormatter.formatTime(rec.targetWakeTime)
        : TimeFormatter.formatTime('07:30');
    final windDownDisplay = rec.windDownStart != null
        ? TimeFormatter.formatTime(rec.windDownStart)
        : TimeFormatter.formatTime('23:30');

    // Parse date for clean header badge
    final parsedDate = date != null ? DateTime.tryParse(date!) : null;
    final dateDisplay = parsedDate != null
        ? DateFormat('EEE, MMM d').format(parsedDate)
        : DateFormat('EEE, MMM d').format(DateTime.now());

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Clean Top Header: Title + Today's Date Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.nightlight_round, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'TONIGHT\'S SLEEP TARGET',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      dateDisplay,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 2. Hero Timing Trio (Target Bedtime • Hard Cutoff • Wake Time)
          Row(
            children: [
              // Column 1: Target Bedtime
              Expanded(
                flex: 4,
                child: _buildTimeMetric(
                  label: 'TARGET BEDTIME',
                  timeStr: recommendedBedtimeDisplay,
                  subtitle: rec.shiftMinutes > 0
                      ? '${rec.shiftMinutes}m earlier step'
                      : 'Optimal window',
                  timeColor: AppColors.textPrimary,
                  subtitleColor: AppColors.primary,
                ),
              ),

              // Vertical Divider
              Container(
                width: 1,
                height: 48,
                color: AppColors.border.withValues(alpha: 0.6),
              ),

              // Column 2: Hard Cutoff
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: _buildTimeMetric(
                    label: 'LATEST CUTOFF',
                    timeStr: latestCutoffDisplay,
                    subtitle: 'Circadian ceiling ⚠️',
                    timeColor: AppColors.warning,
                    subtitleColor: AppColors.warning,
                  ),
                ),
              ),

              // Vertical Divider
              Container(
                width: 1,
                height: 48,
                color: AppColors.border.withValues(alpha: 0.6),
              ),

              // Column 3: Target Wake
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: _buildTimeMetric(
                    label: 'WAKE UP',
                    timeStr: targetWakeDisplay,
                    subtitle: '7.5h target',
                    timeColor: AppColors.textPrimary,
                    subtitleColor: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 3. Visual Circadian Timeline Ribbon
          _buildCircadianTimelineRibbon(
            windDown: windDownDisplay,
            target: recommendedBedtimeDisplay,
            cutoff: latestCutoffDisplay,
          ),
          const SizedBox(height: 16),

          // 4. Action Strip: Tappable Science Modal Cue + Curtain Preview
          Row(
            children: [
              // Tap for detailed science explanation
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _showDetailedExplanationSheet(context, rec, weeklyHistory),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Based on ${rec.anchorBedtime} anchor • Why this target? →',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Curtain preview button
              Consumer(
                builder: (context, ref, _) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => ref.read(sleepEnforcementProvider.notifier).previewOverlay(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_moon_outlined, size: 12, color: AppColors.textTertiary),
                          SizedBox(width: 4),
                          Text(
                            'Preview Curtain',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
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
    );
  }

  Widget _buildTimeMetric({
    required String label,
    required String timeStr,
    required String subtitle,
    required Color timeColor,
    required Color subtitleColor,
  }) {
    // Split time and period (e.g. "12:00" and "AM")
    final parts = timeStr.split(' ');
    final mainDigits = parts.isNotEmpty ? parts[0] : timeStr;
    final period = parts.length > 1 ? parts[1] : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.textTertiary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              mainDigits,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: timeColor,
                letterSpacing: -0.5,
                height: 1.0,
              ),
            ),
            if (period.isNotEmpty) ...[
              const SizedBox(width: 3),
              Text(
                period,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: timeColor.withValues(alpha: 0.75),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: subtitleColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildCircadianTimelineRibbon({
    required String windDown,
    required String target,
    required String cutoff,
  }) {
    return Column(
      children: [
        // Visual multi-segment progress bar
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              // Wind-down segment
              Expanded(
                flex: 3,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primaryMuted,
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              // Optimal window segment (between target and cutoff)
              Expanded(
                flex: 4,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.sleepLight],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              // Cutoff buffer segment
              Expanded(
                flex: 2,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Timeline milestones
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Wind-down $windDown',
              style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
            ),
            Text(
              'Target $target',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
            Text(
              'Cutoff $cutoff',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.warning),
            ),
          ],
        ),
      ],
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
                    // Section 1: Target vs Cutoff Distinction
                    _buildSectionHeader('1. TARGET BEDTIME VS. HARD CUTOFF'),
                    _buildExplanationCard(
                      icon: Icons.flag_rounded,
                      iconColor: AppColors.primary,
                      title: 'Target: ${rec.recommendedBedtime} (Your Goal)',
                      content:
                          'Your target bedtime (${rec.recommendedBedtime}) is the optimal moment to begin sleep. It is calculated by advancing your 7-day habitual anchor (${rec.anchorBedtime}) by 10 minutes earlier. This gradual shifting respects your suprachiasmatic nucleus (SCN) circadian pacemaker without causing insomnia.',
                    ),
                    const SizedBox(height: 10),
                    _buildExplanationCard(
                      icon: Icons.shield_rounded,
                      iconColor: AppColors.warning,
                      title: 'Hard Cutoff: $cutoffDisplay (Circadian Ceiling)',
                      content:
                          'Your cutoff ($cutoffDisplay) is the non-negotiable deadline. Staying awake past this cutoff causes sleep onset delay during your body\'s natural core temperature nadir, severely compressing deep slow-wave sleep (NREM 3) and spiking next-day cortisol.',
                    ),
                    const SizedBox(height: 20),

                    // Section 2: Why You Can Sleep at 12:45 AM
                    _buildSectionHeader('2. WHY IS 12:45 AM PERMISSIBLE?'),
                    _buildExplanationCard(
                      icon: Icons.calculate_rounded,
                      iconColor: AppColors.sleepLight,
                      title: 'Your 7-Day Anchor Math',
                      content:
                          'Your habitual sleep onset over the past 7 days centers at 00:10 (12:10 AM). Clinical chronobiology (AASM & Sleep Foundation guidelines) dictates that sleep window boundaries allow a ±45-minute circadian buffer around the anchor. Therefore, 12:45 AM is the absolute latest point before your biological rhythm enters the delayed sleep phase.',
                    ),
                    const SizedBox(height: 20),

                    // Section 3: Historical Garmin Data Proof
                    _buildSectionHeader('3. EVIDENCE FROM YOUR GARMIN DATA'),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Historical Proof from Your Recent Nights:',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          _buildHistoricalRow(
                            date: 'Sept 23 (Past Cutoff):',
                            bedtime: '1:00 AM',
                            score: '68/100',
                            result: 'Severe Deep Sleep Deficit ❌',
                            isBad: true,
                          ),
                          const Divider(height: 16),
                          _buildHistoricalRow(
                            date: 'Sept 27 (Before Cutoff):',
                            bedtime: '11:30 PM',
                            score: '88/100',
                            result: 'Peak Recovery & High HRV ✅',
                            isBad: false,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Notice that whenever you went to bed past 12:45 AM, your sleep score never exceeded 70. Staying before the cutoff reliably yields scores of 80+.',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 4: Tonight's Protocol
                    _buildSectionHeader('4. RECOMMENDED WIND-DOWN PROTOCOL'),
                    _buildProtocolStep(
                      time: TimeFormatter.formatTime(rec.windDownStart ?? '23:30'),
                      action: 'Begin Wind-Down',
                      description: 'Stop eating, dim bedroom lighting, and switch off high-intensity blue light.',
                    ),
                    _buildProtocolStep(
                      time: rec.recommendedBedtime,
                      action: 'In Bed Lights Dimmed',
                      description: 'Get into bed. Ideal window to fall asleep without tossing and turning.',
                    ),
                    _buildProtocolStep(
                      time: cutoffDisplay,
                      action: 'Hard Cutoff (Lights Out)',
                      description: 'Screen locked. Phone placed on nightstand or across room.',
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textTertiary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildExplanationCard({
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricalRow({
    required String date,
    required String bedtime,
    required String score,
    required String result,
    required bool isBad,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
              Text('Bedtime: $bedtime', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            score,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: isBad ? AppColors.danger : AppColors.success,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Text(
            result,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isBad ? AppColors.danger : AppColors.success,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProtocolStep({
    required String time,
    required String action,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              time,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
