/// =============================================================================
/// Conversation Controller - Chat Flow Management
/// =============================================================================
/// 🆕 NEW FILE
///
/// Controls the conversation flow between child and Learno:
/// - Manages message sending/receiving
/// - Handles TTS/STT coordination
/// - Controls silence detection
/// - Manages teaching flow (continue, respond, hint)
/// =============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../api/api_service.dart';
import '../api/api_config.dart';
import '../api/dto.dart';
import '../models/chat_message.dart';
import '../services/tts_service.dart';
import '../services/stt_service.dart';
import '../providers/interaction_mode.dart';
import '../core/session_state.dart';

enum ConversationState {
  idle,
  loading,
  speaking,
  listening,
  waitingForInput,
  error,
}

class ConversationController extends ChangeNotifier {
  final TTSService _tts = TTSService();
  final STTService _stt = STTService();

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  ConversationState _state = ConversationState.idle;
  ConversationState get state => _state;

  String _currentResponseType = '';
  bool _waitingForAnswer = false;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Timer? _silenceTimer;
  int _silenceSeconds = 0;
  bool _silenceHandled = false;

  ProgressData? _progress;
  ProgressData? get progress => _progress;

  StudentAnalytics? _analytics;
  StudentAnalytics? get analytics => _analytics;


  Future<void> initialize() async {
    await _tts.init();
    await _stt.init();

    _tts.onStart = () {
      _setState(ConversationState.speaking);
      interactionMode.onSpeakingStarted();
    };
    
    _tts.onComplete = () {
      interactionMode.onSpeakingCompleted();
      _handleTTSComplete();
    };
    
    _tts.onError = (error) {
      interactionMode.onSpeakingCompleted();
      print('TTS Error: $error');
    };

    _stt.onResult = (text, isFinal) {
      if (isFinal && text.isNotEmpty) {
        sendMessage(text, isVoice: true);
      }
    };
    
    _stt.onListeningStarted = () {
      _setState(ConversationState.listening);
      interactionMode.onListeningStarted();
    };
    
    _stt.onListeningStopped = () {
      interactionMode.onListeningStopped();
      if (_state == ConversationState.listening) {
        _setState(ConversationState.waitingForInput);
      }
    };
    
    _stt.onError = (error) {
      interactionMode.onListeningStopped();
      print('STT Error: $error');
    };
  }


  void _setState(ConversationState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  bool get isLoading => _state == ConversationState.loading;
  bool get isSpeaking => _state == ConversationState.speaking;
  bool get isListening => _state == ConversationState.listening;


  Future<void> startSession({bool forceNew = false}) async {
    _setState(ConversationState.loading);
    _errorMessage = null;
    _silenceHandled = false;
    
    try {
      final response = await ApiService.startSession(forceNew: forceNew);
      final learnoMessage = response.learnoResponse;

      _addLearnoMessage(learnoMessage);

      _progress = response.progress;
      _analytics = response.analytics;
      if (response.progress != null) {
        SessionState.updateProgress(response.progress!);
      }
      if (response.analytics != null) {
        SessionState.updateAnalytics(response.analytics);
      }

      _currentResponseType = learnoMessage.responseType;
      _waitingForAnswer = _isQuestionType(_currentResponseType);
      
      _setState(ConversationState.idle);

      if (interactionMode.isVoiceMode) {
        await _speak(learnoMessage.text);
      } else {
        _handleNonVoiceFlow();
      }
      
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ConversationState.error);
    }
  }


