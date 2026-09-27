import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/dashboard_data.dart';
import '../../../../theme/colors.dart';
import '../../../../utils/time_formatter.dart';
import '../../../../widgets/glass_card.dart';

enum SleepChartView { schedule, duration }

class WeeklySleepChart extends StatefulWidget {
  final List<WeeklySleepItem> weeklyData;

  const WeeklySleepChart({
    super.key,
    required this.weeklyData,
  });

  @override
  State<WeeklySleepChart> createState() => _WeeklySleepChartState();
}

class _WeeklySleepChartState extends State<WeeklySleepChart> {
  SleepChartView _currentView = SleepChartView.schedule;
  int? _selectedDayIndex;
  bool _showHistoryList = false;

  @override
  void initState() {
    super.initState();
    // Default selected day to the most recent day with data
    if (widget.weeklyData.isNotEmpty) {
      _selectedDayIndex = widget.weeklyData.length - 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = widget.weeklyData;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title and View Toggle
          Row(
            children: [
              const Icon(Icons.history_toggle_off_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '7-DAY SLEEP SCHEDULE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildViewToggle(),
            ],
          ),

          const SizedBox(height: 6),
          Text(
            _currentView == SleepChartView.schedule
                ? 'Bedtime & wake times across the past 7 days vs circadian target'
                : 'Total sleep duration consistency across the past 7 days',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),

          if (data.isEmpty)
            const SizedBox(
              height: 160,
              child: Center(
                child: Text('No historical sleep data available yet'),
              ),
            )
          else ...[
            if (_currentView == SleepChartView.schedule)
              _buildScheduleChart(context, data)
            else
              _buildDurationChart(context, data),

            const SizedBox(height: 14),

            // Active day inspection detail card
            if (_selectedDayIndex != null && _selectedDayIndex! < data.length)
              _buildDayDetailCard(data[_selectedDayIndex!]),

            const SizedBox(height: 10),

            // Collapsible 7-day history breakdown table button
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() {
                  _showHistoryList = !_showHistoryList;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _showHistoryList ? 'Hide Daily History Table' : 'View 7-Day History Table',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      _showHistoryList ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),

            if (_showHistoryList) ...[
              const SizedBox(height: 8),
              _buildHistoryTable(data),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption(
            title: 'Schedule',
            isSelected: _currentView == SleepChartView.schedule,
            onTap: () => setState(() => _currentView = SleepChartView.schedule),
          ),
          _buildToggleOption(
            title: 'Duration',
            isSelected: _currentView == SleepChartView.duration,
            onTap: () => setState(() => _currentView = SleepChartView.duration),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),

        child: Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.black : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// Visualizes floating Bedtime-to-Wake-Time bars for each day
  Widget _buildScheduleChart(BuildContext context, List<WeeklySleepItem> data) {
    // Timeline window: default 20:00 (8 PM = 480m) to 11:00 (11 AM = 1380m)
    int windowStart = 480;
    int windowEnd = 1380;

    // Scan data for earlier bedtime or later wake time
    for (final item in data) {
      final bed = TimeFormatter.parseTime(item.bedtime);
      if (bed != null) {
        final bedMin = TimeFormatter.toMinutesPastNoon(bed.hour, bed.minute);
        if (bedMin < windowStart) windowStart = (bedMin ~/ 60) * 60;
      }
      final wake = TimeFormatter.parseTime(item.wakeTime);
      if (wake != null) {
        final wakeMin = TimeFormatter.toMinutesPastNoon(wake.hour, wake.minute);
        if (wakeMin > windowEnd) windowEnd = ((wakeMin ~/ 60) + 1) * 60;
      }
    }

    final totalSpan = (windowEnd - windowStart).clamp(360, 1440);
    const chartHeight = 175.0;

    // Target (12:00 AM = 720m) and Cutoff (12:45 AM = 765m) line offsets
    final targetOffset = ((720 - windowStart) / totalSpan).clamp(0.0, 1.0) * chartHeight;
    final cutoffOffset = ((765 - windowStart) / totalSpan).clamp(0.0, 1.0) * chartHeight;

    return Column(
      children: [
        // Legend row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildDot(AppColors.primary, 'On Time (<= 12:45 AM)'),
                const SizedBox(width: 12),
                _buildDot(AppColors.danger, 'Late (> 12:45 AM)'),
              ],
            ),
            const Text(
              '🎯 Target 12:00 AM',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Floating Bars Chart
        SizedBox(
          height: chartHeight + 38, // height + bottom day label area
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Target Bedtime Guideline (12:00 AM Midnight)
              Positioned(
                left: 0,
                right: 0,
                top: targetOffset,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        '12 AM',
                        style: TextStyle(
                          fontSize: 8,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: AppColors.primary.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),

              // Latest Cutoff Guideline (12:45 AM)
              Positioned(
                left: 0,
                right: 0,
                top: cutoffOffset,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        '12:45',
                        style: TextStyle(
                          fontSize: 8,
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: AppColors.danger.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ),

              // 7 Floating Day Columns
              Positioned.fill(
                bottom: 36,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(data.length, (idx) {
                    final item = data[idx];
                    final isSelected = _selectedDayIndex == idx;

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            _selectedDayIndex = idx;
                          });
                        },
                        child: _buildDayColumn(
                          item: item,
                          windowStart: windowStart,
                          totalSpan: totalSpan,
                          chartHeight: chartHeight,
                          isSelected: isSelected,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Day labels along bottom X axis
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 32,
                child: Row(

                  children: List.generate(data.length, (idx) {
                    final item = data[idx];
                    final isSelected = _selectedDayIndex == idx;
                    final dt = DateTime.tryParse(item.date);
                    final dayStr = dt != null ? DateFormat('E').format(dt) : '';
                    final dateStr = dt != null ? DateFormat('d').format(dt) : '';
                    final isToday = idx == data.length - 1;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDayIndex = idx;
                          });
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isToday ? 'Today' : dayStr,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primary
                                    : (isToday ? AppColors.textPrimary : AppColors.textTertiary),
                              ),
                            ),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 9,
                                color: isSelected ? AppColors.primary : AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayColumn({
    required WeeklySleepItem item,
    required int windowStart,
    required int totalSpan,
    required double chartHeight,
    required bool isSelected,
  }) {
    final parsedBed = TimeFormatter.parseTime(item.bedtime);
    final parsedWake = TimeFormatter.parseTime(item.wakeTime);

    if (parsedBed == null || parsedWake == null) {
      // Day with no sleep recorded
      return Center(
        child: Container(
          width: 8,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
    }

    final bedMin = TimeFormatter.toMinutesPastNoon(parsedBed.hour, parsedBed.minute);
    final wakeMin = TimeFormatter.toMinutesPastNoon(parsedWake.hour, parsedWake.minute);

    final topRatio = ((bedMin - windowStart) / totalSpan).clamp(0.0, 0.95);
    final botRatio = ((wakeMin - windowStart) / totalSpan).clamp(topRatio + 0.05, 1.0);

    final barTop = topRatio * chartHeight;
    final barHeight = ((botRatio - topRatio) * chartHeight).clamp(24.0, chartHeight);

    // Is bedtime after 12:45 AM (765m)?
    final isLate = bedMin > 765;

    final gradientColors = isLate
        ? [AppColors.warning, AppColors.danger]
        : [AppColors.primary, AppColors.sleepLight];

    // Format compact time pills
    final bedPillText = _compactTime(item.bedtime);
    final wakePillText = _compactTime(item.wakeTime);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            // Selected highlight column guide
            if (isSelected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryMuted.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                ),
              ),

            // Floating Schedule Bar
            Positioned(
              top: barTop,
              height: barHeight,
              width: constraints.maxWidth * 0.65,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: (isLate ? AppColors.danger : AppColors.primary).withValues(alpha: isSelected ? 0.4 : 0.2),
                      blurRadius: isSelected ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Bedtime tag at top of bar
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        bedPillText,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),

                    // Wake time tag at bottom of bar
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        wakePillText,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Detail inspection card for tapped day
  Widget _buildDayDetailCard(WeeklySleepItem item) {
    final dt = DateTime.tryParse(item.date);
    final dateDisplay = dt != null ? DateFormat('EEEE, MMM d').format(dt) : item.date;
    final bedtimeStr = TimeFormatter.formatTime(item.bedtime);
    final wakeStr = TimeFormatter.formatTime(item.wakeTime);
    final durationStr = item.sleepHours != null ? '${item.sleepHours} hrs' : '--';

    final parsedBed = TimeFormatter.parseTime(item.bedtime);
    final isLate = parsedBed != null && TimeFormatter.toMinutesPastNoon(parsedBed.hour, parsedBed.minute) > 765;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isLate ? AppColors.danger : AppColors.primary).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateDisplay,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isLate ? AppColors.danger : AppColors.success).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isLate ? 'Cutoff Exceeded ⚠️' : 'Target Met 🎯',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isLate ? AppColors.danger : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDetailMetric('Went to Bed', bedtimeStr, Icons.bedtime_rounded, isLate ? AppColors.danger : AppColors.primary),
              ),
              Expanded(
                child: _buildDetailMetric('Woke Up', wakeStr, Icons.wb_sunny_rounded, AppColors.momWarm),
              ),
              Expanded(
                child: _buildDetailMetric('Duration', durationStr, Icons.timer_rounded, AppColors.sleepLight),
              ),
              Expanded(
                child: _buildDetailMetric('Score', item.sleepScore != null ? '${item.sleepScore}' : '--', Icons.star_rounded, AppColors.primary),
              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildDetailMetric(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: AppColors.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  /// 7-Day History Table
  Widget _buildHistoryTable(List<WeeklySleepItem> data) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Date', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('Bedtime', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('Wake', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('Sleep', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                Expanded(flex: 1, child: Text('Score', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
              ],
            ),
          ),
          ...data.reversed.map((item) {
            final dt = DateTime.tryParse(item.date);
            final dayStr = dt != null ? DateFormat('E, MMM d').format(dt) : item.date;
            final bedStr = TimeFormatter.formatTime(item.bedtime);
            final wakeStr = TimeFormatter.formatTime(item.wakeTime);
            final sleepStr = item.sleepHours != null ? '${item.sleepHours}h' : '--';

            final parsedBed = TimeFormatter.parseTime(item.bedtime);
            final isLate = parsedBed != null && TimeFormatter.toMinutesPastNoon(parsedBed.hour, parsedBed.minute) > 765;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.4))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      dayStr,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      bedStr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isLate ? AppColors.danger : AppColors.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      wakeStr,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      sleepStr,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      item.sleepScore != null ? '${item.sleepScore}' : '--',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: (item.sleepScore ?? 0) >= 80 ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Duration bar chart view (original duration visualization)
  Widget _buildDurationChart(BuildContext context, List<WeeklySleepItem> data) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildDot(AppColors.sleepDeep, '>=7h'),
            const SizedBox(width: 8),
            _buildDot(AppColors.sleepLight, '6-7h'),
            const SizedBox(width: 8),
            _buildDot(AppColors.danger, '<6h'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              maxY: 10,
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 2,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.border.withValues(alpha: 0.5),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 4,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}h',
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= data.length) {
                        return const SizedBox.shrink();
                      }
                      final item = data[idx];
                      final dt = DateTime.tryParse(item.date);
                      final dayName = dt != null ? DateFormat('E').format(dt) : '';
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          dayName,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(data.length, (idx) {
                final item = data[idx];
                final hours = item.sleepHours ?? 0.0;

                Color barColor;
                if (hours >= 7.0) {
                  barColor = AppColors.sleepDeep;
                } else if (hours >= 6.0) {
                  barColor = AppColors.sleepLight;
                } else {
                  barColor = AppColors.danger;
                }

                return BarChartGroupData(
                  x: idx,
                  barRods: [
                    BarChartRodData(
                      toY: hours,
                      color: barColor,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: 10,
                        color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 10),
        ),
      ],
    );
  }

  String _compactTime(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return '--';
    final parsed = TimeFormatter.parseTime(timeStr);
    if (parsed == null) return timeStr;

    final hour = parsed.hour;
    final minute = parsed.minute;
    final period = hour >= 12 ? 'P' : 'A';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    if (minute == 0) {
      return '$displayHour$period';
    }
    return '$displayHour:${minute.toString().padLeft(2, '0')}$period';
  }
}
