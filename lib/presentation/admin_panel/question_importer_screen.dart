import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../data/models/question_model.dart';
import '../../data/models/subject_model.dart';
import '../../data/services/local_database.dart';

class QuestionImporterScreen extends StatefulWidget {
  const QuestionImporterScreen({super.key});

  @override
  State<QuestionImporterScreen> createState() => _QuestionImporterScreenState();
}

class _QuestionImporterScreenState extends State<QuestionImporterScreen> {
  List<QuestionModel> _preview = [];
  List<String> _errors = [];
  bool _loading = false;
  bool _saving = false;
  String? _subjectId;
  String _fileName = '';

  Future<void> _pickFile() async {
    setState(() {
      _loading = true;
      _errors = [];
      _preview = [];
    });
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv', 'txt'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      final file = result.files.first;
      _fileName = file.name;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() {
          _loading = false;
          _errors = ['تعذر قراءة الملف'];
        });
        return;
      }
      final content = utf8.decode(bytes);
      final ext = file.extension?.toLowerCase() ?? '';
      if (ext == 'json') {
        _parseJson(content);
      } else if (ext == 'csv' || ext == 'txt') {
        _parseCsv(content);
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _errors = ['خطأ في قراءة الملف: $e'];
      });
    }
  }

  void _parseJson(String content) {
    final errors = <String>[];
    final questions = <QuestionModel>[];
    try {
      final decoded = jsonDecode(content);
      final list = decoded is List ? decoded : [decoded];
      for (int i = 0; i < list.length; i++) {
        try {
          final map = list[i] as Map<String, dynamic>;
          final subjectId =
              _subjectId ?? _findSubjectId(map['subject']?.toString() ?? '');
          final q = QuestionModel.fromJson(map, subjectId);
          if (q.question.isEmpty) {
            errors.add('سؤال ${i + 1}: نص السؤال فارغ');
          } else if (q.correctAnswer.isEmpty) {
            errors.add('سؤال ${i + 1}: الإجابة الصحيحة فارغة');
          } else {
            questions.add(q);
          }
        } catch (e) {
          errors.add('سؤال ${i + 1}: خطأ في التنسيق');
        }
      }
    } catch (e) {
      errors.add('خطأ في تنسيق JSON: $e');
    }
    setState(() {
      _preview = questions;
      _errors = errors;
      _loading = false;
    });
  }

  void _parseCsv(String content) {
    final errors = <String>[];
    final questions = <QuestionModel>[];
    final lines = content
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    // Skip header if present
    final startIdx =
        lines.isNotEmpty && lines[0].toLowerCase().contains('question') ? 1 : 0;
    for (int i = startIdx; i < lines.length; i++) {
      final parts = lines[i].split(',');
      if (parts.length < 3) {
        errors.add('سطر ${i + 1}: بيانات غير كافية');
        continue;
      }
      try {
        final subjectId = _subjectId ?? _findSubjectId(parts[0].trim());
        final q = QuestionModel(
          id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
          subjectId: subjectId,
          subjectName: parts[0].trim(),
          type: parts.length > 5 ? 'mcq' : 'true_false',
          question: parts[1].trim(),
          options: parts.length > 5
              ? [
                  parts[2].trim(),
                  parts[3].trim(),
                  parts[4].trim(),
                  parts[5].trim(),
                ]
              : ['صح', 'خطأ'],
          correctAnswer: parts.length > 6 ? parts[6].trim() : parts[2].trim(),
          explanation: parts.length > 7 ? parts[7].trim() : '',
          difficulty: 'medium',
          category: '',
          tags: [],
        );
        questions.add(q);
      } catch (e) {
        errors.add('سطر ${i + 1}: خطأ في التنسيق');
      }
    }
    setState(() {
      _preview = questions;
      _errors = errors;
      _loading = false;
    });
  }

  String _findSubjectId(String subjectName) {
    if (_subjectId != null) return _subjectId!;
    final subjects = LocalDatabase.instance.getSubjects();
    final match = subjects.firstWhere(
      (s) =>
          s.name.toLowerCase().contains(subjectName.toLowerCase()) ||
          subjectName.toLowerCase().contains(s.name.toLowerCase()),
      orElse: () => subjects.isNotEmpty
          ? subjects.first
          : SubjectModel(
              id: 'unknown',
              level: 1,
              semester: 1,
              name: subjectName,
              nameAr: subjectName,
              icon: 'menu_book',
              colorKey: 'blue',
              category: '',
            ),
    );
    return match.id;
  }

  Future<void> _saveAll() async {
    if (_preview.isEmpty) return;
    setState(() => _saving = true);
    await LocalDatabase.instance.addQuestions(_preview);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم استيراد ${_preview.length} سؤال بنجاح'),
          backgroundColor: AppTheme.success,
        ),
      );
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
          title: const Text(
            'استيراد الأسئلة',
            style: TextStyle(
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
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Format info
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.info.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.info.withAlpha(50)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.info,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'صيغ الملفات المدعومة',
                          style: TextStyle(
                            color: AppTheme.info,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'JSON: مصفوفة من الأسئلة بالصيغة المحددة\nCSV: subject,question,opt1,opt2,opt3,opt4,correct,explanation',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Subject override
              const Text(
                'تعيين المادة (اختياري)',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _subjectId,
                dropdownColor: AppTheme.surfaceVariantDark,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'تلقائي من الملف',
                  hintStyle: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: AppTheme.glassSurface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.glassBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.glassBorder),
                  ),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text(
                      'تلقائي',
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
                  ...subjects.map(
                    (s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(
                        '${s.name} (L${s.level}S${s.semester})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _subjectId = v),
              ),
              const SizedBox(height: 16),
              // Pick file button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _pickFile,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: AppTheme.accent,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.upload_file, size: 20),
                  label: Text(
                    _fileName.isEmpty ? 'اختر ملف JSON أو CSV' : _fileName,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accent,
                    side: const BorderSide(color: AppTheme.accent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              // Errors
              if (_errors.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.error.withAlpha(50)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_errors.length} تحذير',
                        style: const TextStyle(
                          color: AppTheme.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      ..._errors
                          .take(5)
                          .map(
                            (e) => Text(
                              '• $e',
                              style: const TextStyle(
                                color: AppTheme.error,
                                fontSize: 11,
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ],
              // Preview
              if (_preview.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'معاينة: ${_preview.length} سؤال',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveAll,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'استيراد الكل',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._preview
                    .take(20)
                    .map(
                      (q) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.glassSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: q.type == 'mcq'
                                    ? AppTheme.primary.withAlpha(40)
                                    : AppTheme.success.withAlpha(30),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                q.type == 'mcq' ? 'MCQ' : 'T/F',
                                style: TextStyle(
                                  color: q.type == 'mcq'
                                      ? AppTheme.primaryLight
                                      : AppTheme.success,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                q.question,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                if (_preview.length > 20)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '... و ${_preview.length - 20} سؤال آخر',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
