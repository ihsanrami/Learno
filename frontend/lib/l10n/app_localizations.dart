import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Learno'**
  String get appTitle;

  /// No description provided for @learningMadeFun.
  ///
  /// In en, this message translates to:
  /// **'Learning made fun!'**
  String get learningMadeFun;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @kindergarten.
  ///
  /// In en, this message translates to:
  /// **'Kindergarten'**
  String get kindergarten;

  /// No description provided for @firstGrade.
  ///
  /// In en, this message translates to:
  /// **'1st Grade'**
  String get firstGrade;

  /// No description provided for @secondGrade.
  ///
  /// In en, this message translates to:
  /// **'2nd Grade'**
  String get secondGrade;

  /// No description provided for @thirdGrade.
  ///
  /// In en, this message translates to:
  /// **'3rd Grade'**
  String get thirdGrade;

  /// No description provided for @fourthGrade.
  ///
  /// In en, this message translates to:
  /// **'4th Grade'**
  String get fourthGrade;

  /// No description provided for @firstGradeFull.
  ///
  /// In en, this message translates to:
  /// **'First Grade'**
  String get firstGradeFull;

  /// No description provided for @secondGradeFull.
  ///
  /// In en, this message translates to:
  /// **'Second Grade'**
  String get secondGradeFull;

  /// No description provided for @thirdGradeFull.
  ///
  /// In en, this message translates to:
  /// **'Third Grade'**
  String get thirdGradeFull;

  /// No description provided for @fourthGradeFull.
  ///
  /// In en, this message translates to:
  /// **'Fourth Grade'**
  String get fourthGradeFull;

  /// No description provided for @subjectEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get subjectEnglish;

  /// No description provided for @subjectArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get subjectArabic;

  /// No description provided for @subjectScience.
  ///
  /// In en, this message translates to:
  /// **'Science'**
  String get subjectScience;

  /// No description provided for @subjectMath.
  ///
  /// In en, this message translates to:
  /// **'Math'**
  String get subjectMath;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @validationEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get validationEnterEmail;

  /// No description provided for @validationInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get validationInvalidEmail;

  /// No description provided for @validationEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get validationEnterPassword;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @noAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get noAccountQuestion;

  /// No description provided for @registerLink.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerLink;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @joinLearnoToday.
  ///
  /// In en, this message translates to:
  /// **'Join Learno today'**
  String get joinLearnoToday;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @validationEnterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get validationEnterFullName;

  /// No description provided for @validationEnterAPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter a password'**
  String get validationEnterAPassword;

  /// No description provided for @validationPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get validationPasswordTooShort;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @validationPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validationPasswordsDoNotMatch;

  /// No description provided for @alreadyHaveAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccountQuestion;

  /// No description provided for @loginLink.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginLink;

  /// No description provided for @hiName.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}!'**
  String hiName(String name);

  /// No description provided for @whoIsLearningToday.
  ///
  /// In en, this message translates to:
  /// **'Who is learning today?'**
  String get whoIsLearningToday;

  /// No description provided for @noLearnersYet.
  ///
  /// In en, this message translates to:
  /// **'No learners yet!'**
  String get noLearnersYet;

  /// No description provided for @addChildToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Add a child profile to get started'**
  String get addChildToGetStarted;

  /// No description provided for @addChild.
  ///
  /// In en, this message translates to:
  /// **'Add Child'**
  String get addChild;

  /// No description provided for @chooseAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose Avatar'**
  String get chooseAvatar;

  /// No description provided for @childNameSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get childNameSectionLabel;

  /// No description provided for @childNameHint.
  ///
  /// In en, this message translates to:
  /// **'Child\'s name'**
  String get childNameHint;

  /// No description provided for @validationEnterChildName.
  ///
  /// In en, this message translates to:
  /// **'Enter the child\'s name'**
  String get validationEnterChildName;

  /// No description provided for @ageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ageLabel;

  /// No description provided for @gradeSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get gradeSectionLabel;

  /// No description provided for @selectGradeHint.
  ///
  /// In en, this message translates to:
  /// **'Select grade'**
  String get selectGradeHint;

  /// No description provided for @parentProfile.
  ///
  /// In en, this message translates to:
  /// **'Parent Profile'**
  String get parentProfile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutTitle;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @removeChildTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Child'**
  String get removeChildTitle;

  /// No description provided for @removeChildConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from your account?'**
  String removeChildConfirm(String name);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @childrenCount.
  ///
  /// In en, this message translates to:
  /// **'Children ({count})'**
  String childrenCount(int count);

  /// No description provided for @noChildrenAdded.
  ///
  /// In en, this message translates to:
  /// **'No children added yet.'**
  String get noChildrenAdded;

  /// No description provided for @parentDashboard.
  ///
  /// In en, this message translates to:
  /// **'Parent Dashboard'**
  String get parentDashboard;

  /// No description provided for @childAgeYearsGrade.
  ///
  /// In en, this message translates to:
  /// **'{age} years · {grade}'**
  String childAgeYearsGrade(int age, String grade);

  /// No description provided for @childAgeYrsGrade.
  ///
  /// In en, this message translates to:
  /// **'{age} yrs · {grade}'**
  String childAgeYrsGrade(int age, String grade);

  /// No description provided for @grades.
  ///
  /// In en, this message translates to:
  /// **'Grades'**
  String get grades;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @topics.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get topics;

  /// No description provided for @mathTopics.
  ///
  /// In en, this message translates to:
  /// **'Math Topics'**
  String get mathTopics;

  /// No description provided for @scienceTopics.
  ///
  /// In en, this message translates to:
  /// **'Science Topics'**
  String get scienceTopics;

  /// No description provided for @englishTopics.
  ///
  /// In en, this message translates to:
  /// **'English Topics'**
  String get englishTopics;

  /// No description provided for @arabicTopics.
  ///
  /// In en, this message translates to:
  /// **'Arabic Topics'**
  String get arabicTopics;

  /// No description provided for @selectTopicHint.
  ///
  /// In en, this message translates to:
  /// **'Select a topic you want to start with,\nthen press Continue.'**
  String get selectTopicHint;

  /// No description provided for @couldNotLoadTopics.
  ///
  /// In en, this message translates to:
  /// **'Could not load topics.\nPlease check your connection.'**
  String get couldNotLoadTopics;

  /// No description provided for @noTopicsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No topics available.'**
  String get noTopicsAvailable;

  /// No description provided for @welcomeBackLabel.
  ///
  /// In en, this message translates to:
  /// **'Welcome back,'**
  String get welcomeBackLabel;

  /// No description provided for @noChildrenMessage.
  ///
  /// In en, this message translates to:
  /// **'No children added yet.\nGo to Parent Profile to add one.'**
  String get noChildrenMessage;

  /// No description provided for @lessonsToday.
  ///
  /// In en, this message translates to:
  /// **'lessons today'**
  String get lessonsToday;

  /// No description provided for @accuracyLabel.
  ///
  /// In en, this message translates to:
  /// **'accuracy'**
  String get accuracyLabel;

  /// No description provided for @learnedLabel.
  ///
  /// In en, this message translates to:
  /// **'learned'**
  String get learnedLabel;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details →'**
  String get viewDetails;

  /// No description provided for @streakLabel.
  ///
  /// In en, this message translates to:
  /// **'🔥 streak'**
  String get streakLabel;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String daysCount(int days);

  /// No description provided for @minutesGoalProgress.
  ///
  /// In en, this message translates to:
  /// **'{today}/{target}m goal'**
  String minutesGoalProgress(int today, int target);

  /// No description provided for @minutesLessonsLabel.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m · {lessons} lessons'**
  String minutesLessonsLabel(int minutes, int lessons);

  /// No description provided for @tabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tabOverview;

  /// No description provided for @tabWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get tabWeekly;

  /// No description provided for @tabTopics.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get tabTopics;

  /// No description provided for @tabSubjects.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get tabSubjects;

  /// No description provided for @allTimeStats.
  ///
  /// In en, this message translates to:
  /// **'All-Time Stats'**
  String get allTimeStats;

  /// No description provided for @learningStreak.
  ///
  /// In en, this message translates to:
  /// **'Learning Streak'**
  String get learningStreak;

  /// No description provided for @todaysGoal.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Goal'**
  String get todaysGoal;

  /// No description provided for @todaysProgress.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Progress'**
  String get todaysProgress;

  /// No description provided for @learningTime7Days.
  ///
  /// In en, this message translates to:
  /// **'Learning Time (last 7 days)'**
  String get learningTime7Days;

  /// No description provided for @activeDay.
  ///
  /// In en, this message translates to:
  /// **'Active day'**
  String get activeDay;

  /// No description provided for @noLessonsLabel.
  ///
  /// In en, this message translates to:
  /// **'No lessons'**
  String get noLessonsLabel;

  /// No description provided for @noActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get noActivityYet;

  /// No description provided for @noTopicsStudied.
  ///
  /// In en, this message translates to:
  /// **'No topics studied yet'**
  String get noTopicsStudied;

  /// No description provided for @noSubjectsStudied.
  ///
  /// In en, this message translates to:
  /// **'No subjects studied yet'**
  String get noSubjectsStudied;

  /// No description provided for @timeBySubject.
  ///
  /// In en, this message translates to:
  /// **'Time by Subject'**
  String get timeBySubject;

  /// No description provided for @masteredLabel.
  ///
  /// In en, this message translates to:
  /// **'⭐ Mastered'**
  String get masteredLabel;

  /// No description provided for @minTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'min today'**
  String get minTodayLabel;

  /// No description provided for @totalLessonsLabel.
  ///
  /// In en, this message translates to:
  /// **'total lessons'**
  String get totalLessonsLabel;

  /// No description provided for @totalMinLabel.
  ///
  /// In en, this message translates to:
  /// **'total min'**
  String get totalMinLabel;

  /// No description provided for @minutesProgress.
  ///
  /// In en, this message translates to:
  /// **'{today} / {target} minutes'**
  String minutesProgress(int today, int target);

  /// No description provided for @streakDaysCount.
  ///
  /// In en, this message translates to:
  /// **'🔥 {days} days'**
  String streakDaysCount(int days);

  /// No description provided for @achievementsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievementsTooltip;

  /// No description provided for @dailyGoalTooltip.
  ///
  /// In en, this message translates to:
  /// **'Daily Goal'**
  String get dailyGoalTooltip;

  /// No description provided for @attemptsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} attempts'**
  String attemptsCount(int count);

  /// No description provided for @childGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s Goal'**
  String childGoalTitle(String name);

  /// No description provided for @goalUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Goal updated! 🎯'**
  String get goalUpdatedMessage;

  /// No description provided for @setDailyGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Daily Goal'**
  String get setDailyGoalTitle;

  /// No description provided for @howManyMinutesQuestion.
  ///
  /// In en, this message translates to:
  /// **'How many minutes per day should your child learn?'**
  String get howManyMinutesQuestion;

  /// No description provided for @saveGoalButton.
  ///
  /// In en, this message translates to:
  /// **'Save Goal'**
  String get saveGoalButton;

  /// No description provided for @dailyGoalAchievedMessage.
  ///
  /// In en, this message translates to:
  /// **'🏆 Daily goal achieved!'**
  String get dailyGoalAchievedMessage;

  /// No description provided for @minutesLearnedLabel.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes learned'**
  String minutesLearnedLabel(int minutes);

  /// No description provided for @goalMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal: {minutes} min'**
  String goalMinutesLabel(int minutes);

  /// No description provided for @minutesValueLabel.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String minutesValueLabel(int minutes);

  /// No description provided for @fiveMinLabel.
  ///
  /// In en, this message translates to:
  /// **'5 min'**
  String get fiveMinLabel;

  /// No description provided for @sixtyMinLabel.
  ///
  /// In en, this message translates to:
  /// **'60 min'**
  String get sixtyMinLabel;

  /// No description provided for @encouragementGoalAchieved.
  ///
  /// In en, this message translates to:
  /// **'Goal achieved! Amazing job! 🎉'**
  String get encouragementGoalAchieved;

  /// No description provided for @encouragementAlmostThere.
  ///
  /// In en, this message translates to:
  /// **'Almost there, keep going! 💪'**
  String get encouragementAlmostThere;

  /// No description provided for @encouragementHalfway.
  ///
  /// In en, this message translates to:
  /// **'Halfway through, great work! 🌟'**
  String get encouragementHalfway;

  /// No description provided for @encouragementGoodStart.
  ///
  /// In en, this message translates to:
  /// **'Good start, keep learning! 📚'**
  String get encouragementGoodStart;

  /// No description provided for @encouragementReadyToLearn.
  ///
  /// In en, this message translates to:
  /// **'Ready to learn today? Let\'s go! 🦊'**
  String get encouragementReadyToLearn;

  /// No description provided for @childAchievementsTitle.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s Achievements'**
  String childAchievementsTitle(String name);

  /// No description provided for @badgesTitle.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badgesTitle;

  /// No description provided for @earnedBadgesCount.
  ///
  /// In en, this message translates to:
  /// **'{earned} / {total} earned'**
  String earnedBadgesCount(int earned, int total);

  /// No description provided for @startLearningEarnBadges.
  ///
  /// In en, this message translates to:
  /// **'Start learning to earn badges!'**
  String get startLearningEarnBadges;

  /// No description provided for @allBadgesCollected.
  ///
  /// In en, this message translates to:
  /// **'All badges collected! 🎉'**
  String get allBadgesCollected;

  /// No description provided for @moreBadgesToUnlock.
  ///
  /// In en, this message translates to:
  /// **'{count} more to unlock'**
  String moreBadgesToUnlock(int count);

  /// No description provided for @earnedBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Earned!'**
  String get earnedBadgeLabel;

  /// No description provided for @thinkingLabel.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get thinkingLabel;

  /// No description provided for @tapMicOrTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Tap mic or type...'**
  String get tapMicOrTypeHint;

  /// No description provided for @typeYourAnswerHint.
  ///
  /// In en, this message translates to:
  /// **'Type your answer...'**
  String get typeYourAnswerHint;

  /// No description provided for @learnoIsSpeakingLabel.
  ///
  /// In en, this message translates to:
  /// **'🔊 Learno is speaking...'**
  String get learnoIsSpeakingLabel;

  /// No description provided for @listeningLabel.
  ///
  /// In en, this message translates to:
  /// **'🎤 Listening...'**
  String get listeningLabel;

  /// No description provided for @voiceOnTooltip.
  ///
  /// In en, this message translates to:
  /// **'Voice ON'**
  String get voiceOnTooltip;

  /// No description provided for @voiceOffTooltip.
  ///
  /// In en, this message translates to:
  /// **'Voice OFF'**
  String get voiceOffTooltip;

  /// No description provided for @conceptProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Concept {current} of {total}'**
  String conceptProgressLabel(int current, int total);

  /// No description provided for @greatJobTitle.
  ///
  /// In en, this message translates to:
  /// **'🎉 Great Job!'**
  String get greatJobTitle;

  /// No description provided for @lessonCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'You completed the lesson!'**
  String get lessonCompletedMessage;

  /// No description provided for @correctAnswersCount.
  ///
  /// In en, this message translates to:
  /// **'✅ {count} correct answers'**
  String correctAnswersCount(int count);

  /// No description provided for @accuracyScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'📊 {score}% accuracy'**
  String accuracyScoreLabel(String score);

  /// No description provided for @youAreAStar.
  ///
  /// In en, this message translates to:
  /// **'⭐ You are a star! ⭐'**
  String get youAreAStar;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @imageNotAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Image not available'**
  String get imageNotAvailableLabel;

  /// No description provided for @levelLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get levelLearning;

  /// No description provided for @levelGrowing.
  ///
  /// In en, this message translates to:
  /// **'Growing'**
  String get levelGrowing;

  /// No description provided for @levelGreat.
  ///
  /// In en, this message translates to:
  /// **'Great!'**
  String get levelGreat;

  /// No description provided for @levelStar.
  ///
  /// In en, this message translates to:
  /// **'Star!'**
  String get levelStar;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
