import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../services/parent_service.dart';

class GoalsScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const GoalsScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _svc = ParentService();
  GoalStatus? _goal;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  double _sliderValue = 15;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final goal = await _svc.fetchGoal(widget.childId);
      if (!mounted) return;
      setState(() {
        _goal = goal;
        _sliderValue = goal.targetMinutes.toDouble();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      await _svc.setDailyGoal(widget.childId, _sliderValue.round());
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.goalUpdatedMessage),
          backgroundColor: const Color(0xFFFF8D00),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _encouragement(int progress, AppLocalizations l10n) {
    if (progress >= 100) return l10n.encouragementGoalAchieved;
    if (progress >= 75) return l10n.encouragementAlmostThere;
    if (progress >= 50) return l10n.encouragementHalfway;
    if (progress >= 25) return l10n.encouragementGoodStart;
    return l10n.encouragementReadyToLearn;
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
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(l10n),
                Expanded(child: _buildBody(l10n)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF44200B), size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            l10n.childGoalTitle(widget.childName),
            style: const TextStyle(
              fontFamily: 'Recoleta',
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: Color(0xFF44200B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
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
              child: Text(l10n.retry, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final goal = _goal!;
    final progress = (goal.progressPercent / 100.0).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          _buildFoxCard(goal, l10n),
          const SizedBox(height: 20),
          _buildProgressCard(goal, progress, l10n),
          const SizedBox(height: 20),
          _buildGoalSetterCard(l10n),
        ],
      ),
    );
  }

  Widget _buildFoxCard(GoalStatus goal, AppLocalizations l10n) {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('🦊', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 8),
          Text(
            _encouragement(goal.progressPercent, l10n),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Recoleta',
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFF44200B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(GoalStatus goal, double progress, AppLocalizations l10n) {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.todaysProgress,
            style: const TextStyle(
              fontFamily: 'Recoleta',
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFF44200B),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 16,
              backgroundColor: const Color(0xFFF7CDA5),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFF8D00)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.minutesLearnedLabel(goal.todayMinutes),
                style: const TextStyle(color: Color(0xFF76310F), fontSize: 13),
              ),
              Text(
                l10n.goalMinutesLabel(goal.targetMinutes),
                style: const TextStyle(
                  color: Color(0xFFFF8D00),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (goal.progressPercent >= 100) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                l10n.dailyGoalAchievedMessage,
                style: const TextStyle(
                  fontFamily: 'Recoleta',
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Color(0xFFFF8D00),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalSetterCard(AppLocalizations l10n) {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.setDailyGoalTitle,
            style: const TextStyle(
              fontFamily: 'Recoleta',
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFF44200B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.howManyMinutesQuestion,
            style: const TextStyle(color: Color(0xFF76310F), fontSize: 13),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              l10n.minutesValueLabel(_sliderValue.round()),
              style: const TextStyle(
                fontFamily: 'Recoleta',
                fontWeight: FontWeight.w900,
                fontSize: 32,
                color: Color(0xFFFF8D00),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFFF8D00),
              inactiveTrackColor: const Color(0xFFF7CDA5),
              thumbColor: const Color(0xFFFF8D00),
              overlayColor: const Color(0xFFFF8D00).withOpacity(0.2),
            ),
            child: Slider(
              value: _sliderValue,
              min: 5,
              max: 60,
              divisions: 11,
              onChanged: (v) => setState(() => _sliderValue = v),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.fiveMinLabel,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF76310F))),
              Text(l10n.sixtyMinLabel,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF76310F))),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8D00),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      l10n.saveGoalButton,
                      style: const TextStyle(
                        fontFamily: 'Recoleta',
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFFFFEDDC),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF44200B).withOpacity(0.08),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
