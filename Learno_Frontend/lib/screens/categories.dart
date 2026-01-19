import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../core/session_state.dart';
import 'math.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  String _gradeText() {
    switch (SessionState.grade) {
      case Grade.kindergarten:
        return 'Kindergarten';
      case Grade.first:
        return 'First Grade';
      case Grade.second:
        return 'Second Grade';
      case Grade.third:
        return 'Third Grade';
      case Grade.fourth:
        return 'Fourth Grade';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final double itemWidth =
        MediaQuery.of(context).size.width * 0.38;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
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
                      Text(
                        _gradeText(),
                        style: const TextStyle(
                          fontSize: 20,
                          color: Color(0xFF44200B),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                const Text(
                  'Categories',
                  style: TextStyle(
                    fontFamily: 'Recoleta',
                    fontWeight: FontWeight.w900,
                    fontSize: 55,
                    color: Color(0xFF44200B),
                  ),
                ),

                const SizedBox(height: 30),

                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 25),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 20,
                        runSpacing: 30,
                        children: [
                          _wrapItem(
                            context,
                            width: itemWidth,
                            image: 'assets/images/english.png',
                            label: 'English',
                            subject: Subject.english,
                          ),
                          _wrapItem(
                            context,
                            width: itemWidth,
                            image: 'assets/images/arabic.png',
                            label: 'Arabic',
                            subject: Subject.arabic,
                          ),
                          _wrapItem(
                            context,
                            width: itemWidth,
                            image: 'assets/images/science.png',
                            label: 'Science',
                            subject: Subject.science,
                          ),
                          _wrapItem(
                            context,
                            width: itemWidth,
                            image: 'assets/images/math.png',
                            label: 'Math',
                            subject: Subject.math,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _wrapItem(
      BuildContext context, {
        required double width,
        required String image,
        required String label,
        required Subject subject,
      }) {
    return SizedBox(
      width: width,
      child: _topicItem(
        context,
        image: image,
        label: label,
        subject: subject,
      ),
    );
  }

  Widget _topicItem(
      BuildContext context, {
        required String image,
        required String label,
        required Subject subject,
      }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.translate(
          offset: const Offset(0, -6),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _openSubject(context, subject),
            child: Image.asset(image),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: const TextStyle(
            fontFamily: 'Recoleta',
            fontWeight: FontWeight.w400,
            fontSize: 22,
            height: 1.05,
            color: Color(0xFF44200B),
          ),
        ),
      ],
    );
  }

  void _openSubject(BuildContext context, Subject subject) {
    SessionState.subject = subject;

    if (subject == Subject.math &&
        SessionState.grade == Grade.second) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MathScreen(),
        ),
      );
      return;
    }

    final message = subject == Subject.math
        ? 'Math is available for Second Grade only'
        : 'Coming soon 🚧';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
