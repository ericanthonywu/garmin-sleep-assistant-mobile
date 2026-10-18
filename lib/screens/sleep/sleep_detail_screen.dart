import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/sleep_data.dart';
import '../../models/dashboard_data.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/colors.dart';
import '../../utils/time_formatter.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../dashboard/widgets/weekly_sleep_chart.dart';
import 'widgets/hypnogram_chart.dart';
import 'widgets/sleep_stage_bar.dart';
import 'widgets/overnight_hr_chart.dart';
import 'widgets/sleep_calendar_grid.dart';

final sleepDetailFutureProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final date = ref.watch(selectedDateProvider);
  return api.getSleepDetail(date);
});

class SleepDetailScreen extends ConsumerStatefulWidget {
  const SleepDetailScreen({super.key});

  @override
  ConsumerState<SleepDetailScreen> createState() => _SleepDetailScreenState();
}

class _SleepDetailScreenState extends ConsumerState<SleepDetailScreen> {
  // 'calendar' (calendar on top + day details below) or 'focus' (day details with day stepper)
  String _viewMode = 'calendar';

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final calendarAsync = ref.watch(sleepCalendarProvider);
    final detailAsync = ref.watch(sleepDetailFutureProvider);
    final theme = Theme.of(context);

    final selectedDateTime = DateTime.tryParse(selectedDate) ?? DateTime.now();
    final formattedSelectedDate = DateFormat('EEEE, MMMM d, yyyy').format(selectedDateTime);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sleep Quality',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          // View Mode Selector
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'calendar',
                  icon: Icon(Icons.calendar_month_rounded, size: 16),
                  label: Text('Calendar', style: TextStyle(fontSize: 12)),
                ),
                ButtonSegment<String>(
                  value: 'focus',
                  icon: Icon(Icons.nightlight_round, size: 16),
                  label: Text('Day', style: TextStyle(fontSize: 12)),
                ),
              ],
              selected: {_viewMode},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _viewMode = newSelection.first;
                });
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ref.invalidate(sleepCalendarProvider);
          ref.invalidate(sleepDetailFutureProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 1. Calendar View Mode
            if (_viewMode == 'calendar') ...[
              calendarAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: ShimmerLoading(width: double.infinity, height: 260),
                ),
                error: (err, _) => GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Failed to load sleep calendar: $err',
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
                data: (calendarData) => SleepCalendarGrid(
                  currentMonth: selectedMonth,
                  selectedDate: selectedDate,
                  calendarData: calendarData,
                  onSelectDate: (dateStr) {
                    ref.read(selectedDateProvider.notifier).setDate(dateStr);
                  },
                  onPreviousMonth: () {
                    ref.read(selectedMonthProvider.notifier).previousMonth();
                  },
                  onNextMonth: () {
                    ref.read(selectedMonthProvider.notifier).nextMonth();
                  },
                  onJumpToToday: () {
                    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
                    ref.read(selectedMonthProvider.notifier).currentMonth();
                    ref.read(selectedDateProvider.notifier).setDate(todayStr);
                  },
                ),
              ),
              const SizedBox(height: 18),
            ],

            // 2. Day Stepper Header in 'focus' mode
            if (_viewMode == 'focus') ...[
              _buildDayStepperHeader(context, selectedDateTime),
              const SizedBox(height: 14),
            ],

            // 3. Selected Day Sleep Details Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.insights_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      _viewMode == 'calendar' ? 'DETAILS FOR SELECTED DATE' : 'SLEEP METRICS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  DateFormat('MMM d, yyyy').format(selectedDateTime),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 4. Detailed Sleep Data for Selected Day
            detailAsync.when(
              loading: () => const Column(
                children: [
                  ShimmerLoading(width: double.infinity, height: 90),
                  SizedBox(height: 12),
                  ShimmerLoading(width: double.infinity, height: 160),
                  SizedBox(height: 12),
                  ShimmerLoading(width: double.infinity, height: 120),
                ],
              ),
              error: (err, _) => GlassCard(
                padding: const EdgeInsets.all(16),
                child: Text('Error loading sleep details: $err'),
              ),
              data: (data) => _buildDayDetailsContent(context, theme, data, formattedSelectedDate),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDayStepperHeader(BuildContext context, DateTime selectedDateTime) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary),
            tooltip: 'Previous Day',
            onPressed: () {
              final prev = selectedDateTime.subtract(const Duration(days: 1));
              final prevStr = DateFormat('yyyy-MM-dd').format(prev);
              ref.read(selectedDateProvider.notifier).setDate(prevStr);
            },
          ),
          Column(
            children: [
              Text(
                DateFormat('EEEE').format(selectedDateTime),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                DateFormat('MMMM d, yyyy').format(selectedDateTime),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textPrimary),
            tooltip: 'Next Day',
            onPressed: () {
              final next = selectedDateTime.add(const Duration(days: 1));
              final nextStr = DateFormat('yyyy-MM-dd').format(next);
              ref.read(selectedDateProvider.notifier).setDate(nextStr);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayDetailsContent(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> data,
    String formattedSelectedDate,
  ) {
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

    final sleepScore = (data['sleepScore'] as num?)?.toInt();
    final sleepSecs = (data['sleepSecs'] as num?)?.toInt();
    final sleepHours = (data['sleepHours'] as num?)?.toDouble();
    final sleepFormatted = data['sleepFormatted'] as String? ??
        (sleepSecs != null ? TimeFormatter.formatDurationSecs(sleepSecs) : null);

    final bedtimeStr = TimeFormatter.formatTime(data['bedtime']);
    final wakeStr = TimeFormatter.formatTime(data['wakeTime']);

    final deepMins = (data['deepSleepMins'] as num?)?.toInt() ?? 0;
    final lightMins = (data['lightSleepMins'] as num?)?.toInt() ?? 0;
    final remMins = (data['remSleepMins'] as num?)?.toInt() ?? 0;
    final awakeMins = (data['awakeMins'] as num?)?.toInt() ?? 0;

    final restingHR = (data['restingHR'] as num?)?.toInt();
    final hrv = (data['hrv'] as num?)?.toInt();
    final morningNote = data['morningNote'] as String?;
    final morningVerdict = data['morningVerdict'] as String?;

    final totalSleepMins = deepMins + lightMins + remMins;
    final totalBedMins = totalSleepMins + awakeMins;
    final efficiency = totalBedMins > 0 ? (totalSleepMins / totalBedMins * 100).round() : null;

    final hasSleepRecord = sleepScore != null || sleepSecs != null || stages.isNotEmpty;

    if (!hasSleepRecord) {
      return GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.bedtime_off_rounded,
              size: 42,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'No Sleep Record for $formattedSelectedDate',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'No Garmin or HealthKit sleep stages were recorded for this night. Select another date from the calendar to view its quality breakdown.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sleep Quality Banner Card
        _buildQualityBannerCard(
          sleepScore: sleepScore,
          sleepFormatted: sleepFormatted,
          sleepHours: sleepHours,
          restingHR: restingHR,
          hrv: hrv,
          morningVerdict: morningVerdict,
        ),
        const SizedBox(height: 14),

        // Bedtime, Wake time, Efficiency overview
        Row(
          children: [
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.nightlight_round, size: 15, color: AppColors.primary),
                        const SizedBox(width: 5),
                        Text('BEDTIME', style: theme.textTheme.labelSmall),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      bedtimeStr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.wb_sunny_rounded, size: 15, color: AppColors.momWarm),
                        const SizedBox(width: 5),
                        Text('WAKE TIME', style: theme.textTheme.labelSmall),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      wakeStr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.speed_rounded, size: 15, color: AppColors.success),
                        const SizedBox(width: 5),
                        Text('EFFICIENCY', style: theme.textTheme.labelSmall),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      efficiency != null ? '$efficiency%' : '--',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
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
        if (stages.isNotEmpty) ...[
          HypnogramChart(stages: stages),
          const SizedBox(height: 16),
        ],

        // Stage breakdown bar
        SleepStageBar(
          deepMins: deepMins,
          lightMins: lightMins,
          remMins: remMins,
          awakeMins: awakeMins,
        ),
        const SizedBox(height: 16),

        // Nocturnal Heart Rate curve
        if (hrSamples.isNotEmpty) ...[
          OvernightHrChart(samples: hrSamples),
          const SizedBox(height: 16),
        ],

        // Mom AI Morning Note / Briefing
        if (morningNote != null && morningNote.isNotEmpty) ...[
          _buildMomNoteCard(morningNote, morningVerdict),
          const SizedBox(height: 16),
        ],

        // Historical 7-Day Sleep & Wake Schedule
        if (weeklyList.isNotEmpty) ...[
          WeeklySleepChart(weeklyData: weeklyList),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildQualityBannerCard({
    required int? sleepScore,
    required String? sleepFormatted,
    required double? sleepHours,
    required int? restingHR,
    required int? hrv,
    required String? morningVerdict,
  }) {
    final scoreColor = AppColors.sleepScoreColor(sleepScore);
    String qualityText = 'Restorative Sleep';
    if (sleepScore != null) {
      if (sleepScore >= 85) {
        qualityText = 'Optimal Restoration';
      } else if (sleepScore >= 75) {
        qualityText = 'Good Recovery';
      } else if (sleepScore >= 60) {
        qualityText = 'Fair Sleep';
      } else {
        qualityText = 'Restless / Needs Attention';
      }
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Score Circle Badge
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scoreColor.withValues(alpha: 0.15),
              border: Border.all(color: scoreColor, width: 2.2),
            ),
            child: Center(
              child: Text(
                sleepScore != null ? '$sleepScore' : '--',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: scoreColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Details column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      qualityText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: scoreColor,
                      ),
                    ),
                    if (morningVerdict != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.verdictColor(morningVerdict).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          morningVerdict.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.verdictColor(morningVerdict),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  sleepFormatted != null ? '$sleepFormatted total sleep' : 'Sleep tracked',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    if (restingHR != null) ...[
                      const Icon(Icons.favorite_rounded, size: 12, color: AppColors.danger),
                      const SizedBox(width: 3),
                      Text(
                        '$restingHR bpm',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (hrv != null) ...[
                      const Icon(Icons.graphic_eq_rounded, size: 12, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Text(
                        '$hrv ms HRV',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildMomNoteCard(String note, String? verdict) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_rounded, size: 16, color: AppColors.momWarm),
              const SizedBox(width: 6),
              const Text(
                'MOM\'S MORNING INSIGHT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: AppColors.momWarm,
                ),
              ),
              const Spacer(),
              if (verdict != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.verdictColor(verdict).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    verdict.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.verdictColor(verdict),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            note,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
