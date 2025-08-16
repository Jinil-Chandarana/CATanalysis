import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catalyst_app/models/study_session.dart';
import 'package:catalyst_app/persistence/hive_service.dart';

// A record to hold the structured data for our new screen
typedef DailyActivity = ({
  Duration totalDuration,
  List<double> hourlyBreakdown, // 24 hours, in minutes
  Map<Subject, Duration> sessionsBySubject,
});

// 1. Provider for our HiveService instance
final hiveServiceProvider = Provider<HiveService>((ref) => HiveService());

// 2. The main StateNotifierProvider that manages the list of sessions
final sessionProvider =
    StateNotifierProvider<SessionNotifier, List<StudySession>>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return SessionNotifier(hiveService);
});

class SessionNotifier extends StateNotifier<List<StudySession>> {
  final HiveService _hiveService;

  SessionNotifier(this._hiveService) : super([]) {
    loadSessions(); // Load initial data
  }

  void loadSessions() {
    state = _hiveService.getAllSessions();
  }

  Future<void> addSession(StudySession session) async {
    await _hiveService.addSession(session);
    loadSessions(); // Reload list and notify UI
  }

  Future<void> deleteSession(String id) async {
    await _hiveService.deleteSession(id);
    loadSessions(); // Reload list and notify UI
  }
}

// 3. Existing Derived Providers... (no changes)
final varcSessionsProvider = Provider<List<StudySession>>((ref) {
  final allSessions = ref.watch(sessionProvider);
  return allSessions.where((s) => s.subject == Subject.varc).toList();
});

final lrdiSessionsProvider = Provider<List<StudySession>>((ref) {
  final allSessions = ref.watch(sessionProvider);
  return allSessions.where((s) => s.subject == Subject.lrdi).toList();
});

final qaSessionsProvider = Provider<List<StudySession>>((ref) {
  final allSessions = ref.watch(sessionProvider);
  return allSessions.where((s) => s.subject == Subject.qa).toList();
});

final todaysProgressProvider = Provider<Map<Subject, Duration>>((ref) {
  final allSessions = ref.watch(sessionProvider);
  final today = DateTime.now();
  final todaysSessions = allSessions.where((s) =>
      s.endTime.year == today.year &&
      s.endTime.month == today.month &&
      s.endTime.day == today.day);

  final progress = {
    Subject.varc: Duration.zero,
    Subject.lrdi: Duration.zero,
    Subject.qa: Duration.zero,
  };

  for (var session in todaysSessions) {
    progress[session.subject] =
        (progress[session.subject] ?? Duration.zero) + session.duration;
  }
  return progress;
});

final dailySummaryProvider =
    Provider<Map<DateTime, Map<Subject, Duration>>>((ref) {
  final allSessions = ref.watch(sessionProvider);
  final Map<DateTime, Map<Subject, Duration>> summary = {};

  for (var session in allSessions) {
    final day = DateTime(
        session.endTime.year, session.endTime.month, session.endTime.day);

    if (summary[day] == null) {
      summary[day] = {};
    }
    final currentDuration = summary[day]![session.subject] ?? Duration.zero;
    summary[day]![session.subject] = currentDuration + session.duration;
  }
  return summary;
});

// --- PROVIDERS FOR NEW FEATURES ---

final sessionsForReviewProvider = Provider<List<StudySession>>((ref) {
  final allSessions = ref.watch(sessionProvider);
  return allSessions.where((s) => s.isForReview).toList();
});

final qaTagStatsProvider =
    Provider<Map<String, ({int correct, int total})>>((ref) {
  final qaSession = ref.watch(qaSessionsProvider);
  final Map<String, ({int correct, int total})> tagStats = {};

  for (final session in qaSession) {
    for (final tag in session.tags) {
      final currentCorrect = tagStats[tag]?.correct ?? 0;
      final currentTotal = tagStats[tag]?.total ?? 0;
      tagStats[tag] = (
        correct: currentCorrect + session.qaTotalCorrect,
        total: currentTotal + session.qaTotalAttempted
      );
    }
  }
  return tagStats;
});

// --- THIS IS THE PROVIDER FOR THE WEEKLY GRAPH ---
final activityHeatmapProvider = Provider<Map<int, List<StudySession>>>((ref) {
  final allSessions = ref.watch(sessionProvider);
  final recentSessions = allSessions.where((s) =>
      s.startTime.isAfter(DateTime.now().subtract(const Duration(days: 30))));

  final Map<int, List<StudySession>> groupedByDay = {};
  for (final session in recentSessions) {
    final dayKey = session.startTime.weekday; // Monday=1, Sunday=7
    if (groupedByDay[dayKey] == null) {
      groupedByDay[dayKey] = [];
    }
    groupedByDay[dayKey]!.add(session);
  }
  return groupedByDay;
});

// --- THIS IS THE PROVIDER FOR THE DAILY GRAPH ---
final dailyActivityProvider =
    Provider.family<DailyActivity, DateTime>((ref, day) {
  final allSessions = ref.watch(sessionProvider);
  final targetDay = DateTime(day.year, day.month, day.day);

  final sessionsOnDay = allSessions.where((s) {
    final sessionDay =
        DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
    return sessionDay.isAtSameMomentAs(targetDay);
  }).toList();

  final totalDuration = sessionsOnDay.fold(
      Duration.zero, (prev, session) => prev + session.duration);

  final sessionsBySubject = <Subject, Duration>{};
  for (var session in sessionsOnDay) {
    sessionsBySubject[session.subject] =
        (sessionsBySubject[session.subject] ?? Duration.zero) +
            session.duration;
  }

  final hourlyBreakdown = List.filled(24, 0.0);
  for (final session in sessionsOnDay) {
    for (int hour = 0; hour < 24; hour++) {
      final hourStart =
          DateTime(targetDay.year, targetDay.month, targetDay.day, hour);
      final hourEnd = hourStart.add(const Duration(hours: 1));

      final overlapStart =
          session.startTime.isAfter(hourStart) ? session.startTime : hourStart;
      final overlapEnd =
          session.endTime.isBefore(hourEnd) ? session.endTime : hourEnd;

      if (overlapStart.isBefore(overlapEnd)) {
        final overlapDuration = overlapEnd.difference(overlapStart);
        hourlyBreakdown[hour] += overlapDuration.inMinutes;
      }
    }
  }

  return (
    totalDuration: totalDuration,
    hourlyBreakdown: hourlyBreakdown,
    sessionsBySubject: sessionsBySubject,
  );
});
