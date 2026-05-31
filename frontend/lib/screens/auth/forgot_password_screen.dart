import 'package:flutter/material.dart';
import 'package:learno/l10n/app_localizations.dart';

import '../../api/api_service.dart';
import 'verify_code_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ApiService.forgotPassword(_emailCtrl.text.trim());
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyCodeScreen(
            email: _emailCtrl.text.trim(),
            debugCode: result.debugCode,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFFFEDDC),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/background.png', fit: BoxFit.cover),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Center(
                      child: Image.asset(
                        'assets/images/learno_responce.png',
                        width: 110,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        l10n.forgotPasswordTitle,
                        style: const TextStyle(
                          fontFamily: 'Recoleta',
                          fontWeight: FontWeight.w900,
                          fontSize: 34,
                          color: Color(0xFF44200B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        l10n.forgotPasswordSubtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF76310F),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildCard(
                      child: _buildTextField(
                        controller: _emailCtrl,
                        label: l10n.emailLabel,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return l10n.validationEnterEmail;
                          }
                          if (!v.contains('@')) {
                            return l10n.validationInvalidEmail;
                          }
                          return null;
                        },
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      _buildErrorBubble(_error!),
                    ],
                    const SizedBox(height: 24),
                    _buildPrimaryButton(
                      label: l10n.sendCodeButton,
                      isLoading: _isLoading,
                      onPressed: _sendCode,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          '← ${l10n.loginButton}',
                          style: const TextStyle(
                            color: Color(0xFFFF8D00),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Shared auth helpers ----------

Widget _buildCard({required Widget child}) {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFFFFEDDC),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF44200B).withOpacity(0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    padding: const EdgeInsets.all(20),
    child: child,
  );
}

Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  TextInputType keyboardType = TextInputType.text,
  bool obscureText = false,
  Widget? suffixIcon,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    obscureText: obscureText,
    validator: validator,
    style: const TextStyle(color: Color(0xFF44200B), fontSize: 16),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF76310F)),
      prefixIcon: Icon(icon, color: const Color(0xFF76310F), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFF7CDA5), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF8D00), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

Widget _buildPrimaryButton({
  required String label,
  required bool isLoading,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    height: 56,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF8D00),
        foregroundColor: const Color(0xFF44200B),
        disabledBackgroundColor: const Color(0xFFFF8D00).withOpacity(0.6),
        elevation: 0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: 'Recoleta',
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Color(0xFF44200B),
                strokeWidth: 2.5,
              ),
            )
          : Text(label),
    ),
  );
}

Widget _buildErrorBubble(String message) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0F0),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: Color(0xFF76310F), fontSize: 13),
          ),
        ),
      ],
    ),
  );
}
