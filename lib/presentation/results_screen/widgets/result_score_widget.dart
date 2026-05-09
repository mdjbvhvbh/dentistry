import 'package:flutter/material.dart';

// Kept for compatibility - main logic moved to results_screen.dart
class ResultScoreWidget extends StatelessWidget {
  final double scorePercent;
  final String grade;
  final String gradeAr;
  final String subjectName;
  const ResultScoreWidget({
    super.key,
    required this.scorePercent,
    required this.grade,
    required this.gradeAr,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
