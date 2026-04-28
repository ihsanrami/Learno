import 'api_config.dart';

// Requests

class StartSessionRequest {
  final String studentId;
  final String studentName;
  final int grade;
  final String subject;
  final String lesson;
  final bool forceNew;

  StartSessionRequest({
    required this.studentId,
    required this.studentName,
    required this.grade,
    required this.subject,
    required this.lesson,
    this.forceNew = false,
  });

  Map<String, dynamic> toJson() => {
    'student_id': studentId,
    'student_name': studentName,
    'grade': grade,
    'subject': subject,
    'lesson': lesson,
    'force_new': forceNew,
  };
}

class ContinueRequest {
  final String sessionId;

  ContinueRequest({required this.sessionId});

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
  };
}

class ChildResponseRequest {
  final String sessionId;
  final String transcript;
  final double? confidence;
  final double? duration;

  ChildResponseRequest({
    required this.sessionId,
    required this.transcript,
    this.confidence,
    this.duration,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'session_id': sessionId,
      'transcript': transcript,
    };
    if (confidence != null) map['confidence'] = confidence;
    if (duration != null) map['duration'] = duration;
    return map;
  }
}

class SilenceNotificationRequest {
  final String sessionId;
  final double silenceDuration;

  SilenceNotificationRequest({
    required this.sessionId,
    required this.silenceDuration,
  });

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'silence_duration': silenceDuration,
  };
}

class EndSessionRequest {
  final String sessionId;

  EndSessionRequest({required this.sessionId});

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
  };
}

// Responses

/// One display-ready message segment returned by the backend splitter.
class MessageChunk {
  final String text;
  final int delayMs;

  const MessageChunk({required this.text, required this.delayMs});

  factory MessageChunk.fromJson(Map<String, dynamic> json) => MessageChunk(
        text: json['text'] as String? ?? '',
        delayMs: json['delay_ms'] as int? ?? 0,
      );
}

class LearnoResponse {
  final String text;
  final List<MessageChunk> messages;
  final String responseType;
  final String? imageReference;
  final String? generatedImageUrl;
  final int? imagePosition;

  LearnoResponse({
    required this.text,
    required this.responseType,
    this.messages = const [],
    this.imageReference,
    this.generatedImageUrl,
    this.imagePosition,
  });

  factory LearnoResponse.fromJson(Map<String, dynamic> json) {
    final rawChunks = json['messages'] as List<dynamic>?;
    return LearnoResponse(
      text: json['text'] as String? ?? '',
      messages: rawChunks != null
          ? rawChunks
              .map((m) => MessageChunk.fromJson(m as Map<String, dynamic>))
              .toList()
          : const [],
      responseType: json['response_type'] as String? ?? 'message',
      imageReference: json['image_reference'] as String?,
      generatedImageUrl: json['generated_image_url'] as String?,
      imagePosition: json['image_position'] as int?,
    );
  }

  bool get hasMessages => messages.isNotEmpty;
  bool get hasImage => generatedImageUrl != null || imageReference != null;

  /// Resolves relative paths (e.g. /static/...) against the backend root.
  String? get displayImageUrl {
    final url = generatedImageUrl ?? imageReference;
    if (url == null) return null;
    if (url.startsWith('http')) return url;
    return '${ApiConfig.serverRoot}$url';
  }
}

class ProgressData {
  final String lessonPhase;
  final int currentConcept;
  final int totalConcepts;
  final String conceptPhase;
  final int totalCorrect;
  final int totalWrong;
  final int conceptsCompleted;
  final String studentLevel;
  final String teachingStyle;

  ProgressData({
    required this.lessonPhase,
    required this.currentConcept,
    required this.totalConcepts,
    required this.conceptPhase,
    required this.totalCorrect,
    required this.totalWrong,
    this.conceptsCompleted = 0,
    this.studentLevel = 'developing',
    this.teachingStyle = 'standard',
  });

  factory ProgressData.fromJson(Map<String, dynamic> json) {
    return ProgressData(
      lessonPhase: json['lesson_phase'] ?? '',
      currentConcept: json['current_concept'] ?? 1,
      totalConcepts: json['total_concepts'] ?? 1,
      conceptPhase: json['concept_phase'] ?? '',
      totalCorrect: json['total_correct'] ?? 0,
      totalWrong: json['total_wrong'] ?? 0,
      conceptsCompleted: json['concepts_completed'] ?? 0,
      studentLevel: json['student_level'] ?? 'developing',
      teachingStyle: json['teaching_style'] ?? 'standard',
    );
  }

  double get progressPercent =>
      totalConcepts > 0 ? currentConcept / totalConcepts : 0.0;
}

class StudentAnalytics {
  final String learningLevel;
  final String teachingStyle;
  final double accuracy;
  final List<String> weakConcepts;
  final List<String> strongConcepts;
  final double totalTimeMinutes;
  final int lessonsCompleted;
  final String recommendation;

