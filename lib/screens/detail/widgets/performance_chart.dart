import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:catalyst_app/models/study_session.dart';
import 'package:catalyst_app/theme/app_colors.dart';

class PerformanceChart extends StatelessWidget {
  final List<StudySession> sessions;
  const PerformanceChart({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) return const SizedBox.shrink();
    final subject = sessions.first.subject;

    double? _calculateAverage(
        List<StudySession> sessions,
        double Function(StudySession) getAccuracy,
        bool Function(StudySession) filter) {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 10));
      final recentSessions = sessions
          .where((s) => s.endTime.isAfter(cutoffDate) && filter(s))
          .toList();

      if (recentSessions.isEmpty) return null;

      final totalAccuracy =
          recentSessions.fold<double>(0.0, (prev, s) => prev + getAccuracy(s));
      return totalAccuracy / recentSessions.length;
    }

    final rcAvg = _calculateAverage(
        sessions, (s) => s.rcAccuracy, (s) => s.rcTotalAttempted > 0);
    final vaAvg = _calculateAverage(
        sessions, (s) => s.vaAccuracy, (s) => s.vaTotalAttempted > 0);
    final qaAvg = _calculateAverage(
        sessions, (s) => s.qaAccuracy, (s) => s.qaTotalAttempted > 0);
    final lrdiAvg = _calculateAverage(sessions, (s) => s.lrdiSoloAccuracy,
        (s) => s.lrdiSoloTotalAttempted > 0);

    return switch (subject) {
      Subject.varc => _buildVarcCharts(context, rcAvg, vaAvg),
      Subject.qa => _buildSingleChartContainer(
          context, "QA Accuracy", _buildQaAccuracyChart(),
          averageAccuracy: qaAvg),
      Subject.lrdi => _buildSingleChartContainer(
          context, "LRDI Solo Set Accuracy", _buildLrdiSoloAccuracyChart(),
          averageAccuracy: lrdiAvg),
      Subject.misc => const SizedBox.shrink(),
    };
  }

  Widget _buildVarcCharts(BuildContext context, double? rcAvg, double? vaAvg) {
    return Column(
      children: [
        _buildSingleChartContainer(
            context, "RC Accuracy", _buildRcAccuracyChart(),
            averageAccuracy: rcAvg),
        const SizedBox(height: 16),
        _buildSingleChartContainer(
            context, "VA Accuracy", _buildVaAccuracyChart(),
            averageAccuracy: vaAvg),
      ],
    );
  }

  Widget _buildSingleChartContainer(
      BuildContext context, String title, Widget chart,
      {double? averageAccuracy}) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              if (averageAccuracy != null)
                Text(
                  '${(averageAccuracy * 100).toStringAsFixed(1)}% (10d avg)',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: chart),
        ],
      ),
    );
  }

  LineChart _buildRcAccuracyChart() {
    final relevantSessions =
        sessions.where((s) => s.rcTotalAttempted > 0).toList();
    final spots = relevantSessions.reversed
        .toList()
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.rcAccuracy * 100))
        .toList();
    return _createLineChart(spots, AppColors.getSubjectColor(Subject.varc),
        relevantSessions.reversed.toList());
  }

  LineChart _buildVaAccuracyChart() {
    final relevantSessions =
        sessions.where((s) => s.vaTotalAttempted > 0).toList();
    final spots = relevantSessions.reversed
        .toList()
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.vaAccuracy * 100))
        .toList();
    return _createLineChart(
        spots,
        AppColors.getSubjectColor(Subject.varc).withOpacity(0.7),
        relevantSessions.reversed.toList());
  }

  LineChart _buildLrdiSoloAccuracyChart() {
    final relevantSessions =
        sessions.where((s) => s.lrdiSoloTotalAttempted > 0).toList();
    final spots = relevantSessions.reversed
        .toList()
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.lrdiSoloAccuracy * 100))
        .toList();
    return _createLineChart(spots, AppColors.getSubjectColor(Subject.lrdi),
        relevantSessions.reversed.toList());
  }

  LineChart _buildQaAccuracyChart() {
    final relevantSessions =
        sessions.where((s) => s.qaTotalAttempted > 0).toList();
    final spots = relevantSessions.reversed
        .toList()
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.qaAccuracy * 100))
        .toList();
    return _createLineChart(spots, AppColors.getSubjectColor(Subject.qa),
        relevantSessions.reversed.toList());
  }

  LineChart _createLineChart(
      List<FlSpot> spots, Color color, List<StudySession> sessionsForTooltip) {
    if (spots.isEmpty) {
      return LineChart(LineChartData(lineBarsData: [
        LineChartBarData(spots: [const FlSpot(0, 0)])
      ]));
    }
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => AppColors.accent,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final session = sessionsForTooltip[spot.spotIndex];
                final date = DateFormat.MMMd().format(session.endTime);
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)}%\n',
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: date,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.normal),
                    ),
                  ],
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
            // --- THIS IS THE FIX: Changed from false back to true to restore the curves ---
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 3,
                color: color,
                strokeWidth: 1,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData:
                BarAreaData(show: true, color: color.withOpacity(0.2)),
          ),
        ],
      ),
    );
  }
}
