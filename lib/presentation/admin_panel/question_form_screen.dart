import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../data/models/question_model.dart';
import '../../data/services/local_database.dart';

class QuestionFormScreen extends StatefulWidget {
  final QuestionModel? question;
  const QuestionFormScreen({super.key, this.question});

  @override
  State<QuestionFormScreen> createState() => _QuestionFormScreenState();
}

class _QuestionFormScreenState extends State<QuestionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'mcq';
  String? _subjectId;
  final _questionCtrl = TextEditingController();
  final _explanationCtrl = TextEditingController();
  final _correctCtrl = TextEditingController();
  String _difficulty = 'medium';
  final List<TextEditingController> _optionCtrls = List.generate(
    4,
    (_) => TextEditingController(),
  );
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    if (q != null) {
      _type = q.type;
      _subjectId = q.subjectId;
      _questionCtrl.text = q.question;
      _explanationCtrl.text = q.explanation;
      _correctCtrl.text = q.correctAnswer;
      _difficulty = q.difficulty;
      if (q.type == 'mcq') {
        for (int i = 0; i < q.options.length && i < 4; i++) {
          _optionCtrls[i].text = q.options[i];
        }
      }
    }
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _explanationCtrl.dispose();
    _correctCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_subjectId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('اختر المادة أولاً')));
      return;
    }
    setState(() => _saving = true);

    List<String> options;
    String correctAnswer;
    if (_type == 'true_false') {
      options = ['صح', 'خطأ'];
      correctAnswer = _correctCtrl.text.trim().isEmpty
          ? 'صح'
          : _correctCtrl.text.trim();
    } else {
      options = _optionCtrls
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      correctAnswer = _correctCtrl.text.trim();
    }

    final subjects = LocalDatabase.instance.getSubjects();
    final subject = subjects.firstWhere(
      (s) => s.id == _subjectId,
      orElse: () => subjects.first,
    );

    final q = QuestionModel(
      id:
          widget.question?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      subjectId: _subjectId!,
      subjectName: subject.name,
      type: _type,
      question: _questionCtrl.text.trim(),
      options: options,
      correctAnswer: correctAnswer,
      explanation: _explanationCtrl.text.trim(),
      difficulty: _difficulty,
      category: subject.category,
      tags: [subject.name],
    );

    if (widget.question != null) {
      await LocalDatabase.instance.updateQuestion(q);
    } else {
      await LocalDatabase.instance.addQuestion(q);
    }

    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = LocalDatabase.instance.getSubjects();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundDark,
          title: Text(
            widget.question != null ? 'تعديل السؤال' : 'إضافة سؤال',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white70,
              size: 18,
            ),
          ),
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: AppTheme.accent,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'حفظ',
                      style: TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type selector
                _SectionLabel('نوع السؤال'),
                Row(
                  children: [
                    Expanded(
                      child: _TypeBtn(
                        label: 'اختيار متعدد (MCQ)',
                        selected: _type == 'mcq',
                        onTap: () => setState(() => _type = 'mcq'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TypeBtn(
                        label: 'صح / خطأ',
                        selected: _type == 'true_false',
                        onTap: () => setState(() => _type = 'true_false'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Subject
                _SectionLabel('المادة'),
                DropdownButtonFormField<String>(
                  value: _subjectId,
                  dropdownColor: AppTheme.surfaceVariantDark,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _inputDeco('اختر المادة'),
                  items: subjects
                      .map(
                        (s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(
                            '${s.name} (L${s.level}S${s.semester})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _subjectId = v),
                  validator: (v) => v == null ? 'اختر المادة' : null,
                ),
                const SizedBox(height: 16),
                // Question
                _SectionLabel('نص السؤال'),
                TextFormField(
                  controller: _questionCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  textDirection: TextDirection.rtl,
                  decoration: _inputDeco('أدخل نص السؤال'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'أدخل السؤال' : null,
                ),
                const SizedBox(height: 16),
                // Options (MCQ only)
                if (_type == 'mcq') ...[
                  _SectionLabel('الخيارات'),
                  ...List.generate(
                    4,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextFormField(
                        controller: _optionCtrls[i],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        textDirection: TextDirection.rtl,
                        decoration: _inputDeco('الخيار ${i + 1}'),
                        validator: i < 2
                            ? (v) => v == null || v.trim().isEmpty
                                  ? 'أدخل الخيار'
                                  : null
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // Correct answer
                _SectionLabel(
                  _type == 'true_false'
                      ? 'الإجابة الصحيحة (صح أو خطأ)'
                      : 'الإجابة الصحيحة',
                ),
                if (_type == 'true_false')
                  Row(
                    children: [
                      Expanded(
                        child: _TypeBtn(
                          label: 'صح',
                          selected: _correctCtrl.text == 'صح',
                          onTap: () => setState(() => _correctCtrl.text = 'صح'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TypeBtn(
                          label: 'خطأ',
                          selected: _correctCtrl.text == 'خطأ',
                          onTap: () =>
                              setState(() => _correctCtrl.text = 'خطأ'),
                        ),
                      ),
                    ],
                  )
                else
                  TextFormField(
                    controller: _correctCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    textDirection: TextDirection.rtl,
                    decoration: _inputDeco(
                      'الإجابة الصحيحة (يجب أن تطابق أحد الخيارات)',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'أدخل الإجابة الصحيحة'
                        : null,
                  ),
                const SizedBox(height: 16),
                // Difficulty
                _SectionLabel('مستوى الصعوبة'),
                Row(
                  children: ['easy', 'medium', 'hard'].map((d) {
                    final labels = {
                      'easy': 'سهل',
                      'medium': 'متوسط',
                      'hard': 'صعب',
                    };
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _TypeBtn(
                          label: labels[d]!,
                          selected: _difficulty == d,
                          onTap: () => setState(() => _difficulty = d),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Explanation
                _SectionLabel('الشرح (اختياري)'),
                TextFormField(
                  controller: _explanationCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  textDirection: TextDirection.rtl,
                  decoration: _inputDeco('شرح الإجابة الصحيحة'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
      filled: true,
      fillColor: AppTheme.glassSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.error),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeBtn({
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.glassSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.primaryLight : AppTheme.glassBorder,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white54,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
