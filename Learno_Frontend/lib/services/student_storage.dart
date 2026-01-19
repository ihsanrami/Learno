/// =============================================================================
/// Student Storage Service - Persistent Student Data
/// =============================================================================
/// 🆕 NEW FILE
/// 
/// Saves student ID and name locally so they can resume lessons.
/// Uses SharedPreferences for simple key-value storage.
/// =============================================================================

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class StudentStorage {
  static SharedPreferences? _prefs;

  static const String _keyStudentId = 'student_id';
  static const String _keyStudentName = 'student_name';
  static const String _keyLastGrade = 'last_grade';
  static const String _keyLastSubject = 'last_subject';
  static const String _keyLastLesson = 'last_lesson';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    if (studentId == null) {
      final newId = const Uuid().v4();
      await _prefs!.setString(_keyStudentId, newId);
    }
  }

  static String? get studentId => _prefs?.getString(_keyStudentId);

  static String get studentName => _prefs?.getString(_keyStudentName) ?? 'Student';

  static Future<void> setStudentName(String name) async {
    await _prefs?.setString(_keyStudentName, name);
  }

  static Future<void> saveLastLesson({
    required int grade,
    required String subject,
    required String lesson,
  }) async {
    await _prefs?.setInt(_keyLastGrade, grade);
    await _prefs?.setString(_keyLastSubject, subject);
    await _prefs?.setString(_keyLastLesson, lesson);
  }

  static Map<String, dynamic>? get lastLesson {
    final grade = _prefs?.getInt(_keyLastGrade);
    final subject = _prefs?.getString(_keyLastSubject);
    final lesson = _prefs?.getString(_keyLastLesson);
    
    if (grade != null && subject != null && lesson != null) {
      return {
        'grade': grade,
        'subject': subject,
        'lesson': lesson,
      };
    }
    return null;
  }

  static Future<void> clearLastLesson() async {
    await _prefs?.remove(_keyLastGrade);
    await _prefs?.remove(_keyLastSubject);
    await _prefs?.remove(_keyLastLesson);
  }

  static bool get hasSavedSession => lastLesson != null;
}
