import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/dashboard_data.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/health_sync_provider.dart';
import '../../theme/colors.dart';
import '../../widgets/shimmer_loading.dart';
import 'widgets/sleep_score_ring.dart';
import 'widgets/mom_morning_note.dart';
import 'widgets/metric_card.dart';
import 'widgets/tonight_target_card.dart';
import 'widgets/weekly_sleep_chart.dart';
import 'widgets/daily_sleep_schedule_chart.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(healthSyncProvider.notifier).syncNow();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final syncState = ref.watch(healthSyncProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            await ref.read(healthSyncProvider.notifier).syncNow();
            ref.invalidate(dashboardProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Top App Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getTimeGreeting(),
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              DateFormat('EEEE, MMM d').format(DateTime.now()),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Sync HealthKit',
                              onPressed: syncState.isLoading
                                  ? null
                                  : () => ref.read(healthSyncProvider.notifier).syncNow(),
                              icon: syncState.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : const Icon(Icons.sync_rounded, color: AppColors.primary),
                            ),
                            IconButton(
                              tooltip: 'Settings',
                              onPressed: () => context.push('/settings'),
                              icon: const Icon(Icons.tune_rounded, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Main content loaded via AsyncValue
                    dashboardAsync.when(
                      loading: () => _buildLoadingSkeleton(),
                      error: (err, _) => _buildErrorCard(context, ref, err.toString()),
                      data: (data) => _buildDashboardContent(context, data),
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, DashboardData data) {
    final sleepDurationStr = data.sleepHours != null ? '${data.sleepHours}h' : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. TOP HERO: Circadian Sleep Recommendations (Recommended Bedtime & Latest Cutoff)
        TonightTargetCard(
          recommendation: data.sleepEngineRecommendation,
          weeklyHistory: data.weeklyChart,
          date: data.date,
        ),

        const SizedBox(height: 18),

        // 2. Daily Sleep & Wake Schedule Timeline Chart
        DailySleepScheduleChart(
          bedtime: data.bedtime,
          wakeTime: data.wakeTime,
          sleepHours: data.sleepHours,
          deepSleepMins: data.deepSleepMins,
          lightSleepMins: data.lightSleepMins,
          remSleepMins: data.remSleepMins,
          awakeMins: data.awakeMins,
          sleepStages: data.sleepStages,
          onTapDetails: () => context.go('/sleep'),
        ),
        const SizedBox(height: 18),

        // 2. Priority 2: 7-Day Sleep Consistency Chart
        WeeklySleepChart(
          weeklyData: data.weeklyChart,
          targetBedtime: data.sleepEngineRecommendation?.recommendedBedtime,
          latestCutoff: data.sleepEngineRecommendation?.latestBedtimeCutoff,
        ),
        const SizedBox(height: 18),

        // 3. AI Sleep & Quality Analysis: Morning Briefing Note
        if (data.morningNote != null && data.morningNote!.isNotEmpty) ...[
          MomMorningNote(
            noteContent: data.morningNote,
            verdict: data.morningVerdict,
            onTalkToMom: () => context.go('/chat'),
          ),
          const SizedBox(height: 18),
        ],

        // 4. Deprioritized: Sleep Score Ring
        Center(
          child: GestureDetector(
            onTap: () => context.go('/sleep'),
            child: SleepScoreRing(
              score: data.sleepScore,
              sleepDuration: sleepDurationStr,
              verdict: data.morningVerdict,
            ),
          ),
        ),
        const SizedBox(height: 18),

        // 5. 2x2 Bento Metric Grid
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'Resting HR',
                value: data.restingHR != null ? '${data.restingHR} bpm' : '--',
                subtitle: 'Nocturnal nadir',
                icon: Icons.favorite_rounded,
                iconColor: AppColors.danger,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                title: 'Overnight HRV',
                value: data.hrv != null ? '${data.hrv} ms' : '--',
                subtitle: 'rMSSD recovery',
                icon: Icons.graphic_eq_rounded,
                iconColor: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'VO2 Max',
                value: data.vo2max != null ? '${data.vo2max}' : '--',
                subtitle: 'Aerobic fitness',
                icon: Icons.air_rounded,
                iconColor: AppColors.sleepLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                title: 'Body Battery',
                value: data.bodyBatteryHigh != null
                    ? '${data.bodyBatteryLow ?? "?"}% -> ${data.bodyBatteryHigh}%'
                    : '--',
                subtitle: 'Recharged level',
                icon: Icons.battery_charging_full_rounded,
                iconColor: AppColors.momWarm,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return const Column(
      children: [
        ShimmerLoading(width: double.infinity, height: 210, borderRadius: 16),
        SizedBox(height: 18),
        ShimmerLoading(width: double.infinity, height: 180, borderRadius: 16),
        SizedBox(height: 18),
        ShimmerLoading(width: double.infinity, height: 100, borderRadius: 16),
        SizedBox(height: 18),
        ShimmerLoading(width: 160, height: 160, borderRadius: 80),
        SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: ShimmerLoading(width: double.infinity, height: 95)),
            SizedBox(width: 12),
            Expanded(child: ShimmerLoading(width: double.infinity, height: 95)),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorCard(BuildContext context, WidgetRef ref, String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 36, color: AppColors.warning),
          const SizedBox(height: 10),
          const Text(
            'Cannot reach MomCare backend',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            error,
            style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => ref.refresh(dashboardProvider),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry Connection'),
          ),
        ],
      ),
    );
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 🌤️';
    if (hour < 21) return 'Good evening 🌅';
    return 'Bedtime soon 🌙';
  }
}
