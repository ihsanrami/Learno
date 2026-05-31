import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  String _language = 'en-US';

  Function()? onStart;
  Function()? onComplete;
  Function(String)? onError;

  // Known female voice name substrings for iOS / engines without gender metadata.
  static const _femaleArabic  = ['laila', 'sara', 'nora', 'hana'];
  static const _femaleEnglish = ['samantha', 'karen', 'victoria', 'fiona', 'ava', 'allison'];

  Future<void> setLanguage(String languageCode) async {
    _language = languageCode == 'ar' ? 'ar-SA' : 'en-US';
    if (_isInitialized) {
      await _tts.setLanguage(_language);
      await _pickFemaleVoice(_language);
    }
  }

  Future<void> setSubjectLanguage(String subject) async {
    _language = subject.toLowerCase() == 'arabic' ? 'ar-SA' : 'en-US';
    if (_isInitialized) {
      await _tts.setLanguage(_language);
      await _pickFemaleVoice(_language);
    }
  }

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _tts.setLanguage(_language);
      await _tts.setSpeechRate(0.42);  // slightly slower — calm, child-friendly
      await _tts.setPitch(1.25);       // warmer, softer — female teacher feel
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
      await _pickFemaleVoice(_language);
    } catch (_) {}
  }

  /// Queries available TTS voices and selects the best female voice for [locale].
  /// Priority: (1) Android gender == 'female', (2) known female name substring,
  /// (3) first voice matching locale. Falls back silently if no voices available.
  Future<void> _pickFemaleVoice(String locale) async {
    try {
      final raw = await _tts.getVoices;
      if (raw is! List || raw.isEmpty) return;

      final langCode = locale.split('-').first.toLowerCase(); // 'ar' or 'en'

      final candidates = <Map>[];
      for (final v in raw) {
        if (v is! Map) continue;
        final voiceLocale = (v['locale'] as String? ?? '').toLowerCase();
        if (voiceLocale.startsWith(langCode)) candidates.add(v);
      }
      if (candidates.isEmpty) return;

      Map? picked;

      // 1. Android: prefer explicit female gender tag
      for (final v in candidates) {
        if ((v['gender'] as String? ?? '').toLowerCase() == 'female') {
          picked = v;
          break;
        }
      }

      // 2. iOS / no-gender metadata: match known female voice name substrings
      if (picked == null) {
        final femaleHints = langCode == 'ar' ? _femaleArabic : _femaleEnglish;
        for (final v in candidates) {
          final name = (v['name'] as String? ?? '').toLowerCase();
          if (femaleHints.any((hint) => name.contains(hint))) {
            picked = v;
            break;
          }
        }
      }

      // 3. Graceful fallback: first voice matching the locale
      picked ??= candidates.first;

      final name = picked['name'] as String?;
      final pickedLocale = picked['locale'] as String? ?? locale;
      if (name != null && name.isNotEmpty) {
        await _tts.setVoice({'name': name, 'locale': pickedLocale});
        debugPrint('[TTS] voice selected: $name ($pickedLocale)');
      }
    } catch (e) {
      debugPrint('[TTS] voice pick failed: $e');
    }
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
