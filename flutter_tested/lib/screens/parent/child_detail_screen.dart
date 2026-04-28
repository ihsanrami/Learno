import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:learno/l10n/app_localizations.dart';

import '../../services/parent_service.dart';
import 'achievements_screen.dart';
import 'goals_screen.dart';

class ChildDetailScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const ChildDetailScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen>
    with SingleTickerProviderStateMixin {
  final _svc = ParentService();
  late TabController _tabs;

  ChildOverview? _overview;
  List<DayActivity>? _weekly;
  List<TopicProgress>? _topics;
  List<SubjectBreakdown>? _subjects;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _svc.fetchChildOverview(widget.childId),
        _svc.fetchWeeklyActivity(widget.childId),
        _svc.fetchTopics(widget.childId),
        _svc.fetchSubjects(widget.childId),
      ]);
      if (!mounted) return;
      setState(() {
        _overview = results[0] as ChildOverview;
        _weekly = results[1] as List<DayActivity>;
        _topics = results[2] as List<TopicProgress>;
        _subjects = results[3] as List<SubjectBreakdown>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
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
              children: [
                _buildHeader(l10n),
                _buildTabBar(l10n),
                Expanded(child: _buildTabContent(l10n)),
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
          Expanded(
            child: Text(
              widget.childName,
              style: const TextStyle(
                fontFamily: 'Recoleta',
                fontWeight: FontWeight.w900,
                fontSize: 24,
                color: Color(0xFF44200B),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events, color: Color(0xFFFF8D00)),
            tooltip: l10n.achievementsTooltip,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AchievementsScreen(
                  childId: widget.childId,
                  childName: widget.childName,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.flag, color: Color(0xFFFF8D00)),
            tooltip: l10n.dailyGoalTooltip,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GoalsScreen(
                  childId: widget.childId,
                  childName: widget.childName,
                ),
              ),
            ).then((_) => _load()),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    return Container(
      color: Colors.transparent,
      child: TabBar(
        controller: _tabs,
        labelColor: const Color(0xFFFF8D00),
        unselectedLabelColor: const Color(0xFF76310F),
        indicatorColor: const Color(0xFFFF8D00),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        tabs: [
          Tab(text: l10n.tabOverview),
          Tab(text: l10n.tabWeekly),
          Tab(text: l10n.tabTopics),
          Tab(text: l10n.tabSubjects),
        ],
      ),
    );
  }

  Widget _buildTabContent(AppLocalizations l10n) {
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
              Text(_error!, style: const TextStyle(color: Color(0xFF44200B))),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8D00)),
                child: Text(l10n.retry, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabs,
      children: [
        _buildOverviewTab(l10n),
        _buildWeeklyTab(l10n),
        _buildTopicsTab(l10n),
        _buildSubjectsTab(l10n),
      ],
    );
  }

  Widget _buildOverviewTab(AppLocalizations l10n) {
    final o = _overview;
    if (o == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _card(
            child: Row(
              children: [
                _bigStat('${o.todayMinutes}', l10n.minTodayLabel, '⏱️'),
                _divider(),
                _bigStat('${o.todayLessonsCompleted}', l10n.lessonsToday, '📚'),
                _divider(),
                _bigStat('${o.todayAccuracy.toStringAsFixed(0)}%', l10n.accuracyLabel, '✅'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(l10n.allTimeStats),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _bigStat('${o.totalLessons}', l10n.totalLessonsLabel, '🎓'),
                    _divider(),
                    _bigStat('${o.overallAccuracy.toStringAsFixed(0)}%', l10n.accuracyLabel, '🏆'),
                    _divider(),
                    _bigStat('${o.totalLearningMinutes}', l10n.totalMinLabel, '📖'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _sectionTitle(l10n.learningStreak),
                    const Spacer(),
                    Text(
                      l10n.streakDaysCount(o.streakDays),
                      style: const TextStyle(
                        fontFamily: 'Recoleta',
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: Color(0xFFFF8D00),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _sectionTitle(l10n.todaysGoal),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (o.goalProgressPercent / 100.0).clamp(0.0, 1.0),
                    minHeight: 12,
                    backgroundColor: const Color(0xFFF7CDA5),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFF8D00)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.minutesProgress(o.todayMinutes, o.targetMinutes),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF76310F)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTab(AppLocalizations l10n) {
    final weekly = _weekly;
    if (weekly == null || weekly.isEmpty) {
      return Center(child: Text(l10n.noActivityYet, style: const TextStyle(color: Color(0xFF76310F))));
    }

    final maxMinutes = weekly.map((d) => d.minutes).fold(0, (a, b) => a > b ? a : b);
    final spots = weekly.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.minutes.toDouble(),
            color: e.value.lessonsCompleted > 0
                ? const Color(0xFFFF8D00)
                : const Color(0xFFF7CDA5),
            width: 28,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(l10n.learningTime7Days),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      maxY: (maxMinutes > 0 ? maxMinutes * 1.3 : 30).toDouble(),
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: const Color(0xFFF7CDA5),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, _) {
                              final idx = val.toInt();
                              if (idx < 0 || idx >= weekly.length) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  weekly[idx].dayLabel,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF76310F),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: spots,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _legend(const Color(0xFFFF8D00), l10n.activeDay),
                    const SizedBox(width: 16),
                    _legend(const Color(0xFFF7CDA5), l10n.noLessonsLabel),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._buildWeeklyList(weekly, l10n),
        ],
      ),
    );
  }

  List<Widget> _buildWeeklyList(List<DayActivity> weekly, AppLocalizations l10n) {
    return weekly.reversed.map((d) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _card(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  d.dayLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF44200B),
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: d.minutes > 0 ? (d.minutes / 30).clamp(0.0, 1.0) : 0,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF7CDA5),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFF8D00)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.minutesLessonsLabel(d.minutes, d.lessonsCompleted),
                style: const TextStyle(fontSize: 11, color: Color(0xFF76310F)),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildTopicsTab(AppLocalizations l10n) {
    final topics = _topics;
    if (topics == null || topics.isEmpty) {
      return Center(
        child: Text(l10n.noTopicsStudied, style: const TextStyle(color: Color(0xFF76310F))),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: topics.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final t = topics[i];
        return _card(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.topicId.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF44200B),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (t.mastered)
                    Text(l10n.masteredLabel,
                        style: const TextStyle(fontSize: 12, color: Color(0xFFFF8D00))),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${t.subject.toUpperCase()} · ${l10n.attemptsCount(t.attempts)}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF76310F)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (t.accuracy / 100).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: const Color(0xFFF7CDA5),
                        valueColor: AlwaysStoppedAnimation(
                          t.mastered ? const Color(0xFFFF8D00) : const Color(0xFF76310F),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${t.accuracy.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF44200B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubjectsTab(AppLocalizations l10n) {
    final subjects = _subjects;
    if (subjects == null || subjects.isEmpty) {
      return Center(
        child: Text(l10n.noSubjectsStudied, style: const TextStyle(color: Color(0xFF76310F))),
      );
    }

    final colors = [
      const Color(0xFFFF8D00),
      const Color(0xFF76310F),
      const Color(0xFFF7CDA5),
      const Color(0xFF44200B),
    ];

    final sections = subjects.asMap().entries.map((e) {
      final color = colors[e.key % colors.length];
      return PieChartSectionData(
        value: e.value.percent,
        color: color,
        title: '${e.value.percent.toStringAsFixed(0)}%',
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        radius: 80,
      );
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(l10n.timeBySubject),
                const SizedBox(height: 20),
                SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 48,
                      sectionsSpace: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...subjects.asMap().entries.map((e) {
                  final color = colors[e.key % colors.length];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration:
                              BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.value.subject.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF44200B),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          '${e.value.minutes}m (${e.value.percent.toStringAsFixed(0)}%)',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF76310F)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
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
      padding: padding ?? const EdgeInsets.all(18),
      child: child,
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Recoleta',
        fontWeight: FontWeight.w900,
        fontSize: 16,
        color: Color(0xFF44200B),
      ),
    );
  }

  Widget _bigStat(String value, String label, String icon) {
    return Expanded(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Recoleta',
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: Color(0xFF44200B),
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF76310F))),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 50, color: const Color(0xFFF7CDA5));
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF76310F))),
      ],
    );
  }
}
