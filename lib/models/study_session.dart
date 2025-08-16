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

  // --- GETTERS FOR VARC ---
  List<Map> get _rcSets => (metrics['rc_sets'] as List?)?.cast<Map>() ?? [];
  int get rcTotalAttempted =>
      _rcSets.fold(0, (prev, set) => prev + ((set['questions'] ?? 0) as int));
  int get rcTotalCorrect =>
      _rcSets.fold(0, (prev, set) => prev + ((set['correct'] ?? 0) as int));
  double get rcAccuracy =>
      rcTotalAttempted > 0 ? rcTotalCorrect / rcTotalAttempted : 0.0;

  int get vaTotalAttempted => (metrics['va_attempted'] ?? 0) as int;
  int get vaTotalCorrect => (metrics['va_correct'] ?? 0) as int;
  double get vaAccuracy =>
      vaTotalAttempted > 0 ? vaTotalCorrect / vaTotalAttempted : 0.0;

  // --- NEW: Time-based metrics for VARC ---
  double get rcTimePerQuestion =>
      rcTotalAttempted > 0 ? duration.inSeconds / rcTotalAttempted : 0.0;

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

  // --- NEW: Time-based metrics for LRDI ---
  double get lrdiTimePerSet =>
      lrdiSetsAttempted > 0 ? duration.inMinutes / lrdiSetsAttempted : 0.0;

  // --- GETTERS FOR QA ---
  int get qaTotalAttempted => (metrics['questionsAttempted'] ?? 0) as int;
  int get qaTotalCorrect => (metrics['questionsCorrect'] ?? 0) as int;
  double get qaAccuracy =>
      qaTotalAttempted > 0 ? qaTotalCorrect / qaTotalAttempted : 0.0;

  // --- NEW: Time-based metrics for QA ---
  double get qaTimePerQuestion =>
      qaTotalAttempted > 0 ? duration.inSeconds / qaTotalAttempted : 0.0;
}
