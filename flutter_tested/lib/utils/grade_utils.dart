import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/enums.dart';

String localizedGradeLabel(String grade, AppLocalizations l) {
  switch (grade) {
    case 'kindergarten': return l.kindergarten;
    case 'first': return l.firstGrade;
    case 'second': return l.secondGrade;
    case 'third': return l.thirdGrade;
    case 'fourth': return l.fourthGrade;
    default: return grade;
  }
}

String localizedGradeFromEnum(Grade? grade, AppLocalizations l) {
  switch (grade) {
    case Grade.kindergarten: return l.kindergarten;
    case Grade.first: return l.firstGradeFull;
    case Grade.second: return l.secondGradeFull;
    case Grade.third: return l.thirdGradeFull;
    case Grade.fourth: return l.fourthGradeFull;
    default: return '';
  }
}
