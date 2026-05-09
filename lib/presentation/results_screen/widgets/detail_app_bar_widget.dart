import 'package:flutter/material.dart';

// Kept for compatibility - main logic moved to results_screen.dart
class DetailAppBarWidget extends StatelessWidget {
  final VoidCallback? onBack;
  const DetailAppBarWidget({super.key, this.onBack});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
