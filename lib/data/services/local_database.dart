import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/question_model.dart';
import '../models/subject_model.dart';
import '../models/exam_result_model.dart';

class LocalDatabase {
  static LocalDatabase? _instance;
  static LocalDatabase get instance => _instance ??= LocalDatabase._();
  LocalDatabase._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _seedIfEmpty();
  }

  SharedPreferences get prefs {
    if (_prefs == null) throw Exception('Database not initialized');
    return _prefs!;
  }

  // ── SUBJECTS ─────────────────────────────────────────────────

  Future<void> saveSubjects(List<SubjectModel> subjects) async {
    final list = subjects.map((s) => jsonEncode(s.toMap())).toList();
    await prefs.setStringList('subjects', list);
  }

  List<SubjectModel> getSubjects() {
    final list = prefs.getStringList('subjects') ?? [];
    return list
        .map((s) => SubjectModel.fromMap(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  List<SubjectModel> getSubjectsByLevelAndSemester(int level, int semester) {
    return getSubjects()
        .where((s) => s.level == level && s.semester == semester)
        .toList();
  }

  // ── QUESTIONS ─────────────────────────────────────────────────

  Future<void> saveQuestions(List<QuestionModel> questions) async {
    final list = questions.map((q) => jsonEncode(q.toMap())).toList();
    await prefs.setStringList('questions', list);
  }

  List<QuestionModel> getAllQuestions() {
    final list = prefs.getStringList('questions') ?? [];
    return list
        .map(
          (q) => QuestionModel.fromMap(jsonDecode(q) as Map<String, dynamic>),
        )
        .toList();
  }

  List<QuestionModel> getQuestionsBySubject(String subjectId) {
    return getAllQuestions().where((q) => q.subjectId == subjectId).toList();
  }

  Future<void> addQuestion(QuestionModel question) async {
    final questions = getAllQuestions();
    // Deduplication check
    final exists = questions.any(
      (q) =>
          q.question.trim() == question.question.trim() &&
          q.subjectId == question.subjectId,
    );
    if (!exists) {
      questions.add(question);
      await saveQuestions(questions);
    }
  }

  Future<void> addQuestions(List<QuestionModel> newQuestions) async {
    final existing = getAllQuestions();
    final existingTexts = existing
        .map((q) => '${q.subjectId}::${q.question.trim()}')
        .toSet();
    final toAdd = newQuestions
        .where(
          (q) =>
              !existingTexts.contains('${q.subjectId}::${q.question.trim()}'),
        )
        .toList();
    existing.addAll(toAdd);
    await saveQuestions(existing);
  }

  Future<void> updateQuestion(QuestionModel updated) async {
    final questions = getAllQuestions();
    final idx = questions.indexWhere((q) => q.id == updated.id);
    if (idx >= 0) {
      questions[idx] = updated;
      await saveQuestions(questions);
    }
  }

  Future<void> deleteQuestion(String id) async {
    final questions = getAllQuestions();
    questions.removeWhere((q) => q.id == id);
    await saveQuestions(questions);
  }

  // ── EXAM RESULTS ─────────────────────────────────────────────

  Future<void> saveResult(ExamResultModel result) async {
    final results = getAllResults();
    results.add(result);
    final list = results.map((r) => jsonEncode(r.toMap())).toList();
    await prefs.setStringList('results', list);
  }

  List<ExamResultModel> getAllResults() {
    final list = prefs.getStringList('results') ?? [];
    return list
        .map(
          (r) => ExamResultModel.fromMap(jsonDecode(r) as Map<String, dynamic>),
        )
        .toList();
  }

  List<ExamResultModel> getResultsBySubject(String subjectId) {
    return getAllResults().where((r) => r.subjectId == subjectId).toList();
  }

  // ── STUDENT NAME ─────────────────────────────────────────────

  String getStudentName() => prefs.getString('student_name') ?? 'الطالب';
  Future<void> setStudentName(String name) =>
      prefs.setString('student_name', name);

  // ── ADMIN AUTH ───────────────────────────────────────────────

  String getAdminPassword() =>
      prefs.getString('admin_password') ?? 'Admin@2026';
  Future<void> setAdminPassword(String password) =>
      prefs.setString('admin_password', password);

  String getOwnerPassword() =>
      prefs.getString('owner_password') ?? 'Owner@2026';
  Future<void> setOwnerPassword(String password) =>
      prefs.setString('owner_password', password);

  // ── SEED DATA ─────────────────────────────────────────────────

  Future<void> _seedIfEmpty() async {
    final seeded = prefs.getBool('seeded_v3') ?? false;
    if (seeded) return;

    await saveSubjects(_seedSubjects());
    await saveQuestions(_seedQuestions());
    await prefs.setBool('seeded_v3', true);
  }

  List<SubjectModel> _seedSubjects() {
    return [
      // Level 1 Semester 1
      SubjectModel(
        id: 'l1s1_dental_anatomy',
        level: 1,
        semester: 1,
        name: 'Dental Anatomy',
        nameAr: 'تشريح الأسنان',
        icon: 'menu_book',
        colorKey: 'blue',
        category: 'Anatomy',
      ),
      SubjectModel(
        id: 'l1s1_english',
        level: 1,
        semester: 1,
        name: 'English Language Skills',
        nameAr: 'مهارات اللغة الإنجليزية',
        icon: 'language',
        colorKey: 'green',
        category: 'Language',
      ),
      SubjectModel(
        id: 'l1s1_arabic',
        level: 1,
        semester: 1,
        name: 'مهارات اللغة العربية',
        nameAr: 'مهارات اللغة العربية',
        icon: 'translate',
        colorKey: 'amber',
        category: 'Language',
      ),
      SubjectModel(
        id: 'l1s1_islamic',
        level: 1,
        semester: 1,
        name: 'الثقافة الإسلامية',
        nameAr: 'الثقافة الإسلامية',
        icon: 'auto_stories',
        colorKey: 'teal',
        category: 'Culture',
      ),
      SubjectModel(
        id: 'l1s1_biochemistry',
        level: 1,
        semester: 1,
        name: 'Biochemistry',
        nameAr: 'الكيمياء الحيوية',
        icon: 'science',
        colorKey: 'purple',
        category: 'Basic Sciences',
      ),
      SubjectModel(
        id: 'l1s1_physics',
        level: 1,
        semester: 1,
        name: 'Medical Physics',
        nameAr: 'الفيزياء الطبية',
        icon: 'analytics',
        colorKey: 'rose',
        category: 'Basic Sciences',
      ),
      SubjectModel(
        id: 'l1s1_anatomy',
        level: 1,
        semester: 1,
        name: 'General Anatomy',
        nameAr: 'التشريح العام',
        icon: 'biotech',
        colorKey: 'blue',
        category: 'Anatomy',
      ),
      SubjectModel(
        id: 'l1s1_psychology',
        level: 1,
        semester: 1,
        name: 'Medical Psychology',
        nameAr: 'علم النفس الطبي',
        icon: 'psychology',
        colorKey: 'purple',
        category: 'Behavioral Science',
      ),
      SubjectModel(
        id: 'l1s1_intro',
        level: 1,
        semester: 1,
        name: 'Introduction to Dentistry',
        nameAr: 'مقدمة في طب الأسنان',
        icon: 'local_hospital',
        colorKey: 'teal',
        category: 'Clinical Foundation',
      ),
      // Level 1 Semester 2
      SubjectModel(
        id: 'l1s2_dental_anatomy2',
        level: 1,
        semester: 2,
        name: 'Dental Anatomy 2',
        nameAr: 'تشريح الأسنان 2',
        icon: 'menu_book',
        colorKey: 'blue',
        category: 'Anatomy',
      ),
      SubjectModel(
        id: 'l1s2_english2',
        level: 1,
        semester: 2,
        name: 'English Language Skills 2',
        nameAr: 'مهارات اللغة الإنجليزية 2',
        icon: 'language',
        colorKey: 'green',
        category: 'Language',
      ),
      SubjectModel(
        id: 'l1s2_arabic2',
        level: 1,
        semester: 2,
        name: 'مهارات اللغة العربية',
        nameAr: 'مهارات اللغة العربية',
        icon: 'translate',
        colorKey: 'amber',
        category: 'Language',
      ),
      SubjectModel(
        id: 'l1s2_computer',
        level: 1,
        semester: 2,
        name: 'Computer Skills',
        nameAr: 'مهارات الحاسوب',
        icon: 'computer',
        colorKey: 'teal',
        category: 'General',
      ),
      SubjectModel(
        id: 'l1s2_biochemistry2',
        level: 1,
        semester: 2,
        name: 'Biochemistry 2',
        nameAr: 'الكيمياء الحيوية 2',
        icon: 'science',
        colorKey: 'purple',
        category: 'Basic Sciences',
      ),
      SubjectModel(
        id: 'l1s2_communication',
        level: 1,
        semester: 2,
        name: 'Communication Skills',
        nameAr: 'مهارات التواصل',
        icon: 'chat',
        colorKey: 'rose',
        category: 'Behavioral Science',
      ),
      SubjectModel(
        id: 'l1s2_histology',
        level: 1,
        semester: 2,
        name: 'General Histology',
        nameAr: 'علم الأنسجة العام',
        icon: 'biotech',
        colorKey: 'green',
        category: 'Histology',
      ),
      // Level 2 Semester 1
      SubjectModel(
        id: 'l2s1_pathology',
        level: 2,
        semester: 1,
        name: 'General Pathology',
        nameAr: 'علم الأمراض العام',
        icon: 'biotech',
        colorKey: 'rose',
        category: 'Pathology',
      ),
      SubjectModel(
        id: 'l2s1_microbiology',
        level: 2,
        semester: 1,
        name: 'Microbiology',
        nameAr: 'علم الأحياء الدقيقة',
        icon: 'coronavirus',
        colorKey: 'purple',
        category: 'Microbiology',
      ),
      SubjectModel(
        id: 'l2s1_physiology',
        level: 2,
        semester: 1,
        name: 'Human Physiology',
        nameAr: 'فسيولوجيا الإنسان',
        icon: 'monitor_heart',
        colorKey: 'blue',
        category: 'Physiology',
      ),
      SubjectModel(
        id: 'l2s1_biochemistry',
        level: 2,
        semester: 1,
        name: 'Biochemistry',
        nameAr: 'الكيمياء الحيوية',
        icon: 'science',
        colorKey: 'teal',
        category: 'Basic Sciences',
      ),
      SubjectModel(
        id: 'l2s1_psychology',
        level: 2,
        semester: 1,
        name: 'Medical Psychology',
        nameAr: 'علم النفس الطبي',
        icon: 'psychology',
        colorKey: 'amber',
        category: 'Behavioral Science',
      ),
      SubjectModel(
        id: 'l2s1_immunology',
        level: 2,
        semester: 1,
        name: 'Immunology',
        nameAr: 'المناعة',
        icon: 'vaccines',
        colorKey: 'green',
        category: 'Immunology',
      ),
      SubjectModel(
        id: 'l2s1_dental_material',
        level: 2,
        semester: 1,
        name: 'Dental Material I',
        nameAr: 'مواد طب الأسنان 1',
        icon: 'healing',
        colorKey: 'blue',
        category: 'Dental Materials',
      ),
      SubjectModel(
        id: 'l2s1_oral_histo',
        level: 2,
        semester: 1,
        name: 'Oral Histology and Embryology 1',
        nameAr: 'هستولوجيا الفم والأجنة 1',
        icon: 'biotech',
        colorKey: 'purple',
        category: 'Histology',
      ),
      // Level 2 Semester 2
      SubjectModel(
        id: 'l2s2_ethics',
        level: 2,
        semester: 2,
        name: 'Medical Ethics',
        nameAr: 'أخلاقيات الطب',
        icon: 'gavel',
        colorKey: 'teal',
        category: 'Ethics',
      ),
      SubjectModel(
        id: 'l2s2_surgery',
        level: 2,
        semester: 2,
        name: 'General Surgery',
        nameAr: 'الجراحة العامة',
        icon: 'medical_services',
        colorKey: 'rose',
        category: 'Surgery',
      ),
      SubjectModel(
        id: 'l2s2_physiology2',
        level: 2,
        semester: 2,
        name: 'Human Physiology II',
        nameAr: 'فسيولوجيا الإنسان 2',
        icon: 'monitor_heart',
        colorKey: 'blue',
        category: 'Physiology',
      ),
      SubjectModel(
        id: 'l2s2_medicine',
        level: 2,
        semester: 2,
        name: 'General Medicine',
        nameAr: 'الطب العام',
        icon: 'local_hospital',
        colorKey: 'green',
        category: 'Medicine',
      ),
      SubjectModel(
        id: 'l2s2_operative',
        level: 2,
        semester: 2,
        name: 'Operative Dentistry 1',
        nameAr: 'طب الأسنان التشغيلي 1',
        icon: 'build',
        colorKey: 'amber',
        category: 'Operative',
      ),
      SubjectModel(
        id: 'l2s2_removable',
        level: 2,
        semester: 2,
        name: 'Removable Prosthodontics 1',
        nameAr: 'التعويضات المتحركة 1',
        icon: 'healing',
        colorKey: 'purple',
        category: 'Prosthodontics',
      ),
      SubjectModel(
        id: 'l2s2_dental_material2',
        level: 2,
        semester: 2,
        name: 'Dental Material II',
        nameAr: 'مواد طب الأسنان 2',
        icon: 'science',
        colorKey: 'rose',
        category: 'Dental Materials',
      ),
      SubjectModel(
        id: 'l2s2_oral_histo2',
        level: 2,
        semester: 2,
        name: 'Oral Histology and Embryology 2',
        nameAr: 'هستولوجيا الفم والأجنة 2',
        icon: 'biotech',
        colorKey: 'teal',
        category: 'Histology',
      ),
      // Level 3 Semester 1
      SubjectModel(
        id: 'l3s1_oral_path',
        level: 3,
        semester: 1,
        name: 'Oral Pathology 1',
        nameAr: 'أمراض الفم 1',
        icon: 'biotech',
        colorKey: 'rose',
        category: 'Pathology',
      ),
      SubjectModel(
        id: 'l3s1_removable2',
        level: 3,
        semester: 1,
        name: 'Removable Prosthodontics 2',
        nameAr: 'التعويضات المتحركة 2',
        icon: 'healing',
        colorKey: 'blue',
        category: 'Prosthodontics',
      ),
      SubjectModel(
        id: 'l3s1_pharmacology',
        level: 3,
        semester: 1,
        name: 'Pharmacology',
        nameAr: 'علم الأدوية',
        icon: 'medication',
        colorKey: 'purple',
        category: 'Pharmacology',
      ),
      SubjectModel(
        id: 'l3s1_fixed',
        level: 3,
        semester: 1,
        name: 'Fixed Prosthodontics 1',
        nameAr: 'التعويضات الثابتة 1',
        icon: 'build',
        colorKey: 'teal',
        category: 'Prosthodontics',
      ),
      SubjectModel(
        id: 'l3s1_endo',
        level: 3,
        semester: 1,
        name: 'Endodontics 1',
        nameAr: 'علاج الجذور 1',
        icon: 'medical_services',
        colorKey: 'amber',
        category: 'Endodontics',
      ),
      SubjectModel(
        id: 'l3s1_operative2',
        level: 3,
        semester: 1,
        name: 'Operative Dentistry 2',
        nameAr: 'طب الأسنان التشغيلي 2',
        icon: 'construction',
        colorKey: 'green',
        category: 'Operative',
      ),
      SubjectModel(
        id: 'l3s1_infection',
        level: 3,
        semester: 1,
        name: 'Infection Control in Dentistry',
        nameAr: 'مكافحة العدوى في طب الأسنان',
        icon: 'coronavirus',
        colorKey: 'rose',
        category: 'Infection Control',
      ),
      SubjectModel(
        id: 'l3s1_radiology',
        level: 3,
        semester: 1,
        name: 'Oral Radiology 1',
        nameAr: 'الأشعة الفموية 1',
        icon: 'radiology',
        colorKey: 'blue',
        category: 'Radiology',
      ),
      SubjectModel(
        id: 'l3s1_oral_surgery',
        level: 3,
        semester: 1,
        name: 'Oral Surgery 1',
        nameAr: 'جراحة الفم 1',
        icon: 'medical_services',
        colorKey: 'purple',
        category: 'Surgery',
      ),
      SubjectModel(
        id: 'l3s1_intro',
        level: 3,
        semester: 1,
        name: 'Introduction to Dentistry',
        nameAr: 'مقدمة في طب الأسنان',
        icon: 'local_hospital',
        colorKey: 'teal',
        category: 'Clinical Foundation',
      ),
      // Level 3 Semester 2
      SubjectModel(
        id: 'l3s2_oral_path2',
        level: 3,
        semester: 2,
        name: 'Oral Pathology 2',
        nameAr: 'أمراض الفم 2',
        icon: 'biotech',
        colorKey: 'rose',
        category: 'Pathology',
      ),
      SubjectModel(
        id: 'l3s2_removable3',
        level: 3,
        semester: 2,
        name: 'Removable Prosthodontics 3',
        nameAr: 'التعويضات المتحركة 3',
        icon: 'healing',
        colorKey: 'blue',
        category: 'Prosthodontics',
      ),
      SubjectModel(
        id: 'l3s2_fixed2',
        level: 3,
        semester: 2,
        name: 'Fixed Prosthodontics 2',
        nameAr: 'التعويضات الثابتة 2',
        icon: 'build',
        colorKey: 'green',
        category: 'Prosthodontics',
      ),
      SubjectModel(
        id: 'l3s2_oral_surgery2',
        level: 3,
        semester: 2,
        name: 'Oral Surgery 2',
        nameAr: 'جراحة الفم 2',
        icon: 'medical_services',
        colorKey: 'amber',
        category: 'Surgery',
      ),
      SubjectModel(
        id: 'l3s2_endo2',
        level: 3,
        semester: 2,
        name: 'Endodontics 2',
        nameAr: 'علاج الجذور 2',
        icon: 'medical_services',
        colorKey: 'purple',
        category: 'Endodontics',
      ),
      SubjectModel(
        id: 'l3s2_oral_diag',
        level: 3,
        semester: 2,
        name: 'Oral Diagnosis',
        nameAr: 'تشخيص أمراض الفم',
        icon: 'search',
        colorKey: 'teal',
        category: 'Diagnosis',
      ),
      SubjectModel(
        id: 'l3s2_surgery',
        level: 3,
        semester: 2,
        name: 'General Surgery',
        nameAr: 'الجراحة العامة',
        icon: 'medical_services',
        colorKey: 'rose',
        category: 'Surgery',
      ),
      SubjectModel(
        id: 'l3s2_medicine',
        level: 3,
        semester: 2,
        name: 'General Medicine',
        nameAr: 'الطب العام',
        icon: 'local_hospital',
        colorKey: 'blue',
        category: 'Medicine',
      ),
      SubjectModel(
        id: 'l3s2_radiology2',
        level: 3,
        semester: 2,
        name: 'Oral Radiology 2',
        nameAr: 'الأشعة الفموية 2',
        icon: 'radiology',
        colorKey: 'green',
        category: 'Radiology',
      ),
      SubjectModel(
        id: 'l3s2_ortho',
        level: 3,
        semester: 2,
        name: 'Orthodontics 1',
        nameAr: 'تقويم الأسنان 1',
        icon: 'straighten',
        colorKey: 'amber',
        category: 'Orthodontics',
      ),
      SubjectModel(
        id: 'l3s2_operative3',
        level: 3,
        semester: 2,
        name: 'Operative Dentistry 3',
        nameAr: 'طب الأسنان التشغيلي 3',
        icon: 'construction',
        colorKey: 'purple',
        category: 'Operative',
      ),
      SubjectModel(
        id: 'l3s2_perio',
        level: 3,
        semester: 2,
        name: 'Periodontics 1',
        nameAr: 'أمراض اللثة 1',
        icon: 'healing',
        colorKey: 'teal',
        category: 'Periodontics',
      ),
      SubjectModel(
        id: 'l3s2_pediatric',
        level: 3,
        semester: 2,
        name: 'Pediatric Dentistry 1',
        nameAr: 'طب أسنان الأطفال 1',
        icon: 'child_care',
        colorKey: 'rose',
        category: 'Pediatric',
      ),
      SubjectModel(
        id: 'l3s2_immunology',
        level: 3,
        semester: 2,
        name: 'Immunology',
        nameAr: 'المناعة',
        icon: 'vaccines',
        colorKey: 'blue',
        category: 'Immunology',
      ),
      // Level 4 Semester 1
      SubjectModel(
        id: 'l4s1_oral_surgery3',
        level: 4,
        semester: 1,
        name: 'Oral Surgery 3',
        nameAr: 'جراحة الفم 3',
        icon: 'medical_services',
        colorKey: 'rose',
        category: 'Surgery',
      ),
      SubjectModel(
        id: 'l4s1_oral_medicine',
        level: 4,
        semester: 1,
        name: 'Oral Medicine 1',
        nameAr: 'طب الفم 1',
        icon: 'local_hospital',
        colorKey: 'blue',
        category: 'Medicine',
      ),
      SubjectModel(
        id: 'l4s1_perio2',
        level: 4,
        semester: 1,
        name: 'Periodontics 2',
        nameAr: 'أمراض اللثة 2',
        icon: 'healing',
        colorKey: 'green',
        category: 'Periodontics',
      ),
      SubjectModel(
        id: 'l4s1_removable4',
        level: 4,
        semester: 1,
        name: 'Removable Prosthodontics 4',
        nameAr: 'التعويضات المتحركة 4',
        icon: 'healing',
        colorKey: 'amber',
        category: 'Prosthodontics',
      ),
      SubjectModel(
        id: 'l4s1_fixed3',
        level: 4,
        semester: 1,
        name: 'Fixed Prosthodontics 3',
        nameAr: 'التعويضات الثابتة 3',
        icon: 'build',
        colorKey: 'purple',
        category: 'Prosthodontics',
      ),
      SubjectModel(
        id: 'l4s1_endo3',
        level: 4,
        semester: 1,
        name: 'Endodontics 3',
        nameAr: 'علاج الجذور 3',
        icon: 'medical_services',
        colorKey: 'teal',
        category: 'Endodontics',
      ),
      SubjectModel(
        id: 'l4s1_pediatric2',
        level: 4,
        semester: 1,
        name: 'Pediatric Dentistry 2',
        nameAr: 'طب أسنان الأطفال 2',
        icon: 'child_care',
        colorKey: 'rose',
        category: 'Pediatric',
      ),
      SubjectModel(
        id: 'l4s1_ortho2',
        level: 4,
        semester: 1,
        name: 'Orthodontics 2',
        nameAr: 'تقويم الأسنان 2',
        icon: 'straighten',
        colorKey: 'blue',
        category: 'Orthodontics',
      ),
      SubjectModel(
        id: 'l4s1_preventive',
        level: 4,
        semester: 1,
        name: 'Preventive Dentistry 1',
        nameAr: 'طب الأسنان الوقائي 1',
        icon: 'shield',
        colorKey: 'green',
        category: 'Preventive',
      ),
      SubjectModel(
        id: 'l4s1_operative4',
        level: 4,
        semester: 1,
        name: 'Operative Dentistry 4',
        nameAr: 'طب الأسنان التشغيلي 4',
        icon: 'construction',
        colorKey: 'amber',
        category: 'Operative',
      ),
      SubjectModel(
        id: 'l4s1_intro',
        level: 4,
        semester: 1,
        name: 'Introduction to Dentistry',
        nameAr: 'مقدمة في طب الأسنان',
        icon: 'local_hospital',
        colorKey: 'purple',
        category: 'Clinical Foundation',
      ),
      // Level 4 Semester 2
      SubjectModel(
        id: 'l4s2_oral_surgery4',
        level: 4,
        semester: 2,
        name: 'Oral Surgery 4',
        nameAr: 'جراحة الفم 4',
        icon: 'medical_services',
        colorKey: 'rose',
        category: 'Surgery',
      ),
      SubjectModel(
        id: 'l4s2_oral_medicine2',
        level: 4,
        semester: 2,
        name: 'Oral Medicine 2',
        nameAr: 'طب الفم 2',
        icon: 'local_hospital',
        colorKey: 'blue',
        category: 'Medicine',
      ),
      SubjectModel(
        id: 'l4s2_perio3',
        level: 4,
        semester: 2,
        name: 'Periodontics 3',
        nameAr: 'أمراض اللثة 3',
        icon: 'healing',
        colorKey: 'teal',
        category: 'Periodontics',
      ),
      SubjectModel(
        id: 'l4s2_removable5',
        level: 4,
        semester: 2,
        name: 'Removable Prosthodontics 5',
        nameAr: 'التعويضات المتحركة 5',
        icon: 'healing',
        colorKey: 'green',
        category: 'Prosthodontics',
      ),
      SubjectModel(
        id: 'l4s2_fixed4',
        level: 4,
        semester: 2,
        name: 'Fixed Prosthodontics 4',
        nameAr: 'التعويضات الثابتة 4',
        icon: 'build',
        colorKey: 'amber',
        category: 'Prosthodontics',
      ),
      SubjectModel(
        id: 'l4s2_endo4',
        level: 4,
        semester: 2,
        name: 'Endodontics 4',
        nameAr: 'علاج الجذور 4',
        icon: 'medical_services',
        colorKey: 'purple',
        category: 'Endodontics',
      ),
      SubjectModel(
        id: 'l4s2_pediatric3',
        level: 4,
        semester: 2,
        name: 'Pediatric Dentistry 3',
        nameAr: 'طب أسنان الأطفال 3',
        icon: 'child_care',
        colorKey: 'rose',
        category: 'Pediatric',
      ),
      SubjectModel(
        id: 'l4s2_ortho3',
        level: 4,
        semester: 2,
        name: 'Orthodontics 3',
        nameAr: 'تقويم الأسنان 3',
        icon: 'straighten',
        colorKey: 'blue',
        category: 'Orthodontics',
      ),
      SubjectModel(
        id: 'l4s2_preventive2',
        level: 4,
        semester: 2,
        name: 'Preventive Dentistry 2',
        nameAr: 'طب الأسنان الوقائي 2',
        icon: 'shield',
        colorKey: 'green',
        category: 'Preventive',
      ),
    ];
  }

  List<QuestionModel> _seedQuestions() {
    final questions = <QuestionModel>[];

    // Helper to add MCQ + T/F for each subject
    void addQ(
      String subjectId,
      String subjectName,
      String mcqQ,
      List<String> opts,
      String correct,
      String mcqExp,
      String tfQ,
      bool tfAnswer,
      String tfExp,
    ) {
      questions.add(
        QuestionModel(
          id: '${subjectId}_mcq_1',
          subjectId: subjectId,
          subjectName: subjectName,
          type: 'mcq',
          question: mcqQ,
          options: opts,
          correctAnswer: correct,
          explanation: mcqExp,
          difficulty: 'medium',
          category: 'General',
          tags: [subjectName],
        ),
      );
      questions.add(
        QuestionModel(
          id: '${subjectId}_tf_1',
          subjectId: subjectId,
          subjectName: subjectName,
          type: 'true_false',
          question: tfQ,
          options: ['صح', 'خطأ'],
          correctAnswer: tfAnswer ? 'صح' : 'خطأ',
          explanation: tfExp,
          difficulty: 'easy',
          category: 'General',
          tags: [subjectName],
        ),
      );
    }

    addQ(
      'l1s1_dental_anatomy',
      'Dental Anatomy',
      'كم عدد الأسنان الدائمة في الفم البشري الطبيعي؟',
      ['28', '30', '32', '34'],
      '32',
      'عدد الأسنان الدائمة الطبيعية هو 32 سناً تشمل 4 أضراس عقل.',
      'الميناء هو أصلب نسيج في جسم الإنسان.',
      true,
      'الميناء (Enamel) هو الأصلب لاحتوائه على نسبة عالية من هيدروكسيباتيت.',
    );

    addQ(
      'l1s1_english',
      'English Language Skills',
      'Which word is a synonym for "difficult"?',
      ['Easy', 'Hard', 'Simple', 'Clear'],
      'Hard',
      'Hard is a synonym for difficult.',
      'Grammar is the study of sentence structure.',
      true,
      'Grammar deals with the rules governing the structure of sentences.',
    );

    addQ(
      'l1s1_arabic',
      'مهارات اللغة العربية',
      'ما هو جمع كلمة "كتاب"؟',
      ['كتابات', 'كتب', 'أكتب', 'مكتبة'],
      'كتب',
      'جمع كلمة كتاب هو كتب وهو جمع تكسير.',
      'الفعل المضارع يدل على الحال أو الاستقبال.',
      true,
      'الفعل المضارع يدل على حدث يقع في الحال أو المستقبل.',
    );

    addQ(
      'l1s1_islamic',
      'الثقافة الإسلامية',
      'كم عدد أركان الإسلام؟',
      ['3', '4', '5', '6'],
      '5',
      'أركان الإسلام خمسة: الشهادتان والصلاة والزكاة والصوم والحج.',
      'الزكاة ركن من أركان الإسلام.',
      true,
      'الزكاة هي الركن الثالث من أركان الإسلام.',
    );

    addQ(
      'l1s1_biochemistry',
      'Biochemistry',
      'ما الوظيفة الأساسية للإنزيمات؟',
      ['تخزين الطاقة', 'تسريع التفاعلات', 'نقل الأكسجين', 'بناء البروتينات'],
      'تسريع التفاعلات',
      'الإنزيمات تعمل كمحفزات حيوية تسرع التفاعلات بتقليل طاقة التنشيط.',
      'الإنزيمات تُستهلك في التفاعل الكيميائي.',
      false,
      'الإنزيمات لا تُستهلك في التفاعل بل تُعاد للاستخدام مرات عديدة.',
    );

    addQ(
      'l1s1_physics',
      'Medical Physics',
      'ما وحدة قياس الضغط في النظام الدولي؟',
      ['نيوتن', 'باسكال', 'جول', 'واط'],
      'باسكال',
      'وحدة قياس الضغط في النظام الدولي هي الباسكال (Pa).',
      'الصوت موجة ميكانيكية تحتاج وسطاً مادياً للانتشار.',
      true,
      'الصوت موجة ميكانيكية طولية تنتقل عبر الأوساط المادية.',
    );

    addQ(
      'l1s1_anatomy',
      'General Anatomy',
      'ما هو أكبر عضو في جسم الإنسان؟',
      ['الكبد', 'الجلد', 'الرئة', 'القلب'],
      'الجلد',
      'الجلد هو أكبر عضو في جسم الإنسان من حيث المساحة والوزن.',
      'الجسم البشري يحتوي على 206 عظمة في مرحلة البلوغ.',
      true,
      'يحتوي الجسم البشري البالغ على 206 عظمة.',
    );

    addQ(
      'l1s1_psychology',
      'Medical Psychology',
      'من هو مؤسس التحليل النفسي؟',
      ['يونغ', 'أدلر', 'فرويد', 'سكينر'],
      'فرويد',
      'سيغموند فرويد هو مؤسس التحليل النفسي.',
      'القلق استجابة طبيعية للتهديد.',
      true,
      'القلق استجابة طبيعية تساعد الجسم على التعامل مع المواقف الضاغطة.',
    );

    addQ(
      'l1s1_intro',
      'Introduction to Dentistry',
      'ما هو تخصص طب الأسنان الذي يعالج أمراض اللثة؟',
      ['Endodontics', 'Periodontics', 'Orthodontics', 'Prosthodontics'],
      'Periodontics',
      'Periodontics هو تخصص علاج أمراض اللثة والأنسجة الداعمة للأسنان.',
      'طب الأسنان التحفظي يهتم بعلاج تسوس الأسنان.',
      true,
      'طب الأسنان التحفظي أو التشغيلي يختص بعلاج تسوس الأسنان وترميمها.',
    );

    addQ(
      'l1s2_dental_anatomy2',
      'Dental Anatomy 2',
      'ما هو السطح الذي يواجه اللسان في الأسنان السفلية؟',
      ['Labial', 'Buccal', 'Lingual', 'Palatal'],
      'Lingual',
      'السطح اللساني (Lingual) هو السطح الذي يواجه اللسان في الأسنان السفلية.',
      'الأسنان الأمامية تُستخدم للقطع والتقطيع.',
      true,
      'الأسنان الأمامية (القواطع والأنياب) وظيفتها الأساسية القطع والتقطيع.',
    );

    addQ(
      'l1s2_english2',
      'English Language Skills 2',
      'What is the past tense of "go"?',
      ['Goed', 'Gone', 'Went', 'Going'],
      'Went',
      'The past tense of go is went (irregular verb).',
      'Reading improves vocabulary and comprehension.',
      true,
      'Regular reading helps expand vocabulary and improve reading comprehension.',
    );

    addQ(
      'l1s2_arabic2',
      'مهارات اللغة العربية',
      'ما هو المبتدأ في جملة "العلم نور"؟',
      ['نور', 'العلم', 'الجملة كلها', 'لا يوجد'],
      'العلم',
      'المبتدأ هو الاسم المرفوع في أول الجملة الاسمية وهو هنا "العلم".',
      'الخبر يكمل معنى المبتدأ في الجملة الاسمية.',
      true,
      'الخبر هو الجزء الذي يكمل معنى المبتدأ ويخبر عنه.',
    );

    addQ(
      'l1s2_computer',
      'Computer Skills',
      'ما هو اختصار نسخ النص في نظام Windows؟',
      ['Ctrl+V', 'Ctrl+X', 'Ctrl+C', 'Ctrl+Z'],
      'Ctrl+C',
      'Ctrl+C هو اختصار لوحة المفاتيح لنسخ النص في Windows.',
      'الإنترنت شبكة عالمية تربط ملايين الحواسيب.',
      true,
      'الإنترنت هي شبكة عالمية تربط ملايين الحواسيب حول العالم.',
    );

    addQ(
      'l1s2_biochemistry2',
      'Biochemistry 2',
      'ما هو المونومر الأساسي للبروتينات؟',
      ['الجلوكوز', 'الأحماض الأمينية', 'الأحماض الدهنية', 'النيوكليوتيدات'],
      'الأحماض الأمينية',
      'البروتينات تتكون من تسلسل أحماض أمينية مرتبطة بروابط ببتيدية.',
      'الـ DNA ثنائي الشريط بينما الـ RNA أحادي الشريط.',
      true,
      'DNA يتكون من شريطين ملتفين بينما RNA عادةً أحادي الشريط.',
    );

    addQ(
      'l1s2_communication',
      'Communication Skills',
      'ما هو أهم عنصر في التواصل الفعّال؟',
      ['الكلام', 'الاستماع', 'الكتابة', 'القراءة'],
      'الاستماع',
      'الاستماع الفعّال هو أهم عنصر في التواصل لأنه يضمن الفهم الصحيح.',
      'التواصل غير اللفظي يشمل لغة الجسد وتعابير الوجه.',
      true,
      'التواصل غير اللفظي يشمل الإيماءات وتعابير الوجه ولغة الجسد.',
    );

    addQ(
      'l1s2_histology',
      'General Histology',
      'ما هو النسيج الذي يغطي سطح الجسم والأعضاء الداخلية؟',
      ['النسيج الضام', 'النسيج الطلائي', 'النسيج العضلي', 'النسيج العصبي'],
      'النسيج الطلائي',
      'النسيج الطلائي يغطي سطح الجسم والأعضاء الداخلية ويبطن التجاويف.',
      'الخلايا العصبية تُسمى نيورونات.',
      true,
      'الوحدة الأساسية للجهاز العصبي هي الخلية العصبية أو النيورون.',
    );

    addQ(
      'l2s1_pathology',
      'General Pathology',
      'ما هي المرحلة الأولى في الاستجابة الالتهابية الحادة؟',
      [
        'تكاثر الخلايا',
        'توسع الأوعية الدموية',
        'تكوين النسيج الضام',
        'الإفراز الخلوي',
      ],
      'توسع الأوعية الدموية',
      'الاستجابة الالتهابية الحادة تبدأ بتوسع الأوعية الدموية مما يسبب الاحمرار والحرارة.',
      'الورم الحميد ينتشر إلى الأنسجة المجاورة.',
      false,
      'الورم الحميد لا ينتشر بل يبقى محاطاً بكبسولة.',
    );

    addQ(
      'l2s1_microbiology',
      'Microbiology',
      'ما هو الفيروس المسبب لمرض الإيدز؟',
      ['HBV', 'HIV', 'HPV', 'HSV'],
      'HIV',
      'فيروس نقص المناعة البشرية (HIV) هو المسبب لمرض الإيدز.',
      'البكتيريا كائنات وحيدة الخلية بدائية النواة.',
      true,
      'البكتيريا كائنات وحيدة الخلية تفتقر إلى نواة حقيقية (بدائية النواة).',
    );

    addQ(
      'l2s1_physiology',
      'Human Physiology',
      'ما هو معدل ضربات القلب الطبيعي في الدقيقة للبالغين؟',
      ['40-60', '60-100', '100-120', '120-140'],
      '60-100',
      'معدل ضربات القلب الطبيعي للبالغين يتراوح بين 60 و100 ضربة في الدقيقة.',
      'الرئتان مسؤولتان عن تبادل الغازات في الجسم.',
      true,
      'الرئتان تقومان بتبادل الأكسجين وثاني أكسيد الكربون بين الدم والهواء.',
    );

    addQ(
      'l2s1_biochemistry',
      'Biochemistry',
      'في أي عضية تحدث عملية التنفس الخلوي؟',
      ['النواة', 'الميتوكوندريا', 'الريبوسوم', 'الشبكة الإندوبلازمية'],
      'الميتوكوندريا',
      'الميتوكوندريا هي موقع التنفس الخلوي وإنتاج ATP.',
      'الكلوروفيل مسؤول عن اللون الأخضر في النباتات.',
      true,
      'الكلوروفيل هو الصبغة الخضراء المسؤولة عن امتصاص الضوء في عملية التمثيل الضوئي.',
    );

    addQ(
      'l2s1_psychology',
      'Medical Psychology',
      'ما هو نوع الذاكرة التي تخزن المعلومات لفترة قصيرة؟',
      [
        'الذاكرة طويلة المدى',
        'الذاكرة الحسية',
        'الذاكرة قصيرة المدى',
        'الذاكرة الإجرائية',
      ],
      'الذاكرة قصيرة المدى',
      'الذاكرة قصيرة المدى تخزن المعلومات لفترة وجيزة (ثوانٍ إلى دقائق).',
      'الإجهاد المزمن يؤثر سلباً على الصحة الجسدية.',
      true,
      'الإجهاد المزمن يمكن أن يؤدي إلى أمراض القلب وضعف المناعة وغيرها.',
    );

    addQ(
      'l2s1_immunology',
      'Immunology',
      'ما هو نوع الخلايا المسؤولة عن إنتاج الأجسام المضادة؟',
      [
        'الخلايا التائية',
        'الخلايا البائية',
        'الخلايا القاتلة الطبيعية',
        'الضامة',
      ],
      'الخلايا البائية',
      'الخلايا البائية (B cells) هي المسؤولة عن إنتاج الأجسام المضادة.',
      'اللقاحات تعمل عن طريق تحفيز الجهاز المناعي.',
      true,
      'اللقاحات تحفز الجهاز المناعي لإنتاج أجسام مضادة دون التسبب في المرض.',
    );

    addQ(
      'l2s1_dental_material',
      'Dental Material I',
      'ما هو المادة الأكثر استخداماً في حشوات الأسنان الخلفية؟',
      ['الذهب', 'الأمالغم', 'الكومبوزيت', 'السيراميك'],
      'الأمالغم',
      'الأمالغم كان تاريخياً الأكثر استخداماً في الحشوات الخلفية لمتانته.',
      'الكومبوزيت مادة حشو تشبه لون الأسنان الطبيعي.',
      true,
      'الكومبوزيت (Composite Resin) مادة حشو بلون الأسنان تُستخدم للحشوات الجمالية.',
    );

    addQ(
      'l2s1_oral_histo',
      'Oral Histology and Embryology 1',
      'من أي طبقة جنينية يتطور الميناء؟',
      ['الأديم الباطن', 'الأديم المتوسط', 'الأديم الظاهر', 'الأديم العصبي'],
      'الأديم الظاهر',
      'الميناء يتطور من الأديم الظاهر (Ectoderm) عبر خلايا الأملوبلاست.',
      'العاج يتطور من الأديم المتوسط.',
      true,
      'العاج يتطور من الأديم المتوسط (Mesoderm) عبر خلايا الأودونتوبلاست.',
    );

    addQ(
      'l2s2_ethics',
      'Medical Ethics',
      'ما هو المبدأ الأخلاقي الذي يقضي بعدم إيذاء المريض؟',
      ['الاستقلالية', 'العدالة', 'عدم الإيذاء', 'الإحسان'],
      'عدم الإيذاء',
      'مبدأ عدم الإيذاء (Non-maleficence) يقضي بعدم التسبب في ضرر للمريض.',
      'الموافقة المستنيرة حق أساسي للمريض.',
      true,
      'الموافقة المستنيرة تعني أن يوافق المريض على العلاج بعد فهم كامل للمعلومات.',
    );

    addQ(
      'l2s2_surgery',
      'General Surgery',
      'ما هو أول إجراء في علاج الجروح؟',
      ['الخياطة', 'التضميد', 'التنظيف والتعقيم', 'إعطاء المضادات الحيوية'],
      'التنظيف والتعقيم',
      'أول خطوة في علاج الجروح هي التنظيف والتعقيم لمنع العدوى.',
      'الجراحة المفتوحة أقل خطورة من الجراحة بالمنظار.',
      false,
      'الجراحة بالمنظار عموماً أقل خطورة وأسرع تعافياً من الجراحة المفتوحة.',
    );

    addQ(
      'l2s2_physiology2',
      'Human Physiology II',
      'ما هو الهرمون المسؤول عن تنظيم مستوى السكر في الدم؟',
      ['الأدرينالين', 'الأنسولين', 'الكورتيزول', 'الثيروكسين'],
      'الأنسولين',
      'الأنسولين هو الهرمون الرئيسي المسؤول عن خفض مستوى السكر في الدم.',
      'الكلى تصفي الدم وتنتج البول.',
      true,
      'الكلى تقوم بتصفية الدم وإزالة الفضلات وإنتاج البول.',
    );

    addQ(
      'l2s2_medicine',
      'General Medicine',
      'ما هو الضغط الطبيعي للدم؟',
      ['100/60', '120/80', '140/90', '160/100'],
      '120/80',
      'الضغط الطبيعي للدم هو 120/80 ملم زئبق.',
      'السكري من النوع الثاني يرتبط بمقاومة الأنسولين.',
      true,
      'السكري من النوع الثاني يتميز بمقاومة الخلايا للأنسولين.',
    );

    addQ(
      'l2s2_operative',
      'Operative Dentistry 1',
      'ما هو تصنيف Black للتجاويف الموجودة في الأسطح التقريبية للأسنان الأمامية؟',
      ['Class I', 'Class II', 'Class III', 'Class IV'],
      'Class III',
      'Class III هي التجاويف الموجودة في الأسطح التقريبية للأسنان الأمامية دون إصابة الحافة القاطعة.',
      'تسوس الأسنان يسببه تراكم البلاك البكتيري.',
      true,
      'تسوس الأسنان ناتج عن تراكم البلاك البكتيري الذي ينتج أحماضاً تذيب الميناء.',
    );

    addQ(
      'l2s2_removable',
      'Removable Prosthodontics 1',
      'ما هو الغرض الأساسي من الطقم الكامل؟',
      [
        'الجمال فقط',
        'استعادة الوظيفة والجمال',
        'منع تآكل العظم فقط',
        'تحسين النطق فقط',
      ],
      'استعادة الوظيفة والجمال',
      'الطقم الكامل يهدف إلى استعادة وظيفة المضغ والجمال وتحسين النطق.',
      'الطقم المتحرك يمكن إخراجه من الفم للتنظيف.',
      true,
      'من مميزات الطقم المتحرك إمكانية إخراجه للتنظيف الجيد.',
    );

    addQ(
      'l2s2_dental_material2',
      'Dental Material II',
      'ما هو مكون الأمالغم الرئيسي؟',
      ['الذهب', 'الزئبق', 'الفضة', 'النحاس'],
      'الزئبق',
      'الأمالغم يتكون أساساً من الزئبق مع مسحوق سبيكة من الفضة والقصدير والنحاس.',
      'الزنك أوكسيد يوجينول يُستخدم كمادة مؤقتة في طب الأسنان.',
      true,
      'ZOE (Zinc Oxide Eugenol) يُستخدم كحشوة مؤقتة ومادة قاعدية في طب الأسنان.',
    );

    addQ(
      'l2s2_oral_histo2',
      'Oral Histology and Embryology 2',
      'ما هو اسم الغشاء الذي يغطي جذر السن؟',
      ['Enamel', 'Dentin', 'Cementum', 'Pulp'],
      'Cementum',
      'الأسمنت (Cementum) هو النسيج الذي يغطي جذر السن ويربطه بالعظم.',
      'اللب السني يحتوي على أوعية دموية وأعصاب.',
      true,
      'اللب السني (Dental Pulp) يحتوي على أوعية دموية وأعصاب وخلايا أودونتوبلاست.',
    );

    addQ(
      'l3s1_oral_path',
      'Oral Pathology 1',
      'ما هو أكثر أنواع سرطان الفم شيوعاً؟',
      ['Adenocarcinoma', 'Squamous Cell Carcinoma', 'Melanoma', 'Lymphoma'],
      'Squamous Cell Carcinoma',
      'سرطان الخلايا الحرشفية (SCC) هو أكثر أنواع سرطان الفم شيوعاً.',
      'التدخين عامل خطر رئيسي لسرطان الفم.',
      true,
      'التدخين يزيد خطر الإصابة بسرطان الفم بشكل كبير.',
    );

    addQ(
      'l3s1_removable2',
      'Removable Prosthodontics 2',
      'ما هو الخطاف الأكثر استخداماً في التعويضات الجزئية المتحركة؟',
      ['Continuous clasp', 'Akers clasp', 'Ring clasp', 'Back action clasp'],
      'Akers clasp',
      'خطاف Akers هو الأكثر استخداماً لبساطته وفعاليته.',
      'التعويض الجزئي المتحرك يعتمد على الأسنان المتبقية للدعم.',
      true,
      'التعويض الجزئي المتحرك يستخدم الأسنان الطبيعية المتبقية كدعامات.',
    );

    addQ(
      'l3s1_pharmacology',
      'Pharmacology',
      'ما هو المضاد الحيوي الأول الذي تم اكتشافه؟',
      ['الأموكسيسيلين', 'البنسلين', 'الإريثروميسين', 'التتراسيكلين'],
      'البنسلين',
      'البنسلين هو أول مضاد حيوي تم اكتشافه بواسطة ألكسندر فليمنج عام 1928.',
      'المضادات الحيوية فعّالة ضد الفيروسات.',
      false,
      'المضادات الحيوية فعّالة فقط ضد البكتيريا وليس الفيروسات.',
    );

    addQ(
      'l3s1_fixed',
      'Fixed Prosthodontics 1',
      'ما هو الغرض من التاج الدائم؟',
      [
        'تبييض الأسنان',
        'حماية السن التالف واستعادة شكله',
        'علاج اللثة',
        'تقويم الأسنان',
      ],
      'حماية السن التالف واستعادة شكله',
      'التاج الدائم يحمي السن التالف ويستعيد شكله ووظيفته.',
      'الجسر الثابت يستخدم لاستبدال سن مفقود.',
      true,
      'الجسر الثابت يعتمد على الأسنان المجاورة لاستبدال السن المفقود.',
    );

    addQ(
      'l3s1_endo',
      'Endodontics 1',
      'ما هو الهدف الرئيسي من علاج قناة الجذر؟',
      [
        'إزالة السن',
        'إزالة اللب المصاب وتعقيم القناة',
        'تبييض السن',
        'تقوية الجذر',
      ],
      'إزالة اللب المصاب وتعقيم القناة',
      'علاج قناة الجذر يهدف إلى إزالة اللب المصاب وتعقيم القناة وإغلاقها.',
      'ألم السن الحاد المستمر قد يشير إلى التهاب اللب.',
      true,
      'الألم الحاد المستمر في السن يشير إلى التهاب اللب (Pulpitis) الذي يستلزم علاج القناة.',
    );

    addQ(
      'l3s1_operative2',
      'Operative Dentistry 2',
      'ما هو الغرض من استخدام الرابط (Bonding Agent) في الحشوات الكومبوزيت؟',
      ['تلوين الحشوة', 'تحسين الالتصاق بالسن', 'تصلب الحشوة', 'تعقيم التجويف'],
      'تحسين الالتصاق بالسن',
      'الرابط يحسن الالتصاق بين مادة الكومبوزيت وأنسجة السن.',
      'الحفر الحمضي يزيد من مساحة سطح الميناء لتحسين الالتصاق.',
      true,
      'الحفر الحمضي يخشن سطح الميناء مما يزيد مساحة الالتصاق للرابط والكومبوزيت.',
    );

    addQ(
      'l3s1_infection',
      'Infection Control in Dentistry',
      'ما هو أهم إجراء للوقاية من انتقال العدوى في عيادة الأسنان؟',
      [
        'ارتداء القفازات فقط',
        'غسل اليدين',
        'استخدام الكمامة فقط',
        'تعقيم الأدوات فقط',
      ],
      'غسل اليدين',
      'غسل اليدين هو أهم إجراء للوقاية من انتقال العدوى.',
      'التعقيم بالأوتوكلاف يقضي على جميع الكائنات الدقيقة بما فيها الأبواغ.',
      true,
      'الأوتوكلاف يستخدم البخار تحت ضغط عالٍ للقضاء على جميع الكائنات الدقيقة بما فيها الأبواغ.',
    );

    addQ(
      'l3s1_radiology',
      'Oral Radiology 1',
      'ما هو نوع الأشعة الأكثر استخداماً في طب الأسنان؟',
      ['أشعة جاما', 'أشعة X', 'أشعة فوق البنفسجية', 'أشعة تحت الحمراء'],
      'أشعة X',
      'أشعة X هي الأكثر استخداماً في طب الأسنان للتشخيص.',
      'الأشعة البانورامية تُظهر الفكين كاملاً في صورة واحدة.',
      true,
      'الأشعة البانورامية (OPG) تُظهر الفكين العلوي والسفلي والأسنان في صورة واحدة.',
    );

    addQ(
      'l3s1_oral_surgery',
      'Oral Surgery 1',
      'ما هو الموضع الصحيح لحقن التخدير الموضعي لخلع الضرس السفلي؟',
      ['العصب الوجني', 'العصب السنخي السفلي', 'العصب الحنكي', 'العصب الشدقي'],
      'العصب السنخي السفلي',
      'تخدير العصب السنخي السفلي (Inferior Alveolar Nerve Block) يُستخدم لخلع الأسنان السفلية.',
      'الخلع هو آخر خيار علاجي للأسنان.',
      true,
      'يجب استنفاد جميع الخيارات العلاجية قبل اللجوء إلى الخلع.',
    );

    addQ(
      'l3s1_intro',
      'Introduction to Dentistry',
      'ما هو عدد التخصصات الرئيسية المعترف بها في طب الأسنان؟',
      ['5', '7', '9', '11'],
      '9',
      'هناك 9 تخصصات رئيسية معترف بها في طب الأسنان من قبل ADA.',
      'طب الأسنان التجميلي تخصص معترف به رسمياً من ADA.',
      false,
      'طب الأسنان التجميلي ليس تخصصاً معترفاً به رسمياً من ADA.',
    );

    addQ(
      'l3s2_oral_path2',
      'Oral Pathology 2',
      'ما هو الكيس الأكثر شيوعاً في الفكين؟',
      ['Dentigerous cyst', 'Radicular cyst', 'Keratocyst', 'Nasopalatine cyst'],
      'Radicular cyst',
      'الكيس الجذري (Radicular Cyst) هو الأكثر شيوعاً في الفكين وينشأ من بقايا Malassez.',
      'الكيس الجذري يرتبط بسن غير حيوي.',
      true,
      'الكيس الجذري ينشأ عند قمة جذر سن غير حيوي (ميت).',
    );

    addQ(
      'l3s2_removable3',
      'Removable Prosthodontics 3',
      'ما هو الغرض من الحافة الوظيفية في الطقم الكامل؟',
      ['الجمال', 'الثبات والاحتجاز', 'الراحة فقط', 'سهولة التنظيف'],
      'الثبات والاحتجاز',
      'الحافة الوظيفية تساهم في ثبات الطقم الكامل واحتجازه في مكانه.',
      'الطقم الكامل يجب أن يُنظف يومياً.',
      true,
      'يجب تنظيف الطقم الكامل يومياً لمنع تراكم البكتيريا والفطريات.',
    );

    addQ(
      'l3s2_fixed2',
      'Fixed Prosthodontics 2',
      'ما هو أفضل مادة لصنع التيجان الجمالية الأمامية؟',
      ['الذهب', 'الأمالغم', 'السيراميك الكامل', 'الأكريليك'],
      'السيراميك الكامل',
      'السيراميك الكامل يوفر أفضل نتيجة جمالية للتيجان الأمامية.',
      'التيجان المعدنية الخزفية تجمع بين القوة والجمال.',
      true,
      'التيجان المعدنية الخزفية (PFM) توفر قوة المعدن مع جمال الخزف.',
    );

    addQ(
      'l3s2_oral_surgery2',
      'Oral Surgery 2',
      'ما هو أكثر مضاعفات خلع الأسنان شيوعاً؟',
      ['كسر الفك', 'السنخ الجاف', 'النزيف الشديد', 'التهاب العظم'],
      'السنخ الجاف',
      'السنخ الجاف (Dry Socket/Alveolar Osteitis) هو أكثر مضاعفات الخلع شيوعاً.',
      'التدخين يزيد خطر الإصابة بالسنخ الجاف.',
      true,
      'التدخين يعيق تكوين الجلطة ويزيد خطر الإصابة بالسنخ الجاف.',
    );

    addQ(
      'l3s2_endo2',
      'Endodontics 2',
      'ما هو المادة الأكثر استخداماً لحشو قناة الجذر؟',
      ['الأمالغم', 'الكومبوزيت', 'الجوتابيركا', 'الأسمنت الزجاجي'],
      'الجوتابيركا',
      'الجوتابيركا (Gutta-percha) هي المادة الأكثر استخداماً لحشو قناة الجذر.',
      'قياس طول القناة ضروري قبل حشوها.',
      true,
      'قياس طول العمل (Working Length) ضروري لضمان حشو القناة بالكامل دون تجاوز القمة.',
    );

    addQ(
      'l3s2_oral_diag',
      'Oral Diagnosis',
      'ما هو أول خطوة في التشخيص السريري؟',
      [
        'الفحص بالأشعة',
        'أخذ التاريخ المرضي',
        'الفحص السريري',
        'الفحوصات المخبرية',
      ],
      'أخذ التاريخ المرضي',
      'أخذ التاريخ المرضي هو أول خطوة في التشخيص السريري.',
      'الفحص خارج الفم يسبق الفحص داخل الفم.',
      true,
      'يجب إجراء الفحص خارج الفم أولاً ثم الانتقال إلى الفحص داخل الفم.',
    );

    addQ(
      'l3s2_surgery',
      'General Surgery',
      'ما هو الغرض من الصرف الجراحي؟',
      [
        'تسريع الشفاء',
        'إزالة السوائل والقيح من الجرح',
        'تجميل الجرح',
        'منع النزيف',
      ],
      'إزالة السوائل والقيح من الجرح',
      'الصرف الجراحي يهدف إلى إزالة السوائل والقيح لمنع تراكمها وتسهيل الشفاء.',
      'الخياطة الأولية تُجرى مباشرة بعد الجرح.',
      true,
      'الخياطة الأولية (Primary Closure) تُجرى مباشرة بعد الجرح النظيف.',
    );

    addQ(
      'l3s2_medicine',
      'General Medicine',
      'ما هو العلاج الأول لنوبة الربو الحادة؟',
      [
        'الكورتيزون',
        'موسعات الشعب الهوائية',
        'المضادات الحيوية',
        'مضادات الهيستامين',
      ],
      'موسعات الشعب الهوائية',
      'موسعات الشعب الهوائية (Bronchodilators) هي العلاج الأول لنوبة الربو الحادة.',
      'الربو مرض مزمن يصيب الجهاز التنفسي.',
      true,
      'الربو مرض التهابي مزمن يصيب الشعب الهوائية ويسبب ضيق التنفس.',
    );

    addQ(
      'l3s2_radiology2',
      'Oral Radiology 2',
      'ما هو نوع الأشعة المستخدمة في CBCT؟',
      [
        'أشعة X تقليدية',
        'أشعة X مخروطية الشعاع',
        'الرنين المغناطيسي',
        'الموجات فوق الصوتية',
      ],
      'أشعة X مخروطية الشعاع',
      'CBCT (Cone Beam CT) يستخدم أشعة X مخروطية الشعاع لإنتاج صور ثلاثية الأبعاد.',
      'CBCT يوفر صوراً ثلاثية الأبعاد للفكين والأسنان.',
      true,
      'CBCT يوفر صوراً ثلاثية الأبعاد دقيقة تُستخدم في زراعة الأسنان وعلاج القنوات وغيرها.',
    );

    addQ(
      'l3s2_ortho',
      'Orthodontics 1',
      'ما هو الهدف الرئيسي من تقويم الأسنان؟',
      [
        'تبييض الأسنان',
        'تصحيح الإطباق وتحسين الجمال',
        'علاج اللثة',
        'تقوية الأسنان',
      ],
      'تصحيح الإطباق وتحسين الجمال',
      'تقويم الأسنان يهدف إلى تصحيح الإطباق وتحسين الجمال والوظيفة.',
      'تقويم الأسنان يمكن تطبيقه في أي عمر.',
      true,
      'يمكن تطبيق تقويم الأسنان في أي عمر وإن كان أكثر فعالية في مرحلة النمو.',
    );

    addQ(
      'l3s2_operative3',
      'Operative Dentistry 3',
      'ما هو الغرض من استخدام الحاجز المطاطي (Rubber Dam)؟',
      ['تجميل الإجراء', 'عزل السن عن الرطوبة', 'تخدير المريض', 'تسريع العمل'],
      'عزل السن عن الرطوبة',
      'الحاجز المطاطي يعزل السن عن الرطوبة والريق لضمان نجاح الإجراء.',
      'الحاجز المطاطي إلزامي في علاج قناة الجذر.',
      true,
      'الحاجز المطاطي إلزامي في علاج قناة الجذر لمنع تلوث القناة بالريق.',
    );

    addQ(
      'l3s2_perio',
      'Periodontics 1',
      'ما هو أول علامة لالتهاب اللثة؟',
      ['تراجع اللثة', 'نزيف اللثة', 'تحرك الأسنان', 'ألم شديد'],
      'نزيف اللثة',
      'نزيف اللثة عند التنظيف هو أول علامة لالتهاب اللثة.',
      'التهاب اللثة قابل للعكس إذا عولج مبكراً.',
      true,
      'التهاب اللثة البسيط (Gingivitis) قابل للعكس بالتنظيف الجيد والعلاج المبكر.',
    );

    addQ(
      'l3s2_pediatric',
      'Pediatric Dentistry 1',
      'ما هو عدد الأسنان اللبنية؟',
      ['16', '18', '20', '24'],
      '20',
      'عدد الأسنان اللبنية هو 20 سناً: 8 قواطع و4 أنياب و8 أضراس.',
      'الأسنان اللبنية تبدأ في الظهور عند عمر 6 أشهر تقريباً.',
      true,
      'تبدأ الأسنان اللبنية في الظهور عادةً بين 6-8 أشهر من عمر الطفل.',
    );

    addQ(
      'l3s2_immunology',
      'Immunology',
      'ما هو نوع المناعة التي تنتقل من الأم إلى الجنين عبر المشيمة؟',
      [
        'المناعة الفعّالة',
        'المناعة السلبية',
        'المناعة الخلوية',
        'المناعة الذاتية',
      ],
      'المناعة السلبية',
      'المناعة السلبية تنتقل من الأم إلى الجنين عبر المشيمة على شكل أجسام مضادة IgG.',
      'اللقاحات تُحفز المناعة الفعّالة.',
      true,
      'اللقاحات تحفز الجهاز المناعي لإنتاج أجسام مضادة خاصة (مناعة فعّالة).',
    );

    addQ(
      'l4s1_oral_surgery3',
      'Oral Surgery 3',
      'ما هو الإجراء المستخدم لإزالة الكيس الفكي؟',
      ['Extraction', 'Enucleation', 'Apicoectomy', 'Curettage'],
      'Enucleation',
      'Enucleation هو الإجراء الجراحي لإزالة الكيس بالكامل من العظم.',
      'الخراج السني يحتاج إلى صرف وعلاج بالمضادات الحيوية.',
      true,
      'الخراج السني يُعالج بالصرف الجراحي والمضادات الحيوية المناسبة.',
    );

    addQ(
      'l4s1_oral_medicine',
      'Oral Medicine 1',
      'ما هو أكثر أمراض الفم الحويصلية شيوعاً؟',
      ['Pemphigus', 'Herpes Simplex', 'Lichen Planus', 'Aphthous Ulcer'],
      'Herpes Simplex',
      'الهربس البسيط (Herpes Simplex) هو أكثر أمراض الفم الحويصلية شيوعاً.',
      'القرحة الآفثية (Aphthous Ulcer) مؤلمة لكنها حميدة وتشفى تلقائياً.',
      true,
      'القرحة الآفثية مؤلمة وتشفى عادةً في 7-14 يوماً دون علاج.',
    );

    addQ(
      'l4s1_perio2',
      'Periodontics 2',
      'ما هو العلاج الأساسي لالتهاب اللثة؟',
      [
        'الجراحة',
        'التنظيف الاحترافي وتعليم النظافة',
        'المضادات الحيوية',
        'الخلع',
      ],
      'التنظيف الاحترافي وتعليم النظافة',
      'التنظيف الاحترافي (Scaling) وتعليم النظافة الفموية هو العلاج الأساسي لالتهاب اللثة.',
      'التدخين يؤثر سلباً على صحة اللثة.',
      true,
      'التدخين يقلل تدفق الدم إلى اللثة ويضعف الاستجابة المناعية مما يزيد خطر أمراض اللثة.',
    );

    addQ(
      'l4s1_removable4',
      'Removable Prosthodontics 4',
      'ما هو الغرض من تسجيل الإطباق في صنع الطقم الكامل؟',
      [
        'تحديد لون الأسنان',
        'تحديد العلاقة بين الفكين',
        'قياس حجم الفم',
        'تحديد شكل الأسنان',
      ],
      'تحديد العلاقة بين الفكين',
      'تسجيل الإطباق يحدد العلاقة الصحيحة بين الفكين لضمان إطباق صحيح.',
      'الطقم الكامل يُصنع في المختبر السني.',
      true,
      'الطقم الكامل يُصنع في المختبر السني بناءً على البصمات والقياسات المأخوذة من المريض.',
    );

    addQ(
      'l4s1_fixed3',
      'Fixed Prosthodontics 3',
      'ما هو الغرض من الطبقة الانتقالية (Die Spacer) في صنع التيجان؟',
      ['تلوين التاج', 'توفير مساحة للأسمنت', 'تقوية التاج', 'تحسين الجمال'],
      'توفير مساحة للأسمنت',
      'Die Spacer يوفر مساحة كافية لطبقة الأسمنت بين التاج والسن.',
      'التاج المؤقت يحمي السن المحضّر أثناء انتظار التاج الدائم.',
      true,
      'التاج المؤقت يحمي السن المحضّر ويحافظ على الجمال والوظيفة أثناء صنع التاج الدائم.',
    );

    addQ(
      'l4s1_endo3',
      'Endodontics 3',
      'ما هو الغرض من إعادة علاج قناة الجذر؟',
      [
        'تحسين الجمال',
        'معالجة الفشل السابق وإزالة العدوى',
        'تقوية الجذر',
        'تبييض السن',
      ],
      'معالجة الفشل السابق وإزالة العدوى',
      'إعادة العلاج تهدف إلى معالجة فشل العلاج السابق وإزالة العدوى المتبقية.',
      'الفشل في علاج القناة يظهر أحياناً بعد سنوات.',
      true,
      'فشل علاج القناة قد يظهر بعد سنوات على شكل خراج أو كيس حول قمة الجذر.',
    );

    addQ(
      'l4s1_pediatric2',
      'Pediatric Dentistry 2',
      'ما هو علاج تسوس الأسنان اللبنية الشديد في الأطفال الصغار؟',
      ['الخلع فقط', 'علاج قناة الجذر اللبني', 'المراقبة فقط', 'الحشو المؤقت'],
      'علاج قناة الجذر اللبني',
      'علاج قناة الجذر اللبني (Pulpotomy/Pulpectomy) يُستخدم لعلاج تسوس الأسنان اللبنية الشديد.',
      'الأسنان اللبنية مهمة للحفاظ على المسافة للأسنان الدائمة.',
      true,
      'الأسنان اللبنية تحافظ على المسافة اللازمة لبزوغ الأسنان الدائمة بشكل صحيح.',
    );

    addQ(
      'l4s1_ortho2',
      'Orthodontics 2',
      'ما هو الفرق بين التقويم الثابت والمتحرك؟',
      [
        'السعر فقط',
        'الثابت لا يمكن إزالته والمتحرك يمكن إزالته',
        'الثابت للأطفال والمتحرك للبالغين',
        'لا فرق',
      ],
      'الثابت لا يمكن إزالته والمتحرك يمكن إزالته',
      'التقويم الثابت ملصق بالأسنان ولا يمكن إزالته بينما المتحرك يمكن إزالته.',
      'الأسلاك التقويمية تولد قوى لتحريك الأسنان.',
      true,
      'الأسلاك التقويمية تولد قوى خفيفة ومستمرة تحرك الأسنان إلى مواضعها الصحيحة.',
    );

    addQ(
      'l4s1_preventive',
      'Preventive Dentistry 1',
      'ما هو أفضل طريقة للوقاية من تسوس الأسنان؟',
      [
        'تناول الأدوية',
        'تنظيف الأسنان بالفرشاة والخيط',
        'تجنب الطعام',
        'الفلورايد فقط',
      ],
      'تنظيف الأسنان بالفرشاة والخيط',
      'تنظيف الأسنان بالفرشاة والخيط بانتظام هو أفضل طريقة للوقاية من التسوس.',
      'الفلورايد يقوي الميناء ويقاوم التسوس.',
      true,
      'الفلورايد يقوي بلورات الهيدروكسيباتيت في الميناء ويجعلها أكثر مقاومة للأحماض.',
    );

    addQ(
      'l4s1_operative4',
      'Operative Dentistry 4',
      'ما هو الغرض من الطبقة القاعدية (Base) في الحشوات؟',
      [
        'تلوين الحشوة',
        'حماية اللب من الحرارة والمواد الكيميائية',
        'تحسين الالتصاق',
        'تسريع الشفاء',
      ],
      'حماية اللب من الحرارة والمواد الكيميائية',
      'الطبقة القاعدية تحمي اللب من التأثيرات الحرارية والكيميائية للحشوة.',
      'الحشوات العميقة تحتاج إلى طبقة قاعدية لحماية اللب.',
      true,
      'الحشوات العميقة القريبة من اللب تحتاج إلى طبقة قاعدية لحمايته.',
    );

    addQ(
      'l4s1_intro',
      'Introduction to Dentistry',
      'ما هو دور طبيب الأسنان في الصحة العامة؟',
      [
        'علاج الأسنان فقط',
        'الوقاية والتشخيص والعلاج والتثقيف الصحي',
        'الجراحة فقط',
        'التجميل فقط',
      ],
      'الوقاية والتشخيص والعلاج والتثقيف الصحي',
      'دور طبيب الأسنان شامل يتضمن الوقاية والتشخيص والعلاج والتثقيف الصحي.',
      'صحة الفم جزء لا يتجزأ من الصحة العامة.',
      true,
      'صحة الفم مرتبطة ارتباطاً وثيقاً بالصحة العامة وتؤثر على جودة الحياة.',
    );

    addQ(
      'l4s2_oral_surgery4',
      'Oral Surgery 4',
      'ما هو الإجراء الجراحي لعلاج الكيس الجذري الكبير؟',
      ['Extraction only', 'Marsupialization', 'Curettage only', 'Observation'],
      'Marsupialization',
      'Marsupialization تُستخدم للأكياس الكبيرة لتقليل حجمها قبل الإزالة الكاملة.',
      'زراعة الأسنان تعتبر أفضل بديل للأسنان المفقودة.',
      true,
      'زراعة الأسنان توفر بديلاً دائماً ووظيفياً للأسنان المفقودة.',
    );

    addQ(
      'l4s2_oral_medicine2',
      'Oral Medicine 2',
      'ما هو العلاج الأول للقلاع الفموي (Oral Thrush)؟',
      ['المضادات الحيوية', 'مضادات الفطريات', 'الكورتيزون', 'مضادات الفيروسات'],
      'مضادات الفطريات',
      'القلاع الفموي تسببه فطريات Candida ويُعالج بمضادات الفطريات كالنيستاتين.',
      'القلاع الفموي أكثر شيوعاً عند المرضى ضعيفي المناعة.',
      true,
      'القلاع الفموي أكثر شيوعاً عند المرضى ضعيفي المناعة كمرضى السكري ومرضى الإيدز.',
    );

    addQ(
      'l4s2_perio3',
      'Periodontics 3',
      'ما هو الهدف من جراحة اللثة؟',
      [
        'تحسين الجمال فقط',
        'إزالة الجيوب اللثوية العميقة وتحسين الوصول للتنظيف',
        'تقوية الأسنان',
        'علاج التسوس',
      ],
      'إزالة الجيوب اللثوية العميقة وتحسين الوصول للتنظيف',
      'جراحة اللثة تهدف إلى إزالة الجيوب العميقة وتحسين الوصول للتنظيف.',
      'الجيوب اللثوية العميقة تشير إلى تقدم مرض اللثة.',
      true,
      'الجيوب اللثوية العميقة (أكثر من 4 مم) تشير إلى تقدم مرض اللثة وفقدان العظم الداعم.',
    );

    addQ(
      'l4s2_removable5',
      'Removable Prosthodontics 5',
      'ما هو الغرض من إعادة تبطين الطقم (Relining)؟',
      [
        'تغيير لون الطقم',
        'تحسين ملاءمة الطقم للتغيرات في العظم',
        'تقوية الطقم',
        'تحسين الجمال',
      ],
      'تحسين ملاءمة الطقم للتغيرات في العظم',
      'إعادة التبطين تُجرى لتحسين ملاءمة الطقم بعد تغير شكل العظم.',
      'العظم السنخي يتراجع بعد فقدان الأسنان.',
      true,
      'العظم السنخي يتراجع تدريجياً بعد فقدان الأسنان مما يؤثر على ملاءمة الطقم.',
    );

    addQ(
      'l4s2_fixed4',
      'Fixed Prosthodontics 4',
      'ما هو الغرض من الجسر الكامل (Full Arch Bridge)؟',
      [
        'علاج تسوس واحد',
        'استبدال جميع الأسنان في قوس واحد',
        'علاج اللثة',
        'تقويم الأسنان',
      ],
      'استبدال جميع الأسنان في قوس واحد',
      'الجسر الكامل يستبدل جميع الأسنان في قوس واحد معتمداً على زراعات أو أسنان طبيعية.',
      'الزراعات السنية توفر دعماً ممتازاً للتعويضات الثابتة.',
      true,
      'الزراعات السنية توفر دعماً مثالياً للتعويضات الثابتة لأنها تحل محل جذر السن الطبيعي.',
    );

    addQ(
      'l4s2_endo4',
      'Endodontics 4',
      'ما هو الغرض من قطع قمة الجذر (Apicoectomy)؟',
      [
        'تحسين الجمال',
        'إزالة العدوى المستمرة عند قمة الجذر',
        'تقصير الجذر',
        'تقوية الجذر',
      ],
      'إزالة العدوى المستمرة عند قمة الجذر',
      'Apicoectomy تُجرى لإزالة العدوى المستمرة عند قمة الجذر التي لم تستجب للعلاج التقليدي.',
      'Apicoectomy إجراء جراحي يُجرى من خلال اللثة.',
      true,
      'Apicoectomy تُجرى جراحياً من خلال شق في اللثة للوصول إلى قمة الجذر.',
    );

    addQ(
      'l4s2_pediatric3',
      'Pediatric Dentistry 3',
      'ما هو أفضل وقت لبدء تقويم الأسنان عند الأطفال؟',
      ['2-4 سنوات', '6-8 سنوات', '10-14 سنة', '18 سنة فأكثر'],
      '10-14 سنة',
      'أفضل وقت لبدء تقويم الأسنان هو بين 10-14 سنة عندما يكتمل بزوغ الأسنان الدائمة.',
      'الوقاية من تسوس الأسنان تبدأ قبل بزوغ الأسنان.',
      true,
      'الوقاية من تسوس الأسنان تبدأ قبل بزوغ الأسنان بتنظيف اللثة وتقليل السكريات.',
    );

    addQ(
      'l4s2_ortho3',
      'Orthodontics 3',
      'ما هو الغرض من المثبت (Retainer) بعد التقويم؟',
      [
        'تحريك الأسنان',
        'الحفاظ على نتيجة التقويم ومنع الارتداد',
        'تبييض الأسنان',
        'علاج اللثة',
      ],
      'الحفاظ على نتيجة التقويم ومنع الارتداد',
      'المثبت يحافظ على نتيجة التقويم ويمنع ارتداد الأسنان إلى مواضعها السابقة.',
      'الارتداد (Relapse) شائع بعد إزالة التقويم دون استخدام المثبت.',
      true,
      'الارتداد شائع جداً إذا لم يُستخدم المثبت بانتظام بعد إزالة التقويم.',
    );

    addQ(
      'l4s2_preventive2',
      'Preventive Dentistry 2',
      'ما هو الغرض من الفلورة الموضعية (Topical Fluoride)؟',
      [
        'تبييض الأسنان',
        'تقوية الميناء ومنع التسوس',
        'علاج اللثة',
        'تخدير الأسنان',
      ],
      'تقوية الميناء ومنع التسوس',
      'الفلورة الموضعية تقوي الميناء وتجعله أكثر مقاومة للأحماض البكتيرية.',
      'الختم الشقي (Pit and Fissure Sealant) يحمي أسطح الطحن من التسوس.',
      true,
      'الختم الشقي يغلق الشقوق والحفر في أسطح الطحن مما يمنع تراكم البكتيريا والتسوس.',
    );

    return questions;
  }
}
