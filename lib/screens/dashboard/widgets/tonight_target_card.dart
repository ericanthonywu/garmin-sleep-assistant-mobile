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
    final dimLightsDisplay = rec.dimLightsStart != null
        ? TimeFormatter.formatTime(rec.dimLightsStart)
        : TimeFormatter.formatTime('00:00');

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
                  label: 'IN BED BY',
                  timeStr: recommendedBedtimeDisplay,
                  subtitle: _getStatusSubtitle(rec),
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
                    subtitle: rec.sleepNeedHours != null
                        ? '${rec.sleepNeedHours}h need'
                        : 'Target wake',
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
            dimLights: dimLightsDisplay,
            windDown: windDownDisplay,
            target: recommendedBedtimeDisplay,
            cutoff: latestCutoffDisplay,
          ),
          const SizedBox(height: 16),

          // 3.5. Insight chips (sleep debt, onset variability)
          if (rec.sleepDebtHours != null && rec.sleepDebtHours! > 0.5 ||
              rec.onsetVariabilityMins != null && rec.onsetVariabilityMins! >= 45) ...[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (rec.sleepDebtHours != null && rec.sleepDebtHours! > 0.5)
                  _buildInsightChip(
                    icon: Icons.trending_down_rounded,
                    label: '${rec.sleepDebtHours!.toStringAsFixed(1)}h sleep debt',
                    color: rec.sleepDebtHours! >= 3.0 ? AppColors.danger : AppColors.warning,
                  ),
                if (rec.onsetVariabilityMins != null && rec.onsetVariabilityMins! >= 45)
                  _buildInsightChip(
                    icon: Icons.swap_horiz_rounded,
                    label: '±${rec.onsetVariabilityMins}m variability',
                    color: AppColors.warning,
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],

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

  String _getStatusSubtitle(SleepRecommendation rec) {
    switch (rec.adherenceStatus) {
      case 'advancing':
        return '${rec.shiftMinutes}m earlier step';
      case 'holding':
        return 'Holding steady';
      case 'regressing':
        return 'Anchored · resume soon';
      case 'achieved':
        return 'Goal achieved ✓';
      default:
        return 'Optimal window';
    }
  }

  Widget _buildInsightChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusTitle(SleepRecommendation rec) {
    switch (rec.adherenceStatus) {
      case 'advancing':
        return 'Advancing: ${rec.shiftMinutes}m earlier tonight';
      case 'holding':
        return 'Holding: steady at your anchor';
      case 'regressing':
        return 'Regressing: holding at anchor until on track';
      case 'achieved':
        return 'Achieved: maintaining your goal schedule';
      default:
        return 'Tonight\'s Sleep Plan';
    }
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
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
    required String dimLights,
    required String windDown,
    required String target,
    required String cutoff,
  }) {
    return Column(
      children: [
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              // Dim lights segment
              Expanded(
                flex: 2,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF2A2040),
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
                  ),
                ),
              ),
              const SizedBox(width: 1),
              // Wind-down segment
              Expanded(
                flex: 2,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primaryMuted,
                  ),
                ),
              ),
              const SizedBox(width: 1),
              // Optimal window segment (between target and cutoff)
              Expanded(
                flex: 3,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.sleepLight],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 1),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Dim $dimLights',
              style: const TextStyle(fontSize: 9, color: AppColors.textTertiary),
            ),
            Text(
              'Wind-down $windDown',
              style: const TextStyle(fontSize: 9, color: AppColors.textTertiary),
            ),
            Text(
              'In Bed $target',
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
            Text(
              'Cutoff $cutoff',
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.warning),
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
                            'In bed by ${rec.recommendedBedtime} · Cutoff $cutoffDisplay',
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
                    // Section 1: Engine Guidance (dynamic from backend)
                    _buildSectionHeader('1. TONIGHT\'S ANALYSIS'),
                    _buildExplanationCard(
                      icon: Icons.auto_awesome_rounded,
                      iconColor: AppColors.primary,
                      title: _getStatusTitle(rec),
                      content: rec.guidance.isNotEmpty
                          ? rec.guidance
                          : 'Your sleep engine is calculating the optimal schedule based on your recent sleep patterns.',
                    ),
                    const SizedBox(height: 20),

                    // Section 2: Target vs Cutoff Distinction
                    _buildSectionHeader('2. IN-BED TIME VS. HARD CUTOFF'),
                    _buildExplanationCard(
                      icon: Icons.flag_rounded,
                      iconColor: AppColors.primary,
                      title: 'In Bed: ${rec.recommendedBedtime} → Sleep Onset: ${rec.recommendedSleepOnset}',
                      content:
                          'Get into bed at ${rec.recommendedBedtime} (lights-out time). '
                          'Your target sleep onset is ${rec.recommendedSleepOnset}, '
                          'allowing ~15 minutes to fall asleep. '
                          'This is anchored to your habitual onset of ${rec.anchorBedtime}${rec.shiftMinutes > 0 ? ", shifted ${rec.shiftMinutes} minutes earlier tonight" : ""}.',
                    ),
                    const SizedBox(height: 10),
                    _buildExplanationCard(
                      icon: Icons.shield_rounded,
                      iconColor: AppColors.warning,
                      title: 'Hard Cutoff: $cutoffDisplay',
                      content:
                          'Your cutoff ($cutoffDisplay) is the latest point to begin sleep '
                          'without disrupting your circadian rhythm. Staying awake past this '
                          'compresses deep slow-wave sleep and raises next-day cortisol.',
                    ),
                    const SizedBox(height: 20),

                    // Section 3: Sleep Stats
                    _buildSectionHeader('3. YOUR SLEEP METRICS'),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _buildStatRow('Anchor bedtime', rec.anchorBedtime),
                          if (rec.habitualWakeTime != null)
                            _buildStatRow('Habitual wake', rec.habitualWakeTime!),
                          if (rec.sleepNeedHours != null)
                            _buildStatRow('Sleep need', '${rec.sleepNeedHours}h'),
                          if (rec.sleepDebtHours != null && rec.sleepDebtHours! > 0)
                            _buildStatRow('Sleep debt', '${rec.sleepDebtHours!.toStringAsFixed(1)}h'),
                          if (rec.onsetVariabilityMins != null)
                            _buildStatRow('Onset variability', '±${rec.onsetVariabilityMins} min'),
                          if (rec.socialJetlag != 0)
                            _buildStatRow('Social jetlag', '${rec.socialJetlag > 0 ? "+" : ""}${rec.socialJetlag} min'),
                          if (rec.nightsAnalyzed != null)
                            _buildStatRow('Nights analyzed', '${rec.nightsAnalyzed}${rec.outlierNights != null && rec.outlierNights! > 0 ? " (${rec.outlierNights} outliers)" : ""}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 4: Tonight's Protocol
                    _buildSectionHeader('4. WIND-DOWN PROTOCOL'),
                    if (rec.dimLightsStart != null)
                      _buildProtocolStep(
                        time: TimeFormatter.formatTime(rec.dimLightsStart),
                        action: 'Dim Lights',
                        description: 'Reduce room lighting and screen brightness to signal your body clock.',
                      ),
                    _buildProtocolStep(
                      time: TimeFormatter.formatTime(rec.windDownStart ?? rec.recommendedBedtime),
                      action: 'Begin Wind-Down',
                      description: 'Stop eating, dim bedroom lighting, and switch off high-intensity blue light.',
                    ),
                    _buildProtocolStep(
                      time: rec.recommendedBedtime,
                      action: 'In Bed · Lights Out',
                      description: 'Get into bed. Your optimal sleep onset window begins.',
                    ),
                    _buildProtocolStep(
                      time: cutoffDisplay,
                      action: 'Hard Cutoff',
                      description: 'Non-negotiable. Screen locked and placed on nightstand.',
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
