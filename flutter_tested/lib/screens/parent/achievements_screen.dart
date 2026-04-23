import 'package:flutter/material.dart';

import '../../services/parent_service.dart';

class AchievementsScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const AchievementsScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final _svc = ParentService();
  List<AchievementItem>? _achievements;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await _svc.fetchAchievements(widget.childId);
      if (!mounted) return;
      setState(() { _achievements = list; _loading = false; });
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
            child: Text(
              '${widget.childName}\'s Achievements',
              style: const TextStyle(
                fontFamily: 'Recoleta',
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: Color(0xFF44200B),
              ),
            ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Color(0xFF44200B))),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8D00)),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final achievements = _achievements ?? [];
    final earned = achievements.where((a) => a.earned).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(earned, achievements.length),
          const SizedBox(height: 16),
          const Text(
            'Badges',
            style: TextStyle(
              fontFamily: 'Recoleta',
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFF44200B),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: achievements.length,
            itemBuilder: (_, i) => _buildBadge(achievements[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int earned, int total) {
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
          const Text('🏆', style: TextStyle(fontSize: 44)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$earned / $total earned',
                style: const TextStyle(
                  fontFamily: 'Recoleta',
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: Color(0xFF44200B),
                ),
              ),
              Text(
                earned == 0
                    ? 'Start learning to earn badges!'
                    : earned == total
                        ? 'All badges collected! 🎉'
                        : '${total - earned} more to unlock',
                style: const TextStyle(fontSize: 13, color: Color(0xFF76310F)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(AchievementItem achievement) {
    final isEarned = achievement.earned;

    return Container(
      decoration: BoxDecoration(
        color: isEarned ? const Color(0xFFFFEDDC) : const Color(0xFFFFEDDC).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: isEarned
            ? Border.all(color: const Color(0xFFFF8D00), width: 2)
            : Border.all(color: const Color(0xFFF7CDA5), width: 1),
        boxShadow: isEarned
            ? [
                BoxShadow(
                  color: const Color(0xFF44200B).withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Text(
                achievement.icon,
                style: TextStyle(
                  fontSize: 40,
                  color: isEarned ? null : Colors.grey.withOpacity(0.3),
                ),
              ),
              if (!isEarned)
                const Icon(Icons.lock, color: Color(0xFFBBAA99), size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontFamily: 'Recoleta',
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: isEarned ? const Color(0xFF44200B) : const Color(0xFFBBAA99),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isEarned ? 'Earned!' : achievement.description,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: isEarned ? const Color(0xFFFF8D00) : const Color(0xFFBBAA99),
              fontWeight: isEarned ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
