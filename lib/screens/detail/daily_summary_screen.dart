import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:catalyst_app/models/study_session.dart';
import 'package:catalyst_app/providers/session_provider.dart';
import 'package:catalyst_app/theme/app_colors.dart';

class DailySummaryScreen extends ConsumerWidget {
  const DailySummaryScreen({super.key});

  // Helper function to format duration consistently
  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 1 && duration.inSeconds > 0) {
      return '< 1m';
    }
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailySummary = ref.watch(dailySummaryProvider);
    final sortedDays = dailySummary.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Study Log'),
      ),
      body: dailySummary.isEmpty
          ? const Center(
              child: Text(
                'No study sessions have been logged.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: sortedDays.length,
              itemBuilder: (context, index) {
                final day = sortedDays[index];
                final subjectDurations = dailySummary[day]!;

                // Calculate the total duration for the day
                final totalDuration = subjectDurations.values.fold(
                  Duration.zero,
                  (previous, element) => previous + element,
                );

                // Build the breakdown widgets
                final breakdownWidgets = subjectDurations.entries
                    .where((entry) => entry.value.inSeconds > 0)
                    .map((entry) => _buildBreakdownChip(
                          entry.key.name,
                          _formatDuration(entry.value),
                          AppColors.getSubjectColor(entry.key),
                        ))
                    .toList();

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat.yMMMMd().format(day),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Total: ${_formatDuration(totalDuration)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accent,
                                  ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        if (breakdownWidgets.isNotEmpty)
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: breakdownWidgets,
                          )
                        else
                          const Text("No specific subject times logged."),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildBreakdownChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color.withOpacity(1.0),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
