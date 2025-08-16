import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:catalyst_app/models/study_session.dart';
import 'package:catalyst_app/theme/app_colors.dart';

class PerformanceChart extends StatelessWidget {
  final List<StudySession> sessions;
  const PerformanceChart({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) return const SizedBox.shrink();
    final subject = sessions.first.subject;

    // The switch statement is now updated to handle all cases
    return switch (subject) {
      Subject.varc => _buildVarcCharts(context),
      Subject.qa => _buildSingleChartContainer(
          context, "QA Accuracy", _buildQaAccuracyChart()),
      Subject.lrdi => _buildSingleChartContainer(
          context, "LRDI Solo Set Accuracy", _buildLrdiSoloAccuracyChart()),
      // --- THIS IS THE FIX ---
      // If the subject is Misc, we show nothing because there's no data to chart.
      Subject.misc => const SizedBox.shrink(),
    };
  }

  Widget _buildVarcCharts(BuildContext context) {
    return Column(
      children: [
        _buildSingleChartContainer(
            context, "RC Accuracy", _buildRcAccuracyChart()),
        const SizedBox(height: 16),
        _buildSingleChartContainer(
            context, "VA Accuracy", _buildVaAccuracyChart()),
      ],
    );
  }

  Widget _buildSingleChartContainer(
      BuildContext context, String title, Widget chart) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(child: chart),
        ],
      ),
    );
  }

  LineChart _buildRcAccuracyChart() {
    final spots = sessions.reversed.toList().asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.rcAccuracy * 100);
    }).toList();
    return _createLineChart(spots, AppColors.getSubjectColor(Subject.varc));
  }

  LineChart _buildVaAccuracyChart() {
    final spots = sessions.reversed.toList().asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.vaAccuracy * 100);
    }).toList();
    return _createLineChart(
        spots, AppColors.getSubjectColor(Subject.varc).withOpacity(0.7));
  }

  LineChart _buildLrdiSoloAccuracyChart() {
    final spots = sessions.reversed.toList().asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.lrdiSoloAccuracy * 100);
    }).toList();
    return _createLineChart(spots, AppColors.getSubjectColor(Subject.lrdi));
  }

  LineChart _buildQaAccuracyChart() {
    final spots = sessions.reversed.toList().asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.qaAccuracy * 100);
    }).toList();
    return _createLineChart(spots, AppColors.getSubjectColor(Subject.qa));
  }

  LineChart _createLineChart(List<FlSpot> spots, Color color) {
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => AppColors.accent,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)}%',
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData:
                BarAreaData(show: true, color: color.withOpacity(0.2)),
          ),
        ],
      ),
    );
  }
}
