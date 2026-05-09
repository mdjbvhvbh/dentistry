import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../data/models/exam_result_model.dart';
import '../../data/models/subject_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/local_database.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = LocalDatabase.instance.getAllResults();
    final subjects = LocalDatabase.instance.getSubjects();
    final isAdmin = AuthService.instance.isAdmin;

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
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF060B18), Color(0xFF0A0E1A)],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    if (results.isEmpty)
                      const SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bar_chart_rounded,
                                color: Colors.white24,
                                size: 64,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'لا توجد بيانات بعد',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'أكمل اختباراً لرؤية التحليلات',
                                style: TextStyle(
                                  color: Colors.white24,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      SliverToBoxAdapter(child: _buildSummaryCards(results)),
                      SliverToBoxAdapter(
                        child: _buildPerformanceChart(results),
                      ),
                      SliverToBoxAdapter(
                        child: _buildSubjectPerformance(results, subjects),
                      ),
                      if (isAdmin)
                        SliverToBoxAdapter(
                          child: _buildAdminStats(results, subjects),
                        ),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.glassSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white70,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'التحليلات والتقارير',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'تتبع أدائك الأكاديمي',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<ExamResultModel> results) {
    final avgScore = results.isEmpty
        ? 0.0
        : results.map((r) => r.scorePercent).reduce((a, b) => a + b) /
              results.length;
    final bestScore = results.isEmpty
        ? 0.0
        : results.map((r) => r.scorePercent).reduce((a, b) => a > b ? a : b);
    final passCount = results.where((r) => r.scorePercent >= 60).length;
    final passRate = results.isEmpty ? 0.0 : passCount / results.length * 100;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _AnalyticsCard(
                  label: 'متوسط الأداء',
                  value: '${avgScore.toStringAsFixed(1)}%',
                  icon: Icons.trending_up,
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AnalyticsCard(
                  label: 'أعلى درجة',
                  value: '${bestScore.toStringAsFixed(1)}%',
                  icon: Icons.emoji_events,
                  color: AppTheme.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _AnalyticsCard(
                  label: 'نسبة النجاح',
                  value: '${passRate.toStringAsFixed(1)}%',
                  icon: Icons.check_circle_outline,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AnalyticsCard(
                  label: 'الاختبارات',
                  value: '${results.length}',
                  icon: Icons.assignment_turned_in,
                  color: AppTheme.primaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart(List<ExamResultModel> results) {
    final recent = results.length > 10
        ? results.sublist(results.length - 10)
        : results;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.glassSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مسار الأداء',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'آخر 10 اختبارات',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: Colors.white10, strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (v, _) => Text(
                              '${v.toInt()}%',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) => Text(
                              '${v.toInt() + 1}',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                      maxY: 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: recent
                              .asMap()
                              .entries
                              .map(
                                (e) => FlSpot(
                                  e.key.toDouble(),
                                  e.value.scorePercent,
                                ),
                              )
                              .toList(),
                          isCurved: true,
                          color: AppTheme.accent,
                          barWidth: 2.5,
                          dotData: FlDotData(
                            getDotPainter: (_, __, ___, ____) =>
                                FlDotCirclePainter(
                                  radius: 3,
                                  color: AppTheme.accent,
                                  strokeWidth: 0,
                                ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.accent.withAlpha(30),
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
      ),
    );
  }

  Widget _buildSubjectPerformance(
    List<ExamResultModel> results,
    List<SubjectModel> subjects,
  ) {
    // Group by subject
    final subjectMap = <String, List<ExamResultModel>>{};
    for (final r in results) {
      subjectMap.putIfAbsent(r.subjectId, () => []).add(r);
    }

    final subjectStats =
        subjectMap.entries.map((e) {
            final avg =
                e.value.map((r) => r.scorePercent).reduce((a, b) => a + b) /
                e.value.length;
            final subjectName = e.value.first.subjectName;
            return {
              'id': e.key,
              'name': subjectName,
              'avg': avg,
              'count': e.value.length,
            };
          }).toList()
          ..sort((a, b) => (b['avg'] as double).compareTo(a['avg'] as double));

    if (subjectStats.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.glassSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'أداء المواد',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ...subjectStats.take(8).map((s) {
                  final avg = s['avg'] as double;
                  final color = avg >= 75
                      ? AppTheme.success
                      : avg >= 60
                      ? AppTheme.accent
                      : AppTheme.warning;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                s['name'] as String,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${avg.toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: avg / 100,
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 5,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminStats(
    List<ExamResultModel> results,
    List<SubjectModel> subjects,
  ) {
    // Most active subjects
    final subjectCounts = <String, int>{};
    for (final r in results) {
      subjectCounts[r.subjectName] = (subjectCounts[r.subjectName] ?? 0) + 1;
    }
    final sorted = subjectCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.warning.withAlpha(15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.warning.withAlpha(40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      color: AppTheme.warning,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'إحصائيات المشرف',
                      style: TextStyle(
                        color: AppTheme.warning,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'أكثر المواد نشاطاً',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 8),
                ...sorted
                    .take(5)
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.key,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.warning.withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${e.value} اختبار',
                                style: const TextStyle(
                                  color: AppTheme.warning,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'إجمالي الاختبارات',
                        value: '${results.length}',
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MiniStat(
                        label: 'إجمالي المواد',
                        value: '${subjects.length}',
                        color: AppTheme.primaryLight,
                      ),
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
}

class _AnalyticsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _AnalyticsCard({
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(50)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        children: [
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
            style: const TextStyle(color: Colors.white38, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
