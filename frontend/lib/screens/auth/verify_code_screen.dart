import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learno/l10n/app_localizations.dart';

import '../../api/api_service.dart';
import 'reset_password_screen.dart';
import 'forgot_password_screen.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String email;
  final String? debugCode;

  const VerifyCodeScreen({
    super.key,
    required this.email,
    this.debugCode,
  });

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final List<TextEditingController> _digitCtrl =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _digitCtrl) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code =>
      _digitCtrl.map((c) => c.text.trim()).join();

  Future<void> _verify() async {
    final code = _code;
    if (code.length != 6) {
      setState(() => _error = 'Please enter all 6 digits');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final resetToken =
          await ApiService.verifyResetCode(widget.email, code);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(resetToken: resetToken),
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
                      l10n.checkEmailTitle,
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
                      l10n.checkEmailSubtitle(widget.email),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF76310F),
                      ),
                    ),
                  ),

                  if (widget.debugCode != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFFF8D00), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bug_report_outlined,
                              color: Color(0xFFFF8D00), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.demoCodeLabel(widget.debugCode!),
                              style: const TextStyle(
                                color: Color(0xFF44200B),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  Container(
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
                    // Force LTR so digit boxes 0→5 always read left-to-right
                    // regardless of the app's Arabic RTL locale.
                    // Numeric codes are always LTR; reversing the order in RTL
                    // would produce a mirrored code that never matches the backend.
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (i) => _buildDigitBox(i)),
                      ),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    _buildErrorBubble(_error!),
                  ],
                  const SizedBox(height: 24),
                  _buildPrimaryButton(
                    label: l10n.verifyCodeButton,
                    isLoading: _isLoading,
                    onPressed: _verify,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen()),
                      ),
                      child: Text(
                        l10n.resendCodeButton,
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
        ],
      ),
    );
  }

  Widget _buildDigitBox(int index) {
    return SizedBox(
      width: 44,
      height: 56,
      child: TextField(
        controller: _digitCtrl[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF44200B),
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFFF7CDA5), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFFFF8D00), width: 2),
          ),
        ),
        onChanged: (v) {
          if (v.length == 1 && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (v.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}

// ---------- Shared auth helpers ----------

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
