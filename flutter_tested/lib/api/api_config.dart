/// =============================================================================
/// API Configuration - Learno Backend Connection
/// =============================================================================
/// ✅ FIXED: Better URL handling for different platforms
/// =============================================================================

class ApiConfig {
  // ==========================================================================
  // BASE URL - CHANGE THIS BASED ON YOUR SETUP
  // ==========================================================================
  
  // For Android Emulator:
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  // Root URL of the backend server (used to build static file URLs).
  static String get serverRoot {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.host}:${uri.port}';
  }
  
  // For Chrome/Web - uncomment this:
  // static const String baseUrl = 'http://localhost:8000/api/v1';
  
  // For Real Device - replace with your computer's IP:
  // static const String baseUrl = 'http://192.168.1.100:8000/api/v1';
  
  // ==========================================================================
  // ENDPOINTS
  // ==========================================================================
  
  static const String startSession = '/session/start';
  static const String endSession = '/session/end';
  static const String lessonContinue = '/lesson/continue';
  static const String lessonRespond = '/lesson/respond';
  static const String lessonSilence = '/lesson/silence';
  
  // ==========================================================================
  // TIMEOUTS & THRESHOLDS
  // ==========================================================================
  
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const int silenceThresholdSeconds = 12;
}
