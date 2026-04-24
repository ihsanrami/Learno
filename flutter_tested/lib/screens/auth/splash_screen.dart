import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/locale_controller.dart';
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/background.png', fit: BoxFit.cover),
          ),
          // Language toggle at top-right
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: _LanguageToggle(),
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
                  Text(
                    l10n.learningMadeFun,
                    style: const TextStyle(
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

class _LanguageToggle extends StatefulWidget {
  @override
  State<_LanguageToggle> createState() => _LanguageToggleState();
}

class _LanguageToggleState extends State<_LanguageToggle> {
  @override
  void initState() {
    super.initState();
    LocaleController.instance.addListener(_rebuild);
  }

  @override
  void dispose() {
    LocaleController.instance.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = LocaleController.instance.isArabic;
    return GestureDetector(
      onTap: LocaleController.instance.toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEDDC).withOpacity(0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFF8D00), width: 1.5),
        ),
        child: Text(
          isArabic ? 'English' : 'العربية',
          style: const TextStyle(
            color: Color(0xFF44200B),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
