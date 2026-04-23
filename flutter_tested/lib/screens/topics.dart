import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../core/session_state.dart';
import '../api/api_service.dart';
import '../api/dto.dart';
import 'chat.dart';

class TopicsScreen extends StatefulWidget {
  const TopicsScreen({super.key});

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  int? _selectedIndex;
  List<TopicData> _topics = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Same color palette as the original math.dart
  static const List<Color> _topicColors = [
    Color(0xFFFCA311),
    Color(0xFF00BF63),
    Color(0xFFFFADAD),
    Color(0xFF4CC9F0),
    Color(0xFF7678ED),
    Color(0xFFFF5C8A),
  ];

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final grade = _gradeToInt(SessionState.grade!);
      final subject = SessionState.subject!.name; // "math", "science", etc.
      final topics = await ApiService.fetchTopics(grade, subject);
      setState(() {
        _topics = topics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _screenTitle() {
    final subject = SessionState.subject;
    if (subject == null) return 'Topics';
    switch (subject) {
      case Subject.math:    return 'Math Topics';
      case Subject.science: return 'Science Topics';
      case Subject.english: return 'English Topics';
      case Subject.arabic:  return 'Arabic Topics';
      default:              return 'Topics';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/topics_background.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xFF44200B),
                          size: 26,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  _screenTitle(),
                  style: const TextStyle(
                    fontFamily: 'Recoleta',
                    fontWeight: FontWeight.w900,
                    fontSize: 42,
                    color: Color(0xFF44200B),
                  ),
                ),

                const SizedBox(height: 18),

                Expanded(child: _buildBody()),

                const SizedBox(height: 16),

                if (!_isLoading && _errorMessage == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Select a topic you want to start with,\nthen press Continue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Recoleta',
                        fontWeight: FontWeight.w400,
                        fontSize: 17,
                        height: 1.3,
                        color: Color(0xFF44200B),
                      ),
                    ),
                  ),

                const SizedBox(height: 60),

                if (!_isLoading && _errorMessage == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: GestureDetector(
                      onTap: _selectedIndex == null ? null : _startLesson,
                      child: Opacity(
                        opacity: _selectedIndex == null ? 0.4 : 1.0,
                        child: Image.asset(
                          'assets/images/continue.png',
                          width: MediaQuery.of(context).size.width * 0.30,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF8D00)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFF76310F), size: 48),
              const SizedBox(height: 12),
              Text(
                'Could not load topics.\nPlease check your connection.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF44200B),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadTopics,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8D00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_topics.isEmpty) {
      return const Center(
        child: Text(
          'No topics available.',
          style: TextStyle(color: Color(0xFF44200B), fontSize: 16),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 19),
      itemCount: _topics.length,
      separatorBuilder: (_, __) => const SizedBox(height: 9),
      itemBuilder: (context, index) {
        final isSelected = _selectedIndex == index;
        final topic = _topics[index];
        final color = _topicColors[index % _topicColors.length];

        return GestureDetector(
          onTap: () => setState(() => _selectedIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: isSelected
                ? (Matrix4.identity()..scale(1.03))
                : Matrix4.identity(),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    topic.nameEn,
                    style: const TextStyle(
                      fontFamily: 'Recoleta',
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 26,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startLesson() {
    if (_selectedIndex == null || _selectedIndex! >= _topics.length) return;
    final topic = _topics[_selectedIndex!];
    // Pass the English display name as the lesson identifier
    SessionState.lesson = topic.nameEn;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  static int _gradeToInt(Grade grade) {
    switch (grade) {
      case Grade.kindergarten: return 0;
      case Grade.first:        return 1;
      case Grade.second:       return 2;
      case Grade.third:        return 3;
      case Grade.fourth:       return 4;
    }
  }
}
