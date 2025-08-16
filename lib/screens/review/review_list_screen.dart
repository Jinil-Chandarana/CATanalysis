import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:catalyst_app/models/study_session.dart';
import 'package:catalyst_app/providers/session_provider.dart';
import 'package:catalyst_app/screens/detail/section_detail_screen.dart';

class ReviewListScreen extends ConsumerWidget {
  const ReviewListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewSessions = ref.watch(sessionsForReviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flagged for Review'),
      ),
      body: reviewSessions.isEmpty
          ? const Center(
              child: Text(
                'No sessions have been flagged for review.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: reviewSessions.length,
              itemBuilder: (context, index) {
                final session = reviewSessions[index];
                return _buildSessionCard(context, session);
              },
            ),
    );
  }

  // Re-using a simplified card logic here
  Widget _buildSessionCard(BuildContext context, StudySession session) {
    final date = DateFormat.yMMMd().format(session.endTime);
    final timeFormat = DateFormat.jm();
    final timeRange =
        '${timeFormat.format(session.startTime)} - ${timeFormat.format(session.endTime)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        title: Text('${session.subject.name} on $date',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(timeRange),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigate to the full detail screen for context
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SectionDetailScreen(subject: session.subject),
            ),
          );
        },
      ),
    );
  }
}
