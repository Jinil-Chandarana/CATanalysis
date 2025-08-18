import 'package:hive/hive.dart';

part 'study_session.g.dart';

// (Enums and Extensions are unchanged)
@HiveType(typeId: 0)
enum Subject {
  @HiveField(0)
  varc,
  @HiveField(1)
  lrdi,
  @HiveField(2)
  qa,
  @HiveField(3)
  misc,
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
      case Subject.misc:
        return 'Misc';
    }
  }
}

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
  // (Fields are unchanged)
  @HiveField(0)
  late String id;
  @HiveField(1)
  late Subject subject;
  @HiveField(2)
  late DateTime startTime;
  @HiveField(3)
  late DateTime endTime;
  @HiveField(4)
  late Duration focusDuration;
  @HiveField(5)
  late Map<String, dynamic> metrics;
  @HiveField(6)
  late Duration seatingDuration;

  StudySession({
    required this.id,
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.focusDuration,
    required this.seatingDuration,
    required this.metrics,
  });

  // (Getters for notes, review, etc., are unchanged)
  double get focusPercentage {
    if (seatingDuration.inSeconds == 0) return 0.0;
    return focusDuration.inSeconds / seatingDuration.inSeconds;
  }

  String? get notes => metrics['notes'] as String?;
  bool get isForReview => (metrics['is_for_review'] ?? false) as bool;
  List<String> get tags => (metrics['tags'] as List?)?.cast<String>() ?? [];
  String? get taskName => metrics['task_name'] as String?;

  // --- GETTERS FOR VARC (UPDATED) ---
  List<Map> get _rcSets => (metrics['rc_sets'] as List?)?.cast<Map>() ?? [];
  int get rcTotalAttempted =>
      _rcSets.fold(0, (prev, set) => prev + ((set['questions'] ?? 0) as int));
  int get rcTotalCorrect =>
      _rcSets.fold(0, (prev, set) => prev + ((set['correct'] ?? 0) as int));
  double get rcAccuracy =>
      rcTotalAttempted > 0 ? rcTotalCorrect / rcTotalAttempted : 0.0;
  double get rcTimePerQuestion =>
      rcTotalAttempted > 0 ? focusDuration.inSeconds / rcTotalAttempted : 0.0;

  // --- NEW: Logic to handle multiple VA sets ---
  List<Map> get vaSets => (metrics['va_sets'] as List?)?.cast<Map>() ?? [];
  int get vaTotalAttempted =>
      vaSets.fold(0, (prev, set) => prev + ((set['attempted'] ?? 0) as int));
  int get vaTotalCorrect =>
      vaSets.fold(0, (prev, set) => prev + ((set['correct'] ?? 0) as int));
  double get vaAccuracy =>
      vaTotalAttempted > 0 ? vaTotalCorrect / vaTotalAttempted : 0.0;

  // (Getters for LRDI and QA are unchanged)
  List<Map> get _lrdiSets => (metrics['lrdi_sets'] as List?)?.cast<Map>() ?? [];
  List<Map> get lrdiSoloSets =>
      _lrdiSets.where((set) => (set['is_solo'] ?? false) as bool).toList();
  int get lrdiSetsAttempted => _lrdiSets.length;
  int get lrdiSetsSoloCount => lrdiSoloSets.length;
  int get lrdiSoloTotalAttempted => lrdiSoloSets.fold(
      0, (prev, set) => prev + ((set['questions'] ?? 0) as int));
  int get lrdiSoloTotalCorrect => lrdiSoloSets.fold(
      0, (prev, set) => prev + ((set['correct'] ?? 0) as int));
  double get lrdiSoloAccuracy => lrdiSoloTotalAttempted > 0
      ? lrdiSoloTotalCorrect / lrdiSoloTotalAttempted
      : 0.0;
  double get lrdiTimePerSet =>
      lrdiSetsAttempted > 0 ? focusDuration.inMinutes / lrdiSetsAttempted : 0.0;
  int get qaTotalAttempted => (metrics['questionsAttempted'] ?? 0) as int;
  int get qaTotalCorrect => (metrics['questionsCorrect'] ?? 0) as int;
  double get qaAccuracy =>
      qaTotalAttempted > 0 ? qaTotalCorrect / qaTotalAttempted : 0.0;
  double get qaTimePerQuestion =>
      qaTotalAttempted > 0 ? focusDuration.inSeconds / qaTotalAttempted : 0.0;
}
