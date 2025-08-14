import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catalyst_app/models/study_session.dart';
import 'package:catalyst_app/persistence/hive_service.dart';

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

// 3. Derived providers for easy filtering and data aggregation on the UI

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

// Provider for "Today's Progress" on the dashboard
final todaysProgressProvider = Provider<Map<Subject, Duration>>((ref) {
  final allSessions = ref.watch(sessionProvider);
  final today = DateTime.now();
  final todaysSessions = allSessions.where((s) =>
      s.dateTime.year == today.year &&
      s.dateTime.month == today.month &&
      s.dateTime.day == today.day);

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

// --- THIS IS THE UPGRADED PROVIDER ---
// It now returns a map where the value is another map of subject-specific durations.
final dailySummaryProvider =
    Provider<Map<DateTime, Map<Subject, Duration>>>((ref) {
  final allSessions = ref.watch(sessionProvider);
  final Map<DateTime, Map<Subject, Duration>> summary = {};

  for (var session in allSessions) {
    // Normalize DateTime to midnight to group by day
    final day = DateTime(
        session.dateTime.year, session.dateTime.month, session.dateTime.day);

    // Ensure the inner map for the day exists
    if (summary[day] == null) {
      summary[day] = {};
    }

    // Add the session's duration to the specific subject for that day
    final currentDuration = summary[day]![session.subject] ?? Duration.zero;
    summary[day]![session.subject] = currentDuration + session.duration;
  }

  return summary;
});
