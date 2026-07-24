import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/mission_chain.dart';
import '../providers/app_state.dart';
import '../widgets/chain_dashboard_widget.dart';
import 'create_chain_screen.dart';
import 'chain_statistics_screen.dart';

class MissionChainsScreen extends StatelessWidget {
  const MissionChainsScreen({super.key});

  IconData _getIconData(String name) {
    switch (name) {
      case 'code':
        return Icons.code_rounded;
      case 'book':
        return Icons.menu_book_rounded;
      case 'fitness':
        return Icons.fitness_center_rounded;
      case 'brain':
        return Icons.psychology_rounded;
      case 'sun':
        return Icons.wb_sunny_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'rocket':
        return Icons.rocket_launch_rounded;
      default:
        return Icons.repeat_rounded;
    }
  }

  Color _getColorFromHex(String hex) {
    try {
      return Color(int.parse(hex));
    } catch (_) {
      return AppTheme.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final activeChain = appState.activeChain;
        final chains = appState.chains;

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
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Mission Chains',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sequence focus missions into routines & sprints',
                                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.analytics_outlined, color: AppTheme.accent),
                                  tooltip: 'Chain Analytics',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const ChainStatisticsScreen()),
                                    );
                                  },
                                ),
                                const SizedBox(width: 4),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accent,
                                    foregroundColor: const Color(0xFF030712),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const CreateChainScreen()),
                                    );
                                  },
                                  icon: const Icon(Icons.add_rounded, size: 20),
                                  label: const Text('New Chain', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Active Chain Card Banner
                        if (activeChain != null) ...[
                          ChainDashboardWidget(chain: activeChain),
                          const SizedBox(height: 28),
                        ],

                        // Section Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Available Chains',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${chains.length} Total',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Empty State
                        if (chains.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                            decoration: BoxDecoration(
                              color: AppTheme.surface.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: AppTheme.border.withValues(alpha: 0.15)),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.link_rounded, size: 48, color: AppTheme.textMuted),
                                const SizedBox(height: 16),
                                const Text(
                                  'No Mission Chains Created Yet',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Create a chain (e.g. Morning Routine) to automatically execute focus missions in sequence!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accent,
                                    foregroundColor: const Color(0xFF030712),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const CreateChainScreen()),
                                    );
                                  },
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Create Your First Chain', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: chains.length,
                            separatorBuilder: (context, idx) => const SizedBox(height: 18),
                            itemBuilder: (context, idx) {
                              final chain = chains[idx];
                              return _buildChainCard(context, appState, chain);
                            },
                          ),
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

  Widget _buildChainCard(BuildContext context, AppState appState, MissionChain chain) {
    final themeColor = _getColorFromHex(chain.colorHex);
    final isRunning = appState.activeChain?.id == chain.id;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isRunning ? AppTheme.accent : AppTheme.border.withValues(alpha: 0.15),
          width: isRunning ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row (Icon, Title, Popup Actions)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getIconData(chain.iconName), color: themeColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chain.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (chain.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        chain.description,
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                color: AppTheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (val) async {
                  if (val == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CreateChainScreen(initialChain: chain)),
                    );
                  } else if (val == 'delete') {
                    await appState.deleteChain(chain.id);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit Chain')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red, size: 18), SizedBox(width: 8), Text('Delete Chain', style: TextStyle(color: Colors.red))])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Metrics Pill Row
          Row(
            children: [
              _buildMetricChip(Icons.format_list_numbered_rounded, '${chain.totalMissions} Missions'),
              const SizedBox(width: 10),
              _buildMetricChip(Icons.timer_outlined, '~${chain.estimatedTotalDurationMinutes} mins'),
              const SizedBox(width: 10),
              _buildMetricChip(Icons.stars_rounded, '+${chain.xpReward} XP'),
              if (chain.currentStreak > 0) ...[
                const SizedBox(width: 10),
                _buildMetricChip(Icons.local_fire_department_rounded, '${chain.currentStreak}d Streak', color: AppTheme.danger),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Locked/Unlocked Missions Items Sequence List
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceStrong.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MISSION SEQUENCE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 1.1),
                ),
                const SizedBox(height: 10),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: chain.items.length,
                  separatorBuilder: (context, idx) => const Padding(
                    padding: EdgeInsets.only(left: 12, top: 4, bottom: 4),
                    child: Icon(Icons.arrow_downward_rounded, size: 14, color: Colors.grey),
                  ),
                  itemBuilder: (context, idx) {
                    final item = chain.items[idx];
                    final isCompleted = item.isCompleted;
                    final isCurrentActive = isRunning && appState.activeChain?.currentMissionIndex == idx;
                    final isLocked = item.isLocked && !isCompleted && !isCurrentActive;

                    return Row(
                      children: [
                        Icon(
                          isCompleted
                              ? Icons.check_circle_rounded
                              : (isCurrentActive
                                  ? Icons.play_circle_fill_rounded
                                  : Icons.lock_outline_rounded),
                          color: isCompleted
                              ? AppTheme.success
                              : (isCurrentActive ? AppTheme.accent : AppTheme.textMuted),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isCurrentActive ? FontWeight.bold : FontWeight.w600,
                              color: isLocked ? AppTheme.textMuted : AppTheme.text,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isLocked)
                          Text(
                            '🔒 Locked',
                            style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                          )
                        else
                          Text(
                            '${item.estimatedDurationMinutes}m',
                            style: TextStyle(fontSize: 11, color: isCurrentActive ? AppTheme.accent : AppTheme.textMuted),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Start / Resume Chain Quick Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isRunning ? AppTheme.surfaceStrong : themeColor,
                foregroundColor: isRunning ? AppTheme.text : const Color(0xFF030712),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              onPressed: () async {
                if (isRunning) {
                  await appState.resumeActiveChain();
                } else {
                  await appState.startChain(chain.id);
                }
              },
              icon: Icon(isRunning ? Icons.play_arrow_rounded : Icons.play_circle_fill_rounded),
              label: Text(
                isRunning ? 'Resume Active Chain' : 'Start Mission Chain',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String label, {Color? color}) {
    final textColor = color ?? AppTheme.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceStrong.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
          ),
        ],
      ),
    );
  }
}
