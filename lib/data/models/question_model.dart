class QuestionModel {
  final String id;
  final String subjectId;
  final String subjectName;
  final String type; // 'mcq' or 'true_false'
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String difficulty; // 'easy', 'medium', 'hard'
  final String category;
  final List<String> tags;
  final DateTime createdAt;

  QuestionModel({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.type,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.difficulty = 'medium',
    this.category = '',
    this.tags = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'type': type,
      'question': question,
      'options': options.join('||'),
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'difficulty': difficulty,
      'category': category,
      'tags': tags.join(','),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      id: map['id'] as String,
      subjectId: map['subjectId'] as String? ?? '',
      subjectName: map['subjectName'] as String? ?? '',
      type: map['type'] as String? ?? 'mcq',
      question: map['question'] as String,
      options: (map['options'] as String? ?? '')
          .split('||')
          .where((e) => e.isNotEmpty)
          .toList(),
      correctAnswer: map['correctAnswer'] as String,
      explanation: map['explanation'] as String? ?? '',
      difficulty: map['difficulty'] as String? ?? 'medium',
      category: map['category'] as String? ?? '',
      tags: (map['tags'] as String? ?? '')
          .split(',')
          .where((e) => e.isNotEmpty)
          .toList(),
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  factory QuestionModel.fromJson(Map<String, dynamic> json, String subjectId) {
    final type = json['type'] as String? ?? 'mcq';
    List<String> options;
    String correctAnswer;

    if (type == 'true_false') {
      options = ['صح', 'خطأ'];
      final ca = json['correctAnswer'];
      if (ca is bool) {
        correctAnswer = ca ? 'صح' : 'خطأ';
      } else {
        correctAnswer = ca.toString();
      }
    } else {
      options =
          (json['options'] as List?)?.map((e) => e.toString()).toList() ?? [];
      correctAnswer = json['correctAnswer']?.toString() ?? '';
    }

    return QuestionModel(
      id:
          json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      subjectId: subjectId,
      subjectName: json['subject']?.toString() ?? '',
      type: type,
      question: json['question']?.toString() ?? '',
      options: options,
      correctAnswer: correctAnswer,
      explanation: json['explanation']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? 'medium',
      category: json['category']?.toString() ?? '',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  QuestionModel copyWith({
    String? id,
    String? subjectId,
    String? subjectName,
    String? type,
    String? question,
    List<String>? options,
    String? correctAnswer,
    String? explanation,
    String? difficulty,
    String? category,
    List<String>? tags,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      type: type ?? this.type,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      createdAt: createdAt,
    );
  }
}
