import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/mission_chain.dart';
import '../providers/app_state.dart';

class ChainDashboardWidget extends StatelessWidget {
  final MissionChain chain;

  const ChainDashboardWidget({
    super.key,
    required this.chain,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isPaused = chain.status == ChainStatus.paused;
    final currentItem = chain.items.isNotEmpty && chain.currentMissionIndex < chain.items.length
        ? chain.items[chain.currentMissionIndex]
        : null;

    final remainingMissions = chain.items.length - chain.completedMissionsCount;
    final estimatedTimeRemainingMinutes = chain.items
        .skip(chain.currentMissionIndex)
        .fold(0, (sum, item) => sum + item.estimatedDurationMinutes);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.accent.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withValues(alpha: 0.1),
            blurRadius: 16,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPaused ? Icons.pause_circle_outline : Icons.local_fire_department_rounded,
                  color: AppTheme.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isPaused ? 'CHAIN PAUSED' : 'ACTIVE CHAIN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isPaused ? AppTheme.warning : AppTheme.accent,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceStrong,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${chain.completedMissionsCount}/${chain.totalMissions} Done',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chain.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Abandon Button
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                color: AppTheme.textMuted,
                tooltip: 'Abandon Chain',
                onPressed: () => _confirmAbandonChain(context, appState),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Current Mission Callout
          if (currentItem != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceStrong.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Icon(
                    currentItem.isLocked ? Icons.lock_outline : Icons.play_circle_fill_rounded,
                    color: currentItem.isLocked ? AppTheme.textMuted : AppTheme.accent,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CURRENT MISSION',
                          style: TextStyle(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentItem.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '~${currentItem.estimatedDurationMinutes} mins',
                    style: TextStyle(fontSize: 12, color: AppTheme.accent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chain Progress (${(chain.completionPercentage * 100).round()}%)',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '~${estimatedTimeRemainingMinutes}m remaining',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 10,
                  child: LinearProgressIndicator(
                    value: chain.completionPercentage,
                    backgroundColor: AppTheme.surfaceStrong.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Button Row
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isPaused ? AppTheme.warning : AppTheme.accent,
                foregroundColor: const Color(0xFF030712),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              onPressed: () async {
                if (isPaused) {
                  await appState.resumeActiveChain();
                } else {
                  await appState.pauseActiveChain();
                }
              },
              icon: Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
              label: Text(
                isPaused ? 'Resume Chain Execution' : 'Pause Chain Execution',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmAbandonChain(BuildContext context, AppState appState) {
    final completed = chain.completedMissionsCount;
    final remaining = chain.totalMissions - completed;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 28),
            const SizedBox(width: 10),
            const Text(
              'Abandon Chain?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Abandoning this chain will mark it as failed and reduce your discipline score (-15 pts). Completed mission logs will be preserved.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceStrong.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Completed Missions:', style: TextStyle(fontSize: 12)),
                      Text('$completed', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Remaining Missions:', style: TextStyle(fontSize: 12)),
                      Text('$remaining', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.danger)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Continue Chain', style: TextStyle(color: AppTheme.accent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await appState.abandonActiveChain();
            },
            child: const Text('Abandon Chain'),
          ),
        ],
      ),
    );
  }
}