  StudentAnalytics({
    required this.learningLevel,
    required this.teachingStyle,
    required this.accuracy,
    required this.weakConcepts,
    required this.strongConcepts,
    required this.totalTimeMinutes,
    required this.lessonsCompleted,
    required this.recommendation,
  });

  factory StudentAnalytics.fromJson(Map<String, dynamic> json) {
    return StudentAnalytics(
      learningLevel: json['learning_level'] ?? 'developing',
      teachingStyle: json['teaching_style'] ?? 'standard',
      accuracy: (json['accuracy'] ?? 0.0).toDouble(),
      weakConcepts: List<String>.from(json['weak_concepts'] ?? []),
      strongConcepts: List<String>.from(json['strong_concepts'] ?? []),
      totalTimeMinutes: (json['total_time_minutes'] ?? 0.0).toDouble(),
      lessonsCompleted: json['lessons_completed'] ?? 0,
      recommendation: json['recommendation'] ?? '',
    );
  }
}

class StartSessionResponse {
  final String status;
  final String message;
  final String sessionId;
  final LearnoResponse learnoResponse;
  final ProgressData? progress;
  final StudentAnalytics? analytics;

  StartSessionResponse({
    required this.status,
    required this.message,
    required this.sessionId,
    required this.learnoResponse,
    this.progress,
    this.analytics,
  });

  factory StartSessionResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return StartSessionResponse(
      status: json['status'],
      message: json['message'],
      sessionId: data['session_id'],
      learnoResponse: LearnoResponse.fromJson(data['learno_response']),
      progress: data['progress'] != null
          ? ProgressData.fromJson(data['progress'])
          : null,
      analytics: data['student_analytics'] != null
          ? StudentAnalytics.fromJson(data['student_analytics'])
          : null,
    );
  }

  bool get isSuccess => status == 'success';
}

class LessonResponse {
  final String status;
  final String message;
  final LearnoResponse learnoResponse;
  final ProgressData? progress;
  final bool isComplete;
  final StudentAnalytics? analytics;

  LessonResponse({
    required this.status,
    required this.message,
    required this.learnoResponse,
    this.progress,
    this.isComplete = false,
    this.analytics,
  });

  factory LessonResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return LessonResponse(
      status: json['status'],
      message: json['message'],
      learnoResponse: LearnoResponse.fromJson(data['learno_response']),
      progress: data['progress'] != null
          ? ProgressData.fromJson(data['progress'])
          : null,
      isComplete: data['is_complete'] ?? false,
      analytics: data['student_analytics'] != null
          ? StudentAnalytics.fromJson(data['student_analytics'])
          : null,
    );
  }

  bool get isSuccess => status == 'success';
}

class EndSessionResponse {
  final String status;
  final String message;
  final int conceptsCompleted;
  final int totalCorrect;
  final int totalQuestions;
  final bool isComplete;
  final StudentAnalytics? analytics;

  EndSessionResponse({
    required this.status,
    required this.message,
    this.conceptsCompleted = 0,
    this.totalCorrect = 0,
    this.totalQuestions = 0,
    this.isComplete = false,
    this.analytics,
  });

  factory EndSessionResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return EndSessionResponse(
      status: json['status'],
      message: json['message'],
      conceptsCompleted: data['concepts_completed'] ?? 0,
      totalCorrect: data['total_correct'] ?? 0,
      totalQuestions: data['total_questions'] ?? 0,
      isComplete: data['is_complete'] ?? false,
      analytics: data['analytics'] != null
          ? StudentAnalytics.fromJson(data['analytics'])
          : null,
    );
  }

  bool get isSuccess => status == 'success';
}

class TopicData {
  final String topicId;
  final String nameEn;
  final String nameAr;
  final int order;
  final int difficultyLevel;

  TopicData({
    required this.topicId,
    required this.nameEn,
    required this.nameAr,
    required this.order,
    required this.difficultyLevel,
  });

  factory TopicData.fromJson(Map<String, dynamic> json) => TopicData(
        topicId: json['topic_id'] as String? ?? '',
        nameEn: json['name_en'] as String? ?? '',
        nameAr: json['name_ar'] as String? ?? '',
        order: json['order'] as int? ?? 0,
        difficultyLevel: json['difficulty_level'] as int? ?? 1,
      );
}

class SilenceResponse {
  final String status;
  final String message;
  final LearnoResponse? learnoResponse;
  final ProgressData? progress;

  SilenceResponse({
    required this.status,
    required this.message,
    this.learnoResponse,
    this.progress,
  });

  factory SilenceResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return SilenceResponse(
      status: json['status'],
      message: json['message'],
      learnoResponse: data['learno_response'] != null
          ? LearnoResponse.fromJson(data['learno_response'])
          : null,
      progress: data['progress'] != null
          ? ProgressData.fromJson(data['progress'])
          : null,
    );
  }

  bool get isSuccess => status == 'success';
}
