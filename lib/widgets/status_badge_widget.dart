import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum BadgeStatus {
  excellent,
  veryGood,
  good,
  needsImprovement,
  active,
  completed,
  pending,
  warning,
}

class StatusBadgeWidget extends StatelessWidget {
  final BadgeStatus status;
  final String? label;
  final double fontSize;

  const StatusBadgeWidget({
    super.key,
    required this.status,
    this.label,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: config.border, width: 1),
      ),
      child: Text(
        label ?? config.label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: config.text,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  _BadgeConfig _getConfig(BadgeStatus s) {
    switch (s) {
      case BadgeStatus.excellent:
        return _BadgeConfig(
          bg: AppTheme.success.withAlpha(38),
          border: AppTheme.success.withAlpha(102),
          text: AppTheme.success,
          label: 'Excellent',
        );
      case BadgeStatus.veryGood:
        return _BadgeConfig(
          bg: AppTheme.accent.withAlpha(38),
          border: AppTheme.accent.withAlpha(102),
          text: AppTheme.accent,
          label: 'Very Good',
        );
      case BadgeStatus.good:
        return _BadgeConfig(
          bg: AppTheme.info.withAlpha(38),
          border: AppTheme.info.withAlpha(102),
          text: AppTheme.info,
          label: 'Good',
        );
      case BadgeStatus.needsImprovement:
        return _BadgeConfig(
          bg: AppTheme.warning.withAlpha(38),
          border: AppTheme.warning.withAlpha(102),
          text: AppTheme.warning,
          label: 'Needs Improvement',
        );
      case BadgeStatus.active:
        return _BadgeConfig(
          bg: AppTheme.accent.withAlpha(38),
          border: AppTheme.accent.withAlpha(102),
          text: AppTheme.accent,
          label: 'Active',
        );
      case BadgeStatus.completed:
        return _BadgeConfig(
          bg: AppTheme.success.withAlpha(38),
          border: AppTheme.success.withAlpha(102),
          text: AppTheme.success,
          label: 'Completed',
        );
      case BadgeStatus.pending:
        return _BadgeConfig(
          bg: Colors.white.withAlpha(20),
          border: Colors.white.withAlpha(51),
          text: Colors.white60,
          label: 'Pending',
        );
      case BadgeStatus.warning:
        return _BadgeConfig(
          bg: AppTheme.warning.withAlpha(38),
          border: AppTheme.warning.withAlpha(102),
          text: AppTheme.warning,
          label: 'Warning',
        );
    }
  }
}

class _BadgeConfig {
  final Color bg;
  final Color border;
  final Color text;
  final String label;
  const _BadgeConfig({
    required this.bg,
    required this.border,
    required this.text,
    required this.label,
  });
}
