import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:learno/l10n/app_localizations.dart';

import '../core/session_state.dart';
import '../api/api_service.dart';
import '../api/api_config.dart';
import '../api/dto.dart';
import '../models/message_queue.dart';
import '../services/tts_service.dart';
import '../services/stt_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _tts = TTSService();
  final _stt = STTService();

  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  final List<_ChatMessageUI> _messages = [];

  bool _isLoading = false;
  bool _isStartingSession = false;
  bool _sessionStarted = false;
  bool _silenceHandled = false;
  String? _errorMessage;
  String _currentResponseType = '';
  bool _waitingForAnswer = false;

  bool _isVoiceMode = true;
  bool _isSpeaking = false;
  bool _isListening = false;

  MessageQueue? _currentQueue;
  bool _showTypingIndicator = false;

  bool _ttsDone = false;
  bool _queueDone = false;

  Timer? _silenceTimer;
  int _silenceSeconds = 0;

  ProgressData? _progress;

  bool get _inputBlocked => _isLoading || (_currentQueue?.isRunning ?? false);

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
    _currentQueue?.cancel();
    _tts.dispose();
    _stt.dispose();
    super.dispose();
  }

  Future<void> _initServices() async {
    await _tts.init();
    _tts.onStart = () => setState(() => _isSpeaking = true);
    _tts.onComplete = () {
      setState(() => _isSpeaking = false);
      _ttsDone = true;
      _checkBothComplete();
    };
    _tts.onError = (error) {
      setState(() => _isSpeaking = false);
      _ttsDone = true;
      _checkBothComplete();
    };

    await _stt.init();
    _stt.onResult = (text, isFinal) {
      if (isFinal && text.isNotEmpty) _sendMessage(text, isVoice: true);
    };
    _stt.onListeningStarted = () => setState(() => _isListening = true);
    _stt.onListeningStopped = () => setState(() => _isListening = false);
    _stt.onError = (error) => setState(() => _isListening = false);
  }

  Future<void> _startSession() async {
    if (_sessionStarted) return;
    _sessionStarted = true;

    setState(() {
      _isLoading = true;
      _isStartingSession = true;
      _errorMessage = null;
      _silenceHandled = false;
    });

    try {
      final response = await ApiService.startSession();

      if (response.progress != null) {
        _progress = response.progress;
        SessionState.updateProgress(response.progress!);
      }
      if (response.analytics != null) {
        SessionState.updateAnalytics(response.analytics);
      }

      setState(() {
        _isLoading = false;
        _isStartingSession = false;
      });

      _currentResponseType = response.learnoResponse.responseType;
      _waitingForAnswer = _isQuestionType(_currentResponseType);

      _enqueueResponse(response.learnoResponse);
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isStartingSession = false;
        _errorMessage = e.toString();
      });
      _showError(e.toString());
    }
  }

  void _enqueueResponse(LearnoResponse response) {
    _currentQueue?.cancel();
    _currentQueue = null;

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

    _ttsDone = !_isVoiceMode;
    _queueDone = false;

    setState(() => _showTypingIndicator = true);

    _currentQueue = MessageQueue(
      chunks: chunks,
      onShowTypingIndicator: () {
        if (mounted) setState(() => _showTypingIndicator = true);
      },
      onHideTypingIndicator: () {
        if (mounted) setState(() => _showTypingIndicator = false);
      },
      onChunkReady: (text, index) {
        if (!mounted) return;
        setState(() {
          _messages.add(_ChatMessageUI(
            text: text,
            isUser: false,
            responseType: response.responseType,
            imageUrl: (imageUrl != null && index == imagePos) ? imageUrl : null,
          ));
        });
        _scrollToBottom();
      },
      onComplete: () {
        _queueDone = true;
        _checkBothComplete();
      },
    )..start();

    if (_isVoiceMode) {
      _tts.speak(response.text);
    }
  }

  void _checkBothComplete() {
    if (!_ttsDone || !_queueDone) return;
    _ttsDone = false;
    _queueDone = false;
    _handleAfterSequenceComplete();
  }

  void _handleAfterSequenceComplete() {
    if (_waitingForAnswer) {
      _startSilenceTimer();
      if (_isVoiceMode) _startListening();
    } else {
      _continueTeaching();
    }
  }

  Future<void> _continueTeaching() async {
    if (_isLoading || !SessionState.isActive) return;
    if (_waitingForAnswer) return;
    if (_currentQueue?.isRunning ?? false) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.continueLesson();

      if (response.progress != null) {
        _progress = response.progress;
        SessionState.updateProgress(response.progress!);
      }

      setState(() => _isLoading = false);

      if (response.isComplete) {
        _handleLessonComplete();
        return;
      }

      _currentResponseType = response.learnoResponse.responseType;
      _waitingForAnswer = _isQuestionType(_currentResponseType);

      _enqueueResponse(response.learnoResponse);
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

    _currentQueue?.cancel();
    _currentQueue = null;
    _showTypingIndicator = false;
    _ttsDone = false;
    _queueDone = false;

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

      if (response.progress != null) {
        _progress = response.progress;
        SessionState.updateProgress(response.progress!);
      }

      setState(() => _isLoading = false);

      if (response.isComplete) {
        _handleLessonComplete();
        return;
      }

      _currentResponseType = response.learnoResponse.responseType;
      _waitingForAnswer = _isQuestionType(_currentResponseType);

      _enqueueResponse(response.learnoResponse);
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

  void _stopListening() async => _stt.stopListening();

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

      setState(() => _isLoading = false);
      _enqueueResponse(hint);
      _scrollToBottom();

      _silenceHandled = false;
      _startSilenceTimer();
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
    ];
    return questionTypes.contains(responseType);
  }

  void _handleLessonComplete() {
    _silenceTimer?.cancel();
    _currentQueue?.cancel();
    SessionState.isLessonComplete = true;
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _showCompletionDialog();
    });
  }

  void _showCompletionDialog() {
    final l10n = AppLocalizations.of(context)!;
    final accuracy = SessionState.accuracyPercent * 100;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.greatJobTitle, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.lessonCompletedMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Text(l10n.correctAnswersCount(SessionState.totalCorrect),
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(l10n.accuracyScoreLabel(accuracy.toStringAsFixed(0)),
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text(l10n.youAreAStar, style: const TextStyle(fontSize: 20)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(l10n.continueButton,
                style: const TextStyle(fontSize: 18)),
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
          backgroundColor: const Color(0xFF76310F)),
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: _buildAppBar(l10n),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/chat_background.png',
                fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildProgressBar(l10n),
                Expanded(child: _buildMessageList(l10n)),
                _buildInputArea(l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      title: const Text('Learno'),
      backgroundColor: const Color(0xFFFF8D00),
      foregroundColor: Colors.white,
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
                Icon(_getLevelIcon(SessionState.learningLevel),
                    size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(_getLevelText(SessionState.learningLevel, l10n),
                    style: const TextStyle(fontSize: 12, color: Colors.white)),
              ],
            ),
          ),
        IconButton(
          icon: Icon(_isVoiceMode ? Icons.mic : Icons.mic_off),
          onPressed: _toggleVoiceMode,
          tooltip: _isVoiceMode ? l10n.voiceOnTooltip : l10n.voiceOffTooltip,
        ),
      ],
    );
  }

  Widget _buildProgressBar(AppLocalizations l10n) {
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
                l10n.conceptProgressLabel(
                    progress.currentConcept, progress.totalConcepts),
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Color(0xFF44200B)),
              ),
              Text(
                '✅ ${progress.totalCorrect}  ❌ ${progress.totalWrong}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF44200B)),
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
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFFF8D00)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(AppLocalizations l10n) {
    final hasIndicator = _isLoading || _showTypingIndicator;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (hasIndicator ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _messages.length) {
          return _isLoading
              ? _buildLoadingIndicator(l10n)
              : const _TypingIndicator();
        }
        return _buildMessageBubble(_messages[index], l10n);
      },
    );
  }

  Widget _buildMessageBubble(_ChatMessageUI msg, AppLocalizations l10n) {
    final isUser = msg.isUser;
    final maxWidth = MediaQuery.of(context).size.width * 0.75;

    Widget bubble = Align(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            if (msg.imageUrl != null) _buildMessageImage(msg.imageUrl!, l10n),
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

    if (isUser) return bubble;
    return TweenAnimationBuilder<double>(
      key: ValueKey(msg.id),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      builder: (context, opacity, child) =>
          Opacity(opacity: opacity, child: child!),
      child: bubble,
    );
  }

  Widget _buildMessageImage(String imageUrl, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 220,
          height: 220,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 220,
            height: 220,
            color: const Color(0xFFFFEDDC),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF8D00)),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: 220,
            height: 220,
            decoration: const BoxDecoration(color: Color(0xFFFFEDDC)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.image_not_supported,
                    size: 50, color: Color(0xFF76310F)),
                const SizedBox(height: 8),
                Text(l10n.imageNotAvailableLabel,
                    style: const TextStyle(
                        color: Color(0xFF76310F), fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(AppLocalizations l10n) {
    final label = _isStartingSession
        ? 'Preparing your lesson…\nThis may take up to a minute.'
        : l10n.thinkingLabel;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEDDC),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFFFF8D00)),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(label,
                  style: const TextStyle(color: Color(0xFF44200B))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_isSpeaking || _isListening)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    _isSpeaking
                        ? l10n.learnoIsSpeakingLabel
                        : l10n.listeningLabel,
                    style: TextStyle(
                      color: _isSpeaking
                          ? Colors.blue[700]
                          : Colors.green[700],
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
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onSubmitted: _inputBlocked ? null : (t) => _sendMessage(t),
                    decoration: InputDecoration(
                      hintText: _isVoiceMode
                          ? l10n.tapMicOrTypeHint
                          : l10n.typeYourAnswerHint,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (_isVoiceMode)
                  GestureDetector(
                    onTap: _isListening ? _stopListening : _startListening,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isListening
                            ? const Color(0xFF76310F)
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
                if (!_isVoiceMode || _textController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFFFF8D00)),
                    iconSize: 28,
                    onPressed: _inputBlocked
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
      case 'struggling': return Colors.orange;
      case 'developing': return Colors.blue;
      case 'proficient': return Colors.green;
      case 'advanced':   return Colors.purple;
      default:           return Colors.grey;
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level) {
      case 'struggling': return Icons.support;
      case 'developing': return Icons.trending_up;
      case 'proficient': return Icons.star;
      case 'advanced':   return Icons.emoji_events;
      default:           return Icons.school;
    }
  }

  String _getLevelText(String level, AppLocalizations l10n) {
    switch (level) {
      case 'struggling': return l10n.levelLearning;
      case 'developing': return l10n.levelGrowing;
      case 'proficient': return l10n.levelGreat;
      case 'advanced':   return l10n.levelStar;
      default:           return '';
    }
  }
}

// =============================================================================
// TYPING INDICATOR
// =============================================================================

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEDDC),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(controller: _controller, phase: 0.0),
            const SizedBox(width: 5),
            _Dot(controller: _controller, phase: 1 / 3),
            const SizedBox(width: 5),
            _Dot(controller: _controller, phase: 2 / 3),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final AnimationController controller;
  final double phase;

  const _Dot({required this.controller, required this.phase});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = (controller.value + phase) % 1.0;
        final bounce = t < 0.5
            ? Curves.easeOut.transform(t * 2)
            : Curves.easeIn.transform((1.0 - t) * 2);
        return Transform.translate(
          offset: Offset(0, -6 * bounce),
          child: child!,
        );
      },
      child: Container(
        width: 9,
        height: 9,
        decoration: const BoxDecoration(
          color: Color(0xFF44200B),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// =============================================================================
// UI MESSAGE MODEL
// =============================================================================

class _ChatMessageUI {
  static int _counter = 0;

  final int id;
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
  }) : id = _counter++;
}
