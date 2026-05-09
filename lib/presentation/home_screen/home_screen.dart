import 'dart:ui';

import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../data/models/exam_result_model.dart';
import '../../data/models/subject_model.dart';
import '../../data/services/local_database.dart';
import '../admin_panel/admin_login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedLevel = 1;
  int _selectedSemester = 1;
  bool _dbReady = false;
  String _studentName = 'الطالب';
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _initDb();
  }

  Future<void> _initDb() async {
    await LocalDatabase.instance.init();
    _studentName = LocalDatabase.instance.getStudentName();
    if (mounted) {
      setState(() => _dbReady = true);
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  List<SubjectModel> get _subjects => LocalDatabase.instance
      .getSubjectsByLevelAndSemester(_selectedLevel, _selectedSemester);

  void _onLevelChanged(int level) {
    setState(() {
      _selectedLevel = level;
      _selectedSemester = 1;
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  void _onSemesterChanged(int sem) {
    setState(() => _selectedSemester = sem);
    _fadeController.reset();
    _fadeController.forward();
  }

  void _openSubject(SubjectModel subject) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExamSetupSheet(subject: subject),
    );
  }

  void _openAdminLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
    );
  }

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: _studentName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariantDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تغيير الاسم', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'أدخل اسمك',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: AppTheme.glassSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await LocalDatabase.instance.setStudentName(result);
      setState(() => _studentName = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: !_dbReady
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              )
            : Stack(
                children: [
                  _buildBackground(),
                  SafeArea(
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(
                        children: [
                          _buildHeader(),
                          _buildLevelSelector(),
                          _buildSemesterSelector(),
                          Expanded(child: _buildSubjectGrid()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF060B18), Color(0xFF0A1628), Color(0xFF0A0E1A)],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🦷', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(
                      'Dentistry',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: _editName,
                  child: Row(
                    children: [
                      Text(
                        'مرحباً، $_studentName',
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit, size: 12, color: AppTheme.accent),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Analytics button
          _HeaderIconBtn(
            icon: Icons.bar_chart_rounded,
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.analyticsScreen),
          ),
          const SizedBox(width: 8),
          // Hidden admin button - long press
          GestureDetector(
            onLongPress: _openAdminLogin,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.glassSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: const Icon(
                Icons.person_outline,
                color: Colors.white70,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSelector() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        itemBuilder: (_, i) {
          final level = i + 1;
          final selected = level == _selectedLevel;
          return GestureDetector(
            onTap: () => _onLevelChanged(level),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryLight],
                      )
                    : null,
                color: selected ? null : AppTheme.glassSurface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected
                      ? AppTheme.primaryLight
                      : AppTheme.glassBorder,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(80),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                'المستوى $level',
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white60,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSemesterSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          _SemesterTab(
            label: 'الترم الأول',
            selected: _selectedSemester == 1,
            onTap: () => _onSemesterChanged(1),
          ),
          const SizedBox(width: 10),
          _SemesterTab(
            label: 'الترم الثاني',
            selected: _selectedSemester == 2,
            onTap: () => _onSemesterChanged(2),
          ),
          const Spacer(),
          Text(
            '${_subjects.length} مادة',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectGrid() {
    if (_subjects.isEmpty) {
      return const Center(
        child: Text('لا توجد مواد', style: TextStyle(color: Colors.white38)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _subjects.length,
      itemBuilder: (_, i) {
        final subject = _subjects[i];
        final results = LocalDatabase.instance.getResultsBySubject(subject.id);
        final questionCount = LocalDatabase.instance
            .getQuestionsBySubject(subject.id)
            .length;
        return _SubjectCard(
          subject: subject,
          results: results,
          questionCount: questionCount,
          onTap: () => _openSubject(subject),
        );
      },
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.glassSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }
}

class _SemesterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SemesterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppTheme.accent : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.accent : Colors.white38,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final SubjectModel subject;
  final List<ExamResultModel> results;
  final int questionCount;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.subject,
    required this.results,
    required this.questionCount,
    required this.onTap,
  });

  Color get _cardColor {
    switch (subject.colorKey) {
      case 'blue':
        return const Color(0xFF0D2A5C);
      case 'purple':
        return const Color(0xFF1A0D3D);
      case 'teal':
        return const Color(0xFF062828);
      case 'green':
        return const Color(0xFF062818);
      case 'amber':
        return const Color(0xFF2A1800);
      case 'rose':
        return const Color(0xFF2A0A14);
      default:
        return const Color(0xFF0D2A5C);
    }
  }

  Color get _accentColor {
    switch (subject.colorKey) {
      case 'blue':
        return AppTheme.primaryLight;
      case 'purple':
        return const Color(0xFF9C6FFF);
      case 'teal':
        return AppTheme.accent;
      case 'green':
        return AppTheme.success;
      case 'amber':
        return AppTheme.warning;
      case 'rose':
        return AppTheme.error;
      default:
        return AppTheme.primaryLight;
    }
  }

  double get _bestScore {
    if (results.isEmpty) return 0;
    return results.map((r) => r.scorePercent).reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: _cardColor.withAlpha(200),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _accentColor.withAlpha(50)),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _accentColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_getIcon(), color: _accentColor, size: 18),
                    ),
                    const Spacer(),
                    if (results.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _accentColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_bestScore.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: _accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  subject.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subject.nameAr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.quiz_outlined, size: 11, color: Colors.white38),
                    const SizedBox(width: 3),
                    Text(
                      '$questionCount سؤال',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.play_circle_outline,
                      size: 16,
                      color: _accentColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (subject.icon) {
      case 'menu_book':
        return Icons.menu_book;
      case 'science':
        return Icons.science;
      case 'biotech':
        return Icons.biotech;
      case 'analytics':
        return Icons.analytics;
      case 'psychology':
        return Icons.psychology;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'language':
        return Icons.language;
      case 'translate':
        return Icons.translate;
      case 'auto_stories':
        return Icons.auto_stories;
      case 'computer':
        return Icons.computer;
      case 'chat':
        return Icons.chat;
      case 'coronavirus':
        return Icons.coronavirus;
      case 'monitor_heart':
        return Icons.monitor_heart;
      case 'vaccines':
        return Icons.vaccines;
      case 'healing':
        return Icons.healing;
      case 'gavel':
        return Icons.gavel;
      case 'medical_services':
        return Icons.medical_services;
      case 'build':
        return Icons.build;
      case 'construction':
        return Icons.construction;
      case 'medication':
        return Icons.medication;
      case 'search':
        return Icons.search;
      case 'straighten':
        return Icons.straighten;
      case 'child_care':
        return Icons.child_care;
      case 'shield':
        return Icons.shield;
      case 'radiology':
        return Icons.radio_button_checked;
      default:
        return Icons.menu_book;
    }
  }
}

// ── Exam Setup Bottom Sheet ────────────────────────────────────

class _ExamSetupSheet extends StatefulWidget {
  final SubjectModel subject;
  const _ExamSetupSheet({required this.subject});

  @override
  State<_ExamSetupSheet> createState() => _ExamSetupSheetState();
}

class _ExamSetupSheetState extends State<_ExamSetupSheet> {
  int _questionCount = 10;
  int _maxQuestions = 10;

  @override
  void initState() {
    super.initState();
    final total = LocalDatabase.instance
        .getQuestionsBySubject(widget.subject.id)
        .length;
    _maxQuestions = total > 0 ? total : 10;
    _questionCount = _maxQuestions.clamp(1, _maxQuestions);
  }

  void _startExam() {
    Navigator.pop(context);
    Navigator.pushNamed(
      context,
      AppRoutes.examScreen,
      arguments: {'subject': widget.subject, 'questionCount': _questionCount},
    );
  }

  @override
  Widget build(BuildContext context) {
    final quickBtns = [
      10,
      20,
      30,
      40,
      50,
    ].where((v) => v <= _maxQuestions).toList();
    if (quickBtns.isEmpty) quickBtns.add(_maxQuestions);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xEE0D1426),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: AppTheme.glassBorder)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.subject.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                widget.subject.nameAr,
                style: const TextStyle(color: Colors.white38, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'عدد الأسئلة: ',
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                  Text(
                    '$_questionCount',
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    ' / $_maxQuestions',
                    style: const TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.accent,
                  inactiveTrackColor: AppTheme.glassSurface,
                  thumbColor: AppTheme.accent,
                  overlayColor: AppTheme.accent.withAlpha(30),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _questionCount.toDouble(),
                  min: 1,
                  max: _maxQuestions.toDouble(),
                  divisions: _maxQuestions > 1 ? _maxQuestions - 1 : 1,
                  onChanged: (v) => setState(() => _questionCount = v.round()),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: quickBtns.map((n) {
                  final sel = n == _questionCount;
                  return GestureDetector(
                    onTap: () => setState(() => _questionCount = n),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? AppTheme.accent : AppTheme.glassSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? AppTheme.accent : AppTheme.glassBorder,
                        ),
                      ),
                      child: Text(
                        '$n',
                        style: TextStyle(
                          color: sel ? Colors.white : Colors.white60,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _startExam,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'ابدأ الاختبار',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
