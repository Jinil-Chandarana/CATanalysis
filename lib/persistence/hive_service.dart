import 'package:hive_flutter/hive_flutter.dart';
import 'package:catalyst_app/models/study_session.dart';
import 'duration_adapter.dart';

class HiveService {
  static const String sessionBoxName = 'study_sessions';

  // Call this method in main.dart to initialize Hive
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(SubjectAdapter());
    Hive.registerAdapter(StudySessionAdapter());
    Hive.registerAdapter(DurationAdapter());
    await Hive.openBox<StudySession>(sessionBoxName);
  }

  // This is a "getter" for the box, ensuring we always use the correct name.
  Box<StudySession> get _sessionBox => Hive.box<StudySession>(sessionBoxName);

  List<StudySession> getAllSessions() {
    // Sort sessions by date, newest first
    // --- THIS IS THE CORRECTED LINE ---
    final sessions = _sessionBox.values.toList();
    sessions.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return sessions;
  }

  Future<void> addSession(StudySession session) async {
    // Using the getter to prevent future typos
    await _sessionBox.put(session.id, session);
  }

  Future<void> deleteSession(String id) async {
    // Using the getter to prevent future typos
    await _sessionBox.delete(id);
  }
}
