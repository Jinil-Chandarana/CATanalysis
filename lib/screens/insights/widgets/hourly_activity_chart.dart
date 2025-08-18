import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:catalyst_app/theme/app_colors.dart';

class HourlyActivityChart extends StatelessWidget {
  final List<double> hourlyData;

  const HourlyActivityChart({super.key, required this.hourlyData});

  @override
  Widget build(BuildContext context) {
    final double maxVal = hourlyData.fold(0.0, (p, c) => c > p ? c : p);
    final double chartMaxY = (maxVal == 0) ? 60 : (maxVal / 60).ceil() * 60;

    return SizedBox(
      height: 150,
      child: BarChart(
        BarChartData(
          maxY: chartMaxY,
          barGroups: _generateBarGroups(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.accent,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final minutes = rod.toY.toInt();
                return BarTooltipItem(
                  '$minutes min',
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  if (value % 60 == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: Text('${(value / 60).toInt()}h',
                          style: const TextStyle(fontSize: 10)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            // --- TIME FORMAT FIX ---
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final hour = value.toInt();
                  if (hour % 6 == 0) {
                    if (hour == 0)
                      return const Text('12am', style: TextStyle(fontSize: 10));
                    if (hour == 6)
                      return const Text('6am', style: TextStyle(fontSize: 10));
                    if (hour == 12)
                      return const Text('12pm', style: TextStyle(fontSize: 10));
                    if (hour == 18)
                      return const Text('6pm', style: TextStyle(fontSize: 10));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  List<BarChartGroupData> _generateBarGroups() {
    return List.generate(24, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: hourlyData[index],
            color: AppColors.accent,
            width: 5,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }
}
