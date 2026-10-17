import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/sleep_data.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/colors.dart';
import '../../utils/time_formatter.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../../models/dashboard_data.dart';
import '../dashboard/widgets/weekly_sleep_chart.dart';
import 'widgets/hypnogram_chart.dart';
import 'widgets/sleep_stage_bar.dart';
import 'widgets/overnight_hr_chart.dart';


final sleepDetailFutureProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final date = ref.watch(selectedDateProvider);
  return api.getSleepDetail(date);
});

class SleepDetailScreen extends ConsumerWidget {
  const SleepDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(sleepDetailFutureProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Last Night\'s Sleep',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: detailAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(18),
          child: Column(
            children: [
              ShimmerLoading(width: double.infinity, height: 90),
              SizedBox(height: 16),
              ShimmerLoading(width: double.infinity, height: 180),
              SizedBox(height: 16),
              ShimmerLoading(width: double.infinity, height: 120),
            ],
          ),
        ),
        error: (err, _) => Center(
          child: Text('Error loading sleep details: $err'),
        ),
        data: (data) {
          final stagesRaw = (data['sleepStages'] as List<dynamic>?) ?? [];
          final stages = stagesRaw
              .map((e) => SleepStageInterval.fromJson(e as Map<String, dynamic>))
              .toList();

          final hrRaw = (data['overnightHR'] as List<dynamic>?) ?? [];
          final hrSamples = hrRaw
              .map((e) => OvernightHeartRate.fromJson(e as Map<String, dynamic>))
              .toList();

          final weeklyRaw = (data['weeklyChart'] as List<dynamic>?) ?? [];
          final weeklyList = weeklyRaw
              .map((e) => WeeklySleepItem.fromJson(e as Map<String, dynamic>))
              .toList();


          final bedtimeStr = TimeFormatter.formatTime(data['bedtime']);
          final wakeStr = TimeFormatter.formatTime(data['wakeTime']);

          final deepMins = (data['deepSleepMins'] as num?)?.toInt() ?? 0;
          final lightMins = (data['lightSleepMins'] as num?)?.toInt() ?? 0;
          final remMins = (data['remSleepMins'] as num?)?.toInt() ?? 0;
          final awakeMins = (data['awakeMins'] as num?)?.toInt() ?? 0;

          final totalSleepMins = deepMins + lightMins + remMins;
          final totalBedMins = totalSleepMins + awakeMins;
          final efficiency = totalBedMins > 0 ? (totalSleepMins / totalBedMins * 100).round() : null;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            children: [
              // Bedtime and Wake time overview
              Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.nightlight_round, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text('BEDTIME', style: theme.textTheme.labelSmall),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            bedtimeStr,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.wb_sunny_rounded, size: 16, color: AppColors.momWarm),
                              const SizedBox(width: 6),
                              Text('WAKE TIME', style: theme.textTheme.labelSmall),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            wakeStr,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.speed_rounded, size: 16, color: AppColors.success),
                              const SizedBox(width: 6),
                              Text('EFFICIENCY', style: theme.textTheme.labelSmall),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            efficiency != null ? '$efficiency%' : '--',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Magnesium Supplement Status Card
              _buildMagnesiumCard(theme, data['magnesium']),
              const SizedBox(height: 16),

              // Sleep Hypnogram (Stage transitions)
              HypnogramChart(stages: stages),
              const SizedBox(height: 16),

              // Stage breakdown bar
              SleepStageBar(
                deepMins: deepMins,
                lightMins: lightMins,
                remMins: remMins,
                awakeMins: awakeMins,
              ),
              const SizedBox(height: 16),

              // Nocturnal Heart Rate curve
              OvernightHrChart(samples: hrSamples),
              const SizedBox(height: 16),

              // Historical 7-Day Sleep & Wake Schedule
              if (weeklyList.isNotEmpty) ...[
                WeeklySleepChart(weeklyData: weeklyList),
                const SizedBox(height: 24),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildMagnesiumCard(ThemeData theme, dynamic magnesiumRaw) {
    final Map<String, dynamic>? mag =
        magnesiumRaw is Map<String, dynamic> ? magnesiumRaw : null;
    final bool isTaken = mag?['taken'] == true;
    final String? takenAt = mag?['takenAt'] ?? mag?['taken_at'];

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isTaken
                  ? AppColors.success.withValues(alpha: 0.15)
                  : AppColors.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isTaken ? Icons.check_circle_rounded : Icons.medication_rounded,
              size: 18,
              color: isTaken ? AppColors.success : AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'MAGNESIUM SUPPLEMENT',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isTaken ? AppColors.success : AppColors.textTertiary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isTaken
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isTaken ? 'LOGGED' : 'NOT TAKEN',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isTaken ? AppColors.success : AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isTaken
                      ? (takenAt != null
                          ? 'Taken at $takenAt • Promoted neuromuscular calm & NREM 3 deep sleep'
                          : 'Taken before bedtime • Promoted neuromuscular calm & NREM 3 deep sleep')
                      : 'Not logged for this night • Consider taking 30-60m before bed to boost restorative slow-wave sleep',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
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
