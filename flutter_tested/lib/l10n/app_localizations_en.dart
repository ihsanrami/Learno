// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Learno';

  @override
  String get learningMadeFun => 'Learning made fun!';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get kindergarten => 'Kindergarten';

  @override
  String get firstGrade => '1st Grade';

  @override
  String get secondGrade => '2nd Grade';

  @override
  String get thirdGrade => '3rd Grade';

  @override
  String get fourthGrade => '4th Grade';

  @override
  String get firstGradeFull => 'First Grade';

  @override
  String get secondGradeFull => 'Second Grade';

  @override
  String get thirdGradeFull => 'Third Grade';

  @override
  String get fourthGradeFull => 'Fourth Grade';

  @override
  String get subjectEnglish => 'English';

  @override
  String get subjectArabic => 'Arabic';

  @override
  String get subjectScience => 'Science';

  @override
  String get subjectMath => 'Math';

  @override
  String get welcomeBack => 'Welcome Back!';

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get validationEnterEmail => 'Enter your email';

  @override
  String get validationInvalidEmail => 'Enter a valid email';

  @override
  String get validationEnterPassword => 'Enter your password';

  @override
  String get loginButton => 'Login';

  @override
  String get noAccountQuestion => 'Don\'t have an account? ';

  @override
  String get registerLink => 'Register';

  @override
  String get createAccount => 'Create Account';

  @override
  String get joinLearnoToday => 'Join Learno today';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get validationEnterFullName => 'Enter your full name';

  @override
  String get validationEnterAPassword => 'Enter a password';

  @override
  String get validationPasswordTooShort =>
      'Password must be at least 8 characters';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get validationPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get alreadyHaveAccountQuestion => 'Already have an account? ';

  @override
  String get loginLink => 'Login';

  @override
  String hiName(String name) {
    return 'Hi, $name!';
  }

  @override
  String get whoIsLearningToday => 'Who is learning today?';

  @override
  String get noLearnersYet => 'No learners yet!';

  @override
  String get addChildToGetStarted => 'Add a child profile to get started';

  @override
  String get addChild => 'Add Child';

  @override
  String get chooseAvatar => 'Choose Avatar';

  @override
  String get childNameSectionLabel => 'Name';

  @override
  String get childNameHint => 'Child\'s name';

  @override
  String get validationEnterChildName => 'Enter the child\'s name';

  @override
  String get ageLabel => 'Age';

  @override
  String get gradeSectionLabel => 'Grade';

  @override
  String get selectGradeHint => 'Select grade';

  @override
  String get parentProfile => 'Parent Profile';

  @override
  String get logout => 'Logout';

  @override
  String get logoutTitle => 'Logout';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get removeChildTitle => 'Remove Child';

  @override
  String removeChildConfirm(String name) {
    return 'Remove $name from your account?';
  }

  @override
  String get remove => 'Remove';

  @override
  String childrenCount(int count) {
    return 'Children ($count)';
  }

  @override
  String get noChildrenAdded => 'No children added yet.';

  @override
  String get parentDashboard => 'Parent Dashboard';

  @override
  String childAgeYearsGrade(int age, String grade) {
    return '$age years · $grade';
  }

  @override
  String childAgeYrsGrade(int age, String grade) {
    return '$age yrs · $grade';
  }

  @override
  String get grades => 'Grades';

  @override
  String get categories => 'Categories';

  @override
  String get topics => 'Topics';

  @override
  String get mathTopics => 'Math Topics';

  @override
  String get scienceTopics => 'Science Topics';

  @override
  String get englishTopics => 'English Topics';

  @override
  String get arabicTopics => 'Arabic Topics';

  @override
  String get selectTopicHint =>
      'Select a topic you want to start with,\nthen press Continue.';

  @override
  String get couldNotLoadTopics =>
      'Could not load topics.\nPlease check your connection.';

  @override
  String get noTopicsAvailable => 'No topics available.';

  @override
  String get welcomeBackLabel => 'Welcome back,';

  @override
  String get noChildrenMessage =>
      'No children added yet.\nGo to Parent Profile to add one.';

  @override
  String get lessonsToday => 'lessons today';

  @override
  String get accuracyLabel => 'accuracy';

  @override
  String get learnedLabel => 'learned';

  @override
  String get viewDetails => 'View Details →';

  @override
  String get streakLabel => '🔥 streak';

  @override
  String daysCount(int days) {
    return '$days days';
  }

  @override
  String minutesGoalProgress(int today, int target) {
    return '$today/${target}m goal';
  }

  @override
  String minutesLessonsLabel(int minutes, int lessons) {
    return '${minutes}m · $lessons lessons';
  }

  @override
  String get tabOverview => 'Overview';

  @override
  String get tabWeekly => 'Weekly';

  @override
  String get tabTopics => 'Topics';

  @override
  String get tabSubjects => 'Subjects';

  @override
  String get allTimeStats => 'All-Time Stats';

  @override
  String get learningStreak => 'Learning Streak';

  @override
  String get todaysGoal => 'Today\'s Goal';

  @override
  String get todaysProgress => 'Today\'s Progress';

  @override
  String get learningTime7Days => 'Learning Time (last 7 days)';

  @override
  String get activeDay => 'Active day';

  @override
  String get noLessonsLabel => 'No lessons';

  @override
  String get noActivityYet => 'No activity yet';

  @override
  String get noTopicsStudied => 'No topics studied yet';

  @override
  String get noSubjectsStudied => 'No subjects studied yet';

  @override
  String get timeBySubject => 'Time by Subject';

  @override
  String get masteredLabel => '⭐ Mastered';

  @override
  String get minTodayLabel => 'min today';

  @override
  String get totalLessonsLabel => 'total lessons';

  @override
  String get totalMinLabel => 'total min';

  @override
  String minutesProgress(int today, int target) {
    return '$today / $target minutes';
  }

  @override
  String streakDaysCount(int days) {
    return '🔥 $days days';
  }

  @override
  String get achievementsTooltip => 'Achievements';

  @override
  String get dailyGoalTooltip => 'Daily Goal';

  @override
  String attemptsCount(int count) {
    return '$count attempts';
  }

  @override
  String childGoalTitle(String name) {
    return '$name\'s Goal';
  }

  @override
  String get goalUpdatedMessage => 'Goal updated! 🎯';

  @override
  String get setDailyGoalTitle => 'Set Daily Goal';

  @override
  String get howManyMinutesQuestion =>
      'How many minutes per day should your child learn?';

  @override
  String get saveGoalButton => 'Save Goal';

  @override
  String get dailyGoalAchievedMessage => '🏆 Daily goal achieved!';

  @override
  String minutesLearnedLabel(int minutes) {
    return '$minutes minutes learned';
  }

  @override
  String goalMinutesLabel(int minutes) {
    return 'Goal: $minutes min';
  }

  @override
  String minutesValueLabel(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get fiveMinLabel => '5 min';

  @override
  String get sixtyMinLabel => '60 min';

  @override
  String get encouragementGoalAchieved => 'Goal achieved! Amazing job! 🎉';

  @override
  String get encouragementAlmostThere => 'Almost there, keep going! 💪';

  @override
  String get encouragementHalfway => 'Halfway through, great work! 🌟';

  @override
  String get encouragementGoodStart => 'Good start, keep learning! 📚';

  @override
  String get encouragementReadyToLearn => 'Ready to learn today? Let\'s go! 🦊';

  @override
  String childAchievementsTitle(String name) {
    return '$name\'s Achievements';
  }

  @override
  String get badgesTitle => 'Badges';

  @override
  String earnedBadgesCount(int earned, int total) {
    return '$earned / $total earned';
  }

  @override
  String get startLearningEarnBadges => 'Start learning to earn badges!';

  @override
  String get allBadgesCollected => 'All badges collected! 🎉';

  @override
  String moreBadgesToUnlock(int count) {
    return '$count more to unlock';
  }

  @override
  String get earnedBadgeLabel => 'Earned!';

  @override
  String get thinkingLabel => 'Thinking…';

  @override
  String get tapMicOrTypeHint => 'Tap mic or type...';

  @override
  String get typeYourAnswerHint => 'Type your answer...';

  @override
  String get learnoIsSpeakingLabel => '🔊 Learno is speaking...';

  @override
  String get listeningLabel => '🎤 Listening...';

  @override
  String get voiceOnTooltip => 'Voice ON';

  @override
  String get voiceOffTooltip => 'Voice OFF';

  @override
  String conceptProgressLabel(int current, int total) {
    return 'Concept $current of $total';
  }

  @override
  String get greatJobTitle => '🎉 Great Job!';

  @override
  String get lessonCompletedMessage => 'You completed the lesson!';

  @override
  String correctAnswersCount(int count) {
    return '✅ $count correct answers';
  }

  @override
  String accuracyScoreLabel(String score) {
    return '📊 $score% accuracy';
  }

  @override
  String get youAreAStar => '⭐ You are a star! ⭐';

  @override
  String get continueButton => 'Continue';

  @override
  String get imageNotAvailableLabel => 'Image not available';

  @override
  String get levelLearning => 'Learning';

  @override
  String get levelGrowing => 'Growing';

  @override
  String get levelGreat => 'Great!';

  @override
  String get levelStar => 'Star!';
}
