/// =============================================================================
/// API Service - Communication with Learno Backend
/// =============================================================================
/// ✅ FIXED: Removed duplicate Grade enum, using import from models
/// =============================================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'dto.dart';
import '../core/session_state.dart';
import '../services/student_storage.dart';
import '../models/enums.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };


  static Future<StartSessionResponse> startSession({
    bool forceNew = false,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.startSession}');

    final request = StartSessionRequest(
      studentId: StudentStorage.studentId ?? 'default',
      studentName: StudentStorage.studentName,
      grade: _gradeToInt(SessionState.grade!),
      subject: SessionState.subject!.name,
      lesson: SessionState.lesson!,
      forceNew: forceNew,
    );

    final response = await http
        .post(url, headers: _headers, body: jsonEncode(request.toJson()))
        .timeout(ApiConfig.connectionTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Server error: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    final result = StartSessionResponse.fromJson(decoded);

    SessionState.sessionId = result.sessionId;
    SessionState.isActive = true;

    await StudentStorage.saveLastLesson(
      grade: _gradeToInt(SessionState.grade!),
      subject: SessionState.subject!.name,
      lesson: SessionState.lesson!,
    );

    return result;
  }

  static Future<EndSessionResponse> endSession() async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.endSession}');

    final request = EndSessionRequest(
      sessionId: SessionState.sessionId!,
    );

    final response = await http
        .post(url, headers: _headers, body: jsonEncode(request.toJson()))
        .timeout(ApiConfig.connectionTimeout);

    SessionState.clear();
    await StudentStorage.clearLastLesson();

    if (response.statusCode != 200) {
      throw ApiException('Server error: ${response.statusCode}');
    }

    return EndSessionResponse.fromJson(jsonDecode(response.body));
  }


  static Future<LessonResponse> continueLesson() async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.lessonContinue}');

    final request = ContinueRequest(
      sessionId: SessionState.sessionId!,
    );

    final response = await http
        .post(url, headers: _headers, body: jsonEncode(request.toJson()))
        .timeout(ApiConfig.connectionTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Server error: ${response.statusCode}');
    }

    return LessonResponse.fromJson(jsonDecode(response.body));
  }

  static Future<LessonResponse> sendResponse(
    String transcript, {
    double? confidence,
    double? duration,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.lessonRespond}');

    final request = ChildResponseRequest(
      sessionId: SessionState.sessionId!,
      transcript: transcript,
      confidence: confidence,
      duration: duration,
    );

    final response = await http
        .post(url, headers: _headers, body: jsonEncode(request.toJson()))
        .timeout(ApiConfig.connectionTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Server error: ${response.statusCode}');
    }

    return LessonResponse.fromJson(jsonDecode(response.body));
  }

  static Future<SilenceResponse> notifySilence(double silenceDuration) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.lessonSilence}');

    final request = SilenceNotificationRequest(
      sessionId: SessionState.sessionId!,
      silenceDuration: silenceDuration,
    );

    final response = await http
        .post(url, headers: _headers, body: jsonEncode(request.toJson()))
        .timeout(ApiConfig.connectionTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Server error: ${response.statusCode}');
    }

    return SilenceResponse.fromJson(jsonDecode(response.body));
  }


  static int _gradeToInt(Grade grade) {
    switch (grade) {
      case Grade.kindergarten:
        return 0;
      case Grade.first:
        return 1;
      case Grade.second:
        return 2;
      case Grade.third:
        return 3;
      case Grade.fourth:
        return 4;
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
