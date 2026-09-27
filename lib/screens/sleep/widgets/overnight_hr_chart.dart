import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../models/sleep_data.dart';
import '../../../../theme/colors.dart';
import '../../../../widgets/glass_card.dart';

class OvernightHrChart extends StatelessWidget {
  final List<OvernightHeartRate> samples;

  const OvernightHrChart({
    super.key,
    required this.samples,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (samples.isEmpty) {
      return GlassCard(
        child: SizedBox(
          height: 140,
          child: Center(
            child: Text(
              'No overnight heart rate samples available yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ),
      );
    }

    final bpms = samples.map((s) => s.bpm).toList();
    final minBpm = bpms.reduce((a, b) => a < b ? a : b);
    final maxBpm = bpms.reduce((a, b) => a > b ? a : b);
    final avgBpm = (bpms.reduce((a, b) => a + b) / bpms.length).round();

    final spots = <FlSpot>[];
    for (int i = 0; i < samples.length; i++) {
      spots.add(FlSpot(i.toDouble(), samples[i].bpm.toDouble()));
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NOCTURNAL HEART RATE CURVE',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              Row(
                children: [
                  _statBadge('Min', '$minBpm', AppColors.success),
                  const SizedBox(width: 8),
                  _statBadge('Avg', '$avgBpm', AppColors.primary),
                  const SizedBox(width: 8),
                  _statBadge('Max', '$maxBpm', AppColors.danger),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                minY: (minBpm - 5).clamp(35, 120).toDouble(),
                maxY: (maxBpm + 5).clamp(60, 180).toDouble(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 15,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.4),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 20,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}',
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 9),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: AppColors.danger,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.danger.withValues(alpha: 0.25),
                          AppColors.danger.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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

  Widget _statBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
