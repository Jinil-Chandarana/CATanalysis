import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:catalyst_app/models/study_session.dart';
import 'package:catalyst_app/providers/session_provider.dart';
import 'package:catalyst_app/theme/app_colors.dart';
import 'widgets/performance_chart.dart';

class SectionDetailScreen extends ConsumerWidget {
  final Subject subject;

  const SectionDetailScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsProvider = switch (subject) {
      Subject.varc => varcSessionsProvider,
      Subject.lrdi => lrdiSessionsProvider,
      Subject.qa => qaSessionsProvider,
      Subject.misc => miscSessionsProvider, // New
    };
    final sessions = ref.watch(sessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${subject.name} Details'),
      ),
      body: sessions.isEmpty
          ? const Center(
              child: Text(
                'No sessions logged for this subject yet.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (subject == Subject.qa) ...[
                  _buildQaTopicStats(context, ref),
                  const SizedBox(height: 24),
                ],
                // New: Show task analysis for Misc
                if (subject == Subject.misc) ...[
                  _buildMiscTaskStats(context, ref),
                  const SizedBox(height: 24),
                ],
                // New: Hide chart for Misc
                if (subject != Subject.misc)
                  PerformanceChart(sessions: sessions),
                const SizedBox(height: 24),
                Text(
                  'Session History',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...sessions
                    .map((session) => _buildSessionCard(context, session, ref))
                    .toList(),
              ],
            ),
    );
  }

  Widget _buildQaTopicStats(BuildContext context, WidgetRef ref) {
    final tagStats = ref.watch(qaTagStatsProvider);
    if (tagStats.isEmpty) {
      return const SizedBox.shrink();
    }
    final sortedTags = tagStats.entries.toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance by Topic',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (var entry in sortedTags)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text(
                      '${(entry.value.correct / entry.value.total * 100).toStringAsFixed(1)}% (${entry.value.correct}/${entry.value.total})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // New widget for Misc task analysis
  Widget _buildMiscTaskStats(BuildContext context, WidgetRef ref) {
    final taskStats = ref.watch(miscTaskStatsProvider);
    if (taskStats.isEmpty) {
      return const SizedBox.shrink();
    }
    final sortedTasks = taskStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String formatDuration(Duration d) =>
        '${d.inHours}h ${d.inMinutes.remainder(60)}m';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Spent per Task',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (var entry in sortedTasks)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text(
                      formatDuration(entry.value),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(
      BuildContext context, StudySession session, WidgetRef ref) {
    final date = DateFormat.yMMMd().format(session.endTime);
    final timeFormat = DateFormat.jm();
    final timeRange =
        '${timeFormat.format(session.startTime)} - ${timeFormat.format(session.endTime)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                  onPressed: () => ref
                      .read(sessionProvider.notifier)
                      .deleteSession(session.id),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Time: $timeRange',
                style: const TextStyle(color: Colors.black54)),
            const Divider(height: 20),
            _buildMetricsDisplay(session),
            if (session.notes != null && session.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Notes / Analysis',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(session.notes!),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsDisplay(StudySession session) {
    String formatAccuracy(double acc, int correct, int total) {
      if (total == 0) return '0.0% (0/0)';
      return '${(acc * 100).toStringAsFixed(1)}% ($correct/$total)';
    }

    String formatTime(double value, String unit) {
      if (value <= 0) return '-';
      return '${value.toStringAsFixed(1)} $unit';
    }

    switch (session.subject) {
      case Subject.varc:
        return Column(
          children: [
            for (var set in (session.metrics['rc_sets'] as List))
              _buildMetricRow(
                  'RC Set (${Difficulty.values[set['difficulty'] ?? Difficulty.medium.index].name})',
                  formatAccuracy(
                      (set['questions'] ?? 0) > 0
                          ? (set['correct'] as int) / (set['questions'] as int)
                          : 0.0,
                      set['correct'],
                      set['questions'])),
            if (session.vaTotalAttempted > 0)
              _buildMetricRow(
                  'VA Accuracy',
                  formatAccuracy(session.vaAccuracy, session.vaTotalCorrect,
                      session.vaTotalAttempted)),
          ],
        );
      case Subject.lrdi:
        return Column(
          children: [
            for (var set in (session.metrics['lrdi_sets'] as List))
              _buildMetricRow(
                  'LRDI Set (${Difficulty.values[set['difficulty'] ?? Difficulty.medium.index].name})',
                  formatAccuracy(
                      (set['questions'] ?? 0) > 0
                          ? (set['correct'] as int) / (set['questions'] as int)
                          : 0.0,
                      set['correct'],
                      set['questions'])),
            _buildMetricRow(
                'Pacing', formatTime(session.lrdiTimePerSet, 'min/set')),
          ],
        );
      case Subject.qa:
        return Column(
          children: [
            _buildMetricRow(
                'Accuracy',
                formatAccuracy(session.qaAccuracy, session.qaTotalCorrect,
                    session.qaTotalAttempted)),
            _buildMetricRow(
                'Speed', formatTime(session.qaTimePerQuestion, 'sec/ques')),
            if (session.tags.isNotEmpty)
              _buildMetricRow('Topics', session.tags.join(', ')),
          ],
        );
      case Subject.misc: // New
        return _buildMetricRow('Task', session.taskName ?? 'N/A');
    }
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
