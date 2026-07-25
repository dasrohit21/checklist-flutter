import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/app_state.dart';
import '../widgets/target_card.dart';
import 'mission_chains_screen.dart';

/// Missions screen — tabbed container for Mission List and Mission Chains.
///
/// The user thinks: "My chains belong to my missions."
///
/// Tabs:
///   Missions — searchable list of all targets/missions (HomeContent)
///   Chains   — MissionChainsScreen
class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.surface.withValues(alpha: 0.4),
                AppTheme.bg,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Tab bar header
                Container(
                  padding: const EdgeInsets.fromLTRB(
                      AppTheme.sp24, AppTheme.sp16, AppTheme.sp24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Missions',
                        style: AppTheme.displayStyle
                            .copyWith(color: AppTheme.text),
                      ),
                      const SizedBox(height: AppTheme.sp12),
                      // Tab pills
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.surfaceStrong.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppTheme.border.withValues(alpha: 0.1)),
                        ),
                        child: TabBar(
                          indicator: BoxDecoration(
                            color: AppTheme.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: const Color(0xFF0F172A),
                          unselectedLabelColor: AppTheme.textMuted,
                          labelStyle: AppTheme.buttonStyle,
                          unselectedLabelStyle: AppTheme.bodyStyle,
                          tabs: const [
                            Tab(text: 'Missions'),
                            Tab(text: 'Chains'),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.sp8),
                    ],
                  ),
                ),

                // Tab content
                const Expanded(
                  child: TabBarView(
                    children: [
                      _MissionListTab(),
                      MissionChainsScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Mission List Tab ─────────────────────────────────────────────────────────
enum _MissionFilter { all, active, completed, archived, overdue }

class _MissionListTab extends StatefulWidget {
  const _MissionListTab();

  @override
  State<_MissionListTab> createState() => _MissionListTabState();
}

class _MissionListTabState extends State<_MissionListTab> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _searchQuery = '';
  _MissionFilter _filter = _MissionFilter.all;
  String? _filterCategoryId;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  static const _filterLabels = {
    _MissionFilter.all: 'All',
    _MissionFilter.active: 'Active',
    _MissionFilter.completed: 'Completed',
    _MissionFilter.archived: 'Archived',
    _MissionFilter.overdue: 'Overdue',
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppTheme.sp24, AppTheme.sp16, AppTheme.sp24, AppTheme.sp24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar
                  _SearchCard(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    searchQuery: _searchQuery,
                    filter: _filter,
                    filterCategoryId: _filterCategoryId,
                    appState: appState,
                    onQueryChanged: (q) =>
                        setState(() => _searchQuery = q),
                    onFilterChanged: (f) =>
                        setState(() => _filter = f),
                    onCategoryChanged: (id) =>
                        setState(() => _filterCategoryId = id),
                    filterLabels: _filterLabels,
                  ),
                  const SizedBox(height: AppTheme.sp16),

                  // Mission list
                  _buildMissionList(appState),

                  // Archived section
                  if (_filter == _MissionFilter.all ||
                      _filter == _MissionFilter.archived) ...[
                    const SizedBox(height: AppTheme.sp24),
                    _buildArchivedList(appState),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMissionList(AppState appState) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    var items = appState.sortedTargets;

    if (_filterCategoryId != null) {
      items = items.where((t) => t.categoryId == _filterCategoryId).toList();
    }

    switch (_filter) {
      case _MissionFilter.active:
        items = items.where((t) => t.solvedCount < t.targetCount).toList();
        break;
      case _MissionFilter.completed:
        items = items
            .where((t) => t.targetCount > 0 && t.solvedCount >= t.targetCount)
            .toList();
        break;
      case _MissionFilter.overdue:
        items = items.where((t) {
          if (t.dueDate == null) return false;
          final due =
              DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
          return due.isBefore(todayDate) && t.solvedCount < t.targetCount;
        }).toList();
        break;
      case _MissionFilter.all:
      case _MissionFilter.archived:
        break;
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      items = items.where((t) {
        return t.title.toLowerCase().contains(q) ||
            t.notes.toLowerCase().contains(q) ||
            t.tags.any((tag) => tag.toLowerCase().contains(q));
      }).toList();
    }

    if (items.isEmpty) {
      return _EmptyState(
        icon: Icons.rocket_launch_outlined,
        title: 'No missions found.',
        subtitle: _searchQuery.isNotEmpty
            ? 'Try a different search.'
            : 'Create your first mission to begin execution.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MISSIONS',
              style:
                  AppTheme.labelStyle.copyWith(color: AppTheme.textMuted),
            ),
            Consumer<AppState>(
              builder: (context, state, _) => DropdownButton<SortOption>(
                value: state.sortOption,
                underline: const SizedBox.shrink(),
                dropdownColor: AppTheme.surface,
                style: AppTheme.captionStyle.copyWith(color: AppTheme.textMuted),
                icon: Icon(Icons.sort, color: AppTheme.textMuted, size: 18),
                items: const [
                  DropdownMenuItem(value: SortOption.newest, child: Text('Newest')),
                  DropdownMenuItem(value: SortOption.oldest, child: Text('Oldest')),
                  DropdownMenuItem(value: SortOption.alphabetical, child: Text('A → Z')),
                  DropdownMenuItem(value: SortOption.deadline, child: Text('Deadline')),
                  DropdownMenuItem(value: SortOption.progress, child: Text('Progress')),
                  DropdownMenuItem(value: SortOption.priority, child: Text('Priority')),
                ],
                onChanged: (v) {
                  if (v != null) state.setSortOption(v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.sp12),
        ...items.map((item) => TargetCard(item: item, searchQuery: _searchQuery)),
      ],
    );
  }

  Widget _buildArchivedList(AppState appState) {
    var items = appState.archivedTargets.toList();
    if (_filterCategoryId != null) {
      items = items.where((t) => t.categoryId == _filterCategoryId).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      items = items.where((t) {
        return t.title.toLowerCase().contains(q) ||
            t.notes.toLowerCase().contains(q) ||
            t.tags.any((tag) => tag.toLowerCase().contains(q));
      }).toList();
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ARCHIVED',
          style: AppTheme.labelStyle.copyWith(color: AppTheme.textMuted),
        ),
        const SizedBox(height: AppTheme.sp12),
        ...items.map((item) =>
            ArchivedTargetCard(item: item, searchQuery: _searchQuery)),
      ],
    );
  }
}

// ── Search Card ──────────────────────────────────────────────────────────────
class _SearchCard extends StatelessWidget {
  const _SearchCard({
    required this.controller,
    required this.focusNode,
    required this.searchQuery,
    required this.filter,
    required this.filterCategoryId,
    required this.appState,
    required this.onQueryChanged,
    required this.onFilterChanged,
    required this.onCategoryChanged,
    required this.filterLabels,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String searchQuery;
  final _MissionFilter filter;
  final String? filterCategoryId;
  final AppState appState;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<_MissionFilter> onFilterChanged;
  final ValueChanged<String?> onCategoryChanged;
  final Map<_MissionFilter, String> filterLabels;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.sp16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: 'Search missions, notes, tags...',
              prefixIcon:
                  Icon(Icons.search, color: AppTheme.textMuted, size: 20),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close,
                          color: AppTheme.textMuted, size: 18),
                      onPressed: () {
                        controller.clear();
                        onQueryChanged('');
                      },
                    )
                  : null,
            ),
            onChanged: (v) => onQueryChanged(v.trim()),
          ),
          const SizedBox(height: AppTheme.sp12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _MissionFilter.values.map((f) {
                final selected = filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filterLabels[f]!),
                    selected: selected,
                    selectedColor: AppTheme.accent,
                    backgroundColor:
                        AppTheme.surfaceStrong.withValues(alpha: 0.3),
                    labelStyle: AppTheme.captionStyle.copyWith(
                      color: selected
                          ? const Color(0xFF0F172A)
                          : AppTheme.text,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    ),
                    onSelected: (val) {
                      if (val) onFilterChanged(f);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          if (appState.categories.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(color: Color(0x1A94A3B8)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: filterCategoryId == null,
                    selectedColor: AppTheme.accent,
                    backgroundColor:
                        AppTheme.surfaceStrong.withValues(alpha: 0.3),
                    labelStyle: AppTheme.captionStyle.copyWith(
                      color: filterCategoryId == null
                          ? const Color(0xFF0F172A)
                          : AppTheme.text,
                    ),
                    onSelected: (val) {
                      if (val) onCategoryChanged(null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ...appState.categories.map((cat) {
                    final sel = filterCategoryId == cat.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat.name),
                        selected: sel,
                        selectedColor: Color(cat.colorValue),
                        backgroundColor:
                            AppTheme.surfaceStrong.withValues(alpha: 0.3),
                        labelStyle: AppTheme.captionStyle.copyWith(
                          color: sel ? Colors.white : AppTheme.text,
                        ),
                        onSelected: (val) {
                          if (val) onCategoryChanged(cat.id);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared Empty State ───────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: AppTheme.sp32, horizontal: AppTheme.sp24),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 36),
          const SizedBox(height: AppTheme.sp12),
          Text(
            title,
            style: AppTheme.subtitleStyle.copyWith(color: AppTheme.text),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTheme.captionStyle.copyWith(color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
