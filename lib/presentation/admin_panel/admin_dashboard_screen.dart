import 'dart:ui';

import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../data/models/question_model.dart';
import '../../data/models/subject_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/local_database.dart';
import './admin_login_screen.dart';
import './question_form_screen.dart';
import './question_importer_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  int _tab = 0;
  String _searchQuery = '';
  String? _filterSubjectId;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    // Auto-logout check
    if (!AuthService.instance.isSessionValid) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _logout());
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _logout() {
    AuthService.instance.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      (_) => false,
    );
  }

  List<QuestionModel> get _filteredQuestions {
    var qs = LocalDatabase.instance.getAllQuestions();
    if (_filterSubjectId != null) {
      qs = qs.where((q) => q.subjectId == _filterSubjectId).toList();
    }
    if (_searchQuery.isNotEmpty) {
      qs = qs
          .where(
            (q) =>
                q.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                q.subjectName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }
    return qs;
  }

  @override
  Widget build(BuildContext context) {
    AuthService.instance.refreshSession();
    final role = AuthService.instance.currentRole;
    final allQuestions = LocalDatabase.instance.getAllQuestions();
    final allSubjects = LocalDatabase.instance.getSubjects();
    final allResults = LocalDatabase.instance.getAllResults();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF060B18),
                      Color(0xFF0A1628),
                      Color(0xFF0A0E1A),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    _buildHeader(role),
                    _buildTabBar(),
                    Expanded(
                      child: IndexedStack(
                        index: _tab,
                        children: [
                          _buildOverviewTab(
                            allQuestions,
                            allSubjects,
                            allResults,
                          ),
                          _buildQuestionsTab(allSubjects),
                          if (role == AdminRole.owner) _buildSettingsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AdminRole role) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryLight.withAlpha(60)),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: AppTheme.primaryLight,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'لوحة الإدارة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  role == AdminRole.owner ? 'المالك' : 'المشرف',
                  style: TextStyle(
                    color: role == AdminRole.owner
                        ? AppTheme.warning
                        : AppTheme.accent,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.analyticsScreen),
            icon: const Icon(
              Icons.bar_chart_rounded,
              color: Colors.white70,
              size: 20,
            ),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: AppTheme.error, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = [
      'نظرة عامة',
      'الأسئلة',
      if (AuthService.instance.isOwner) 'الإعدادات',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final sel = e.key == _tab;
          return GestureDetector(
            onTap: () => setState(() => _tab = e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppTheme.primary : AppTheme.glassSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel ? AppTheme.primaryLight : AppTheme.glassBorder,
                ),
              ),
              child: Text(
                e.value,
                style: TextStyle(
                  color: sel ? Colors.white : Colors.white54,
                  fontSize: 13,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverviewTab(
    List<QuestionModel> questions,
    List<SubjectModel> subjects,
    List allResults,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'إجمالي الأسئلة',
                  value: '${questions.length}',
                  icon: Icons.quiz,
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'المواد',
                  value: '${subjects.length}',
                  icon: Icons.menu_book,
                  color: AppTheme.primaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'الاختبارات',
                  value: '${allResults.length}',
                  icon: Icons.assignment_turned_in,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'المستويات',
                  value: '4',
                  icon: Icons.school,
                  color: AppTheme.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ActionCard(
            icon: Icons.add_circle_outline,
            title: 'إضافة سؤال جديد',
            subtitle: 'أضف سؤال MCQ أو صح/خطأ',
            color: AppTheme.accent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuestionFormScreen()),
            ).then((_) => setState(() {})),
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.upload_file,
            title: 'استيراد أسئلة',
            subtitle: 'استيراد من JSON أو CSV',
            color: AppTheme.success,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuestionImporterScreen()),
            ).then((_) => setState(() {})),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsTab(List<SubjectModel> subjects) {
    final filtered = _filteredQuestions;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'بحث في الأسئلة...',
                  hintStyle: const TextStyle(
                    color: Colors.white38,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.white38,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: AppTheme.glassSurface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.glassBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.glassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.accent),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: 'الكل',
                      selected: _filterSubjectId == null,
                      onTap: () => setState(() => _filterSubjectId = null),
                    ),
                    ...subjects.map(
                      (s) => _FilterChip(
                        label: s.name.length > 15
                            ? '${s.name.substring(0, 15)}...'
                            : s.name,
                        selected: _filterSubjectId == s.id,
                        onTap: () => setState(() => _filterSubjectId = s.id),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${filtered.length} سؤال',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuestionFormScreen()),
                ).then((_) => setState(() {})),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'إضافة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد أسئلة',
                    style: TextStyle(color: Colors.white38),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _QuestionListItem(
                    question: filtered[i],
                    onEdit: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            QuestionFormScreen(question: filtered[i]),
                      ),
                    ).then((_) => setState(() {})),
                    onDelete: () async {
                      await LocalDatabase.instance.deleteQuestion(
                        filtered[i].id,
                      );
                      setState(() {});
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _SettingsCard(
            title: 'تغيير كلمة مرور المالك',
            icon: Icons.lock,
            color: AppTheme.warning,
            onTap: () => _showChangePasswordDialog('owner'),
          ),
          const SizedBox(height: 10),
          _SettingsCard(
            title: 'تغيير كلمة مرور المشرف',
            icon: Icons.lock_outline,
            color: AppTheme.accent,
            onTap: () => _showChangePasswordDialog('admin'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(String type) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariantDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تغيير كلمة مرور ${type == 'owner' ? 'المالك' : 'المشرف'}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'كلمة المرور الجديدة',
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
            child: const Text('إلغاء', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () async {
              final pass = ctrl.text.trim();
              if (pass.length < 6) return;
              if (type == 'owner') {
                await AuthService.instance.changeOwnerPassword(pass);
              } else {
                await AuthService.instance.changeAdminPassword(pass);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(50)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 14),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.glassSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white38,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accent.withAlpha(30)
              : AppTheme.glassSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.accent : AppTheme.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.accent : Colors.white54,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _QuestionListItem extends StatelessWidget {
  final QuestionModel question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _QuestionListItem({
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.glassSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: question.type == 'mcq'
                  ? AppTheme.primary.withAlpha(40)
                  : AppTheme.success.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              question.type == 'mcq' ? 'MCQ' : 'T/F',
              style: TextStyle(
                color: question.type == 'mcq'
                    ? AppTheme.primaryLight
                    : AppTheme.success,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.question,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  textDirection: TextDirection.rtl,
                ),
                Text(
                  question.subjectName,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(
              Icons.edit_outlined,
              color: AppTheme.accent,
              size: 18,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppTheme.surfaceVariantDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  'حذف السؤال؟',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onDelete();
                    },
                    child: const Text(
                      'حذف',
                      style: TextStyle(color: AppTheme.error),
                    ),
                  ),
                ],
              ),
            ),
            icon: const Icon(
              Icons.delete_outline,
              color: AppTheme.error,
              size: 18,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
