import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:catalyst_app/models/study_session.dart';
import 'package:catalyst_app/providers/session_provider.dart';
import 'package:catalyst_app/theme/app_colors.dart';
import 'widgets/performance_chart.dart';

class SectionDetailScreen extends ConsumerStatefulWidget {
  final Subject subject;
  const SectionDetailScreen({super.key, required this.subject});

  @override
  ConsumerState<SectionDetailScreen> createState() =>
      _SectionDetailScreenState();
}

class _SectionDetailScreenState extends ConsumerState<SectionDetailScreen> {
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final sessionsProvider = switch (widget.subject) {
      Subject.varc => varcSessionsProvider,
      Subject.lrdi => lrdiSessionsProvider,
      Subject.qa => qaSessionsProvider,
      Subject.misc => miscSessionsProvider,
    };
    final sessions = ref.watch(sessionsProvider);

    final sessionsByDay = groupBy<StudySession, DateTime>(
      sessions,
      (s) => DateTime(s.endTime.year, s.endTime.month, s.endTime.day),
    );
    final sortedDays = sessionsByDay.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    // --- THIS IS THE GUARANTEED FIX for the Null Check Error ---
    // On every rebuild, check if the currently selected day is still valid.
    // If it's not (e.g., its sessions were deleted), reset to the latest day.
    if (!sortedDays.contains(_selectedDay) && sortedDays.isNotEmpty) {
      _selectedDay = sortedDays.last;
    } else if (sortedDays.isEmpty) {
      _selectedDay = null;
    }

    // Safely get the sessions for the selected day. Defaults to an empty list.
    final selectedDaySessions = sessionsByDay[_selectedDay] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text('${widget.subject.name} Details')),
      body: sessions.isEmpty
          ? const Center(
              child: Text('No sessions logged for this subject yet.'))
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (widget.subject == Subject.varc) ...[
                  _buildVaTopicStats(context, ref),
                  const SizedBox(height: 24)
                ],
                if (widget.subject == Subject.qa) ...[
                  _buildQaTopicStats(context, ref),
                  const SizedBox(height: 24)
                ],
                if (widget.subject == Subject.misc) ...[
                  _buildMiscTaskStats(context, ref),
                  const SizedBox(height: 24)
                ],
                if (widget.subject != Subject.misc)
                  PerformanceChart(sessions: sessions),
                const SizedBox(height: 24),
                Text('Session History',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (sortedDays.isNotEmpty) ...[
                  SizedBox(
                    height: 70,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: sortedDays.length,
                      controller: _createScrollController(sortedDays),
                      itemBuilder: (context, index) {
                        final day = sortedDays[index];
                        final isSelected = _selectedDay == day;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDay = day;
                            });
                          },
                          child: Container(
                            width: 60,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.getSubjectColor(widget.subject)
                                  : AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat.MMM().format(day),
                                  style: TextStyle(
                                    color:
                                        isSelected ? Colors.white : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat.d().format(day),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      key: ValueKey(_selectedDay),
                      children: selectedDaySessions
                          .map((session) =>
                              _buildSessionCard(context, session, ref))
                          .toList(),
                    ),
                  ),
                ]
              ],
            ),
    );
  }

  ScrollController? _createScrollController(List<DateTime> days) {
    if (_selectedDay == null) return null;
    final selectedIndex = days.indexOf(_selectedDay!);
    if (selectedIndex == -1) return null;
    return ScrollController(initialScrollOffset: selectedIndex * 68.0);
  }

  // (All helper methods below are correct and unchanged)

  Widget _buildSessionCard(
      BuildContext context, StudySession session, WidgetRef ref) {
    final List<Widget> statRows = [..._getMetricsWidgets(session)];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat.yMMMd().format(session.endTime),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                          '${DateFormat.jm().format(session.startTime)} - ${DateFormat.jm().format(session.endTime)}',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13)),
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
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListView.separated(
                  itemCount: statRows.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) => statRows[index],
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                ),
                const SizedBox(height: 12),
                _buildFocusIndicatorBar(session),
              ],
            ),
          ),
          if (session.notes != null && session.notes!.isNotEmpty)
            _buildNotesSection(session),
        ],
      ),
    );
  }

  Widget _buildFocusIndicatorBar(StudySession session) {
    final subjectColor = AppColors.getSubjectColor(session.subject);
    String formatDuration(Duration d) =>
        '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Focus Efficiency',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600)),
            Text('${(session.focusPercentage * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: subjectColor)),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
                height: 10,
                decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(5))),
            LayoutBuilder(
              builder: (context, constraints) => Container(
                height: 10,
                width: constraints.maxWidth * session.focusPercentage,
                decoration: BoxDecoration(
                    color: subjectColor,
                    borderRadius: BorderRadius.circular(5)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Focus: ${formatDuration(session.focusDuration)}',
                style: TextStyle(
                    fontSize: 12,
                    color: subjectColor,
                    fontWeight: FontWeight.bold)),
            Text('Total: ${formatDuration(session.seatingDuration)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ],
    );
  }

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
        for (var set in session.vaSets) {
          if ((set['attempted'] ?? 0) > 0) {
            metrics.add(_buildMetricRow(
              'VA: ${set['topic'] ?? 'Unknown'}',
              formatAccuracy(
                  (set['attempted'] as int) > 0
                      ? (set['correct'] as int) / (set['attempted'] as int)
                      : 0.0,
                  set['correct'],
                  set['attempted']),
            ));
          }
        }
        for (var set in (session.metrics['rc_sets'] as List)) {
          if ((set['questions'] ?? 0) > 0) {
            metrics.add(_buildMetricRow(
              'RC Set (${Difficulty.values[set['difficulty'] ?? Difficulty.medium.index].name})',
              formatAccuracy(
                  (set['questions'] as int) > 0
                      ? (set['correct'] as int) / (set['questions'] as int)
                      : 0.0,
                  set['correct'],
                  set['questions']),
            ));
          }
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

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
            child: Text(label,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                overflow: TextOverflow.ellipsis)),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  Widget _buildNotesSection(StudySession session) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notes / Analysis',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          const SizedBox(height: 8),
          Text(session.notes!,
              style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
        ],
      ),
    );
  }

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
                        style: const TextStyle(fontWeight: FontWeight.w600)),
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
                        style: const TextStyle(fontWeight: FontWeight.w600)),
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
