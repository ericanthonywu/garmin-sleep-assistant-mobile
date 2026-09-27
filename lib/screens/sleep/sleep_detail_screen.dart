import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/sleep_data.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/colors.dart';
import '../../utils/time_formatter.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/shimmer_loading.dart';
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
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
