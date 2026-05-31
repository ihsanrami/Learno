import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'dto.dart';
import '../core/session_state.dart';
import '../controllers/auth_controller.dart';
import '../services/student_storage.dart';
import '../models/enums.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static Map<String, String> get _headers {
    final selectedChildId = AuthController().selectedChild?.id;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (selectedChildId != null)
        'X-Selected-Child-Id': selectedChildId.toString(),
    };
  }

  static Future<StartSessionResponse> startSession({
    bool forceNew = false,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.startSession}');

    final selectedChild = AuthController().selectedChild;
    final childName = selectedChild?.name ?? SessionState.childName;
    final childId = selectedChild?.id;

    final request = StartSessionRequest(
      studentId: StudentStorage.studentId ?? 'default',
      studentName: childName,
      childName: childName,
      appLanguage: SessionState.appLanguage,
      grade: _gradeToInt(SessionState.grade!),
      subject: SessionState.subject!.name,
      lesson: SessionState.lesson!,
      forceNew: forceNew,
      childId: childId,
    );

    final response = await http
        .post(url, headers: _headers, body: jsonEncode(request.toJson()))
        .timeout(ApiConfig.lessonTimeout);

    if (response.statusCode == 429) {
      // Check for daily learning limit before throwing a generic error.
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['error_code'] == 'daily_limit_reached') {
          throw const DailyLimitException();
        }
      } on DailyLimitException {
        rethrow;
      } catch (_) {
        // JSON parse failed or unknown 429 — fall through to generic error
      }
      throw ApiException('Server error: ${response.statusCode}');
    }

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
        .timeout(ApiConfig.lessonTimeout);

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
        .timeout(ApiConfig.lessonTimeout);

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
        .timeout(ApiConfig.lessonTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Server error: ${response.statusCode}');
    }

    return SilenceResponse.fromJson(jsonDecode(response.body));
  }

  static Future<List<TopicData>> fetchTopics(int grade, String subject) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.curriculumTopics}'
      '?grade=$grade&subject=$subject',
    );

    final response = await http
        .get(url, headers: _headers)
        .timeout(ApiConfig.connectionTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Server error: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final rawList = decoded['data'] as List<dynamic>? ?? [];
    return rawList
        .map((e) => TopicData.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<ForgotPasswordResult> forgotPassword(String email) async {
    final url =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.authForgotPassword}');
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}),
        )
        .timeout(ApiConfig.connectionTimeout);
    if (response.statusCode != 200) {
      throw ApiException('Server error: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ForgotPasswordResult(
      message: body['message'] as String,
      debugCode: body['debug_code'] as String?,
    );
  }

  static Future<String> verifyResetCode(String email, String code) async {
    final url =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.authVerifyResetCode}');
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'code': code}),
        )
        .timeout(ApiConfig.connectionTimeout);
    if (response.statusCode == 400) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(body['detail'] as String? ?? 'Invalid code');
    }
    if (response.statusCode != 200) {
      throw ApiException('Server error: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['reset_token'] as String;
  }

  static Future<void> resetPassword(
      String resetToken, String newPassword) async {
    final url =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.authResetPassword}');
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(
              {'reset_token': resetToken, 'new_password': newPassword}),
        )
        .timeout(ApiConfig.connectionTimeout);
    if (response.statusCode == 400) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(body['detail'] as String? ?? 'Reset failed');
    }
    if (response.statusCode != 204) {
      throw ApiException('Server error: ${response.statusCode}');
    }
  }

  static int _gradeToInt(Grade grade) {
    switch (grade) {
      case Grade.kindergarten: return 0;
      case Grade.first:        return 1;
      case Grade.second:       return 2;
      case Grade.third:        return 3;
      case Grade.fourth:       return 4;
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class DailyLimitException implements Exception {
  const DailyLimitException();
}
