

import 'dart:async';
import 'dart:convert';
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
  final TTSService _tts = TTSService();
  final STTService _stt = STTService();

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessageUI> _messages = [];
  bool _isLoading = false;
  bool _sessionStarted = false;
  bool _silenceHandled = false;
  String? _errorMessage;

  String _currentResponseType = '';
  bool _waitingForAnswer = false;

  Timer? _silenceTimer;
  int _silenceSeconds = 0;

  bool _isVoiceMode = true;
  bool _isSpeaking = false;
  bool _isListening = false;

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



  Future<void> _initServices() async {
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

      _addLearnoMessage(learnoMessage);

      if (response.progress != null) {
        _progress = response.progress;
        SessionState.updateProgress(response.progress!);
      }

      if (response.analytics != null) {
        SessionState.updateAnalytics(response.analytics);
      }

      setState(() => _isLoading = false);

      _currentResponseType = learnoMessage.responseType;
      _waitingForAnswer = _isQuestionType(_currentResponseType);

      if (_isVoiceMode) {
        await _tts.speak(learnoMessage.text);
      } else {
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



  void _handleTTSComplete() {
    if (_waitingForAnswer) {
      _startSilenceTimer();
      if (_isVoiceMode) {
        _startListening();
      }
    } else {
      _continueTeaching();
    }
  }



  Future<void> _continueTeaching() async {
    if (_isLoading || !SessionState.isActive) return;
    if (_waitingForAnswer) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.continueLesson();
      final learnoMessage = response.learnoResponse;

      _addLearnoMessage(learnoMessage);

      if (response.progress != null) {
        _progress = response.progress;
        SessionState.updateProgress(response.progress!);
      }

      setState(() => _isLoading = false);

      if (response.isComplete) {
        _handleLessonComplete();
        return;
      }

      _currentResponseType = learnoMessage.responseType;
      _waitingForAnswer = _isQuestionType(_currentResponseType);

      if (_isVoiceMode) {
        await _tts.speak(learnoMessage.text);
      } else {
        if (_waitingForAnswer) {
          _startSilenceTimer();
        } else {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && !_waitingForAnswer && !_isLoading) {
              _continueTeaching();
            }
          });
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


  Future<void> _sendMessage(String text, {bool isVoice = false}) async {
    if (text.trim().isEmpty) return;

    if (_isSpeaking) await _tts.stop();
    if (_isListening) await _stt.stopListening();

    _resetSilenceTimer();
    _silenceHandled = false;

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

      if (response.progress != null) {
        _progress = response.progress;
        SessionState.updateProgress(response.progress!);
      }

      setState(() => _isLoading = false);

      if (response.isComplete) {
        _handleLessonComplete();
        return;
      }

      _currentResponseType = learnoMessage.responseType;
      _waitingForAnswer = _isQuestionType(_currentResponseType);

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

      if (_isVoiceMode) {
        await _tts.speak(hint.text);
      }

      _silenceHandled = false;
      _startSilenceTimer();

      _scrollToBottom();
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }



  bool _isQuestionType(String responseType) {
    const questionTypes = [
      'guided_practice',
      'independent_practice',
      'mastery_check',
      'chapter_review',
      'question',
      'hint',
      'silence_hint',
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/chat_background.png',
              fit: BoxFit.cover,
            ),
          ),
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
      backgroundColor: const Color(0xFFFF8D00),
      title: const Text('Learno'),
      foregroundColor: Colors.white,
      automaticallyImplyLeading: false,
      leadingWidth: 40,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 26,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
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
            if (msg.imageUrl != null) _buildMessageImage(msg.imageUrl!),
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
        child: _buildImageWidget(imageUrl),
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64Data = imageUrl.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          width: 220,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildImageError(),
        );
      } catch (e) {
        print('❌ Base64 decode error: $e');
        return _buildImageError();
      }
    }

    return Image.network(
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
      errorBuilder: (_, __, ___) => _buildImageError(),
    );
  }

  Widget _buildImageError() {
    return Container(
      width: 220,
      height: 220,
      color: Colors.grey[200],
      child: const Icon(Icons.image_not_supported, size: 50),
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
                if (_isVoiceMode)
                  GestureDetector(
                    onTap: _isListening ? _stopListening : _startListening,
                    child: Container(
                      padding: const EdgeInsets.all(7),
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
