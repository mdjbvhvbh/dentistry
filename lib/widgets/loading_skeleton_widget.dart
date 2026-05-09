import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LoadingSkeletonWidget extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingSkeletonWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<LoadingSkeletonWidget> createState() => _LoadingSkeletonWidgetState();
}

class _LoadingSkeletonWidgetState extends State<LoadingSkeletonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _animation = Tween<double>(
      begin: -0.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
              colors: [
                AppTheme.glassSurface,
                AppTheme.glassSurfaceVariant,
                AppTheme.glassSurface,
              ],
            ),
          ),
        );
      },
    );
  }
}

class SubjectCardSkeletonWidget extends StatelessWidget {
  const SubjectCardSkeletonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppTheme.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const LoadingSkeletonWidget(
                width: 40,
                height: 40,
                borderRadius: 999,
              ),
              const LoadingSkeletonWidget(
                width: 60,
                height: 16,
                borderRadius: 8,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const LoadingSkeletonWidget(width: 80, height: 12, borderRadius: 6),
          const SizedBox(height: 8),
          const LoadingSkeletonWidget(
            width: double.infinity,
            height: 16,
            borderRadius: 8,
          ),
          const SizedBox(height: 6),
          const LoadingSkeletonWidget(width: 160, height: 16, borderRadius: 8),
          const Spacer(),
          Row(
            children: [
              const LoadingSkeletonWidget(
                width: 80,
                height: 24,
                borderRadius: 999,
              ),
              const Spacer(),
              const LoadingSkeletonWidget(
                width: 36,
                height: 36,
                borderRadius: 999,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
