/// =============================================================================
/// Session State - Global State Management
/// =============================================================================
/// 🔄 UPDATED: Added analytics, progress tracking, voice state
/// =============================================================================

import '../models/enums.dart';
import '../models/chat_message.dart';
import '../api/dto.dart';

// Re-export ChatMessage for backward compatibility
export '../models/chat_message.dart';

class SessionState {
  static String? sessionId;
  static bool isActive = false;

  static Grade? grade;
  static Subject? subject;
  static String? lesson;

  static int currentStep = 1;
  static int totalSteps = 5;
  static bool isLessonComplete = false;
  static int currentConcept = 1;
  static int totalConcepts = 5;
  static int conceptsCompleted = 0;

  static int totalCorrect = 0;
  static int totalWrong = 0;

  static List<ChatMessage> conversation = [];
  static String? lastResponseType;

  static bool isVoiceMode = true;
  static bool isSpeaking = false;
  static bool isListening = false;

  static String learningLevel = 'developing';
  static String teachingStyle = 'standard';
  static StudentAnalytics? analytics;

  static void clear() {
    sessionId = null;
    isActive = false;

    grade = null;
    subject = null;
    lesson = null;

    currentStep = 1;
    totalSteps = 5;
    isLessonComplete = false;
    currentConcept = 1;
    totalConcepts = 5;
    conceptsCompleted = 0;

    totalCorrect = 0;
    totalWrong = 0;

    conversation.clear();
    lastResponseType = null;

    isVoiceMode = true;
    isSpeaking = false;
    isListening = false;

    learningLevel = 'developing';
    teachingStyle = 'standard';
    analytics = null;
  }

  static void addLearnoMessage(
    String text,
    String responseType, {
    String? imageUrl,
  }) {
    conversation.add(ChatMessage(
      text: text,
      isUser: false,
      responseType: responseType,
      imageUrl: imageUrl,
    ));
    lastResponseType = responseType;
  }

  static void addChildMessage(String text, {bool isVoice = false}) {
    conversation.add(ChatMessage(
      text: text,
      isUser: true,
      isVoiceMessage: isVoice,
    ));
  }

  static void updateProgress(ProgressData progress) {
    currentConcept = progress.currentConcept;
    totalConcepts = progress.totalConcepts;
    conceptsCompleted = progress.conceptsCompleted;
    totalCorrect = progress.totalCorrect;
    totalWrong = progress.totalWrong;
    learningLevel = progress.studentLevel;
    teachingStyle = progress.teachingStyle;

    currentStep = progress.currentConcept;
    totalSteps = progress.totalConcepts;
  }

  static void updateAnalytics(StudentAnalytics? newAnalytics) {
    analytics = newAnalytics;
    if (newAnalytics != null) {
      learningLevel = newAnalytics.learningLevel;
      teachingStyle = newAnalytics.teachingStyle;
    }
  }

  static void toggleVoiceMode() {
    isVoiceMode = !isVoiceMode;
  }

  static double get progressPercent {
    if (totalConcepts == 0) return 0.0;
    return conceptsCompleted / totalConcepts;
  }

  static double get accuracyPercent {
    final total = totalCorrect + totalWrong;
    if (total == 0) return 0.0;
    return totalCorrect / total;
  }

  static Map<String, dynamic> getSummary() {
    return {
      'sessionId': sessionId,
      'isActive': isActive,
      'grade': grade?.name,
      'subject': subject?.name,
      'lesson': lesson,
      'currentConcept': currentConcept,
      'totalConcepts': totalConcepts,
      'conceptsCompleted': conceptsCompleted,
      'totalCorrect': totalCorrect,
      'totalWrong': totalWrong,
      'learningLevel': learningLevel,
      'teachingStyle': teachingStyle,
      'messageCount': conversation.length,
      'isVoiceMode': isVoiceMode,
    };
  }
}
