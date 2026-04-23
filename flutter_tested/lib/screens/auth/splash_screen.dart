import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import 'login_screen.dart';
import 'child_list_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final isLoggedIn = await AuthController().checkAuthState();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            isLoggedIn ? const ChildListScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/background.png', fit: BoxFit.cover),
          ),
          FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/learno_responce.png', width: 140),
                  const SizedBox(height: 20),
                  const Text(
                    'Learno',
                    style: TextStyle(
                      fontFamily: 'Recoleta',
                      fontWeight: FontWeight.w900,
                      fontSize: 58,
                      color: Color(0xFFFF8D00),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Learning made fun!',
                    style: TextStyle(
                      fontFamily: 'Recoleta',
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Color(0xFF76310F),
                    ),
                  ),
                  const SizedBox(height: 48),
                  const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF8D00),
                      strokeWidth: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
