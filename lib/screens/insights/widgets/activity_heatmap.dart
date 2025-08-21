import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catalyst_app/models/study_session.dart';
import 'package:catalyst_app/providers/session_provider.dart';
import 'package:catalyst_app/theme/app_colors.dart';

class ActivityHeatmap extends ConsumerWidget {
  const ActivityHeatmap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityData = ref.watch(activityHeatmapProvider);
    final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Weekly Study Habits",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                "This chart shows an overlay of all sessions from the past 30 days, grouped by weekday.",
                style: TextStyle(color: Colors.black54),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(
              children: [
                const SizedBox(width: 40),
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

  Widget _buildTimeLabel(String text) =>
      Text(text, style: const TextStyle(fontSize: 10));

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
                      borderRadius: BorderRadius.circular(4)),
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
                        width: blockWidth < 1 ? 1 : blockWidth,
                        child: Tooltip(
                          message:
                              '${session.subject.name}: ${session.focusDuration.inMinutes} mins',
                          child: Container(
                            // --- STYLE FIX: Pointy corners and a subtle border for definition ---
                            decoration: BoxDecoration(
                              color: AppColors.getSubjectColor(session.subject)
                                  .withOpacity(0.7),
                              border: Border.all(
                                  color: Colors.black.withOpacity(0.1),
                                  width: 0.5),
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
