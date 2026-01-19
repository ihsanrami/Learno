/// =============================================================================
/// Interaction Mode Provider - Voice/Text Mode Management
/// =============================================================================
/// 🆕 NEW FILE
///
/// Manages the interaction mode (Voice or Text) across the app.
/// Uses ChangeNotifier for state management.
/// =============================================================================

import 'package:flutter/foundation.dart';

enum InteractionMode {
  voice,
  text,
}

class InteractionModeProvider extends ChangeNotifier {
  static final InteractionModeProvider _instance = InteractionModeProvider._internal();
  factory InteractionModeProvider() => _instance;
  InteractionModeProvider._internal();

  InteractionMode _mode = InteractionMode.voice;

  bool _isSpeaking = false;

  bool _isListening = false;

  bool _autoListenEnabled = true;


  InteractionMode get mode => _mode;
  bool get isVoiceMode => _mode == InteractionMode.voice;
  bool get isTextMode => _mode == InteractionMode.text;
  bool get isSpeaking => _isSpeaking;
  bool get isListening => _isListening;
  bool get autoListenEnabled => _autoListenEnabled;
  
  bool get isBusy => _isSpeaking || _isListening;


  void toggleMode() {
    _mode = _mode == InteractionMode.voice 
        ? InteractionMode.text 
        : InteractionMode.voice;
    
    if (_mode == InteractionMode.text) {
      _isSpeaking = false;
      _isListening = false;
    }
    
    notifyListeners();
  }

  void setMode(InteractionMode newMode) {
    if (_mode != newMode) {
      _mode = newMode;
      
      if (_mode == InteractionMode.text) {
        _isSpeaking = false;
        _isListening = false;
      }
      
      notifyListeners();
    }
  }

  void enableVoiceMode() => setMode(InteractionMode.voice);

  void enableTextMode() => setMode(InteractionMode.text);


  void setSpeaking(bool speaking) {
    if (_isSpeaking != speaking) {
      _isSpeaking = speaking;
      notifyListeners();
    }
  }

  void onSpeakingStarted() {
    _isSpeaking = true;
    _isListening = false;
    notifyListeners();
  }

  void onSpeakingCompleted() {
    _isSpeaking = false;
    notifyListeners();
  }


  void setListening(bool listening) {
    if (_isListening != listening) {
      _isListening = listening;
      notifyListeners();
    }
  }

  void onListeningStarted() {
    _isListening = true;
    _isSpeaking = false;
    notifyListeners();
  }

  void onListeningStopped() {
    _isListening = false;
    notifyListeners();
  }


  void toggleAutoListen() {
    _autoListenEnabled = !_autoListenEnabled;
    notifyListeners();
  }

  void setAutoListen(bool enabled) {
    if (_autoListenEnabled != enabled) {
      _autoListenEnabled = enabled;
      notifyListeners();
    }
  }


  void reset() {
    _mode = InteractionMode.voice;
    _isSpeaking = false;
    _isListening = false;
    _autoListenEnabled = true;
    notifyListeners();
  }
}

final interactionMode = InteractionModeProvider();
