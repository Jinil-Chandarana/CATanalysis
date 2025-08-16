import 'package:flutter/material.dart';
import 'package:catalyst_app/models/study_session.dart';
import 'package:catalyst_app/theme/app_colors.dart';

class SessionBreakdownList extends StatelessWidget {
  final Map<Subject, Duration> sessionsBySubject;

  const SessionBreakdownList({super.key, required this.sessionsBySubject});

  @override
  Widget build(BuildContext context) {
    if (sessionsBySubject.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: Text("No sessions for this day.")),
      );
    }

    // Sort subjects for consistent order
    final sortedEntries = sessionsBySubject.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Breakdown by Subject",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        for (var entry in sortedEntries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.getSubjectColor(entry.key),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(entry.key.name),
                const Spacer(),
                Text(
                  '${entry.value.inHours}h ${entry.value.inMinutes.remainder(60)}m',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
      ],
    );
  }
}
