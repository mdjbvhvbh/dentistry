import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/question_model.dart';
import '../models/subject_model.dart';
import 'local_database.dart';

/// مزامنة الأسئلة والمواد من Google Sheets (عبر Apps Script)
/// الذي يغذّيه بوت التيليجرام.
///
/// آلية العمل:
/// 1) عند فتح التطبيق يسأل الخادم عن رقم الإصدار (version)
/// 2) لو تغيّر منذ آخر مزامنة → يسحب كل الأسئلة ويدمجها مع المحلية
/// 3) الأسئلة القادمة من البوت لها الأولوية بنفس الـ id،
///    والأسئلة المحلية التي لا نظير لها تبقى كما هي (لا يُفقد شيء)
/// 4) بدون إنترنت → يعمل التطبيق على النسخة المخزنة محلياً
class RemoteSyncService {
  /// رابط تطبيق الويب (Deploy) من Apps Script — ضعه هنا بعد الإعداد
  static const String baseUrl =
      'https://script.google.com/macros/s/AKfycbzZbwLqol5QxOBpBHGbtU_Pcx4jTgClRwGu9e_7rmhliFPUGfWZPFfL4_ilfHuTyytmCw/exec';

  /// نفس القيمة الموضوعة في Script Properties باسم API_KEY
  static const String apiKey = r'HxdH$V2$0_$d4cfk';

  static const String _versionKey = 'remote_version';

  Future<Map<String, dynamic>?> _get(
    String action, [
    Map<String, String>? extra,
  ]) async {
    final params = {'key': apiKey, 'action': action, ...?extra};
    final uri = Uri.parse(baseUrl).replace(queryParameters: params);
    final res = await http.get(uri).timeout(const Duration(seconds: 25));
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body);
    return body is Map<String, dynamic> ? body : null;
  }

  Future<String?> getRemoteVersion() async {
    final j = await _get('meta');
    return (j?['ok'] == true) ? j!['version']?.toString() : null;
  }

  Future<List<QuestionModel>> fetchQuestions() async {
    final j = await _get('questions');
    if (j?['ok'] != true) return [];
    final list = (j!['questions'] as List?) ?? [];
    return list
        .map((e) {
          final m = e as Map<String, dynamic>;
          return QuestionModel(
            id: m['id']?.toString() ?? '',
            subjectId: m['subjectId']?.toString() ?? '',
            subjectName: m['subjectName']?.toString() ?? '',
            type: m['type']?.toString() ?? 'mcq',
            question: m['question']?.toString() ?? '',
            options:
                (m['options'] as List?)?.map((x) => x.toString()).toList() ??
                [],
            correctAnswer: m['correctAnswer']?.toString() ?? '',
            explanation: m['explanation']?.toString() ?? '',
            difficulty: m['difficulty']?.toString() ?? 'medium',
            category: m['category']?.toString() ?? '',
            tags: (m['tags'] as List?)?.map((x) => x.toString()).toList() ?? [],
          );
        })
        .where((q) => q.id.isNotEmpty)
        .toList();
  }

  Future<List<SubjectModel>> fetchSubjects() async {
    final j = await _get('subjects');
    if (j?['ok'] != true) return [];
    final list = (j!['subjects'] as List?) ?? [];
    return list
        .map((e) {
          final m = e as Map<String, dynamic>;
          final name = m['name']?.toString() ?? '';
          return SubjectModel(
            id: m['id']?.toString() ?? '',
            level: (m['level'] as num?)?.toInt() ?? 1,
            semester: (m['semester'] as num?)?.toInt() ?? 1,
            name: name,
            nameAr: name,
            icon: 'menu_book',
            colorKey: 'blue',
            category: '',
          );
        })
        .where((s) => s.id.isNotEmpty)
        .toList();
  }

  /// ينفّذ المزامنة. النتيجة:
  /// - updated: نُزّلت بيانات جديدة (count = عدد أسئلة الخادم)
  /// - up-to-date: لا جديد
  /// - offline: تعذّر الاتصال (يُستخدم المخزّن محلياً)
  Future<SyncResult> sync() async {
    final db = LocalDatabase.instance;
    try {
      final remoteVersion = await getRemoteVersion();
      if (remoteVersion == null) return SyncResult.offline();

      final localVersion = db.prefs.getString(_versionKey);
      if (localVersion == remoteVersion) return SyncResult.upToDate();

      final remoteQuestions = await fetchQuestions();
      final local = db.getAllQuestions();
      final remoteIds = remoteQuestions.map((q) => q.id).toSet();
      final localOnly = local.where((q) => !remoteIds.contains(q.id)).toList();
      await db.saveQuestions([...remoteQuestions, ...localOnly]);

      final remoteSubjects = await fetchSubjects();
      if (remoteSubjects.isNotEmpty) {
        final localSubs = db.getSubjects();
        final rIds = remoteSubjects.map((s) => s.id).toSet();
        final merged = [
          ...remoteSubjects,
          ...localSubs.where((s) => !rIds.contains(s.id)),
        ];
        await db.saveSubjects(merged);
      }

      await db.prefs.setString(_versionKey, remoteVersion);
      return SyncResult.updated(remoteQuestions.length);
    } catch (_) {
      return SyncResult.offline();
    }
  }
}

class SyncResult {
  /// 'updated' | 'up-to-date' | 'offline'
  final String status;
  final int count;

  SyncResult._(this.status, this.count);

  factory SyncResult.updated(int c) => SyncResult._('updated', c);
  factory SyncResult.upToDate() => SyncResult._('up-to-date', 0);
  factory SyncResult.offline() => SyncResult._('offline', 0);
}
