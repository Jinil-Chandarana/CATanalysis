import 'package:hive/hive.dart';

part 'study_session.g.dart';

@HiveType(typeId: 0)
enum Subject {
  @HiveField(0)
  varc,
  @HiveField(1)
  lrdi,
  @HiveField(2)
  qa,
}

extension SubjectExtension on Subject {
  String get name {
    switch (this) {
      case Subject.varc:
        return 'VARC';
      case Subject.lrdi:
        return 'LRDI';
      case Subject.qa:
        return 'QA';
    }
  }
}

// NEW ENUM FOR DIFFICULTY
enum Difficulty { easy, medium, hard }

extension DifficultyExtension on Difficulty {
  String get name {
    switch (this) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
    }
  }
}

@HiveType(typeId: 1)
class StudySession extends HiveObject {
  @HiveField(0)
  late String id;
  @HiveField(1)
  late Subject subject;
  @HiveField(2)
  late DateTime startTime;
  @HiveField(3)
  late DateTime endTime;
  @HiveField(4)
  late Duration duration;
  @HiveField(5)
  late Map<String, dynamic> metrics;

  StudySession({
    required this.id,
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.metrics,
  });

  // --- NEW: GETTERS FOR NEW FEATURES ---
  String? get notes => metrics['notes'] as String?;
  bool get isForReview => (metrics['is_for_review'] ?? false) as bool;
  List<String> get tags => (metrics['tags'] as List?)?.cast<String>() ?? [];

  // --- GETTERS FOR VARC ---
  List<Map> get _rcSets => (metrics['rc_sets'] as List?)?.cast<Map>() ?? [];
  int get rcTotalAttempted =>
      _rcSets.fold(0, (prev, set) => prev + ((set['questions'] ?? 0) as int));
  int get rcTotalCorrect =>
      _rcSets.fold(0, (prev, set) => prev + ((set['correct'] ?? 0) as int));
  double get rcAccuracy =>
      rcTotalAttempted > 0 ? rcTotalCorrect / rcTotalAttempted : 0.0;
  double get rcTimePerQuestion =>
      rcTotalAttempted > 0 ? duration.inSeconds / rcTotalAttempted : 0.0;

  int get vaTotalAttempted => (metrics['va_attempted'] ?? 0) as int;
  int get vaTotalCorrect => (metrics['va_correct'] ?? 0) as int;
  double get vaAccuracy =>
      vaTotalAttempted > 0 ? vaTotalCorrect / vaTotalAttempted : 0.0;

  // --- GETTERS FOR LRDI ---
  List<Map> get _lrdiSets => (metrics['lrdi_sets'] as List?)?.cast<Map>() ?? [];
  List<Map> get _lrdiSoloSets =>
      _lrdiSets.where((set) => (set['is_solo'] ?? false) as bool).toList();
  int get lrdiSetsAttempted => _lrdiSets.length;
  int get lrdiSetsSolo => _lrdiSoloSets.length;
  int get lrdiSoloTotalAttempted => _lrdiSoloSets.fold(
      0, (prev, set) => prev + ((set['questions'] ?? 0) as int));
  int get lrdiSoloTotalCorrect => _lrdiSoloSets.fold(
      0, (prev, set) => prev + ((set['correct'] ?? 0) as int));
  double get lrdiSoloAccuracy => lrdiSoloTotalAttempted > 0
      ? lrdiSoloTotalCorrect / lrdiSoloTotalAttempted
      : 0.0;
  double get lrdiTimePerSet =>
      lrdiSetsAttempted > 0 ? duration.inMinutes / lrdiSetsAttempted : 0.0;

  // --- GETTERS FOR QA ---
  int get qaTotalAttempted => (metrics['questionsAttempted'] ?? 0) as int;
  int get qaTotalCorrect => (metrics['questionsCorrect'] ?? 0) as int;
  double get qaAccuracy =>
      qaTotalAttempted > 0 ? qaTotalCorrect / qaTotalAttempted : 0.0;
  double get qaTimePerQuestion =>
      qaTotalAttempted > 0 ? duration.inSeconds / qaTotalAttempted : 0.0;
}
