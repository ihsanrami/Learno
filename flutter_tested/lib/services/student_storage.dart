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
  
  // Keys
  static const String _keyStudentId = 'student_id';
  static const String _keyStudentName = 'student_name';
  static const String _keyLastGrade = 'last_grade';
  static const String _keyLastSubject = 'last_subject';
  static const String _keyLastLesson = 'last_lesson';
  
  /// Initialize storage
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Generate student ID if not exists
    if (studentId == null) {
      final newId = const Uuid().v4();
      await _prefs!.setString(_keyStudentId, newId);
    }
  }
  
  /// Get student ID (auto-generated, persistent)
  static String? get studentId => _prefs?.getString(_keyStudentId);
  
  /// Get student name
  static String get studentName => _prefs?.getString(_keyStudentName) ?? 'Student';
  
  /// Set student name
  static Future<void> setStudentName(String name) async {
    await _prefs?.setString(_keyStudentName, name);
  }
  
  /// Save last lesson info (for quick resume)
  static Future<void> saveLastLesson({
    required int grade,
    required String subject,
    required String lesson,
  }) async {
    await _prefs?.setInt(_keyLastGrade, grade);
    await _prefs?.setString(_keyLastSubject, subject);
    await _prefs?.setString(_keyLastLesson, lesson);
  }
  
  /// Get last lesson info
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
  
  /// Clear last lesson (after completion)
  static Future<void> clearLastLesson() async {
    await _prefs?.remove(_keyLastGrade);
    await _prefs?.remove(_keyLastSubject);
    await _prefs?.remove(_keyLastLesson);
  }
  
  /// Check if has saved session
  static bool get hasSavedSession => lastLesson != null;
}
