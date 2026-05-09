class ExamResultModel {
  final String id;
  final String subjectId;
  final String subjectName;
  final int correctCount;
  final int totalCount;
  final int elapsedSeconds;
  final DateTime completedAt;
  final Map<String, String> selectedAnswers; // questionId -> answer

  ExamResultModel({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.correctCount,
    required this.totalCount,
    required this.elapsedSeconds,
    required this.completedAt,
    required this.selectedAnswers,
  });

  double get scorePercent =>
      totalCount > 0 ? (correctCount / totalCount * 100) : 0;
  int get wrongCount => totalCount - correctCount;

  String get grade {
    if (scorePercent >= 90) return 'Excellent';
    if (scorePercent >= 75) return 'Very Good';
    if (scorePercent >= 60) return 'Good';
    return 'Needs Improvement';
  }

  String get gradeAr {
    if (scorePercent >= 90) return 'ممتاز';
    if (scorePercent >= 75) return 'جيد جداً';
    if (scorePercent >= 60) return 'جيد';
    return 'يحتاج تحسين';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'correctCount': correctCount,
      'totalCount': totalCount,
      'elapsedSeconds': elapsedSeconds,
      'completedAt': completedAt.toIso8601String(),
      'selectedAnswers': selectedAnswers.entries
          .map((e) => '${e.key}:${e.value}')
          .join('||'),
    };
  }

  factory ExamResultModel.fromMap(Map<String, dynamic> map) {
    final answersStr = map['selectedAnswers'] as String? ?? '';
    final answers = <String, String>{};
    if (answersStr.isNotEmpty) {
      for (final entry in answersStr.split('||')) {
        final parts = entry.split(':');
        if (parts.length >= 2) {
          answers[parts[0]] = parts.sublist(1).join(':');
        }
      }
    }
    return ExamResultModel(
      id: map['id'] as String,
      subjectId: map['subjectId'] as String,
      subjectName: map['subjectName'] as String? ?? '',
      correctCount: map['correctCount'] as int,
      totalCount: map['totalCount'] as int,
      elapsedSeconds: map['elapsedSeconds'] as int? ?? 0,
      completedAt:
          DateTime.tryParse(map['completedAt'] as String? ?? '') ??
          DateTime.now(),
      selectedAnswers: answers,
    );
  }
}
