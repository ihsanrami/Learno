import 'package:flutter/material.dart';
import 'package:learno/l10n/app_localizations.dart';

import '../models/enums.dart';
import '../core/session_state.dart';
import '../utils/grade_utils.dart';
import 'topics.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final double itemWidth = MediaQuery.of(context).size.width * 0.38;
    final gradeText = localizedGradeFromEnum(SessionState.grade, l10n);

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
                        gradeText,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Color(0xFF44200B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  l10n.categories,
                  style: const TextStyle(
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
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 20,
                        runSpacing: 30,
                        children: [
                          _wrapItem(
                            context,
                            width: itemWidth,
                            image: 'assets/images/english.png',
                            label: l10n.subjectEnglish,
                            subject: Subject.english,
                          ),
                          _wrapItem(
                            context,
                            width: itemWidth,
                            image: 'assets/images/arabic.png',
                            label: l10n.subjectArabic,
                            subject: Subject.arabic,
                          ),
                          _wrapItem(
                            context,
                            width: itemWidth,
                            image: 'assets/images/science.png',
                            label: l10n.subjectScience,
                            subject: Subject.science,
                          ),
                          _wrapItem(
                            context,
                            width: itemWidth,
                            image: 'assets/images/math.png',
                            label: l10n.subjectMath,
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
      child: _topicItem(context, image: image, label: label, subject: subject),
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TopicsScreen()),
    );
  }
}
