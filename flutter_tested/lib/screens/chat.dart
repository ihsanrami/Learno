/// =============================================================================
/// Chat Screen - Main Learning Interface
/// =============================================================================
/// 🔄 MAJOR UPDATE:
/// ✅ TTS auto-start (Learno speaks)
/// ✅ STT integration (child speaks)
/// ✅ Voice/Text mode toggle
/// ✅ Image display from AI
/// ✅ Progress bar with concepts
/// ✅ Student level indicator
/// ✅ Continue teaching flow
/// ✅ Silence detection
/// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';

import '../core/session_state.dart';
import '../api/api_service.dart';
import '../api/api_config.dart';
import '../api/dto.dart';
import '../models/enums.dart';
import '../services/tts_service.dart';
import '../services/stt_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Services
  final TTSService _tts = TTSService();
  final STTService _stt = STTService();

  // Controllers
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // State
  final List<_ChatMessageUI> _messages = [];
  bool _isLoading = false;
  bool _sessionStarted = false;
  bool _silenceHandled = false;
  String? _errorMessage;

  // Current response type (to determine if question)
  String _currentResponseType = '';
  bool _waitingForAnswer = false;

  // Silence timer
  Timer? _silenceTimer;
  int _silenceSeconds = 0;

  // Voice state
  bool _isVoiceMode = true;
  bool _isSpeaking = false;
  bool _isListening = false;

  // Progress
  ProgressData? _progress;

  @override
  void initState() {
    super.initState();
    _initServices();
    _startSession();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _silenceTimer?.cancel();
    _tts.dispose();
    _stt.dispose();
    super.dispose();
  }

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  Future<void> _initServices() async {
    // Initialize TTS
    await _tts.init();
    _tts.onStart = () => setState(() => _isSpeaking = true);
    _tts.onComplete = () {
      setState(() => _isSpeaking = false);
      _handleTTSComplete();
    };
    _tts.onError = (error) {
      setState(() => _isSpeaking = false);
      print('TTS Error: $error');
    };

    // Initialize STT
    await _stt.init();
    _stt.onResult = (text, isFinal) {
      if (isFinal && text.isNotEmpty) {
        _sendMessage(text, isVoice: true);
      }
    };
    _stt.onListeningStarted = () => setState(() => _isListening = true);
    _stt.onListeningStopped = () => setState(() => _isListening = false);
    _stt.onError = (error) {
      setState(() => _isListening = false);
      print('STT Error: $error');
    };
  }

  // ===========================================================================
  // SESSION START
  // ===========================================================================

  Future<void> _startSession() async {
    if (_sessionStarted) return;
    _sessionStarted = true;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _silenceHandled = false;
    });

    try {
      final response = await ApiService.startSession();
      final learnoMessage = response.learnoResponse;

      // Add message
      _addLearnoMessage(learnoMessage);

      // Update progress
      if (response.progress != null) {
        _progress = response.progress;
        SessionState.updateProgress(response.progress!);
      }

      // Update analytics
      if (response.analytics != null) {
        SessionState.updateAnalytics(response.analytics);
      }

      setState(() => _isLoading = false);

      // Determine response type
      _currentResponseType = learnoMessage.responseType;
      _waitingForAnswer = _isQuestionType(_currentResponseType);

      // 🎧 AUTO-START VOICE
      if (_isVoiceMode) {
        await _tts.speak(learnoMessage.text);
      } else {
        // If not voice mode, continue teaching immediately if not question
        if (!_waitingForAnswer) {
          _continueTeaching();
        } else {
          _startSilenceTimer();
        }
      }

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      _showError(e.toString());
    }
  }

  // ===========================================================================
  // HANDLE TTS COMPLETE
  // ===========================================================================

  void _handleTTSComplete() {
    // After TTS finishes speaking...
    if (_waitingForAnswer) {
      // If this was a question, start listening or wait for input
      _startSilenceTimer();
      if (_isVoiceMode) {
        _startListening();
      }
    } else {
      // If not a question, continue teaching
      _continueTeaching();
    }
  }

  // ===========================================================================
  // CONTINUE TEACHING
  // ===========================================================================

  Future<void> _continueTeaching() async {
    if (_isLoading || !SessionState.isActive) return;
    if (_waitingForAnswer) return; // Don't continue if waiting for answer

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.continueLesson();
      final learnoMessage = response.learnoResponse;

      _addLearnoMessage(learnoMessage);

      // Update progress
      if (response.progress != null) {
        _progress = response.progress;
        SessionState.updateProgress(response.progress!);
      }

      setState(() => _isLoading = false);

      // Check if lesson complete
      if (response.isComplete) {
        _handleLessonComplete();
        return;
      }

      // Update response type
      _currentResponseType = learnoMessage.responseType;
      _waitingForAnswer = _isQuestionType(_currentResponseType);

      // Speak the response
      if (_isVoiceMode) {
        await _tts.speak(learnoMessage.text);
      } else {
        if (!_waitingForAnswer) {
          // Auto-continue after delay if not question
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && !_waitingForAnswer) {
              _continueTeaching();
            }
          });
        } else {
          _startSilenceTimer();
        }
      }

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      _showError(e.toString());
    }
  }

  // ===========================================================================
  // SEND MESSAGE (Answer)
  // ===========================================================================

  Future<void> _sendMessage(String text, {bool isVoice = false}) async {
    if (text.trim().isEmpty) return;

    // Stop TTS/STT
    if (_isSpeaking) await _tts.stop();
    if (_isListening) await _stt.stopListening();

    _resetSilenceTimer();
    _silenceHandled = false;

    // Add user message
    setState(() {
      _messages.add(_ChatMessageUI(
        text: text,
        isUser: true,
        isVoiceMessage: isVoice,
      ));
      _isLoading = true;
      _errorMessage = null;
    });

    SessionState.addChildMessage(text, isVoice: isVoice);
    _scrollToBottom();

    try {
      final response = await ApiService.sendResponse(text);
      final learnoMessage = response.learnoResponse;

      _addLearnoMessage(learnoMessage);

      // Update progress
      if (response.progress != null) {
        _progress = response.progress;
        SessionState.updateProgress(response.progress!);
      }

      setState(() => _isLoading = false);

      // Check if complete
      if (response.isComplete) {
        _handleLessonComplete();
        return;
      }

      // Update response type
      _currentResponseType = learnoMessage.responseType;
      _waitingForAnswer = _isQuestionType(_currentResponseType);

      // Speak
      if (_isVoiceMode) {
        await _tts.speak(learnoMessage.text);
      } else {
        if (!_waitingForAnswer) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && !_waitingForAnswer) {
              _continueTeaching();
            }
          });
        } else {
          _startSilenceTimer();
        }
      }

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      _showError(e.toString());
    }

    _textController.clear();
  }

  // ===========================================================================
  // VOICE CONTROLS
  // ===========================================================================

  void _startListening() async {
    if (!_isVoiceMode || _isLoading || _isSpeaking) return;
    await _stt.startListening();
  }

  void _stopListening() async {
    await _stt.stopListening();
  }

  void _toggleVoiceMode() {
    setState(() {
      _isVoiceMode = !_isVoiceMode;
      SessionState.isVoiceMode = _isVoiceMode;
    });

    if (!_isVoiceMode) {
      _tts.stop();
      _stt.stopListening();
    }
  }

  // ===========================================================================
  // SILENCE HANDLING
  // ===========================================================================

  void _startSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceSeconds = 0;

    _silenceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _silenceSeconds++;

      if (_silenceSeconds >= ApiConfig.silenceThresholdSeconds &&
          !_silenceHandled) {
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
    if (_isLoading || !SessionState.isActive || _silenceHandled) return;

    _silenceHandled = true;

    try {
      setState(() => _isLoading = true);

      final response = await ApiService.notifySilence(
        ApiConfig.silenceThresholdSeconds.toDouble(),
      );

      final hint = response.learnoResponse;
      if (hint == null) {
        setState(() => _isLoading = false);
        return;
      }

      _addLearnoMessage(hint);
      setState(() => _isLoading = false);

      // Speak hint
      if (_isVoiceMode) {
        await _tts.speak(hint.text);
      }

      // Reset silence handling for next question
      _silenceHandled = false;
      _startSilenceTimer();

      _scrollToBottom();
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

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
    setState(() {
      _messages.add(_ChatMessageUI(
        text: response.text,
        isUser: false,
        responseType: response.responseType,
        imageUrl: response.generatedImageUrl,
      ));
    });

    SessionState.addLearnoMessage(
      response.text,
      response.responseType,
      imageUrl: response.generatedImageUrl,
    );
  }

  void _handleLessonComplete() {
    _silenceTimer?.cancel();
    SessionState.isLessonComplete = true;

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _showCompletionDialog();
    });
  }

  void _showCompletionDialog() {
    final accuracy = SessionState.accuracyPercent * 100;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 Great Job!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You completed the lesson!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              '✅ ${SessionState.totalCorrect} correct answers',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '📊 ${accuracy.toStringAsFixed(0)}% accuracy',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text('⭐ You are a star! ⭐', style: TextStyle(fontSize: 20)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Continue', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[400],
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ===========================================================================
  // BUILD UI
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/chat_background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                _buildProgressBar(),
                Expanded(child: _buildMessageList()),
                _buildInputArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Learno'),
      backgroundColor: const Color(0xFFFF8D00),
      foregroundColor: Colors.white,
      actions: [
        // Student level indicator
        if (_progress != null)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getLevelColor(SessionState.learningLevel),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getLevelIcon(SessionState.learningLevel),
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  _getLevelText(SessionState.learningLevel),
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
          ),
        // Voice toggle
        IconButton(
          icon: Icon(_isVoiceMode ? Icons.mic : Icons.mic_off),
          onPressed: _toggleVoiceMode,
          tooltip: _isVoiceMode ? 'Voice ON' : 'Voice OFF',
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final progress = _progress;
    if (progress == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white.withOpacity(0.95),
      child: Column(
        children: [
          // Progress info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Concept ${progress.currentConcept} of ${progress.totalConcepts}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF44200B),
                ),
              ),
              Text(
                '✅ ${progress.totalCorrect}  ❌ ${progress.totalWrong}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF44200B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.progressPercent,
              minHeight: 10,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFF8D00),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isLoading) {
          return _buildLoadingIndicator();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(_ChatMessageUI msg) {
    final isUser = msg.isUser;
    final maxWidth = MediaQuery.of(context).size.width * 0.75;

    return Align(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            // Image
            if (msg.imageUrl != null) _buildMessageImage(msg.imageUrl!),
            // Text bubble
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFFFFB876)
                    : const Color(0xFFFFEDDC),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: const TextStyle(
                  color: Color(0xFF44200B),
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageImage(String imageUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          width: 220,
          height: 220,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 220,
              height: 220,
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF8D00),
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            width: 220,
            height: 220,
            color: Colors.grey[200],
            child: const Icon(Icons.image_not_supported, size: 50),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEDDC),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFFF8D00),
              ),
            ),
            SizedBox(width: 10),
            Text('Thinking...', style: TextStyle(color: Color(0xFF44200B))),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Speaking/Listening indicator
          if (_isSpeaking || _isListening)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isSpeaking ? Colors.blue[100] : Colors.green[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isSpeaking ? Icons.volume_up : Icons.mic,
                    size: 18,
                    color: _isSpeaking ? Colors.blue[700] : Colors.green[700],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isSpeaking ? '🔊 Learno is speaking...' : '🎤 Listening...',
                    style: TextStyle(
                      color: _isSpeaking ? Colors.blue[700] : Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          // Input row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Text input
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onSubmitted: _isLoading ? null : (t) => _sendMessage(t),
                    decoration: InputDecoration(
                      hintText: _isVoiceMode
                          ? 'Tap mic or type...'
                          : 'Type your answer...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                // Mic button (voice mode)
                if (_isVoiceMode)
                  GestureDetector(
                    onTap: _isListening ? _stopListening : _startListening,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isListening
                            ? Colors.red[400]
                            : const Color(0xFFFF8D00),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isListening ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                // Send button
                if (!_isVoiceMode || _textController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFFFF8D00)),
                    iconSize: 28,
                    onPressed: _isLoading
                        ? null
                        : () => _sendMessage(_textController.text),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LEVEL HELPERS
  // ===========================================================================

  Color _getLevelColor(String level) {
    switch (level) {
      case 'struggling':
        return Colors.orange;
      case 'developing':
        return Colors.blue;
      case 'proficient':
        return Colors.green;
      case 'advanced':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level) {
      case 'struggling':
        return Icons.support;
      case 'developing':
        return Icons.trending_up;
      case 'proficient':
        return Icons.star;
      case 'advanced':
        return Icons.emoji_events;
      default:
        return Icons.school;
    }
  }

  String _getLevelText(String level) {
    switch (level) {
      case 'struggling':
        return 'Learning';
      case 'developing':
        return 'Growing';
      case 'proficient':
        return 'Great!';
      case 'advanced':
        return 'Star!';
      default:
        return '';
    }
  }
}

// ===========================================================================
// UI MESSAGE MODEL
// ===========================================================================

class _ChatMessageUI {
  final String text;
  final bool isUser;
  final String? responseType;
  final String? imageUrl;
  final bool isVoiceMessage;

  _ChatMessageUI({
    required this.text,
    required this.isUser,
    this.responseType,
    this.imageUrl,
    this.isVoiceMessage = false,
  });
}
