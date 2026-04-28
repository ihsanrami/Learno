// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'ليرنو';

  @override
  String get learningMadeFun => 'التعلم بطريقة ممتعة!';

  @override
  String get cancel => 'إلغاء';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get language => 'اللغة';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get kindergarten => 'روضة الأطفال';

  @override
  String get firstGrade => 'الصف الأول';

  @override
  String get secondGrade => 'الصف الثاني';

  @override
  String get thirdGrade => 'الصف الثالث';

  @override
  String get fourthGrade => 'الصف الرابع';

  @override
  String get firstGradeFull => 'الصف الأول';

  @override
  String get secondGradeFull => 'الصف الثاني';

  @override
  String get thirdGradeFull => 'الصف الثالث';

  @override
  String get fourthGradeFull => 'الصف الرابع';

  @override
  String get subjectEnglish => 'إنجليزي';

  @override
  String get subjectArabic => 'عربي';

  @override
  String get subjectScience => 'علوم';

  @override
  String get subjectMath => 'رياضيات';

  @override
  String get welcomeBack => 'مرحباً بعودتك!';

  @override
  String get signInToContinue => 'سجّل دخولك للمتابعة';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get validationEnterEmail => 'أدخل بريدك الإلكتروني';

  @override
  String get validationInvalidEmail => 'أدخل بريداً إلكترونياً صحيحاً';

  @override
  String get validationEnterPassword => 'أدخل كلمة المرور';

  @override
  String get loginButton => 'دخول';

  @override
  String get noAccountQuestion => 'ليس لديك حساب؟ ';

  @override
  String get registerLink => 'سجّل الآن';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get joinLearnoToday => 'انضم إلى ليرنو اليوم';

  @override
  String get fullNameLabel => 'الاسم الكامل';

  @override
  String get validationEnterFullName => 'أدخل اسمك الكامل';

  @override
  String get validationEnterAPassword => 'أدخل كلمة مرور';

  @override
  String get validationPasswordTooShort =>
      'كلمة المرور يجب أن تكون 8 أحرف على الأقل';

  @override
  String get confirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get validationPasswordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get alreadyHaveAccountQuestion => 'لديك حساب بالفعل؟ ';

  @override
  String get loginLink => 'دخول';

  @override
  String hiName(String name) {
    return 'مرحباً، $name!';
  }

  @override
  String get whoIsLearningToday => 'من يتعلم اليوم؟';

  @override
  String get noLearnersYet => 'لا يوجد متعلمون بعد!';

  @override
  String get addChildToGetStarted => 'أضف ملف طفل للبدء';

  @override
  String get addChild => 'إضافة طفل';

  @override
  String get chooseAvatar => 'اختر الصورة الرمزية';

  @override
  String get childNameSectionLabel => 'الاسم';

  @override
  String get childNameHint => 'اسم الطفل';

  @override
  String get validationEnterChildName => 'أدخل اسم الطفل';

  @override
  String get ageLabel => 'العمر';

  @override
  String get gradeSectionLabel => 'الصف الدراسي';

  @override
  String get selectGradeHint => 'اختر الصف';

  @override
  String get parentProfile => 'ملف ولي الأمر';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get logoutTitle => 'تسجيل الخروج';

  @override
  String get logoutConfirm => 'هل أنت متأكد من تسجيل الخروج؟';

  @override
  String get removeChildTitle => 'إزالة الطفل';

  @override
  String removeChildConfirm(String name) {
    return 'إزالة $name من حسابك؟';
  }

  @override
  String get remove => 'إزالة';

  @override
  String childrenCount(int count) {
    return 'الأطفال ($count)';
  }

  @override
  String get noChildrenAdded => 'لا يوجد أطفال مضافون بعد.';

  @override
  String get parentDashboard => 'لوحة تحكم ولي الأمر';

  @override
  String childAgeYearsGrade(int age, String grade) {
    return '$age سنوات · $grade';
  }

  @override
  String childAgeYrsGrade(int age, String grade) {
    return '$age سنة · $grade';
  }

  @override
  String get grades => 'الصفوف';

  @override
  String get categories => 'المواد';

  @override
  String get topics => 'المواضيع';

  @override
  String get mathTopics => 'مواضيع الرياضيات';

  @override
  String get scienceTopics => 'مواضيع العلوم';

  @override
  String get englishTopics => 'مواضيع الإنجليزية';

  @override
  String get arabicTopics => 'مواضيع العربية';

  @override
  String get selectTopicHint => 'اختر موضوعاً تريد البدء به،\nثم اضغط متابعة.';

  @override
  String get couldNotLoadTopics =>
      'تعذّر تحميل المواضيع.\nتحقق من اتصالك بالإنترنت.';

  @override
  String get noTopicsAvailable => 'لا توجد مواضيع متاحة.';

  @override
  String get welcomeBackLabel => 'مرحباً بعودتك،';

  @override
  String get noChildrenMessage =>
      'لا يوجد أطفال مضافون بعد.\nاذهب إلى ملف ولي الأمر لإضافة طفل.';

  @override
  String get lessonsToday => 'دروس اليوم';

  @override
  String get accuracyLabel => 'الدقة';

  @override
  String get learnedLabel => 'تعلّم';

  @override
  String get viewDetails => 'عرض التفاصيل ←';

  @override
  String get streakLabel => '🔥 سلسلة';

  @override
  String daysCount(int days) {
    return '$days أيام';
  }

  @override
  String minutesGoalProgress(int today, int target) {
    return '$today/$target د هدف';
  }

  @override
  String minutesLessonsLabel(int minutes, int lessons) {
    return '$minutesد · $lessons درس';
  }

  @override
  String get tabOverview => 'نظرة عامة';

  @override
  String get tabWeekly => 'أسبوعي';

  @override
  String get tabTopics => 'مواضيع';

  @override
  String get tabSubjects => 'مواد';

  @override
  String get allTimeStats => 'إحصائيات كلية';

  @override
  String get learningStreak => 'سلسلة التعلم';

  @override
  String get todaysGoal => 'هدف اليوم';

  @override
  String get todaysProgress => 'تقدم اليوم';

  @override
  String get learningTime7Days => 'وقت التعلم (آخر 7 أيام)';

  @override
  String get activeDay => 'يوم نشط';

  @override
  String get noLessonsLabel => 'لا دروس';

  @override
  String get noActivityYet => 'لا نشاط بعد';

  @override
  String get noTopicsStudied => 'لم تُدرَس مواضيع بعد';

  @override
  String get noSubjectsStudied => 'لم تُدرَس مواد بعد';

  @override
  String get timeBySubject => 'الوقت حسب المادة';

  @override
  String get masteredLabel => '⭐ أتقن';

  @override
  String get minTodayLabel => 'د اليوم';

  @override
  String get totalLessonsLabel => 'إجمالي الدروس';

  @override
  String get totalMinLabel => 'إجمالي الدقائق';

  @override
  String minutesProgress(int today, int target) {
    return '$today / $target دقيقة';
  }

  @override
  String streakDaysCount(int days) {
    return '🔥 $days أيام';
  }

  @override
  String get achievementsTooltip => 'الإنجازات';

  @override
  String get dailyGoalTooltip => 'الهدف اليومي';

  @override
  String attemptsCount(int count) {
    return '$count محاولات';
  }

  @override
  String childGoalTitle(String name) {
    return 'هدف $name';
  }

  @override
  String get goalUpdatedMessage => 'تم تحديث الهدف! 🎯';

  @override
  String get setDailyGoalTitle => 'تحديد الهدف اليومي';

  @override
  String get howManyMinutesQuestion => 'كم دقيقة يجب أن يتعلم طفلك يومياً؟';

  @override
  String get saveGoalButton => 'حفظ الهدف';

  @override
  String get dailyGoalAchievedMessage => '🏆 تم تحقيق الهدف اليومي!';

  @override
  String minutesLearnedLabel(int minutes) {
    return '$minutes دقيقة تعلّم';
  }

  @override
  String goalMinutesLabel(int minutes) {
    return 'الهدف: $minutes د';
  }

  @override
  String minutesValueLabel(int minutes) {
    return '$minutes دقيقة';
  }

  @override
  String get fiveMinLabel => '5 د';

  @override
  String get sixtyMinLabel => '60 د';

  @override
  String get encouragementGoalAchieved => 'تم تحقيق الهدف! أحسنت! 🎉';

  @override
  String get encouragementAlmostThere => 'على وشك الإنتهاء، استمر! 💪';

  @override
  String get encouragementHalfway => 'في المنتصف، عمل رائع! 🌟';

  @override
  String get encouragementGoodStart => 'بداية جيدة، واصل التعلم! 📚';

  @override
  String get encouragementReadyToLearn => 'جاهز للتعلم اليوم؟ هيا نبدأ! 🦊';

  @override
  String childAchievementsTitle(String name) {
    return 'إنجازات $name';
  }

  @override
  String get badgesTitle => 'الشارات';

  @override
  String earnedBadgesCount(int earned, int total) {
    return '$earned / $total مكتسبة';
  }

  @override
  String get startLearningEarnBadges => 'ابدأ التعلم لكسب الشارات!';

  @override
  String get allBadgesCollected => 'تم جمع كل الشارات! 🎉';

  @override
  String moreBadgesToUnlock(int count) {
    return '$count أخرى للفتح';
  }

  @override
  String get earnedBadgeLabel => 'مكتسبة!';

  @override
  String get thinkingLabel => 'جاري التفكير…';

  @override
  String get tapMicOrTypeHint => 'اضغط الميكروفون أو اكتب...';

  @override
  String get typeYourAnswerHint => 'اكتب إجابتك...';

  @override
  String get learnoIsSpeakingLabel => '🔊 ليرنو يتحدث...';

  @override
  String get listeningLabel => '🎤 جاري الاستماع...';

  @override
  String get voiceOnTooltip => 'الصوت مفعّل';

  @override
  String get voiceOffTooltip => 'الصوت معطّل';

  @override
  String conceptProgressLabel(int current, int total) {
    return 'المفهوم $current من $total';
  }

  @override
  String get greatJobTitle => '🎉 أحسنت!';

  @override
  String get lessonCompletedMessage => 'أكملت الدرس!';

  @override
  String correctAnswersCount(int count) {
    return '✅ $count إجابات صحيحة';
  }

  @override
  String accuracyScoreLabel(String score) {
    return '📊 دقة $score%';
  }

  @override
  String get youAreAStar => '⭐ أنت نجم! ⭐';

  @override
  String get continueButton => 'متابعة';

  @override
  String get imageNotAvailableLabel => 'الصورة غير متاحة';

  @override
  String get levelLearning => 'يتعلم';

  @override
  String get levelGrowing => 'ينمو';

  @override
  String get levelGreat => 'ممتاز!';

  @override
  String get levelStar => 'نجم!';
}
