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
    // This build method is correct and remains unchanged
    final sessionsProvider = switch (subject) {
      Subject.varc => varcSessionsProvider,
      Subject.lrdi => lrdiSessionsProvider,
      Subject.qa => qaSessionsProvider,
      Subject.misc => miscSessionsProvider,
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
                if (subject == Subject.varc) ...[
                  _buildVaTopicStats(context, ref),
                  const SizedBox(height: 24),
                ],
                if (subject == Subject.qa) ...[
                  _buildQaTopicStats(context, ref),
                  const SizedBox(height: 24),
                ],
                if (subject == Subject.misc) ...[
                  _buildMiscTaskStats(context, ref),
                  const SizedBox(height: 24),
                ],
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

  // --- WIDGET REDESIGNED with a clean Linear Progress Bar ---
  Widget _buildSessionCard(
      BuildContext context, StudySession session, WidgetRef ref) {
    // Create a single list of all stat widgets for this session
    final List<Widget> statRows = [
      ..._getMetricsWidgets(session), // Subject-specific metrics
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior:
          Clip.antiAlias, // Important for the notes section background
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER: Date, Time, and Delete Button ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat.yMMMd().format(session.endTime),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat.jm().format(session.startTime)} - ${DateFormat.jm().format(session.endTime)}',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  onPressed: () => ref
                      .read(sessionProvider.notifier)
                      .deleteSession(session.id),
                ),
              ],
            ),
          ),

          // --- DIVIDER: Cleanly separates header from data ---
          const Divider(height: 1),

          // --- STATS AND PROGRESS BAR SECTION ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The list of text-based stats
                ListView.separated(
                  itemCount: statRows.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) => statRows[index],
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                ),
                // --- THIS IS THE ONLY CHANGE: Reduced the spacing from 16 to 12 ---
                const SizedBox(height: 12),
                // The new, cool linear progress bar
                _buildFocusIndicatorBar(session),
              ],
            ),
          ),

          // --- NOTES SECTION (if available) ---
          if (session.notes != null && session.notes!.isNotEmpty)
            _buildNotesSection(session),
        ],
      ),
    );
  }

  // --- NEW WIDGET: The Linear Progress Indicator Bar ---
  Widget _buildFocusIndicatorBar(StudySession session) {
    final subjectColor = AppColors.getSubjectColor(session.subject);
    String formatDuration(Duration d) =>
        '${d.inHours}h ${d.inMinutes.remainder(60)}m';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title for the bar
        Text(
          'Focus Efficiency',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        // The bar itself, built with a Stack and Containers
        Stack(
          children: [
            // The background of the bar
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // The foreground (progress) of the bar
            LayoutBuilder(
              builder: (context, constraints) => Container(
                height: 10,
                width: constraints.maxWidth * session.focusPercentage,
                decoration: BoxDecoration(
                  color: subjectColor,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Labels below the bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Focus: ${formatDuration(session.focusDuration)}',
              style: TextStyle(
                  fontSize: 12,
                  color: subjectColor,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              'Total: ${formatDuration(session.seatingDuration)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  // --- HELPER: The simple, clean "bill-style" row ---
  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }

  // --- HELPER: A dedicated, styled notes section ---
  Widget _buildNotesSection(StudySession session) {
    return Container(
      width: double.infinity,
      color: Colors.grey.shade50,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes / Analysis',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            session.notes!,
            style: TextStyle(color: Colors.grey.shade700, height: 1.4),
          ),
        ],
      ),
    );
  }

  // --- HELPER: Gathers all subject-specific metric widgets ---
  List<Widget> _getMetricsWidgets(StudySession session) {
    String formatAccuracy(double acc, int correct, int total) {
      if (total == 0) return '0.0% ($correct/$total)';
      return '${(acc * 100).toStringAsFixed(1)}% ($correct/$total)';
    }

    String formatTime(double value, String unit) {
      if (value <= 0) return '-';
      final minutes = value / 60;
      return '${minutes.toStringAsFixed(1)} $unit';
    }

    List<Widget> metrics = [];
    switch (session.subject) {
      case Subject.varc:
        for (var set in (session.metrics['rc_sets'] as List)) {
          metrics.add(_buildMetricRow(
            'RC Set (${Difficulty.values[set['difficulty'] ?? Difficulty.medium.index].name})',
            formatAccuracy(
                (set['questions'] ?? 0) > 0
                    ? (set['correct'] as int) / (set['questions'] as int)
                    : 0.0,
                set['correct'],
                set['questions']),
          ));
        }
        if (session.vaTotalAttempted > 0) {
          metrics.add(_buildMetricRow(
              'VA: ${session.tags.isNotEmpty ? session.tags.first : ""}',
              formatAccuracy(session.vaAccuracy, session.vaTotalCorrect,
                  session.vaTotalAttempted)));
        }
        break;
      case Subject.lrdi:
        for (var set in (session.metrics['lrdi_sets'] as List)) {
          metrics.add(_buildMetricRow(
            'LRDI Set (${Difficulty.values[set['difficulty'] ?? Difficulty.medium.index].name})',
            formatAccuracy(
                (set['questions'] ?? 0) > 0
                    ? (set['correct'] as int) / (set['questions'] as int)
                    : 0.0,
                set['correct'],
                set['questions']),
          ));
        }
        metrics.add(_buildMetricRow(
            'Pacing', '${session.lrdiTimePerSet.toStringAsFixed(1)} min/set'));
        break;
      case Subject.qa:
        metrics.add(_buildMetricRow(
            'Accuracy',
            formatAccuracy(session.qaAccuracy, session.qaTotalCorrect,
                session.qaTotalAttempted)));
        metrics.add(_buildMetricRow(
            'Speed', formatTime(session.qaTimePerQuestion, 'min/ques')));
        if (session.tags.isNotEmpty) {
          metrics.add(_buildMetricRow('Topic', session.tags.join(', ')));
        }
        break;
      case Subject.misc:
        metrics.add(_buildMetricRow('Task', session.taskName ?? 'N/A'));
        break;
    }
    return metrics;
  }

  // --- UNCHANGED WIDGETS BELOW ---
  Widget _buildVaTopicStats(BuildContext context, WidgetRef ref) {
    final tagStats = ref.watch(vaTagStatsProvider);
    if (tagStats.isEmpty) return const SizedBox.shrink();
    final sortedTags = tagStats.entries.toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Performance by VA Topic',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
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

  Widget _buildQaTopicStats(BuildContext context, WidgetRef ref) {
    final tagStats = ref.watch(qaTagStatsProvider);
    if (tagStats.isEmpty) return const SizedBox.shrink();
    final sortedTags = tagStats.entries.toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Performance by QA Topic',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
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

  Widget _buildMiscTaskStats(BuildContext context, WidgetRef ref) {
    final taskStats = ref.watch(miscTaskStatsProvider);
    if (taskStats.isEmpty) return const SizedBox.shrink();
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
            Text('Time Spent per Task',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (var entry in sortedTasks)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text(formatDuration(entry.value),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
