import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/mission.dart';
import '../models/mission_chain.dart';
import '../models/target_item.dart';
import '../providers/app_state.dart';

class CreateChainScreen extends StatefulWidget {
  final MissionChain? initialChain;

  const CreateChainScreen({
    super.key,
    this.initialChain,
  });

  @override
  State<CreateChainScreen> createState() => _CreateChainScreenState();
}

class _CreateChainScreenState extends State<CreateChainScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;

  String _selectedIcon = 'routine';
  String _selectedColor = '0xFF6366F1';
  ChainRepeatOption _repeatOption = ChainRepeatOption.daily;
  List<MissionChainItem> _items = [];

  final List<String> _icons = ['routine', 'code', 'book', 'fitness', 'brain', 'sun', 'star', 'rocket'];
  final List<String> _colors = [
    '0xFF6366F1', // Indigo
    '0xFF10B981', // Emerald
    '0xFFF59E0B', // Amber
    '0xFFEF4444', // Red
    '0xFF8B5CF6', // Purple
    '0xFFEC4899', // Pink
    '0xFF06B6D4', // Cyan
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialChain?.name ?? '');
    _descController = TextEditingController(text: widget.initialChain?.description ?? '');

    if (widget.initialChain != null) {
      _selectedIcon = widget.initialChain!.iconName;
      _selectedColor = widget.initialChain!.colorHex;
      _repeatOption = widget.initialChain!.repeatOption;
      _items = List<MissionChainItem>.from(widget.initialChain!.items);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

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
    return Color(int.parse(hex));
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isEditing = widget.initialChain != null;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text(
          isEditing ? 'Edit Mission Chain' : 'Create Mission Chain',
          style: TextStyle(color: AppTheme.text, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chain Name
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: AppTheme.text),
                  decoration: InputDecoration(
                    labelText: 'Chain Name',
                    hintText: 'e.g. Morning Focus Routine',
                    labelStyle: TextStyle(color: AppTheme.accent),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a chain name' : null,
                ),
                const SizedBox(height: 20),

                // Description
                TextFormField(
                  controller: _descController,
                  style: TextStyle(color: AppTheme.text),
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Brief summary of this routine',
                    labelStyle: TextStyle(color: AppTheme.accent),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 24),

                // Icon & Color Selection
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Chain Icon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _icons.map((iconStr) {
                              final isSelected = _selectedIcon == iconStr;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedIcon = iconStr),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.accent.withValues(alpha: 0.2)
                                        : AppTheme.surfaceStrong.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? AppTheme.accent : Colors.transparent,
                                    ),
                                  ),
                                  child: Icon(_getIconData(iconStr), color: isSelected ? AppTheme.accent : AppTheme.textMuted, size: 20),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Theme Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _colors.map((hexStr) {
                              final isSelected = _selectedColor == hexStr;
                              final color = _getColorFromHex(hexStr);
                              return GestureDetector(
                                onTap: () => setState(() => _selectedColor = hexStr),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? Colors.white : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Repeat Schedule
                const Text('Repeat Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<ChainRepeatOption>(
                  initialValue: _repeatOption,
                  dropdownColor: AppTheme.surface,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  items: ChainRepeatOption.values.map((opt) {
                    return DropdownMenuItem(
                      value: opt,
                      child: Text(opt.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _repeatOption = val);
                  },
                ),
                const SizedBox(height: 28),

                // Chain Missions Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chain Missions (${_items.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddMissionModal(context, appState),
                      icon: Icon(Icons.add_rounded, color: AppTheme.accent),
                      label: Text('Add Mission', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Reorderable List of Missions
                if (_items.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border.withValues(alpha: 0.15)),
                    ),
                    child: Center(
                      child: Text(
                        'No missions added yet.\nTap "Add Mission" above to build your sequence!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                    ),
                  )
                else
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    onReorderItem: (oldIdx, newIdx) {
                      setState(() {
                        final item = _items.removeAt(oldIdx);
                        _items.insert(newIdx, item);
                        _items = _items.asMap().entries.map((e) => e.value.copyWith(order: e.key)).toList();
                      });
                    },
                    itemBuilder: (context, idx) {
                      final item = _items[idx];
                      return Container(
                        key: ValueKey(item.id),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surface.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${idx + 1}',
                                style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
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
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.type.name.toUpperCase()} • ${item.estimatedDurationMinutes} mins',
                                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 20),
                              color: AppTheme.danger,
                              onPressed: () {
                                setState(() {
                                  _items.removeAt(idx);
                                  _items = _items.asMap().entries.map((e) => e.value.copyWith(order: e.key)).toList();
                                });
                              },
                            ),
                            const Icon(Icons.drag_handle_rounded, color: Colors.grey),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 36),

                // Save Chain Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: const Color(0xFF030712),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      if (_items.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please add at least one mission to the chain.')),
                        );
                        return;
                      }

                      final chain = MissionChain(
                        id: widget.initialChain?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        name: _nameController.text.trim(),
                        description: _descController.text.trim(),
                        iconName: _selectedIcon,
                        colorHex: _selectedColor,
                        repeatOption: _repeatOption,
                        items: _items,
                        status: widget.initialChain?.status ?? ChainStatus.idle,
                      );

                      if (isEditing) {
                        await appState.updateChain(chain);
                      } else {
                        await appState.addChain(chain);
                      }

                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                    child: Text(
                      isEditing ? 'Save Changes' : 'Create Mission Chain',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddMissionModal(BuildContext context, AppState appState) {
    if (appState.targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create targets first before adding to a chain.')),
      );
      return;
    }

    TargetItem selectedTarget = appState.targets.first;
    String missionName = 'Mission: ${selectedTarget.title}';
    int estimatedDuration = 30;
    MissionType selectedType = MissionType.normal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add Chain Mission', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // Target Selector Dropdown
                  DropdownButtonFormField<TargetItem>(
                    initialValue: selectedTarget,
                    dropdownColor: AppTheme.surface,
                    decoration: InputDecoration(
                      labelText: 'Select Target',
                      labelStyle: TextStyle(color: AppTheme.accent),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: appState.targets.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedTarget = val;
                          missionName = 'Mission: ${val.title}';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // Mission Name Input
                  TextFormField(
                    initialValue: missionName,
                    style: TextStyle(color: AppTheme.text),
                    decoration: InputDecoration(
                      labelText: 'Mission Title',
                      labelStyle: TextStyle(color: AppTheme.accent),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onChanged: (val) => missionName = val,
                  ),
                  const SizedBox(height: 14),

                  // Estimated Duration Dropdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimated Duration:', style: TextStyle(fontWeight: FontWeight.w600)),
                      DropdownButton<int>(
                        value: estimatedDuration,
                        dropdownColor: AppTheme.surface,
                        underline: const SizedBox(),
                        style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold),
                        items: [15, 25, 30, 45, 60, 90, 120].map((mins) {
                          return DropdownMenuItem(value: mins, child: Text('$mins mins'));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => estimatedDuration = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Mission Type Selector
                  DropdownButtonFormField<MissionType>(
                    initialValue: selectedType,
                    dropdownColor: AppTheme.surface,
                    decoration: InputDecoration(
                      labelText: 'Mission Type',
                      labelStyle: TextStyle(color: AppTheme.accent),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: MissionType.values.map((t) {
                      return DropdownMenuItem(value: t, child: Text(t.name.toUpperCase()));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedType = val);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Add Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: const Color(0xFF030712),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        final newItem = MissionChainItem(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          targetId: selectedTarget.id,
                          name: missionName.trim().isEmpty ? 'Mission: ${selectedTarget.title}' : missionName.trim(),
                          estimatedDurationMinutes: estimatedDuration,
                          type: selectedType,
                          order: _items.length,
                          isCompleted: false,
                          isLocked: _items.isNotEmpty,
                        );

                        setState(() {
                          _items.add(newItem);
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Add to Chain', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
