import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../services/auth_service.dart';
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
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFEDDC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontFamily: 'Recoleta',
            fontWeight: FontWeight.w900,
            color: Color(0xFF44200B),
          ),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Color(0xFF76310F)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF76310F))),
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
            child: const Text('Logout'),
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFEDDC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Remove Child',
          style: TextStyle(
            fontFamily: 'Recoleta',
            fontWeight: FontWeight.w900,
            color: Color(0xFF44200B),
          ),
        ),
        content: Text(
          'Remove ${child.name} from your account?',
          style: const TextStyle(color: Color(0xFF76310F)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF76310F))),
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) await _controller.deleteChild(child.id);
  }

  @override
  Widget build(BuildContext context) {
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
                      const Text(
                        'Parent Profile',
                        style: TextStyle(
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
                        _buildChildrenSection(children),
                        const SizedBox(height: 20),
                        _buildDashboardButton(),
                        const SizedBox(height: 12),
                        _buildLogoutButton(),
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

  Widget _buildChildrenSection(List<ChildModel> children) {
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
            'Children (${children.length})',
            style: const TextStyle(
              fontFamily: 'Recoleta',
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFF44200B),
            ),
          ),
          const SizedBox(height: 12),
          if (children.isEmpty)
            const Text(
              'No children added yet.',
              style: TextStyle(color: Color(0xFF76310F), fontSize: 14),
            )
          else
            ...children.map((child) => _buildChildRow(child)),
        ],
      ),
    );
  }

  Widget _buildChildRow(ChildModel child) {
    final emoji = _avatarEmojis[child.avatar] ?? '🦊';
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
                  '${child.age} years · ${_gradeLabel(child.grade)}',
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

  Widget _buildDashboardButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        ),
        icon: const Icon(Icons.bar_chart, size: 20),
        label: const Text('Parent Dashboard'),
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

  Widget _buildLogoutButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _controller.isLoading ? null : _logout,
        icon: const Icon(Icons.logout, size: 20),
        label: const Text('Logout'),
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

String _gradeLabel(String grade) {
  switch (grade) {
    case 'kindergarten':
      return 'Kindergarten';
    case 'first':
      return '1st Grade';
    case 'second':
      return '2nd Grade';
    case 'third':
      return '3rd Grade';
    case 'fourth':
      return '4th Grade';
    default:
      return grade;
  }
}
