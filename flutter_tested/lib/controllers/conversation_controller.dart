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
import '../models/message_queue.dart';
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
  // Services
  final TTSService _tts = TTSService();
  final STTService _stt = STTService();
  
  // Messages
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  
  // State
  ConversationState _state = ConversationState.idle;
  ConversationState get state => _state;
  
  // Current response info
  String _currentResponseType = '';
  bool _waitingForAnswer = false;

  // Error handling
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Silence detection
  Timer? _silenceTimer;
  int _silenceSeconds = 0;
  bool _silenceHandled = false;

  // Progress
  ProgressData? _progress;
  ProgressData? get progress => _progress;

  // Analytics
  StudentAnalytics? _analytics;
  StudentAnalytics? get analytics => _analytics;

  // Sequential display
  MessageQueue? _currentQueue;
  bool _showTypingIndicator = false;
  bool _ttsDone = false;
  bool _queueDone = false;

  bool get showTypingIndicator => _showTypingIndicator;
  bool get isDisplayingChunks => _currentQueue?.isRunning ?? false;
  bool get inputBlocked => isLoading || isDisplayingChunks;

  // =========================================================================
  // INITIALIZATION
  // =========================================================================

  Future<void> initialize() async {
    await _tts.init();
    await _stt.init();
    
    // Setup TTS callbacks
    _tts.onStart = () {
      _setState(ConversationState.speaking);
      interactionMode.onSpeakingStarted();
    };
    
    _tts.onComplete = () {
      interactionMode.onSpeakingCompleted();
      _ttsDone = true;
      _checkBothComplete();
    };

    _tts.onError = (error) {
      interactionMode.onSpeakingCompleted();
      _ttsDone = true;
      _checkBothComplete();
    };
    
    // Setup STT callbacks
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
      debugPrint('STT Error: $error');
    };
  }

  // =========================================================================
  // STATE MANAGEMENT
  // =========================================================================

  void _setState(ConversationState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  bool get isLoading => _state == ConversationState.loading;
  bool get isSpeaking => _state == ConversationState.speaking;
  bool get isListening => _state == ConversationState.listening;

  // =========================================================================
  // START SESSION
  // =========================================================================

  Future<void> startSession({bool forceNew = false}) async {
    _setState(ConversationState.loading);
    _errorMessage = null;
    _silenceHandled = false;
    
    try {
      final response = await ApiService.startSession(forceNew: forceNew);
      final learnoMessage = response.learnoResponse;
      
      // Update progress & analytics
      _progress = response.progress;
      _analytics = response.analytics;
      if (response.progress != null) {
        SessionState.updateProgress(response.progress!);
      }
      if (response.analytics != null) {
        SessionState.updateAnalytics(response.analytics);
      }

      // Set response type
      _currentResponseType = learnoMessage.responseType;
      _waitingForAnswer = _isQuestionType(_currentResponseType);

      _setState(ConversationState.idle);
      _enqueueResponse(learnoMessage);
      
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ConversationState.error);
    }
  }

  // =========================================================================
  // CONTINUE TEACHING
  // =========================================================================

  Future<void> continueTeaching() async {
    if (_state == ConversationState.loading) return;
    if (_waitingForAnswer) return;
    
    _setState(ConversationState.loading);
    
    try {
      final response = await ApiService.continueLesson();
      final learnoMessage = response.learnoResponse;
      
      // Update progress
      if (response.progress != null) {
        _progress = response.progress;
        SessionState.updateProgress(response.progress!);
      }

      _setState(ConversationState.idle);

      // Check completion
      if (response.isComplete) {
        SessionState.isLessonComplete = true;
        notifyListeners();
        return;
      }

      // Update response type
      _currentResponseType = learnoMessage.responseType;
      _waitingForAnswer = _isQuestionType(_currentResponseType);

      _enqueueResponse(learnoMessage);

    } catch (e) {
      _errorMessage = e.toString();
      _setState(ConversationState.error);
    }
  }

  // =========================================================================
  // SEND MESSAGE
  // =========================================================================

  Future<void> sendMessage(String text, {bool isVoice = false}) async {
    if (text.trim().isEmpty) return;

    // Abort any in-flight queue.
    _currentQueue?.cancel();
    _currentQueue = null;
    _showTypingIndicator = false;
    _ttsDone = false;
    _queueDone = false;

    // Stop TTS/STT
    await _tts.stop();
    await _stt.stopListening();

    _resetSilenceTimer();
    _silenceHandled = false;

    // Add user message
    _addUserMessage(text, isVoice: isVoice);

    _setState(ConversationState.loading);

    try {
      final response = await ApiService.sendResponse(text);
      final learnoMessage = response.learnoResponse;

      // Update progress
      if (response.progress != null) {
        _progress = response.progress;
        SessionState.updateProgress(response.progress!);
      }

      _setState(ConversationState.idle);

      // Check completion
      if (response.isComplete) {
        SessionState.isLessonComplete = true;
        notifyListeners();
        return;
      }

      // Update response type
      _currentResponseType = learnoMessage.responseType;
      _waitingForAnswer = _isQuestionType(_currentResponseType);

      _enqueueResponse(learnoMessage);

    } catch (e) {
      _errorMessage = e.toString();
      _setState(ConversationState.error);
    }
  }

  // =========================================================================
  // SEQUENTIAL DISPLAY
  // =========================================================================

  /// Enqueues a [LearnoResponse] for sequential chunk display.
  /// Starts TTS on the full text in parallel (voice mode only).
  void _enqueueResponse(LearnoResponse response) {
    _currentQueue?.cancel();
    _currentQueue = null;

    // Record full message in session state once (not per chunk).
    SessionState.addLearnoMessage(
      response.text,
      response.responseType,
      imageUrl: response.displayImageUrl,
    );

    final chunks = response.hasMessages
        ? response.messages
            .map((m) => QueuedChunk(text: m.text, delayMs: m.delayMs))
            .toList()
        : [QueuedChunk(text: response.text, delayMs: 0)];

    final imageUrl = response.displayImageUrl;
    final imagePos = response.imagePosition;

    // In text mode TTS never fires, so pre-mark it done.
    _ttsDone = !interactionMode.isVoiceMode;
    _queueDone = false;

    _showTypingIndicator = true;
    notifyListeners();

    _currentQueue = MessageQueue(
      chunks: chunks,
      onShowTypingIndicator: () {
        _showTypingIndicator = true;
        notifyListeners();
      },
      onHideTypingIndicator: () {
        _showTypingIndicator = false;
        notifyListeners();
      },
      onChunkReady: (text, index) {
        _messages.add(ChatMessage(
          text: text,
          isUser: false,
          responseType: response.responseType,
          imageUrl: (imageUrl != null && index == imagePos) ? imageUrl : null,
        ));
        notifyListeners();
      },
      onComplete: () {
        _queueDone = true;
        _checkBothComplete();
      },
    )..start();

    // TTS reads the full combined text as one continuous read.
    if (interactionMode.isVoiceMode) {
      _setState(ConversationState.speaking);
      _tts.speak(response.text);
    }
  }

  /// Called when both TTS and the chunk queue have finished.
  void _checkBothComplete() {
    if (!_ttsDone || !_queueDone) return;
    _ttsDone = false;
    _queueDone = false;
    _handleAfterSequenceComplete();
  }

  void _handleAfterSequenceComplete() {
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

  // =========================================================================
  // VOICE CONTROL
  // =========================================================================

  Future<void> startListening() async {
    if (!interactionMode.isVoiceMode) return;
    if (_state == ConversationState.loading) return;
    if (_state == ConversationState.speaking) return;

    await _stt.startListening();
  }

  Future<void> stopListening() async {
    await _stt.stopListening();
  }

  // =========================================================================
  // SILENCE HANDLING
  // =========================================================================

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

      // If user sent a message while the API call was in flight,
      // sendMessage() will have set _silenceHandled = false — discard the hint.
      if (!_silenceHandled) return;

      final hint = response.learnoResponse;
      if (hint == null) {
        _setState(ConversationState.waitingForInput);
        return;
      }

      _setState(ConversationState.idle);
      _enqueueResponse(hint);

      // Reset for next silence (happens after sequence completes via _handleAfterSequenceComplete)
      _silenceHandled = false;
      _startSilenceTimer();

    } catch (e) {
      _setState(ConversationState.waitingForInput);
    }
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

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

  void _addUserMessage(String text, {bool isVoice = false}) {
    _messages.add(ChatMessage(
      text: text,
      isUser: true,
      isVoiceMessage: isVoice,
    ));
    
    SessionState.addChildMessage(text, isVoice: isVoice);
    notifyListeners();
  }

  // =========================================================================
  // CLEANUP
  // =========================================================================

  void clear() {
    _currentQueue?.cancel();
    _currentQueue = null;
    _showTypingIndicator = false;
    _ttsDone = false;
    _queueDone = false;
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
    _currentQueue?.cancel();
    _silenceTimer?.cancel();
    _tts.dispose();
    _stt.dispose();
    super.dispose();
  }
}
