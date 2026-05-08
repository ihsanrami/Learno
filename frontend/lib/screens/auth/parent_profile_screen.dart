import 'package:flutter/material.dart';
import 'package:learno/l10n/app_localizations.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/locale_controller.dart';
import '../../services/auth_service.dart';
import '../../utils/grade_utils.dart';
import '../parent/dashboard_screen.dart';
import 'login_screen.dart';

const _avatarEmojis = {
  'fox': '🦊',
  'bear': '🐻',
  'panda': '🐼',
  'rabbit': '🐰',
  'lion': '🦁',
  'tiger': '🐯',
};

class ParentProfileScreen extends StatefulWidget {
  const ParentProfileScreen({super.key});

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  final _controller = AuthController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
    LocaleController.instance.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    LocaleController.instance.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFEDDC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.logoutTitle,
          style: const TextStyle(
            fontFamily: 'Recoleta',
            fontWeight: FontWeight.w900,
            color: Color(0xFF44200B),
          ),
        ),
        content: Text(
          l10n.logoutConfirm,
          style: const TextStyle(color: Color(0xFF76310F)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel,
                style: const TextStyle(color: Color(0xFF76310F))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF76310F),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    await _controller.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _deleteChild(ChildModel child) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFEDDC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.removeChildTitle,
          style: const TextStyle(
            fontFamily: 'Recoleta',
            fontWeight: FontWeight.w900,
            color: Color(0xFF44200B),
          ),
        ),
        content: Text(
          l10n.removeChildConfirm(child.name),
          style: const TextStyle(color: Color(0xFF76310F)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel,
                style: const TextStyle(color: Color(0xFF76310F))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );

    if (confirm == true) await _controller.deleteChild(child.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final parent = _controller.currentParent;
    final children = _controller.children;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child:
                Image.asset('assets/images/background.png', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Color(0xFF44200B), size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        l10n.parentProfile,
                        style: const TextStyle(
                          fontFamily: 'Recoleta',
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                          color: Color(0xFF44200B),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildParentCard(parent),
                        const SizedBox(height: 20),
                        _buildChildrenSection(children, l10n),
                        const SizedBox(height: 20),
                        _buildLanguageSection(l10n),
                        const SizedBox(height: 20),
                        _buildDashboardButton(l10n),
                        const SizedBox(height: 12),
                        _buildLogoutButton(l10n),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentCard(ParentModel? parent) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDDC),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF44200B).withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFF7CDA5),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.person, color: Color(0xFF44200B), size: 32),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parent?.fullName ?? '—',
                  style: const TextStyle(
                    fontFamily: 'Recoleta',
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: Color(0xFF44200B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  parent?.email ?? '—',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF76310F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenSection(List<ChildModel> children, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDDC),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF44200B).withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.childrenCount(children.length),
            style: const TextStyle(
              fontFamily: 'Recoleta',
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFF44200B),
            ),
          ),
          const SizedBox(height: 12),
          if (children.isEmpty)
            Text(
              l10n.noChildrenAdded,
              style: const TextStyle(color: Color(0xFF76310F), fontSize: 14),
            )
          else
            ...children.map((child) => _buildChildRow(child, l10n)),
        ],
      ),
    );
  }

  Widget _buildChildRow(ChildModel child, AppLocalizations l10n) {
    final emoji = _avatarEmojis[child.avatar] ?? '🦊';
    final gradeLabel = localizedGradeLabel(child.grade, l10n);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFF7CDA5),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF44200B),
                    fontSize: 15,
                  ),
                ),
                Text(
                  l10n.childAgeYearsGrade(child.age, gradeLabel),
                  style: const TextStyle(
                      color: Color(0xFF76310F), fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.redAccent, size: 22),
            onPressed: () => _deleteChild(child),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSection(AppLocalizations l10n) {
    final isArabic = LocaleController.instance.isArabic;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDDC),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF44200B).withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.language,
            style: const TextStyle(
              fontFamily: 'Recoleta',
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFF44200B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLangButton(
                l10n.languageEnglish,
                !isArabic,
                () => LocaleController.instance.setLocale(const Locale('en')),
              ),
              const SizedBox(width: 12),
              _buildLangButton(
                l10n.languageArabic,
                isArabic,
                () => LocaleController.instance.setLocale(const Locale('ar')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLangButton(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF8D00) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFF8D00)
                  : const Color(0xFFF7CDA5),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isSelected
                  ? const Color(0xFF44200B)
                  : const Color(0xFF76310F),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardButton(AppLocalizations l10n) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        ),
        icon: const Icon(Icons.bar_chart, size: 20),
        label: Text(l10n.parentDashboard),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8D00),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontFamily: 'Recoleta',
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(AppLocalizations l10n) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _controller.isLoading ? null : _logout,
        icon: const Icon(Icons.logout, size: 20),
        label: Text(l10n.logout),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF76310F),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontFamily: 'Recoleta',
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
