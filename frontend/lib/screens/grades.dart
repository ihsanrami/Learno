import 'package:flutter/material.dart';
import 'package:learno/l10n/app_localizations.dart';

import '../models/enums.dart';
import '../core/session_state.dart';
import '../controllers/auth_controller.dart';
import 'categories.dart';

class GradesScreen extends StatelessWidget {
  const GradesScreen({super.key});

  /// Maps the child's grade string (from ChildModel) to a numeric index
  /// matching the Grade enum order: kindergarten=0 … fourth=4.
  static int _gradeStringToInt(String grade) {
    switch (grade) {
      case 'kindergarten': return 0;
      case 'first':        return 1;
      case 'second':       return 2;
      case 'third':        return 3;
      case 'fourth':       return 4;
      default:             return 4; // unknown → allow all
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Child's maximum allowed grade index (their own grade and below are open).
    // If no child is selected (should not happen in normal flow), allow all.
    final selectedChild = AuthController().selectedChild;
    final maxGradeIndex = selectedChild != null
        ? _gradeStringToInt(selectedChild.grade)
        : 4;

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
                Text(
                  l10n.grades,
                  style: const TextStyle(
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
                        l10n: l10n,
                        imageBase: 'kindergarten',
                        grade: Grade.kindergarten,
                        maxGradeIndex: maxGradeIndex,
                      ),
                      const SizedBox(height: 20),
                      _gradeButton(
                        context: context,
                        l10n: l10n,
                        imageBase: 'first_grade',
                        grade: Grade.first,
                        maxGradeIndex: maxGradeIndex,
                      ),
                      const SizedBox(height: 20),
                      _gradeButton(
                        context: context,
                        l10n: l10n,
                        imageBase: 'second_grade',
                        grade: Grade.second,
                        maxGradeIndex: maxGradeIndex,
                      ),
                      const SizedBox(height: 20),
                      _gradeButton(
                        context: context,
                        l10n: l10n,
                        imageBase: 'third_grade',
                        grade: Grade.third,
                        maxGradeIndex: maxGradeIndex,
                      ),
                      const SizedBox(height: 20),
                      _gradeButton(
                        context: context,
                        l10n: l10n,
                        imageBase: 'fourth_grade',
                        grade: Grade.fourth,
                        maxGradeIndex: maxGradeIndex,
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
    required AppLocalizations l10n,
    required String imageBase,
    required Grade grade,
    required int maxGradeIndex,
  }) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final imagePath = isArabic
        ? 'assets/images/${imageBase}_ar.png'
        : 'assets/images/$imageBase.png';

    final isLocked = grade.index > maxGradeIndex;

    if (isLocked) {
      // Locked: faded grade image with a tidy lock badge placed BESIDE it (not on top).
      // Tapping anywhere shows the message — NO API call is made.
      return GestureDetector(
        onTap: () => showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(l10n.gradeLockedTitle,
                textAlign: TextAlign.center),
            content: Text(
              l10n.gradeLockedMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  l10n.okButton,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFFFF8D00),
                  ),
                ),
              ),
            ],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Opacity(
                opacity: 0.65,
                child: Image.asset(imagePath),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDDC),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 22,
                color: Color(0xFFFF8D00),
              ),
            ),
          ],
        ),
      );
    }

    // Unlocked: normal tappable button.
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
      child: Image.asset(imagePath),
    );
  }
}
