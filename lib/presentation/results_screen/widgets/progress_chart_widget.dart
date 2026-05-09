import 'package:flutter/material.dart';

// Kept for compatibility - main logic moved to results_screen.dart
class ProgressChartWidget extends StatelessWidget {
  final int correctCount;
  final int wrongCount;
  final int totalCount;
  final String subjectName;
  const ProgressChartWidget({
    super.key,
    required this.correctCount,
    required this.wrongCount,
    required this.totalCount,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
