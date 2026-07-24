import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/app_state.dart';

class ChainStatisticsScreen extends StatelessWidget {
  const ChainStatisticsScreen({super.key});

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final hrs = mins ~/ 60;
    if (hrs > 0) {
      return '${hrs}h ${mins % 60}m';
    }
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final stats = appState.chainStats;
    final history = appState.chainHistory.reversed.toList();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text(
          'Chain Analytics & History',
          style: TextStyle(color: AppTheme.text, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Metrics Summary Grid
              const Text(
                'Chain Performance Metrics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth > 600 ? 3 : 2;
                  final width = (constraints.maxWidth - (16 * (cols - 1))) / cols;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildCard('Completed Chains', '${stats.chainsCompleted}', 'Successfully finished', AppTheme.success, Icons.check_circle_rounded, width),
                      _buildCard('Current Streak', '${stats.currentChainStreak} Days', 'Active daily streak', AppTheme.accent, Icons.local_fire_department_rounded, width),
                      _buildCard('Longest Streak', '${stats.longestChainStreak} Days', 'Personal record', AppTheme.warning, Icons.emoji_events_rounded, width),
                      _buildCard('Perfect Days', '${stats.perfectDays}', 'Zero-fail days', AppTheme.accent, Icons.stars_rounded, width),
                      _buildCard('Avg Completion', '${(stats.averageCompletionRate * 100).toStringAsFixed(0)}%', 'Chain finish rate', AppTheme.success, Icons.donut_large_rounded, width),
                      _buildCard('Avg Duration', _formatDuration(stats.averageDurationSeconds), 'Per chain session', AppTheme.accent, Icons.timer_rounded, width),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Best & Worst Performing Cards
              if (stats.bestPerformingChainName != null || stats.mostFailedChainName != null) ...[
                Row(
                  children: [
                    if (stats.bestPerformingChainName != null)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('TOP PERFORMER', style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                              const SizedBox(height: 6),
                              Text(stats.bestPerformingChainName!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ),
                    if (stats.bestPerformingChainName != null && stats.mostFailedChainName != null)
                      const SizedBox(width: 12),
                    if (stats.mostFailedChainName != null)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('MOST FAILED', style: TextStyle(color: AppTheme.danger, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                              const SizedBox(height: 6),
                              Text(stats.mostFailedChainName!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
              ],

              // History Logs List
              const Text(
                'Chain Activity History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),

              if (history.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No chain execution history recorded yet.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  separatorBuilder: (context, idx) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final item = history[idx];
                    final isCompleted = item.status == 'completed';
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
                              isCompleted ? Icons.workspace_premium_rounded : Icons.cancel_outlined,
                              color: isCompleted ? AppTheme.success : AppTheme.danger,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.chainName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.completedMissions} missions • ${_formatDuration(item.durationSeconds)}',
                                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                isCompleted ? '+${item.xpEarned} XP' : 'Failed',
                                style: TextStyle(
                                  color: isCompleted ? AppTheme.accent : AppTheme.danger,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${(item.completionPercentage * 100).round()}% Completed',
                                style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, String val, String sub, Color color, IconData icon, double width) {
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
              Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
