import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catalyst_app/providers/session_provider.dart';
import 'package:catalyst_app/screens/insights/widgets/activity_heatmap.dart';
import 'package:catalyst_app/screens/insights/widgets/day_selector.dart';
import 'package:catalyst_app/screens/insights/widgets/hourly_activity_chart.dart';
import 'package:catalyst_app/screens/insights/widgets/session_breakdown_list.dart';

class ActivityInsightsScreen extends StatefulWidget {
  const ActivityInsightsScreen({super.key});

  @override
  State<ActivityInsightsScreen> createState() => _ActivityInsightsScreenState();
}

class _ActivityInsightsScreenState extends State<ActivityInsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Insights'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _DailyActivityView(),
          // --- FIX: Reduced padding for a wider, more modern look ---
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
            child: ActivityHeatmap(),
          ),
        ],
      ),
    );
  }
}

// ... (Rest of the file is unchanged, only the part above was modified)

class _DailyActivityView extends ConsumerStatefulWidget {
  const _DailyActivityView();

  @override
  ConsumerState<_DailyActivityView> createState() => __DailyActivityViewState();
}

class __DailyActivityViewState extends ConsumerState<_DailyActivityView> {
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final dailyData = ref.watch(dailyActivityProvider(_selectedDay));

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        DaySelector(
          onDateSelected: (newDate) {
            setState(() {
              _selectedDay = newDate;
            });
          },
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDuration(dailyData.totalDuration),
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Total study time for the selected day.",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                HourlyActivityChart(hourlyData: dailyData.hourlyBreakdown),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SessionBreakdownList(sessionsBySubject: dailyData.sessionsBySubject),
      ],
    );
  }
}
