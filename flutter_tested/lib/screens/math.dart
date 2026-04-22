import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../core/session_state.dart';
import 'chat.dart';

class MathScreen extends StatefulWidget {
  const MathScreen({super.key});

  @override
  State<MathScreen> createState() => _MathScreenState();
}

class _MathScreenState extends State<MathScreen> {
  int? selectedIndex;

  final List<String> grade2MathTopics = [
    'Counting',
    'Comparing and ordering',
    'Skip counting and number patterns',
    'Names of numbers',
    'Even and odd',
    'Mixed operations: one digit',
  ];

  final List<Color> topicColors = const [
    Color(0xFFFCA311),
    Color(0xFF00BF63),
    Color(0xFFFFADAD),
    Color(0xFF4CC9F0),
    Color(0xFF7678ED),
    Color(0xFFFF5C8A),
  ];

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

                const Text(
                  'Math Topics',
                  style: TextStyle(
                    fontFamily: 'Recoleta',
                    fontWeight: FontWeight.w900,
                    fontSize: 42,
                    color: Color(0xFF44200B),
                  ),
                ),

                const SizedBox(height: 18),

                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 19),
                    itemCount: grade2MathTopics.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final isSelected = selectedIndex == index;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration:
                          const Duration(milliseconds: 200),
                          transform: isSelected
                              ? (Matrix4.identity()..scale(1.03))
                              : Matrix4.identity(),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: topicColors[
                            index % topicColors.length],
                            borderRadius:
                            BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(0.15),
                                blurRadius: 8,
                                offset:
                                const Offset(0, 4),
                              ),
                            ]
                                : [],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  grade2MathTopics[index],
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
                  ),
                ),

                const SizedBox(height: 16),

                const Padding(
                  padding:
                  EdgeInsets.symmetric(horizontal: 20),
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

                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: GestureDetector(
                    onTap: selectedIndex == null
                        ? null
                        : () {
                      SessionState.lesson =
                      grade2MathTopics[
                      selectedIndex!];

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const ChatScreen(),
                        ),
                      );
                    },
                    child: Opacity(
                      opacity:
                      selectedIndex == null ? 0.4 : 1.0,
                      child: Image.asset(
                        'assets/images/continue.png',
                        width: MediaQuery.of(context)
                            .size
                            .width *
                            0.30,
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
}
