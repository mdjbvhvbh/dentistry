import 'package:flutter/material.dart';

// Kept for compatibility - main logic moved to home_screen.dart
class HomeAppBarWidget extends StatelessWidget {
  final String studentName;
  final VoidCallback? onAnalytics;
  const HomeAppBarWidget({
    super.key,
    this.studentName = 'الطالب',
    this.onAnalytics,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
