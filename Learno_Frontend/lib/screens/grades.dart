import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../core/session_state.dart';
import 'categories.dart';

class GradesScreen extends StatelessWidget {
  const GradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(height: 50),
                const Text(
                  'Grades',
                  style: TextStyle(
                    fontFamily: 'Recoleta',
                    fontWeight: FontWeight.w900,
                    fontSize: 55,
                    color: Color(0xFF44200B),
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    children: [
                      _gradeButton(
                        context: context,
                        image: 'assets/images/kindergarten.png',
                        grade: Grade.kindergarten,
                      ),

                      const SizedBox(height: 20),

                      _gradeButton(
                        context: context,
                        image: 'assets/images/first_grade.png',
                        grade: Grade.first,
                      ),

                      const SizedBox(height: 20),

                      _gradeButton(
                        context: context,
                        image: 'assets/images/second_grade.png',
                        grade: Grade.second,
                      ),

                      const SizedBox(height: 20),

                      _gradeButton(
                        context: context,
                        image: 'assets/images/third_grade.png',
                        grade: Grade.third,
                      ),

                      const SizedBox(height: 20),

                      _gradeButton(
                        context: context,
                        image: 'assets/images/fourth_grade.png',
                        grade: Grade.fourth,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradeButton({
    required BuildContext context,
    required String image,
    required Grade grade,
  }) {
    return InkWell(
      onTap: () {
        SessionState.grade = grade;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CategoriesScreen(),
          ),
        );
      },
      child: Image.asset(image),
    );
  }
}
