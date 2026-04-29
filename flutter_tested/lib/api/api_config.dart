// URL resolved at compile time from --dart-define=API_BASE_URL=<url>.
// Falls back to the Android emulator loopback when the define is absent.
//
// Examples:
//   flutter run
//   flutter run --dart-define=API_BASE_URL=http://192.168.8.47:8000/api/v1
//   flutter build apk --dart-define=API_BASE_URL=https://api.learno.com/api/v1

class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  static String get serverRoot {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.host}:${uri.port}';
  }

  // Lesson endpoints
  static const String startSession = '/session/start';
  static const String endSession = '/session/end';
  static const String lessonContinue = '/lesson/continue';
  static const String lessonRespond = '/lesson/respond';
  static const String lessonSilence = '/lesson/silence';

  // Curriculum
  static const String curriculumTopics = '/curriculum/topics';

  // Auth
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authLogout = '/auth/logout';
  static const String authRefresh = '/auth/refresh';
  static const String authMe = '/auth/me';

  // Children
  static const String children = '/children/';

  // Parent panel
  static const String parentDashboard = '/parent/dashboard';
  static String parentOverview(int childId) => '/parent/children/$childId/overview';
  static String parentWeekly(int childId) => '/parent/children/$childId/weekly';
  static String parentTopics(int childId) => '/parent/children/$childId/topics';
  static String parentSubjects(int childId) => '/parent/children/$childId/subjects';
  static String parentAchievements(int childId) => '/parent/children/$childId/achievements';
  static String parentGoal(int childId) => '/parent/children/$childId/goal';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  // Lesson endpoints invoke GPT-4 which can take ~47s; 2-minute headroom.
  static const Duration lessonTimeout = Duration(seconds: 120);

  static const int silenceThresholdSeconds = 60;
}
