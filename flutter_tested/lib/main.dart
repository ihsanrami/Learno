import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'controllers/locale_controller.dart';
import 'screens/auth/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/student_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await StudentStorage.init();
  AuthService().init();
  await LocaleController.instance.loadSavedLocale();

  runApp(const LearnoApp());
}

class LearnoApp extends StatefulWidget {
  const LearnoApp({super.key});

  @override
  State<LearnoApp> createState() => _LearnoAppState();
}

class _LearnoAppState extends State<LearnoApp> {
  final _localeCtrl = LocaleController.instance;

  @override
  void initState() {
    super.initState();
    _localeCtrl.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    _localeCtrl.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learno',
      debugShowCheckedModeBanner: false,
      locale: _localeCtrl.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      theme: ThemeData(
        primaryColor: const Color(0xFFFF8D00),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF8D00),
        ),
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}
