
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


class LearnoResponse {
  final String text;
  final String responseType;
  final String? imageReference;
  final String? generatedImageUrl;

  LearnoResponse({
    required this.text,
    required this.responseType,
    this.imageReference,
    this.generatedImageUrl,
  });

  factory LearnoResponse.fromJson(Map<String, dynamic> json) {
    return LearnoResponse(
      text: json['text'] ?? '',
      responseType: json['response_type'] ?? 'message',
      imageReference: json['image_reference'],
      generatedImageUrl: json['generated_image_url'],
    );
  }

  bool get hasImage => generatedImageUrl != null || imageReference != null;
  String? get displayImageUrl => generatedImageUrl ?? imageReference;
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
