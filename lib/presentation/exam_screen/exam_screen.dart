import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../data/models/exam_result_model.dart';
import '../../data/models/question_model.dart';
import '../../data/models/subject_model.dart';
import '../../data/services/local_database.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> with TickerProviderStateMixin {
  SubjectModel? _subject;
  List<QuestionModel> _questions = [];
  int _currentIndex = 0;
  final Map<int, String> _selectedAnswers = {};
  bool _loaded = false;
  int _elapsedSeconds = 0;
  Timer? _timer;
  late AnimationController _questionAnim;
  late Animation<double> _questionFade;
  late Animation<Offset> _questionSlide;

  @override
  void initState() {
    super.initState();
    _questionAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _questionFade = CurvedAnimation(
      parent: _questionAnim,
      curve: Curves.easeOut,
    );
    _questionSlide = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _questionAnim, curve: Curves.easeOut));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _subject = args['subject'] as SubjectModel?;
        final count = args['questionCount'] as int? ?? 10;
        if (_subject != null) {
          final all = LocalDatabase.instance.getQuestionsBySubject(
            _subject!.id,
          );
          all.shuffle();
          _questions = all.take(count).toList();
          // Shuffle options for MCQ
          for (int i = 0; i < _questions.length; i++) {
            if (_questions[i].type == 'mcq') {
              final opts = List<String>.from(_questions[i].options)..shuffle();
              _questions[i] = _questions[i].copyWith(options: opts);
            }
          }
        }
        _loaded = true;
        _questionAnim.forward();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _questionAnim.dispose();
    super.dispose();
  }

  QuestionModel get _current => _questions[_currentIndex];
  bool get _isAnswered => _selectedAnswers.containsKey(_currentIndex);

  void _selectAnswer(String answer) {
    if (_isAnswered) return;
    setState(() => _selectedAnswers[_currentIndex] = answer);
  }

  void _goNext() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
      _questionAnim.reset();
      _questionAnim.forward();
    } else {
      _finishExam();
    }
  }

  void _goPrev() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _questionAnim.reset();
      _questionAnim.forward();
    }
  }

  void _finishExam() {
    _timer?.cancel();
    int correct = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_selectedAnswers[i] == _questions[i].correctAnswer) correct++;
    }

    // Save result
    final result = ExamResultModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      subjectId: _subject?.id ?? '',
      subjectName: _subject?.name ?? '',
      correctCount: correct,
      totalCount: _questions.length,
      elapsedSeconds: _elapsedSeconds,
      completedAt: DateTime.now(),
      selectedAnswers: _selectedAnswers.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
    );
    LocalDatabase.instance.saveResult(result);

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.resultsScreen,
      arguments: {
        'subject': _subject?.toMap() ?? {},
        'questions': _questions.map((q) => q.toMap()).toList(),
        'selectedAnswers': _selectedAnswers,
        'correctCount': correct,
        'totalCount': _questions.length,
        'elapsedSeconds': _elapsedSeconds,
      },
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.accent),
              const SizedBox(height: 16),
              const Text(
                'لا توجد أسئلة في هذه المادة',
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'رجوع',
                  style: TextStyle(color: AppTheme.accent),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final progress = (_currentIndex + 1) / _questions.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Stack(
          children: [
            _buildBg(),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(progress),
                  Expanded(
                    child: SlideTransition(
                      position: _questionSlide,
                      child: FadeTransition(
                        opacity: _questionFade,
                        child: _buildQuestionArea(),
                      ),
                    ),
                  ),
                  _buildNavBar(),
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF060B18), Color(0xFF0A0E1A)],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _showExitDialog(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.glassSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _subject?.name ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'سؤال ${_currentIndex + 1} من ${_questions.length}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.glassSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 13,
                      color: AppTheme.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(_elapsedSeconds),
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.glassSurface,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionArea() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question type badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _current.type == 'mcq'
                      ? AppTheme.primary.withAlpha(60)
                      : AppTheme.success.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _current.type == 'mcq'
                        ? AppTheme.primaryLight.withAlpha(80)
                        : AppTheme.success.withAlpha(80),
                  ),
                ),
                child: Text(
                  _current.type == 'mcq' ? 'اختيار متعدد' : 'صح / خطأ',
                  style: TextStyle(
                    color: _current.type == 'mcq'
                        ? AppTheme.primaryLight
                        : AppTheme.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.glassSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _current.difficulty == 'easy'
                      ? 'سهل'
                      : _current.difficulty == 'hard'
                      ? 'صعب'
                      : 'متوسط',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Question text
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.glassSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: Text(
                  _current.question,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Options
          ..._current.options.asMap().entries.map((entry) {
            final idx = entry.key;
            final opt = entry.value;
            final isSelected = _selectedAnswers[_currentIndex] == opt;
            final isCorrect = _isAnswered && opt == _current.correctAnswer;
            final isWrong =
                _isAnswered && isSelected && opt != _current.correctAnswer;

            Color borderColor = AppTheme.glassBorder;
            Color bgColor = AppTheme.glassSurface;
            Color textColor = Colors.white70;
            IconData? trailingIcon;

            if (isCorrect) {
              borderColor = AppTheme.success;
              bgColor = AppTheme.success.withAlpha(25);
              textColor = AppTheme.success;
              trailingIcon = Icons.check_circle;
            } else if (isWrong) {
              borderColor = AppTheme.error;
              bgColor = AppTheme.error.withAlpha(25);
              textColor = AppTheme.error;
              trailingIcon = Icons.cancel;
            } else if (isSelected) {
              borderColor = AppTheme.accent;
              bgColor = AppTheme.accent.withAlpha(25);
              textColor = AppTheme.accent;
            }

            return GestureDetector(
              onTap: () => _selectAnswer(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected || isCorrect
                            ? borderColor.withAlpha(40)
                            : AppTheme.glassSurface,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + idx),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        opt,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 8),
                      Icon(trailingIcon, color: textColor, size: 18),
                    ],
                  ],
                ),
              ),
            );
          }),
          // Explanation
          if (_isAnswered && _current.explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.info.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.info.withAlpha(60)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: AppTheme.info,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _current.explanation,
                      style: const TextStyle(
                        color: AppTheme.info,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavBar() {
    final isLast = _currentIndex == _questions.length - 1;
    final answeredCount = _selectedAnswers.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.glassBorder)),
      ),
      child: Row(
        children: [
          // Prev
          GestureDetector(
            onTap: _currentIndex > 0 ? _goPrev : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _currentIndex > 0
                    ? AppTheme.glassSurface
                    : AppTheme.glassSurface.withAlpha(80),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: _currentIndex > 0 ? Colors.white70 : Colors.white24,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Progress dots
          Expanded(
            child: Column(
              children: [
                Text(
                  '$answeredCount / ${_questions.length} أجبت',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _questions.isEmpty
                        ? 0
                        : answeredCount / _questions.length,
                    backgroundColor: AppTheme.glassSurface,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.success,
                    ),
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Next / Finish
          GestureDetector(
            onTap: _goNext,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryLight],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(80),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    isLast ? 'إنهاء' : 'التالي',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isLast ? Icons.check_circle_outline : Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariantDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'إنهاء الاختبار؟',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'هل تريد إنهاء الاختبار والخروج؟',
          style: TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'متابعة',
              style: TextStyle(color: AppTheme.accent),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _timer?.cancel();
              Navigator.pop(context);
            },
            child: const Text('خروج', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}
