import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/app_state.dart';
import '../providers/theme_provider.dart';
import '../services/pdf_export_service.dart';
import 'chain_completion_screen.dart';
import 'execution_home_screen.dart';
import 'insights_screen.dart';
import 'missions_screen.dart';
import 'mission_screen.dart';
import 'planner_screen.dart';
import 'settings_screen.dart';

/// Shell widget that owns the bottom navigation and switches between the 5
/// top-level tabs:
///
///   0 — Home      (ExecutionHomeScreen — execution-first view)
///   1 — Planner   (PlannerScreen — unchanged)
///   2 — Missions  (MissionsScreen — missions list + chains)
///   3 — Insights  (InsightsScreen — learning + productivity)
///   4 — Settings  (SettingsScreen — unchanged)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeProvider>(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Theme(
            data: AppTheme.buildTheme(),
            child: Builder(
              builder: (context) {
                final appState = Provider.of<AppState>(context);

                // Full-screen overlays take priority over tabs
                if (appState.celebratingChain != null) {
                  return ChainCompletionScreen(
                      chain: appState.celebratingChain!);
                }
                if (appState.activeMission != null) {
                  return const MissionScreen();
                }

                const screens = [
                  ExecutionHomeScreen(), // 0 — Home
                  PlannerScreen(),       // 1 — Planner
                  MissionsScreen(),      // 2 — Missions (list + chains)
                  InsightsScreen(),      // 3 — Insights (learning + productivity)
                  SettingsScreen(),      // 4 — Settings
                ];

                const titles = [
                  'Home',
                  'Planner',
                  'Missions',
                  'Insights',
                  'Settings',
                ];

                return Focus(
                  autofocus: true,
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent) {
                      final isControl =
                          event.logicalKey == LogicalKeyboardKey.controlLeft ||
                          event.logicalKey == LogicalKeyboardKey.controlRight ||
                          HardwareKeyboard.instance.isControlPressed;

                      // Ctrl+N → go to Missions
                      if (isControl &&
                          event.logicalKey == LogicalKeyboardKey.keyN) {
                        setState(() => _currentIndex = 2);
                        return KeyEventResult.handled;
                      }
                      // Ctrl+S → backup to clipboard
                      if (isControl &&
                          event.logicalKey == LogicalKeyboardKey.keyS) {
                        appState.exportBackup().then((backup) {
                          Clipboard.setData(ClipboardData(text: backup));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Data backup copied!')),
                          );
                        });
                        return KeyEventResult.handled;
                      }
                      // Escape → unfocus
                      if (event.logicalKey == LogicalKeyboardKey.escape) {
                        FocusScope.of(context).unfocus();
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: Scaffold(
                    backgroundColor: AppTheme.bg,
                    appBar: AppBar(
                      backgroundColor:
                          AppTheme.surface.withValues(alpha: 0.95),
                      elevation: 0,
                      title: Text(
                        titles[_currentIndex],
                        style: AppTheme.titleStyle.copyWith(
                            color: AppTheme.text,
                            fontWeight: FontWeight.w700),
                      ),
                      centerTitle: true,
                      actions: [
                        IconButton(
                          icon: Icon(Icons.picture_as_pdf,
                              color: AppTheme.accent),
                          tooltip: 'Export Report to PDF',
                          onPressed: () async {
                            await PdfExportService.exportReport(
                              targets: appState.targets,
                              archivedTargets: appState.archivedTargets,
                              checklistItems: appState.checklistItems,
                              streak: appState.currentStreak,
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    body: AnimatedSwitcher(
                      duration: Duration(
                          milliseconds: appState.animationsOn ? 280 : 0),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: KeyedSubtree(
                        key: ValueKey(_currentIndex),
                        child: screens[_currentIndex],
                      ),
                    ),
                    bottomNavigationBar: _BottomNav(
                      currentIndex: _currentIndex,
                      onTap: (i) => setState(() => _currentIndex = i),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onTap});
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
            top: BorderSide(color: AppTheme.border.withValues(alpha: 0.2))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.view_timeline_outlined,
                activeIcon: Icons.view_timeline_rounded,
                label: 'Planner',
                index: 1,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.rocket_launch_outlined,
                activeIcon: Icons.rocket_launch_rounded,
                label: 'Missions',
                index: 2,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.insights_outlined,
                activeIcon: Icons.insights_rounded,
                label: 'Insights',
                index: 3,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings_rounded,
                label: 'Settings',
                index: 4,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive ? AppTheme.accent : AppTheme.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTheme.captionStyle.copyWith(
                color: isActive ? AppTheme.accent : AppTheme.textMuted,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w400,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
