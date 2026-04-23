import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/parent_service.dart';
import 'child_detail_screen.dart';

const _avatarEmojis = {
  'fox': '🦊',
  'bear': '🐻',
  'panda': '🐼',
  'rabbit': '🐰',
  'lion': '🦁',
  'tiger': '🐯',
};

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _svc = ParentService();
  List<ChildOverview>? _children;
  String? _error;
  bool _loading = true;
  late String _parentName;

  @override
  void initState() {
    super.initState();
    _parentName = 'Parent';
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final parent = await AuthService().getCurrentParent();
      final children = await _svc.fetchDashboard();
      if (!mounted) return;
      setState(() {
        _parentName = parent.fullName.split(' ').first;
        _children = children;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/background.png', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF44200B), size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF76310F)),
                ),
                Text(
                  _parentName,
                  style: const TextStyle(
                    fontFamily: 'Recoleta',
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: Color(0xFF44200B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF44200B)),
            onPressed: _load,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF8D00)));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFFF8D00), size: 48),
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Color(0xFF44200B))),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8D00)),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final children = _children ?? [];
    if (children.isEmpty) {
      return const Center(
        child: Text(
          'No children added yet.\nGo to Parent Profile to add one.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF76310F), fontSize: 15),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFFF8D00),
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, i) => _buildChildCard(children[i]),
      ),
    );
  }

  Widget _buildChildCard(ChildOverview child) {
    final emoji = _avatarEmojis[child.avatar] ?? '🦊';
    final progress = child.goalProgressPercent / 100.0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChildDetailScreen(childId: child.id, childName: child.name)),
      ).then((_) => _load()),
      child: Container(
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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7CDA5),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.name,
                        style: const TextStyle(
                          fontFamily: 'Recoleta',
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Color(0xFF44200B),
                        ),
                      ),
                      Text(
                        '${child.age} years · ${_gradeLabel(child.grade)}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF76310F)),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${child.streakDays} days',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF8D00),
                        fontSize: 14,
                      ),
                    ),
                    const Text('🔥 streak', style: TextStyle(fontSize: 11, color: Color(0xFF76310F))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _statChip('📚', '${child.todayLessonsCompleted}', 'lessons today'),
                const SizedBox(width: 10),
                _statChip('✅', '${child.todayAccuracy.toStringAsFixed(0)}%', 'accuracy'),
                const SizedBox(width: 10),
                _statChip('⏱️', '${child.todayMinutes}m', 'learned'),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: const Color(0xFFF7CDA5),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFFFF8D00)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${child.todayMinutes}/${child.targetMinutes}m goal',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF76310F)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'View Details →',
                style: const TextStyle(
                  color: Color(0xFFFF8D00),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF7CDA5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF44200B),
            )),
            Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF76310F))),
          ],
        ),
      ),
    );
  }
}

String _gradeLabel(String grade) {
  switch (grade) {
    case 'kindergarten': return 'Kindergarten';
    case 'first': return '1st Grade';
    case 'second': return '2nd Grade';
    case 'third': return '3rd Grade';
    case 'fourth': return '4th Grade';
    default: return grade;
  }
}
