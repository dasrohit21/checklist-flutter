import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/coach_personality.dart';
import '../providers/coach_provider.dart';

/// Settings screen for managing the Coach Engine.
///
/// Features:
///   - Enable / Disable toggle for Coach Engine.
///   - Personality selection (Mentor, Balanced, Drill Sergeant, Rival, Stoic).
///   - Interactive Live Preview displaying sample observations.
class CoachSettingsScreen extends StatelessWidget {
  const CoachSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CoachProvider>(
      builder: (context, coach, _) {
        return Scaffold(
          backgroundColor: AppTheme.bg,
          appBar: AppBar(
            backgroundColor: AppTheme.surface,
            elevation: 0,
            title: Text(
              'Coach Settings',
              style: TextStyle(
                color: AppTheme.text,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            iconTheme: IconThemeData(color: AppTheme.text),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── 1. Enable / Disable Toggle ───────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.border.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.psychology_rounded,
                        color: AppTheme.accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enable Coach Engine',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Behavior-driven observations inside your planner.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: coach.isEnabled,
                      onChanged: (val) => coach.setEnabled(val),
                      activeTrackColor: AppTheme.accent.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (coach.isEnabled) ...[
                // ── 2. Personality Selector ─────────────────────────────────
                Text(
                  'COACH PERSONALITY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                ...CoachPersonality.values.map((p) {
                  final isSelected = coach.personality == p;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.accent.withValues(alpha: 0.12)
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.accent
                            : AppTheme.border.withValues(alpha: 0.15),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: ListTile(
                      onTap: () => coach.setPersonality(p),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.accent
                              : AppTheme.surfaceStrong.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          p.icon,
                          size: 20,
                          color: isSelected
                              ? const Color(0xFF030712)
                              : AppTheme.textMuted,
                        ),
                      ),
                      title: Text(
                        p.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppTheme.accent : AppTheme.text,
                        ),
                      ),
                      subtitle: Text(
                        p.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded,
                              color: AppTheme.accent, size: 20)
                          : null,
                    ),
                  );
                }),
                const SizedBox(height: 24),

                // ── 3. Live Personality Preview ──────────────────────────────
                Text(
                  'LIVE PREVIEW',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                _PreviewCard(personality: coach.personality),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final CoachPersonality personality;

  const _PreviewCard({required this.personality});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.accent.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(personality.icon, color: AppTheme.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'Coach · ${personality.displayName}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            personality.sampleQuote,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.text,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Focus: Execute your planned missions in order.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
