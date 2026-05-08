import 'package:dio/dio.dart';

import '../api/api_config.dart';
import '../services/auth_service.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class ChildOverview {
  final int id;
  final String name;
  final int age;
  final String grade;
  final String avatar;
  final int todayMinutes;
  final int todayLessonsCompleted;
  final double todayAccuracy;
  final int streakDays;
  final int targetMinutes;
  final int goalProgressPercent;
  final int totalLessons;
  final double overallAccuracy;
  final int totalLearningMinutes;

  ChildOverview({
    required this.id,
    required this.name,
    required this.age,
    required this.grade,
    required this.avatar,
    required this.todayMinutes,
    required this.todayLessonsCompleted,
    required this.todayAccuracy,
    required this.streakDays,
    required this.targetMinutes,
    required this.goalProgressPercent,
    required this.totalLessons,
    required this.overallAccuracy,
    required this.totalLearningMinutes,
  });

  factory ChildOverview.fromJson(Map<String, dynamic> j) => ChildOverview(
        id: j['id'] ?? 0,
        name: j['name'] ?? '',
        age: j['age'] ?? 0,
        grade: j['grade'] ?? '',
        avatar: j['avatar'] ?? 'fox',
        todayMinutes: j['today_minutes'] ?? 0,
        todayLessonsCompleted: j['today_lessons_completed'] ?? 0,
        todayAccuracy: (j['today_accuracy'] ?? 0.0).toDouble(),
        streakDays: j['streak_days'] ?? 0,
        targetMinutes: j['target_minutes'] ?? 15,
        goalProgressPercent: j['goal_progress_percent'] ?? 0,
        totalLessons: j['total_lessons'] ?? 0,
        overallAccuracy: (j['overall_accuracy'] ?? 0.0).toDouble(),
        totalLearningMinutes: j['total_learning_minutes'] ?? 0,
      );
}

class DayActivity {
  final String date;
  final String dayLabel;
  final int minutes;
  final int lessonsCompleted;

  DayActivity({
    required this.date,
    required this.dayLabel,
    required this.minutes,
    required this.lessonsCompleted,
  });

  factory DayActivity.fromJson(Map<String, dynamic> j) => DayActivity(
        date: j['date'] ?? '',
        dayLabel: j['day_label'] ?? '',
        minutes: j['minutes'] ?? 0,
        lessonsCompleted: j['lessons_completed'] ?? 0,
      );
}

class TopicProgress {
  final String subject;
  final String topicId;
  final double accuracy;
  final int attempts;
  final bool mastered;

  TopicProgress({
    required this.subject,
    required this.topicId,
    required this.accuracy,
    required this.attempts,
    required this.mastered,
  });

  factory TopicProgress.fromJson(Map<String, dynamic> j) => TopicProgress(
        subject: j['subject'] ?? '',
        topicId: j['topic_id'] ?? '',
        accuracy: (j['accuracy'] ?? 0.0).toDouble(),
        attempts: j['attempts'] ?? 0,
        mastered: j['mastered'] ?? false,
      );
}

class SubjectBreakdown {
  final String subject;
  final int minutes;
  final double percent;

  SubjectBreakdown({
    required this.subject,
    required this.minutes,
    required this.percent,
  });

  factory SubjectBreakdown.fromJson(Map<String, dynamic> j) => SubjectBreakdown(
        subject: j['subject'] ?? '',
        minutes: j['minutes'] ?? 0,
        percent: (j['percent'] ?? 0.0).toDouble(),
      );
}

class AchievementItem {
  final String type;
  final String title;
  final String description;
  final String icon;
  final bool earned;
  final String? earnedAt;

  AchievementItem({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.earned,
    this.earnedAt,
  });

  factory AchievementItem.fromJson(Map<String, dynamic> j) => AchievementItem(
        type: j['type'] ?? '',
        title: j['title'] ?? '',
        description: j['description'] ?? '',
        icon: j['icon'] ?? '🏅',
        earned: j['earned'] ?? false,
        earnedAt: j['earned_at'],
      );
}

class GoalStatus {
  final int targetMinutes;
  final int todayMinutes;
  final int progressPercent;

  GoalStatus({
    required this.targetMinutes,
    required this.todayMinutes,
    required this.progressPercent,
  });

  factory GoalStatus.fromJson(Map<String, dynamic> j) => GoalStatus(
        targetMinutes: j['target_minutes'] ?? 15,
        todayMinutes: j['today_minutes'] ?? 0,
        progressPercent: j['progress_percent'] ?? 0,
      );
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class ParentService {
  static final ParentService _instance = ParentService._internal();
  factory ParentService() => _instance;
  ParentService._internal();

  Dio get _dio => AuthService().dio;

  Future<List<ChildOverview>> fetchDashboard() async {
    final res = await _dio.get(ApiConfig.parentDashboard);
    final list = res.data['data'] as List;
    return list.map((e) => ChildOverview.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ChildOverview> fetchChildOverview(int childId) async {
    final res = await _dio.get(ApiConfig.parentOverview(childId));
    final child = res.data['data'] as Map<String, dynamic>;
    return ChildOverview.fromJson({...child, 'id': childId});
  }

  Future<List<DayActivity>> fetchWeeklyActivity(int childId) async {
    final res = await _dio.get(ApiConfig.parentWeekly(childId));
    final list = res.data['data'] as List;
    return list.map((e) => DayActivity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<TopicProgress>> fetchTopics(int childId) async {
    final res = await _dio.get(ApiConfig.parentTopics(childId));
    final list = res.data['data'] as List;
    return list.map((e) => TopicProgress.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<SubjectBreakdown>> fetchSubjects(int childId) async {
    final res = await _dio.get(ApiConfig.parentSubjects(childId));
    final list = res.data['data'] as List;
    return list.map((e) => SubjectBreakdown.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AchievementItem>> fetchAchievements(int childId) async {
    final res = await _dio.get(ApiConfig.parentAchievements(childId));
    final list = res.data['data'] as List;
    return list.map((e) => AchievementItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<GoalStatus> fetchGoal(int childId) async {
    final res = await _dio.get(ApiConfig.parentGoal(childId));
    return GoalStatus.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> setDailyGoal(int childId, int minutes) async {
    await _dio.post(
      ApiConfig.parentGoal(childId),
      data: {'target_minutes': minutes},
    );
  }
}
