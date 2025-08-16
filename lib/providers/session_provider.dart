import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catalyst_app/models/study_session.dart';
import 'package:catalyst_app/persistence/hive_service.dart';

typedef DailyActivity = ({
  Duration totalDuration,
  List<double> hourlyBreakdown,
  Map<Subject, Duration> sessionsBySubject,
});

final hiveServiceProvider = Provider<HiveService>((ref) => HiveService());

final sessionProvider =
    StateNotifierProvider<SessionNotifier, List<StudySession>>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return SessionNotifier(hiveService);
});

class SessionNotifier extends StateNotifier<List<StudySession>> {
  final HiveService _hiveService;

  SessionNotifier(this._hiveService) : super([]) {
    loadSessions();
  }

  void loadSessions() {
    state = _hiveService.getAllSessions();
  }

  Future<void> addSession(StudySession session) async {
    await _hiveService.addSession(session);
    loadSessions();
  }

  Future<void> deleteSession(String id) async {
    await _hiveService.deleteSession(id);
    loadSessions();
  }
}

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

// New Provider for Misc Sessions
final miscSessionsProvider = Provider<List<StudySession>>((ref) {
  final allSessions = ref.watch(sessionProvider);
  return allSessions.where((s) => s.subject == Subject.misc).toList();
});

final todaysProgressProvider = Provider<Map<Subject, Duration>>((ref) {
  final allSessions = ref.watch(sessionProvider);
  final today = DateTime.now();
  final todaysSessions = allSessions.where((s) =>
      s.endTime.year == today.year &&
      s.endTime.month == today.month &&
      s.endTime.day == today.day);

  // Updated to include Misc
  final progress = {
    Subject.varc: Duration.zero,
    Subject.lrdi: Duration.zero,
    Subject.qa: Duration.zero,
    Subject.misc: Duration.zero,
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

// New Provider to analyze Misc tasks
final miscTaskStatsProvider = Provider<Map<String, Duration>>((ref) {
  final miscSessions = ref.watch(miscSessionsProvider);
  final Map<String, Duration> taskStats = {};

  for (final session in miscSessions) {
    final taskName = session.taskName;
    if (taskName != null && taskName.isNotEmpty) {
      taskStats[taskName] =
          (taskStats[taskName] ?? Duration.zero) + session.duration;
    }
  }
  return taskStats;
});

final activityHeatmapProvider = Provider<Map<int, List<StudySession>>>((ref) {
  final allSessions = ref.watch(sessionProvider);
  final recentSessions = allSessions.where((s) =>
      s.startTime.isAfter(DateTime.now().subtract(const Duration(days: 30))));

  final Map<int, List<StudySession>> groupedByDay = {};
  for (final session in recentSessions) {
    final dayKey = session.startTime.weekday;
    if (groupedByDay[dayKey] == null) {
      groupedByDay[dayKey] = [];
    }
    groupedByDay[dayKey]!.add(session);
  }
  return groupedByDay;
});

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
