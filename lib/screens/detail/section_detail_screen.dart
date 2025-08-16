import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:catalyst_app/models/study_session.dart';
import 'package:catalyst_app/providers/session_provider.dart';
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
    };
    final sessions = ref.watch(sessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${subject.name} Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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

  Widget _buildSessionCard(
      BuildContext context, StudySession session, WidgetRef ref) {
    final date = DateFormat.yMMMd().format(session.endTime);
    // NEW: Format start and end times
    final timeFormat = DateFormat.jm(); // e.g., 5:08 PM
    final timeRange =
        '${timeFormat.format(session.startTime)} - ${timeFormat.format(session.endTime)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        title: Text('Session on $date',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // UPDATED: Display time range instead of just duration
            Text('Time: $timeRange'),
            _buildMetricsText(session),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
          onPressed: () =>
              ref.read(sessionProvider.notifier).deleteSession(session.id),
        ),
      ),
    );
  }

  Widget _buildMetricsText(StudySession session) {
    String formatAccuracy(String label, double acc, int correct, int total) {
      return '$label: ${(acc * 100).toStringAsFixed(1)}% ($correct/$total)';
    }

    // NEW: Helper to format time-based metrics
    String formatTime(String label, double value, String unit) {
      if (value <= 0) return '';
      return '$label: ${value.toStringAsFixed(1)} $unit';
    }

    switch (session.subject) {
      case Subject.varc:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (session.rcTotalAttempted > 0)
              Text(formatAccuracy('RC Accuracy', session.rcAccuracy,
                  session.rcTotalCorrect, session.rcTotalAttempted)),
            // NEW: Display RC time per question
            if (session.rcTotalAttempted > 0)
              Text(formatTime(
                  'RC Speed', session.rcTimePerQuestion, 'sec/ques')),
            if (session.vaTotalAttempted > 0)
              Text(formatAccuracy('VA Accuracy', session.vaAccuracy,
                  session.vaTotalCorrect, session.vaTotalAttempted)),
          ],
        );
      case Subject.lrdi:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Sets: ${session.lrdiSetsSolo} solo / ${session.lrdiSetsAttempted} attempted'),
            if (session.lrdiSoloTotalAttempted > 0)
              Text(formatAccuracy(
                  'Solo Accuracy',
                  session.lrdiSoloAccuracy,
                  session.lrdiSoloTotalCorrect,
                  session.lrdiSoloTotalAttempted)),
            // NEW: Display LRDI time per set
            if (session.lrdiSetsAttempted > 0)
              Text(formatTime('Pacing', session.lrdiTimePerSet, 'min/set')),
          ],
        );
      case Subject.qa:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formatAccuracy('Accuracy', session.qaAccuracy,
                session.qaTotalCorrect, session.qaTotalAttempted)),
            // NEW: Display QA time per question
            if (session.qaTotalAttempted > 0)
              Text(formatTime('Speed', session.qaTimePerQuestion, 'sec/ques')),
          ],
        );
    }
  }
}
