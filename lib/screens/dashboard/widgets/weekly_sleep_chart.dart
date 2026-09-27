import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/dashboard_data.dart';
import '../../../../theme/colors.dart';
import '../../../../widgets/glass_card.dart';

class WeeklySleepChart extends StatelessWidget {
  final List<WeeklySleepItem> weeklyData;

  const WeeklySleepChart({
    super.key,
    required this.weeklyData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '7-DAY SLEEP CONSISTENCY',
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  _legendDot(AppColors.sleepDeep, '>=7h'),
                  const SizedBox(width: 8),
                  _legendDot(AppColors.sleepLight, '6-7h'),
                  const SizedBox(width: 8),
                  _legendDot(AppColors.danger, '<6h'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: weeklyData.isEmpty
                ? const Center(child: Text('No weekly data yet'))
                : BarChart(
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
                              if (idx < 0 || idx >= weeklyData.length) {
                                return const SizedBox.shrink();
                              }
                              final item = weeklyData[idx];
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
                      barGroups: List.generate(weeklyData.length, (idx) {
                        final item = weeklyData[idx];
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
      ),
    );
  }

  Widget _legendDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
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
}
