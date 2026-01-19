/// =============================================================================
/// TTS Service - Text-to-Speech for Learno
/// =============================================================================
/// 🆕 NEW FILE
///
/// Handles voice output - Learno speaks to the child.
/// =============================================================================

import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  Function()? onStart;
  Function()? onComplete;
  Function(String)? onError;


  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await _tts.setLanguage("en-US");

      await _tts.setSpeechRate(0.42);

      await _tts.setPitch(1.25);

      await _tts.setVolume(1.0);

      await _setFemaleVoice();

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
      print('✅ TTS initialized with gentle female voice');
    } catch (e) {
      print('❌ TTS init error: $e');
    }
  }

  Future<void> _setFemaleVoice() async {
    try {
      List<dynamic> voices = await _tts.getVoices;

      if (voices.isEmpty) {
        print('⚠️ No voices available, using default');
        return;
      }

      final preferredVoices = [
        'Samantha',
        'Karen',
        'Moira',
        'Tessa',
        'Fiona',
        'en-us-x-sfg#female_1',
        'en-us-x-sfg#female_2',
        'en-US-language',
        'en-us-x-tpf#female_1',
        'en-GB-language',
      ];

      for (var preferredName in preferredVoices) {
        for (var voice in voices) {
          String voiceName = voice['name']?.toString().toLowerCase() ?? '';
          String voiceLocale = voice['locale']?.toString().toLowerCase() ?? '';

          if (voiceName.contains(preferredName.toLowerCase()) ||
              (voiceName.contains('female') && voiceLocale.contains('en'))) {
            await _tts.setVoice({"name": voice['name'], "locale": voice['locale']});
            print('✅ Set voice: ${voice['name']}');
            return;
          }
        }
      }

      for (var voice in voices) {
        String voiceName = voice['name']?.toString().toLowerCase() ?? '';
        String voiceLocale = voice['locale']?.toString().toLowerCase() ?? '';

        if (voiceLocale.contains('en') &&
            (voiceName.contains('female') ||
                voiceName.contains('woman') ||
                voiceName.contains('girl'))) {
          await _tts.setVoice({"name": voice['name'], "locale": voice['locale']});
          print('✅ Set fallback female voice: ${voice['name']}');
          return;
        }
      }

      print('⚠️ No female voice found, using default with higher pitch');
    } catch (e) {
      print('⚠️ Could not set female voice: $e');
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
      print('❌ TTS speak error: $e');
      onError?.call(e.toString());
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
    } catch (e) {
      print('❌ TTS stop error: $e');
    }
  }

  bool get isSpeaking => _isSpeaking;

  String _removeEmojis(String text) {
    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}]|'
      r'[\u{1F300}-\u{1F5FF}]|'
      r'[\u{1F680}-\u{1F6FF}]|'
      r'[\u{2600}-\u{26FF}]|'
      r'[\u{2700}-\u{27BF}]|'
      r'[\u{1F1E0}-\u{1F1FF}]|'
      r'[\u{1F900}-\u{1F9FF}]|'
      r'[\u{1FA00}-\u{1FA6F}]|'
      r'[\u{1FA70}-\u{1FAFF}]|'
      r'[\u{FE00}-\u{FE0F}]|'
      r'[\u{200D}]|'
      r'[\u{20E3}]|'
      r'[\u{2300}-\u{23FF}]|'
      r'[\u{2190}-\u{21FF}]|'
      r'[\u{25A0}-\u{25FF}]|'
      r'[\u{2B00}-\u{2BFF}]|'
      r'[\u{3000}-\u{303F}]|'
      r'[\u{2460}-\u{24FF}]|'
      r'[0-9]\u{FE0F}?\u{20E3}|'
      r'[\u{2B50}]|'
      r'[\u{2764}\u{FE0F}?]|'
      r'[✓✔✗✘✅❌❓❗❕❔⭐⚡⚠️➡️⬅️⬆️⬇️▶️◀️🔴🟠🟡🟢🔵🟣⚫⚪🟤]',
      unicode: true,
    );

    String cleaned = text.replaceAll(emojiRegex, '');

    cleaned = cleaned.replaceAll(RegExp(r'[\u{FE0F}\u{200D}]', unicode: true), '');

    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleaned;
  }

  Future<void> dispose() async {
    await stop();
    _isInitialized = false;
  }
}
