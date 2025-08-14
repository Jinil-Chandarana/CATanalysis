import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catalyst_app/models/study_session.dart';
import 'package:catalyst_app/providers/session_provider.dart';
import 'package:catalyst_app/screens/detail/daily_summary_screen.dart';
import 'package:catalyst_app/screens/detail/section_detail_screen.dart';
import 'package:catalyst_app/screens/logging/log_session_screen.dart';
import 'package:catalyst_app/theme/app_colors.dart'; // <-- Import our new colors
import 'widgets/subject_card.dart';
import 'widgets/todays_progress_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final varcSessions = ref.watch(varcSessionsProvider);
    final lrdiSessions = ref.watch(lrdiSessionsProvider);
    final qaSessions = ref.watch(qaSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CATALYST',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.secondaryText),
            tooltip: 'Daily History',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const DailySummaryScreen(),
              ));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const TodaysProgressCard(),
          const SizedBox(height: 24),
          Text(
            'Overall Progress',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          SubjectCard(
            subject: Subject.varc,
            progressText: '${varcSessions.length} sessions logged',
            color:
                AppColors.getSubjectColor(Subject.varc), // <-- Using new color
            onTap: () => _navigateToDetail(context, Subject.varc),
          ),
          const SizedBox(height: 16),
          SubjectCard(
            subject: Subject.lrdi,
            progressText: '${lrdiSessions.length} sessions logged',
            color:
                AppColors.getSubjectColor(Subject.lrdi), // <-- Using new color
            onTap: () => _navigateToDetail(context, Subject.lrdi),
          ),
          const SizedBox(height: 16),
          SubjectCard(
            subject: Subject.qa,
            progressText: '${qaSessions.length} sessions logged',
            color: AppColors.getSubjectColor(Subject.qa), // <-- Using new color
            onTap: () => _navigateToDetail(context, Subject.qa),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LogSessionScreen()),
          );
        },
        label: const Text('Log Session'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.accent, // <-- Using new color
        foregroundColor: Colors.white,
      ),
    );
  }

  void _navigateToDetail(BuildContext context, Subject subject) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SectionDetailScreen(subject: subject),
      ),
    );
  }
}
