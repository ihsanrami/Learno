

class ApiConfig {


  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  static const String startSession = '/session/start';
  static const String endSession = '/session/end';
  static const String lessonContinue = '/lesson/continue';
  static const String lessonRespond = '/lesson/respond';
  static const String lessonSilence = '/lesson/silence';

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const int silenceThresholdSeconds = 12;
}
