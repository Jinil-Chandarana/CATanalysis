import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catalyst_app/models/study_session.dart';
import 'package:catalyst_app/providers/session_provider.dart';

class TodaysProgressCard extends ConsumerWidget {
  const TodaysProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaysProgress = ref.watch(todaysProgressProvider);

    // This is the new, more descriptive formatting function
    String formatDuration(Duration duration) {
      if (duration.inMinutes == 0) return "0 mins";

      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);

      final parts = <String>[];
      if (hours > 0) {
        parts.add('$hours hr${hours > 1 ? 's' : ''}');
      }
      if (minutes > 0) {
        parts.add('$minutes min${minutes > 1 ? 's' : ''}');
      }

      return parts.join(' ');
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Progress",
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProgressItem(context, 'VARC',
                  formatDuration(todaysProgress[Subject.varc]!)),
              _buildProgressItem(context, 'LRDI',
                  formatDuration(todaysProgress[Subject.lrdi]!)),
              _buildProgressItem(
                  context, 'QA', formatDuration(todaysProgress[Subject.qa]!)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
              ),
        ),
      ],
    );
  }
}
