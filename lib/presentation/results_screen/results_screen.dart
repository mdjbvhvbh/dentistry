import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../data/models/question_model.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic> _data = {};
  bool _loaded = false;
  late AnimationController _scoreAnim;
  late AnimationController _contentAnim;
  late Animation<double> _scoreProgress;
  late Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _scoreAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _contentAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scoreProgress = CurvedAnimation(
      parent: _scoreAnim,
      curve: Curves.easeOutCubic,
    );
    _contentFade = CurvedAnimation(parent: _contentAnim, curve: Curves.easeOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _data = args;
        _loaded = true;
        Future.delayed(const Duration(milliseconds: 200), () {
          _scoreAnim.forward();
          Future.delayed(
            const Duration(milliseconds: 600),
            () => _contentAnim.forward(),
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _scoreAnim.dispose();
    _contentAnim.dispose();
    super.dispose();
  }

  int get _correct => _data['correctCount'] as int? ?? 0;
  int get _total => _data['totalCount'] as int? ?? 1;
  int get _elapsed => _data['elapsedSeconds'] as int? ?? 0;
  double get _percent => _total > 0 ? (_correct / _total * 100) : 0;
  int get _wrong => _total - _correct;

  String get _grade {
    if (_percent >= 90) return 'Excellent';
    if (_percent >= 75) return 'Very Good';
    if (_percent >= 60) return 'Good';
    return 'Needs Improvement';
  }

  String get _gradeAr {
    if (_percent >= 90) return 'ممتاز';
    if (_percent >= 75) return 'جيد جداً';
    if (_percent >= 60) return 'جيد';
    return 'يحتاج تحسين';
  }

  Color get _gradeColor {
    if (_percent >= 90) return AppTheme.success;
    if (_percent >= 75) return AppTheme.accent;
    if (_percent >= 60) return AppTheme.info;
    return AppTheme.warning;
  }

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '$mد $secث';
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }

    final subject = _data['subject'] as Map<String, dynamic>? ?? {};
    final rawQuestions =
        (_data['questions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final questions = rawQuestions
        .map((q) => QuestionModel.fromMap(q))
        .toList();
    final selectedAnswers =
        (_data['selectedAnswers'] as Map?)?.map(
          (k, v) => MapEntry(k as int, v as String),
        ) ??
        {};

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Stack(
          children: [
            _buildBg(),
            SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildTopBar(subject)),
                  SliverToBoxAdapter(child: _buildScoreRing()),
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _contentFade,
                      child: _buildStatsRow(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _contentFade,
                      child: _buildGradeCard(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _contentFade,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            const Text(
                              'مراجعة الأسئلة',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${questions.length} سؤال',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => FadeTransition(
                        opacity: _contentFade,
                        child: _QuestionReviewCard(
                          question: questions[i],
                          selectedAnswer: selectedAnswers[i],
                          index: i,
                        ),
                      ),
                      childCount: questions.length,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _contentFade,
                      child: _buildActions(),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBg() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_gradeColor.withAlpha(20), const Color(0xFF0A0E1A)],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(Map<String, dynamic> subject) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.homeScreen,
              (_) => false,
            ),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.glassSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: const Icon(
                Icons.home_outlined,
                color: Colors.white70,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              subject['name'] as String? ?? 'النتائج',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRing() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: AnimatedBuilder(
          animation: _scoreProgress,
          builder: (_, __) {
            final animatedPercent = _percent * _scoreProgress.value;
            return Column(
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CustomPaint(
                    painter: _ScoreRingPainter(
                      progress: _scoreProgress.value * (_percent / 100),
                      color: _gradeColor,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${animatedPercent.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: _gradeColor,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '$_correct / $_total',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _gradeAr,
                  style: TextStyle(
                    color: _gradeColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _grade,
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatBox(
              label: 'صحيح',
              value: '$_correct',
              color: AppTheme.success,
              icon: Icons.check_circle_outline,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatBox(
              label: 'خطأ',
              value: '$_wrong',
              color: AppTheme.error,
              icon: Icons.cancel_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatBox(
              label: 'الوقت',
              value: _formatTime(_elapsed),
              color: AppTheme.accent,
              icon: Icons.timer_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _gradeColor.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _gradeColor.withAlpha(60)),
            ),
            child: Row(
              children: [
                Icon(_gradeIcon(), color: _gradeColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _gradeAr,
                        style: TextStyle(
                          color: _gradeColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _gradeMessage(),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _gradeIcon() {
    if (_percent >= 90) return Icons.emoji_events;
    if (_percent >= 75) return Icons.star;
    if (_percent >= 60) return Icons.thumb_up;
    return Icons.trending_up;
  }

  String _gradeMessage() {
    if (_percent >= 90) return 'أداء رائع! استمر في التميز';
    if (_percent >= 75) return 'أداء جيد جداً، أنت على المسار الصحيح';
    if (_percent >= 60) return 'أداء جيد، يمكنك التحسين أكثر';
    return 'راجع المادة وحاول مرة أخرى';
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.homeScreen,
                (_) => false,
              ),
              icon: const Icon(Icons.home_outlined, size: 18),
              label: const Text('الرئيسية'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: AppTheme.glassBorder),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.replay, size: 18),
              label: const Text('إعادة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(50)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionReviewCard extends StatefulWidget {
  final QuestionModel question;
  final String? selectedAnswer;
  final int index;
  const _QuestionReviewCard({
    required this.question,
    required this.selectedAnswer,
    required this.index,
  });

  @override
  State<_QuestionReviewCard> createState() => _QuestionReviewCardState();
}

class _QuestionReviewCardState extends State<_QuestionReviewCard> {
  bool _expanded = false;

  bool get _isCorrect => widget.selectedAnswer == widget.question.correctAnswer;
  bool get _isSkipped => widget.selectedAnswer == null;

  @override
  Widget build(BuildContext context) {
    final color = _isSkipped
        ? Colors.white38
        : (_isCorrect ? AppTheme.success : AppTheme.error);
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index + 1}',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.question.question,
                      maxLines: _expanded ? null : 2,
                      overflow: _expanded ? null : TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isSkipped
                        ? Icons.remove_circle_outline
                        : (_isCorrect ? Icons.check_circle : Icons.cancel),
                    color: color,
                    size: 18,
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.selectedAnswer != null && !_isCorrect) ...[
                      _AnswerRow(
                        label: 'إجابتك',
                        value: widget.selectedAnswer!,
                        color: AppTheme.error,
                      ),
                      const SizedBox(height: 6),
                    ],
                    _AnswerRow(
                      label: 'الإجابة الصحيحة',
                      value: widget.question.correctAnswer,
                      color: AppTheme.success,
                    ),
                    if (widget.question.explanation.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.info.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.question.explanation,
                          style: const TextStyle(
                            color: AppTheme.info,
                            fontSize: 12,
                            height: 1.4,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _AnswerRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(color: color.withAlpha(180), fontSize: 12),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
      ],
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _ScoreRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;
    final strokeWidth = 10.0;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white12
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) => old.progress != progress;
}
