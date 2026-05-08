import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  // Active TTS language — call setLanguage() when the app language changes.
  String _language = 'en-US';

  Function()? onStart;
  Function()? onComplete;
  Function(String)? onError;

  Future<void> setLanguage(String languageCode) async {
    _language = languageCode == 'ar' ? 'ar-SA' : 'en-US';
    if (_isInitialized) {
      await _tts.setLanguage(_language);
    }
  }

  Future<void> setSubjectLanguage(String subject) async {
    _language = subject.toLowerCase() == 'arabic' ? 'ar-SA' : 'en-US';
    if (_isInitialized) {
      await _tts.setLanguage(_language);
    }
  }

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _tts.setLanguage(_language);
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.1);
      await _tts.setVolume(1.0);

      _tts.setStartHandler(() {
        _isSpeaking = true;
        onStart?.call();
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        onComplete?.call();
      });

      _tts.setErrorHandler((message) {
        _isSpeaking = false;
        onError?.call(message.toString());
      });

      _isInitialized = true;
    } catch (_) {}
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) await init();
    if (_isSpeaking) await stop();

    final cleanText = _removeEmojis(text);
    if (cleanText.trim().isEmpty) return;

    try {
      await _tts.speak(cleanText);
    } catch (e) {
      onError?.call(e.toString());
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
    } catch (_) {}
  }

  bool get isSpeaking => _isSpeaking;
  String get currentLanguage => _language;

  String _removeEmojis(String text) {
    final emojiRegex = RegExp(
      r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|'
      r'[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]',
      unicode: true,
    );
    return text.replaceAll(emojiRegex, '').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<void> dispose() async {
    await stop();
    _isInitialized = false;
  }
}