  Future<void> continueTeaching() async {
    if (_state == ConversationState.loading) return;
    if (_waitingForAnswer) return;
    
    _setState(ConversationState.loading);
    
    try {
      final response = await ApiService.continueLesson();
      final learnoMessage = response.learnoResponse;
      
      _addLearnoMessage(learnoMessage);

      if (response.progress != null) {
        _progress = response.progress;
        SessionState.updateProgress(response.progress!);
      }
      
      _setState(ConversationState.idle);

      if (response.isComplete) {
        SessionState.isLessonComplete = true;
        notifyListeners();
        return;
      }

      _currentResponseType = learnoMessage.responseType;
      _waitingForAnswer = _isQuestionType(_currentResponseType);

      if (interactionMode.isVoiceMode) {
        await _speak(learnoMessage.text);
      } else {
        _handleNonVoiceFlow();
      }
      
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ConversationState.error);
    }
  }


  Future<void> sendMessage(String text, {bool isVoice = false}) async {
    if (text.trim().isEmpty) return;

    await _tts.stop();
    await _stt.stopListening();
    
    _resetSilenceTimer();
    _silenceHandled = false;

    _addUserMessage(text, isVoice: isVoice);
    
    _setState(ConversationState.loading);
    
    try {
      final response = await ApiService.sendResponse(text);
      final learnoMessage = response.learnoResponse;
      
      _addLearnoMessage(learnoMessage);

      if (response.progress != null) {
        _progress = response.progress;
        SessionState.updateProgress(response.progress!);
      }
      
      _setState(ConversationState.idle);

      if (response.isComplete) {
        SessionState.isLessonComplete = true;
        notifyListeners();
        return;
      }

      _currentResponseType = learnoMessage.responseType;
      _waitingForAnswer = _isQuestionType(_currentResponseType);

      if (interactionMode.isVoiceMode) {
        await _speak(learnoMessage.text);
      } else {
        _handleNonVoiceFlow();
      }
      
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ConversationState.error);
    }
  }


  Future<void> _speak(String text) async {
    _setState(ConversationState.speaking);
    await _tts.speak(text);
  }

  Future<void> startListening() async {
    if (!interactionMode.isVoiceMode) return;
    if (_state == ConversationState.loading) return;
    if (_state == ConversationState.speaking) return;
    
    await _stt.startListening();
  }

  Future<void> stopListening() async {
    await _stt.stopListening();
  }

  void _handleTTSComplete() {
    if (_waitingForAnswer) {
      _startSilenceTimer();
      if (interactionMode.isVoiceMode && interactionMode.autoListenEnabled) {
        startListening();
      } else {
        _setState(ConversationState.waitingForInput);
      }
    } else {
      continueTeaching();
    }
  }

  void _handleNonVoiceFlow() {
    if (_waitingForAnswer) {
      _startSilenceTimer();
      _setState(ConversationState.waitingForInput);
    } else {
      Future.delayed(const Duration(seconds: 2), () {
        if (!_waitingForAnswer) {
          continueTeaching();
        }
      });
    }
  }


  void _startSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceSeconds = 0;
    
    _silenceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _silenceSeconds++;
      
      if (_silenceSeconds >= ApiConfig.silenceThresholdSeconds && !_silenceHandled) {
        _handleSilence();
        timer.cancel();
      }
    });
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceSeconds = 0;
  }

  Future<void> _handleSilence() async {
    if (_state == ConversationState.loading || _silenceHandled) return;
    
    _silenceHandled = true;
    _setState(ConversationState.loading);
    
    try {
      final response = await ApiService.notifySilence(
        ApiConfig.silenceThresholdSeconds.toDouble(),
      );
      
      final hint = response.learnoResponse;
      if (hint == null) {
        _setState(ConversationState.waitingForInput);
        return;
      }
      
      _addLearnoMessage(hint);
      _setState(ConversationState.idle);

      if (interactionMode.isVoiceMode) {
        await _speak(hint.text);
      }

      _silenceHandled = false;
      _startSilenceTimer();
      
    } catch (e) {
      _setState(ConversationState.waitingForInput);
    }
  }


  bool _isQuestionType(String responseType) {
    const questionTypes = [
      'guided_practice',
      'independent_practice', 
      'mastery_check',
      'chapter_review',
      'question',
    ];
    return questionTypes.contains(responseType);
  }

  void _addLearnoMessage(LearnoResponse response) {
    _messages.add(ChatMessage(
      text: response.text,
      isUser: false,
      responseType: response.responseType,
      imageUrl: response.generatedImageUrl,
    ));
    
    SessionState.addLearnoMessage(
      response.text,
      response.responseType,
      imageUrl: response.generatedImageUrl,
    );
    
    notifyListeners();
  }

  void _addUserMessage(String text, {bool isVoice = false}) {
    _messages.add(ChatMessage(
      text: text,
      isUser: true,
      isVoiceMessage: isVoice,
    ));
    
    SessionState.addChildMessage(text, isVoice: isVoice);
    notifyListeners();
  }


  void clear() {
    _messages.clear();
    _silenceTimer?.cancel();
    _state = ConversationState.idle;
    _errorMessage = null;
    _progress = null;
    _analytics = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _tts.dispose();
    _stt.dispose();
    super.dispose();
  }
}
