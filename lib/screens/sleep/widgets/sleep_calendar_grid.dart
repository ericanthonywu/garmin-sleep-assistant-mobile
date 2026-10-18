import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/sleep_calendar_data.dart';
import '../../../theme/colors.dart';
import '../../../widgets/glass_card.dart';

class SleepCalendarGrid extends StatelessWidget {
  final DateTime currentMonth;
  final String selectedDate;
  final SleepCalendarResponse? calendarData;
  final ValueChanged<String> onSelectDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onJumpToToday;

  const SleepCalendarGrid({
    super.key,
    required this.currentMonth,
    required this.selectedDate,
    required this.calendarData,
    required this.onSelectDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onJumpToToday,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthTitle = DateFormat('MMMM yyyy').format(currentMonth);

    final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final firstWeekday = DateTime(currentMonth.year, currentMonth.month, 1).weekday; // 1 = Mon, 7 = Sun
    final leadingEmpty = firstWeekday - 1;
    final totalCells = leadingEmpty + daysInMonth;

    final daysMap = <String, SleepCalendarDay>{};
    if (calendarData != null) {
      for (final day in calendarData!.days) {
        daysMap[day.date] = day;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Month Selector Bar
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary),
                tooltip: 'Previous Month',
                onPressed: onPreviousMonth,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    monthTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: onJumpToToday,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary),
                    tooltip: 'Next Month',
                    onPressed: onNextMonth,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Weekday Column Headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            _WeekdayLabel('M'),
            _WeekdayLabel('T'),
            _WeekdayLabel('W'),
            _WeekdayLabel('T'),
            _WeekdayLabel('F'),
            _WeekdayLabel('S'),
            _WeekdayLabel('S'),
          ],
        ),
        const SizedBox(height: 8),

        // Calendar Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 0.84,
            crossAxisSpacing: 5,
            mainAxisSpacing: 6,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            if (index < leadingEmpty) {
              return const SizedBox.shrink();
            }

            final dayNum = index - leadingEmpty + 1;
            final dateStr = DateFormat('yyyy-MM-dd').format(
              DateTime(currentMonth.year, currentMonth.month, dayNum),
            );
            final dayData = daysMap[dateStr];
            final isSelected = dateStr == selectedDate;
            final isToday = dateStr == DateFormat('yyyy-MM-dd').format(DateTime.now());

            return _CalendarDayCell(
              dayNum: dayNum,
              dateStr: dateStr,
              dayData: dayData,
              isSelected: isSelected,
              isToday: isToday,
              onTap: () => onSelectDate(dateStr),
            );
          },
        ),

        // Monthly Stats Bar
        if (calendarData?.monthlyStats != null &&
            calendarData!.monthlyStats!.totalNightsTracked > 0) ...[
          const SizedBox(height: 14),
          _buildMonthlyStatsCard(context, calendarData!.monthlyStats!),
        ],
      ],
    );
  }

  Widget _buildMonthlyStatsCard(BuildContext context, SleepCalendarStats stats) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MONTHLY SLEEP OVERVIEW',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.textTertiary,
                ),
              ),
              Text(
                '${stats.totalNightsTracked} nights tracked',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Average score ring
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.sleepScoreColor(stats.averageSleepScore).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.sleepScoreColor(stats.averageSleepScore).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.nightlight_round,
                      size: 14,
                      color: AppColors.sleepScoreColor(stats.averageSleepScore),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      stats.averageSleepScore != null ? '${stats.averageSleepScore}' : '--',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.sleepScoreColor(stats.averageSleepScore),
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'avg score',
                      style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Average duration
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text(
                      stats.averageSleepHours != null ? '${stats.averageSleepHours}h' : '--',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'avg',
                      style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Magnesium Adherence
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.medication_rounded, size: 14, color: Color(0xFFA855F7)),
                    const SizedBox(width: 4),
                    Text(
                      '${stats.magnesiumAdherenceRate}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFA855F7),
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'magnesium',
                      style: TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Quality Breakdown Distribution bar
          Row(
            children: [
              _buildQualityChip('Optimal (85+)', stats.optimalNights, AppColors.success),
              const SizedBox(width: 6),
              _buildQualityChip('Good (75-84)', stats.goodNights, AppColors.primary),
              const SizedBox(width: 6),
              _buildQualityChip('Fair (60-74)', stats.fairNights, AppColors.warning),
              const SizedBox(width: 6),
              _buildQualityChip('Poor (<60)', stats.poorNights, AppColors.danger),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQualityChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label.split(' ')[0],
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.9),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;
  const _WeekdayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final int dayNum;
  final String dateStr;
  final SleepCalendarDay? dayData;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.dayNum,
    required this.dateStr,
    required this.dayData,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasScore = dayData != null && dayData!.hasData && dayData!.sleepScore != null;
    final score = dayData?.sleepScore;
    final scoreColor = AppColors.sleepScoreColor(score);
    final isMagTaken = dayData?.magnesiumTaken == true;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.22)
              : (hasScore
                  ? scoreColor.withValues(alpha: 0.08)
                  : AppColors.surfaceElevated.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isToday
                    ? AppColors.momWarm
                    : (hasScore
                        ? scoreColor.withValues(alpha: 0.35)
                        : AppColors.border.withValues(alpha: 0.6))),
            width: isSelected ? 2.0 : (isToday ? 1.5 : 1.0),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Day number & optional magnesium pill / today indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$dayNum',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isToday || isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isToday
                            ? AppColors.momWarm
                            : (hasScore ? AppColors.textPrimary : AppColors.textTertiary)),
                  ),
                ),
                if (isMagTaken)
                  const Icon(
                    Icons.medication_rounded,
                    size: 11,
                    color: Color(0xFFA855F7),
                  )
                else if (isToday)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.momWarm,
                    ),
                  ),
              ],
            ),

            // Middle: Sleep Score Pill or Placeholder
            if (hasScore)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: scoreColor,
                  ),
                ),
              )
            else
              const Text(
                '·',
                style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
              ),

            // Bottom: Hours string
            Text(
              hasScore && dayData?.sleepHours != null
                  ? '${dayData!.sleepHours!.toStringAsFixed(1)}h'
                  : '--',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: hasScore ? AppColors.textSecondary : AppColors.textTertiary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
