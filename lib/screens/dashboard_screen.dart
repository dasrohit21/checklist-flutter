import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/app_state.dart';
import '../models/target_item.dart';
import 'calendar_screen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _titleController = TextEditingController();
  final _countController = TextEditingController(text: '5');
  String _selectedPriority = 'medium';
  String? _selectedCategoryId;
  DateTime? _dueDate;
  int _selectedTab = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _countController.dispose();
    super.dispose();
  }


  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final todayStr = _todayString();
        final targetsToday = appState.dailyActivity[todayStr] ?? [];
        final totalSolvedToday = targetsToday.length;

        // Overall progress
        final totalActiveCount = appState.targets.length;
        final solvedActiveCount = appState.targets.where((t) => t.solvedCount >= t.targetCount).length;
        final overallProgress = totalActiveCount == 0 ? 0.0 : solvedActiveCount / totalActiveCount;

        // Upcoming deadlines
        final upcomingDeadlines = appState.targets
            .where((t) => t.dueDate != null && t.solvedCount < t.targetCount)
            .toList();
        upcomingDeadlines.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

        // Recent active targets worked on
        final recentTargets = appState.targets.take(5).toList();

        return Scaffold(
          backgroundColor: AppTheme.bg,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.surface.withValues(alpha: 0.4), AppTheme.bg],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeHeader(appState),
                        const SizedBox(height: 20),
                        _buildTabSelector(),
                        const SizedBox(height: 24),
                        
                        if (_selectedTab == 0) ...[
                          // Progress Overview Cards (Today's & Overall)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildProgressCard(
                                      title: "Today's Activity",
                                      value: "$totalSolvedToday",
                                      subtitle: "Targets worked on today",
                                      progress: totalSolvedToday == 0 ? 0.0 : 1.0,
                                      progressColor: AppTheme.success,
                                      icon: Icons.done_all,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildProgressCard(
                                      title: "Overall Progress",
                                      value: "${(overallProgress * 100).toStringAsFixed(0)}%",
                                      subtitle: "$solvedActiveCount of $totalActiveCount completed",
                                      progress: overallProgress,
                                      progressColor: AppTheme.accent,
                                      icon: Icons.donut_large,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // Streak and statistics
                          _buildStreakStatsRow(appState),
                          const SizedBox(height: 24),

                          // Upcoming deadlines & Recent Activity
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final useWide = constraints.maxWidth > 768;
                              if (useWide) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildUpcomingDeadlinesCard(upcomingDeadlines)),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildRecentActivityCard(recentTargets)),
                                  ],
                                );
                              } else {
                                return Column(
                                  children: [
                                    _buildUpcomingDeadlinesCard(upcomingDeadlines),
                                    const SizedBox(height: 24),
                                    _buildRecentActivityCard(recentTargets),
                                  ],
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 24),

                          // Quick Add Target
                          _buildQuickAddCard(appState),
                        ] else ...[
                          // Focus & Productivity Hub
                          _buildLevelHeader(appState),
                          const SizedBox(height: 20),
                          _buildStreakHubCard(appState),
                          const SizedBox(height: 24),
                          const Text(
                            'Focus Analytics',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 14),
                          _buildStatsGrid(appState),
                          const SizedBox(height: 28),
                          _buildAchievementsHub(appState),
                          const SizedBox(height: 28),
                          _buildMissionHistoryHub(appState),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceStrong.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(0, 'Targets Dashboard', Icons.dashboard_rounded),
          ),
          Expanded(
            child: _buildTabButton(1, 'Productivity Engine', Icons.track_changes_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? const Color(0xFF030712) : AppTheme.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF030712) : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelHeader(AppState appState) {
    final xpInLevel = appState.totalXp % 1000;
    final levelProgress = xpInLevel / 1000.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Level badge
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.accent, AppTheme.accent.withValues(alpha: 0.6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Center(
              child: Text(
                'Lvl ${appState.level}',
                style: const TextStyle(
                  color: Color(0xFF030712),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Productivity Tier',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '$xpInLevel / 1000 XP',
                      style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 10,
                    child: LinearProgressIndicator(
                      value: levelProgress,
                      backgroundColor: AppTheme.surfaceStrong.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
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

  Widget _buildStreakHubCard(AppState appState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Icon(Icons.local_fire_department_rounded, color: AppTheme.danger, size: 36),
              const SizedBox(height: 8),
              Text(
                '${appState.missionStreakCurrent} Days',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text('Current Streak', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ],
          ),
          Container(width: 1, height: 50, color: AppTheme.border.withValues(alpha: 0.15)),
          Column(
            children: [
              Icon(Icons.emoji_events_rounded, color: AppTheme.warning, size: 36),
              const SizedBox(height: 8),
              Text(
                '${appState.missionStreakBest} Days',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text('Longest Streak', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(AppState appState) {
    final history = appState.missionHistory;
    final completed = history.where((m) => m.status == 'completed').toList();
    final abandoned = history.where((m) => m.status == 'abandoned').toList();
    final totalMissions = history.length;
    final completionRate = totalMissions == 0 ? 0.0 : completed.length / totalMissions;
    
    final totalSeconds = completed.fold(0, (s, m) => s + m.durationSeconds);
    final deepWorkHours = totalSeconds / 3600.0;
    
    final totalFocus = history.fold(0, (s, m) => s + m.focusScore);
    final avgFocus = totalMissions == 0 ? 0 : totalFocus ~/ totalMissions;
    
    final longestMinutes = appState.longestSessionSeconds ~/ 60;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 600 ? 3 : 2;
        final width = (constraints.maxWidth - (16 * (columns - 1))) / columns;
        
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatHubCard('Completed', '${completed.length}', 'Successful runs', AppTheme.success, Icons.check_circle_rounded, width),
            _buildStatHubCard('Failed / Aborted', '${abandoned.length}', 'Abandoned sessions', AppTheme.danger, Icons.cancel_rounded, width),
            _buildStatHubCard('Completion Rate', '${(completionRate * 100).toStringAsFixed(0)}%', 'Overall efficiency', AppTheme.accent, Icons.donut_large, width),
            _buildStatHubCard('Deep Work', '${deepWorkHours.toStringAsFixed(1)} hrs', 'Total focus time', AppTheme.success, Icons.timer_rounded, width),
            _buildStatHubCard('Avg Focus Score', '$avgFocus / 100', 'Focus rating', AppTheme.warning, Icons.track_changes_rounded, width),
            _buildStatHubCard('Longest Session', '$longestMinutes mins', 'Personal record', AppTheme.accent, Icons.workspace_premium_rounded, width),
          ],
        );
      }
    );
  }

  Widget _buildStatHubCard(String title, String value, String subtitle, Color color, IconData icon, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildAchievementsHub(AppState appState) {
    final achievements = appState.achievements;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Achievements & Badges',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 500;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: achievements.length,
              itemBuilder: (context, idx) {
                final ach = achievements[idx];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ach.isUnlocked
                        ? AppTheme.accent.withValues(alpha: 0.08)
                        : AppTheme.surface.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ach.isUnlocked ? AppTheme.accent : AppTheme.border.withValues(alpha: 0.1),
                      width: ach.isUnlocked ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        ach.icon,
                        color: ach.isUnlocked ? AppTheme.accent : AppTheme.textMuted,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ach.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: ach.isUnlocked ? AppTheme.text : AppTheme.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ach.description,
                        style: TextStyle(
                          fontSize: 9,
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            );
          }
        ),
      ],
    );
  }

  Widget _buildMissionHistoryHub(AppState appState) {
    final history = appState.missionHistory.reversed.toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mission Activity History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        if (history.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No missions completed yet. Launch a target mission to get started!',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length > 5 ? 5 : history.length,
            separatorBuilder: (context, idx) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final item = history[idx];
              final isCompleted = item.status == 'completed';
              final durationMins = item.durationSeconds ~/ 60;
              
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppTheme.success.withValues(alpha: 0.1)
                            : AppTheme.danger.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_rounded : Icons.close_rounded,
                        color: isCompleted ? AppTheme.success : AppTheme.danger,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Type: ${item.type.name.toUpperCase()} • $durationMins mins • ${item.interruptions} interruptions',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isCompleted ? '+${item.xpEarned} XP' : '0 XP',
                          style: TextStyle(
                            color: isCompleted ? AppTheme.accent : AppTheme.textMuted,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isCompleted ? 'Focus: ${item.focusScore}' : 'Failed',
                          style: TextStyle(
                            color: isCompleted ? AppTheme.success : AppTheme.danger,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }


  Widget _buildWelcomeHeader(AppState appState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Stay focused. Keep track of your targets.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
            ),
          ],
        ),
        IconButton(
          icon: Icon(Icons.calendar_month, color: AppTheme.accent, size: 28),
          tooltip: 'Activity Calendar',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CalendarScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard({
    required String title,
    required String value,
    required String subtitle,
    required double progress,
    required Color progressColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Icon(icon, color: progressColor, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppTheme.bg,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakStatsRow(AppState appState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Streak & Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${appState.currentStreak} Days',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Current Streak',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${appState.bestStreak} Days',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Best Streak',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0x1A94A3B8)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _simpleStatBox("Problems Solved", "${appState.totalProblemsSolved}", AppTheme.success),
              _simpleStatBox("Remaining", "${appState.problemsRemaining}", AppTheme.warning),
              _simpleStatBox("Total Targets", "${appState.totalTargets}", AppTheme.accent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _simpleStatBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildUpcomingDeadlinesCard(List<TargetItem> items) {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Deadlines',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'No upcoming deadlines.',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  )
                : ListView.builder(
                    itemCount: items.length > 5 ? 5 : items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final dateStr = '${item.dueDate!.day}/${item.dueDate!.month}/${item.dueDate!.year}';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.danger.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                dateStr,
                                style: TextStyle(color: AppTheme.danger, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard(List<TargetItem> items) {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Active Targets',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'No active targets.',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  )
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final pct = item.targetCount == 0 ? 0.0 : item.solvedCount / item.targetCount;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              "${(pct * 100).toStringAsFixed(0)}% Done",
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddCard(AppState appState) {
    if (_selectedCategoryId == null && appState.categories.isNotEmpty) {
      _selectedCategoryId = appState.defaultCategoryId ?? appState.categories.first.id;
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Add Target',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final useWide = constraints.maxWidth > 640;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: useWide ? 300 : double.infinity,
                    child: TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'Enter target title',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _countController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Count',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedPriority,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'high', child: Text('🔴 High')),
                        DropdownMenuItem(value: 'medium', child: Text('🟡 Medium')),
                        DropdownMenuItem(value: 'low', child: Text('🟢 Low')),
                      ],
                      onChanged: (v) => setState(() => _selectedPriority = v ?? 'medium'),
                    ),
                  ),
                  if (appState.categories.isNotEmpty)
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCategoryId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: appState.categories.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedCategoryId = v),
                      ),
                    ),


                  SizedBox(
                    width: 150,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _dueDate == null ? AppTheme.text : AppTheme.accent,
                        side: BorderSide(color: AppTheme.border.withValues(alpha: 0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (picked != null) {
                          setState(() => _dueDate = picked);
                        }
                      },
                      child: Text(_dueDate == null ? 'Set Due Date' : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final title = _titleController.text.trim();
                      final count = int.tryParse(_countController.text) ?? 5;
                      if (title.isEmpty) return;
                      await appState.addTarget(
                        title,
                        count,
                        dueDate: _dueDate,
                        priority: _selectedPriority,
                        categoryId: _selectedCategoryId,
                      );
                      _titleController.clear();
                      _countController.text = '5';
                      if (!context.mounted) return;
                      setState(() {
                        _dueDate = null;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Target added!')),
                      );
                    },

                    child: const Text('Add Target'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
