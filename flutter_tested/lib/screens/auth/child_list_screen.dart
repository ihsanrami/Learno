import 'package:flutter/material.dart';
import 'package:learno/l10n/app_localizations.dart';

import '../../controllers/auth_controller.dart';
import '../../services/auth_service.dart';
import '../../utils/grade_utils.dart';
import '../grades.dart';
import 'add_child_screen.dart';
import 'parent_profile_screen.dart';

const _avatarEmojis = {
  'fox': '🦊',
  'bear': '🐻',
  'panda': '🐼',
  'rabbit': '🐰',
  'lion': '🦁',
  'tiger': '🐯',
};

class ChildListScreen extends StatefulWidget {
  const ChildListScreen({super.key});

  @override
  State<ChildListScreen> createState() => _ChildListScreenState();
}

class _ChildListScreenState extends State<ChildListScreen> {
  final _controller = AuthController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _selectChild(ChildModel child) {
    _controller.selectChild(child);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GradesScreen()),
    );
  }

  void _openAddChild() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddChildScreen()),
    );
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ParentProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final children = _controller.children;
    final parent = _controller.currentParent;

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
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.hiName(parent?.fullName.split(' ').first ?? 'there'),
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF76310F),
                              ),
                            ),
                            Text(
                              l10n.whoIsLearningToday,
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
                      IconButton(
                        onPressed: _openProfile,
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: Color(0xFF44200B),
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: children.isEmpty
                      ? _buildEmpty(l10n)
                      : _buildGrid(children, l10n),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🦊', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text(
            l10n.noLearnersYet,
            style: const TextStyle(
              fontFamily: 'Recoleta',
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: Color(0xFF44200B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addChildToGetStarted,
            style: const TextStyle(color: Color(0xFF76310F), fontSize: 15),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _openAddChild,
            icon: const Icon(Icons.add),
            label: Text(l10n.addChild),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8D00),
              foregroundColor: const Color(0xFF44200B),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(
                fontFamily: 'Recoleta',
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<ChildModel> children, AppLocalizations l10n) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: children.length + 1,
      itemBuilder: (context, index) {
        if (index == children.length) {
          return _buildAddCard(l10n);
        }
        return _buildChildCard(children[index], l10n);
      },
    );
  }

  Widget _buildChildCard(ChildModel child, AppLocalizations l10n) {
    final emoji = _avatarEmojis[child.avatar] ?? '🦊';
    final gradeLabel = localizedGradeLabel(child.grade, l10n);

    return GestureDetector(
      onTap: () => _selectChild(child),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFEDDC),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF44200B).withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFF7CDA5),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 38)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              child.name,
              style: const TextStyle(
                fontFamily: 'Recoleta',
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Color(0xFF44200B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.childAgeYrsGrade(child.age, gradeLabel),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF76310F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCard(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _openAddChild,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFEDDC).withOpacity(0.7),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFFF8D00).withOpacity(0.5),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline,
                color: Color(0xFFFF8D00), size: 44),
            const SizedBox(height: 10),
            Text(
              l10n.addChild,
              style: const TextStyle(
                fontFamily: 'Recoleta',
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Color(0xFFFF8D00),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
