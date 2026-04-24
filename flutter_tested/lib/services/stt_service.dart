/// =============================================================================
/// STT Service - Speech-to-Text for Learno
/// =============================================================================
/// Handles voice input - captures child's spoken answers.
/// Supports locale switching for bilingual (English/Arabic) sessions.
/// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

class STTService {
  static final STTService _instance = STTService._internal();
  factory STTService() => _instance;
  STTService._internal();

  final SpeechToText _stt = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  // Active locale — updated via setLocale() when app language changes.
  String _localeId = 'en_US';

  // Callbacks
  Function(String text, bool isFinal)? onResult;
  Function(String error)? onError;
  Function()? onListeningStarted;
  Function()? onListeningStopped;

  /// Switch the recognition locale.  Call this whenever the app language changes.
  /// [languageCode] should be 'en' or 'ar'.
  void setLocale(String languageCode) {
    _localeId = languageCode == 'ar' ? 'ar_SA' : 'en_US';
  }

  /// Initialize STT
  Future<bool> init() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _stt.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('STT init error: $e');
      return false;
    }
  }

  /// Start listening using the current locale.
  Future<void> startListening() async {
    if (!_isInitialized) {
      final success = await init();
      if (!success) {
        onError?.call('Speech recognition not available');
        return;
      }
    }

    if (_isListening) return;

    try {
      await _stt.listen(
        onResult: _handleResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: _localeId,
        listenMode: ListenMode.confirmation,
      );
      _isListening = true;
      onListeningStarted?.call();
    } catch (e) {
      debugPrint('STT listen error: $e');
      onError?.call(e.toString());
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;
    try {
      await _stt.stop();
      _isListening = false;
      onListeningStopped?.call();
    } catch (e) {
      debugPrint('STT stop error: $e');
    }
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    try {
      await _stt.cancel();
      _isListening = false;
      onListeningStopped?.call();
    } catch (e) {
      debugPrint('STT cancel error: $e');
    }
  }

  void _handleResult(SpeechRecognitionResult result) {
    onResult?.call(result.recognizedWords, result.finalResult);
    if (result.finalResult) {
      _isListening = false;
      onListeningStopped?.call();
    }
  }

  void _handleError(SpeechRecognitionError error) {
    _isListening = false;
    onError?.call(error.errorMsg);
    onListeningStopped?.call();
  }

  void _handleStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      onListeningStopped?.call();
    }
  }

  bool get isListening => _isListening;
  bool get isAvailable => _isInitialized;
  String get currentLocale => _localeId;

  Future<void> dispose() async {
    await stopListening();
    _isInitialized = false;
  }
}
