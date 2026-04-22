/// =============================================================================
/// Main Entry Point - Learno Educational App
/// =============================================================================
/// ✅ FIXED & TESTED
/// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/grades.dart';
import 'services/student_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock to portrait mode (better for kids)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize student storage
  await StudentStorage.init();
  
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
      home: const GradesScreen(),
    );
  }
}
