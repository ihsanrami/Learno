import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  runApp(const LearnoApp());
}

class LearnoApp extends StatelessWidget {
  const LearnoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learno',
      debugShowCheckedModeBanner: false,
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
