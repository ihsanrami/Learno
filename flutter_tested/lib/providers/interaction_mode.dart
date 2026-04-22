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
  voice,  // TTS + STT enabled
  text,   // Manual typing only
}

class InteractionModeProvider extends ChangeNotifier {
  static final InteractionModeProvider _instance = InteractionModeProvider._internal();
  factory InteractionModeProvider() => _instance;
  InteractionModeProvider._internal();

  // Current mode (default: voice for kids)
  InteractionMode _mode = InteractionMode.voice;
  
  // TTS state
  bool _isSpeaking = false;
  
  // STT state
  bool _isListening = false;
  
  // Auto-listen after TTS completes
  bool _autoListenEnabled = true;

  // =========================================================================
  // GETTERS
  // =========================================================================

  InteractionMode get mode => _mode;
  bool get isVoiceMode => _mode == InteractionMode.voice;
  bool get isTextMode => _mode == InteractionMode.text;
  bool get isSpeaking => _isSpeaking;
  bool get isListening => _isListening;
  bool get autoListenEnabled => _autoListenEnabled;
  
  /// Check if interaction is busy (speaking or listening)
  bool get isBusy => _isSpeaking || _isListening;

  // =========================================================================
  // MODE CONTROL
  // =========================================================================

  /// Toggle between voice and text mode
  void toggleMode() {
    _mode = _mode == InteractionMode.voice 
        ? InteractionMode.text 
        : InteractionMode.voice;
    
    // Reset states when switching to text mode
    if (_mode == InteractionMode.text) {
      _isSpeaking = false;
      _isListening = false;
    }
    
    notifyListeners();
  }

  /// Set mode explicitly
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

  /// Enable voice mode
  void enableVoiceMode() => setMode(InteractionMode.voice);

  /// Enable text mode
  void enableTextMode() => setMode(InteractionMode.text);

  // =========================================================================
  // TTS STATE
  // =========================================================================

  /// Set speaking state
  void setSpeaking(bool speaking) {
    if (_isSpeaking != speaking) {
      _isSpeaking = speaking;
      notifyListeners();
    }
  }

  /// Called when TTS starts
  void onSpeakingStarted() {
    _isSpeaking = true;
    _isListening = false; // Can't listen while speaking
    notifyListeners();
  }

  /// Called when TTS completes
  void onSpeakingCompleted() {
    _isSpeaking = false;
    notifyListeners();
  }

  // =========================================================================
  // STT STATE
  // =========================================================================

  /// Set listening state
  void setListening(bool listening) {
    if (_isListening != listening) {
      _isListening = listening;
      notifyListeners();
    }
  }

  /// Called when STT starts
  void onListeningStarted() {
    _isListening = true;
    _isSpeaking = false; // Can't speak while listening
    notifyListeners();
  }

  /// Called when STT stops
  void onListeningStopped() {
    _isListening = false;
    notifyListeners();
  }

  // =========================================================================
  // AUTO-LISTEN CONTROL
  // =========================================================================

  /// Toggle auto-listen after TTS
  void toggleAutoListen() {
    _autoListenEnabled = !_autoListenEnabled;
    notifyListeners();
  }

  /// Set auto-listen
  void setAutoListen(bool enabled) {
    if (_autoListenEnabled != enabled) {
      _autoListenEnabled = enabled;
      notifyListeners();
    }
  }

  // =========================================================================
  // RESET
  // =========================================================================

  /// Reset all states
  void reset() {
    _mode = InteractionMode.voice;
    _isSpeaking = false;
    _isListening = false;
    _autoListenEnabled = true;
    notifyListeners();
  }
}

/// Global singleton instance
final interactionMode = InteractionModeProvider();
