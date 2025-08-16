import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catalyst_app/models/study_session.dart';
import 'package:catalyst_app/providers/session_provider.dart';
import 'package:catalyst_app/theme/app_colors.dart';

class ActivityHeatmap extends ConsumerWidget {
  const ActivityHeatmap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This provider gives data grouped by weekday
    final activityData = ref.watch(activityHeatmapProvider);
    final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Weekly Study Habits",
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "This chart shows the times of day you've typically studied over the past 30 days.",
              style: TextStyle(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const SizedBox(width: 40), // Spacer for day labels
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTimeLabel('12 AM'),
                      _buildTimeLabel('6 AM'),
                      _buildTimeLabel('12 PM'),
                      _buildTimeLabel('6 PM'),
                      _buildTimeLabel('11 PM'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < 7; i++)
              _buildDayRow(daysOfWeek[i], activityData[i + 1] ?? []),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 10));
  }

  Widget _buildDayRow(String dayLabel, List<StudySession> sessions) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text(dayLabel)),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    children: sessions.map((session) {
                      final startPercent = session.startTime.hour / 24 +
                          session.startTime.minute / (24 * 60);
                      final endPercent = session.endTime.hour / 24 +
                          session.endTime.minute / (24 * 60);

                      final left = startPercent * width;
                      final blockWidth = (endPercent - startPercent) * width;

                      return Positioned(
                        left: left,
                        top: 0,
                        bottom: 0,
                        width: blockWidth < 2 ? 2 : blockWidth, // Min width
                        child: Tooltip(
                          message:
                              '${session.subject.name}: ${session.duration.inMinutes} mins',
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.getSubjectColor(session.subject),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
