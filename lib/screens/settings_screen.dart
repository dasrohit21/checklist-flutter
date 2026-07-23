import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../providers/app_state.dart';
import '../models/category_item.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _backupController = TextEditingController();

  @override
  void dispose() {
    _backupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final appState = Provider.of<AppState>(context);

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
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 24),

                    // Theme selector card
                    _buildSettingsCard(
                      title: "Appearance",
                      icon: Icons.palette,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Select Theme', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: AppThemeMode.values.map((mode) {
                              final isSelected = themeProvider.mode == mode;
                              String label = '';
                              Color previewBg = Colors.black;
                              Color previewAccent = Colors.blue;

                              switch (mode) {
                                case AppThemeMode.dark:
                                  label = 'Dark';
                                  previewBg = const Color(0xFF0F172A);
                                  previewAccent = const Color(0xFF38BDF8);
                                  break;
                                case AppThemeMode.light:
                                  label = 'Light';
                                  previewBg = const Color(0xFFF8FAFC);
                                  previewAccent = const Color(0xFF0284C7);
                                  break;
                                case AppThemeMode.oledBlack:
                                  label = 'OLED Black';
                                  previewBg = Colors.black;
                                  previewAccent = const Color(0xFF38BDF8);
                                  break;
                                case AppThemeMode.blue:
                                  label = 'Blue';
                                  previewBg = const Color(0xFF0B132B);
                                  previewAccent = const Color(0xFF48CAE4);
                                  break;
                              }

                              return InkWell(
                                onTap: () => themeProvider.setThemeMode(mode),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 150,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppTheme.surfaceStrong : AppTheme.surface.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? AppTheme.accent : AppTheme.border.withValues(alpha: 0.15),
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: previewBg,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: previewAccent, width: 2),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            color: isSelected ? AppTheme.text : AppTheme.textMuted,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Target Defaults Settings Card
                    _buildSettingsCard(
                      title: "Defaults & Behavior",
                      icon: Icons.tune,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Default Target Count', style: TextStyle(fontWeight: FontWeight.w600)),
                              SizedBox(
                                width: 80,
                                child: DropdownButton<int>(
                                  value: appState.defaultTargetCount,
                                  dropdownColor: AppTheme.surface,
                                  items: [1, 2, 3, 5, 10, 15, 20].map((val) {
                                    return DropdownMenuItem<int>(
                                      value: val,
                                      child: Text('$val'),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) appState.setDefaultTargetCount(val);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Color(0x1A94A3B8)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Default Category', style: TextStyle(fontWeight: FontWeight.w600)),
                              DropdownButton<String>(
                                value: appState.defaultCategoryId,
                                dropdownColor: AppTheme.surface,
                                hint: const Text('None'),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('None'),
                                  ),
                                  ...appState.categories.map((c) {
                                    return DropdownMenuItem<String>(
                                      value: c.id,
                                      child: Text(c.name),
                                    );
                                  }),
                                ],
                                onChanged: (val) {
                                  appState.setDefaultCategoryId(val);
                                },
                              ),
                            ],
                          ),
                          const Divider(color: Color(0x1A94A3B8)),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Enable UI Animations', style: TextStyle(fontWeight: FontWeight.w600)),
                            value: appState.animationsOn,
                            activeThumbColor: AppTheme.accent,
                            onChanged: (val) => appState.setAnimationsOn(val),

                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Categories Management Card
                    _buildSettingsCard(
                      title: "Manage Categories",
                      icon: Icons.category,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${appState.categories.length} categories configured',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accent,
                                  foregroundColor: const Color(0xFF0F172A),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => _showCategoryDialog(context, null),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Category'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: appState.categories.map((cat) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Color(cat.colorValue).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Color(cat.colorValue).withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: Color(cat.colorValue),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      cat.name,
                                      style: TextStyle(
                                        color: Color(cat.colorValue),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => _showCategoryDialog(context, cat),
                                      child: Icon(Icons.edit, size: 14, color: AppTheme.textMuted),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            backgroundColor: const Color(0xFF0F172A),
                                            title: const Text('Delete Category?'),
                                            content: Text('Are you sure you want to delete category "${cat.name}"? Targets assigned to this category will be reset to uncategorized.'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, true),
                                                child: Text('Delete', style: TextStyle(color: AppTheme.danger)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await appState.deleteCategory(cat.id);
                                        }
                                      },
                                      child: Icon(Icons.close, size: 14, color: AppTheme.danger),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Backup & Restore settings card
                    _buildSettingsCard(
                      title: "Backup & Restore",
                      icon: Icons.backup,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Generate or Restore your checklists local data backup payload.', style: TextStyle(fontSize: 13)),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.surfaceStrong,
                                  foregroundColor: AppTheme.text,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () async {
                                  final backup = await appState.exportBackup();
                                  _backupController.text = backup;
                                  Clipboard.setData(ClipboardData(text: backup));
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Backup copied to clipboard!')),
                                  );
                                },
                                icon: const Icon(Icons.copy_all, size: 18),
                                label: const Text('Generate Backup payload'),
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.text,
                                  side: BorderSide(color: AppTheme.border.withValues(alpha: 0.3)),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => _showRestoreDialog(context, appState),
                                icon: const Icon(Icons.settings_backup_restore, size: 18),
                                label: const Text('Import Backup'),
                              ),
                            ],
                          ),

                          if (_backupController.text.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _backupController,
                              readOnly: true,
                              maxLines: 4,
                              decoration: InputDecoration(
                                labelText: 'Generated Backup Code',
                                labelStyle: TextStyle(color: AppTheme.accent),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Focus & Productivity Settings card
                    _buildSettingsCard(
                      title: "Focus Preferences",
                      icon: Icons.track_changes_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            title: const Text('XP Popups & Alerts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: const Text('Display visual XP animations on completing missions', style: TextStyle(fontSize: 12)),
                            value: appState.xpPopupsEnabled,
                            activeThumbColor: AppTheme.accent,
                            onChanged: (val) => appState.setXpPopupsEnabled(val),
                            contentPadding: EdgeInsets.zero,
                          ),
                          const Divider(color: Color(0x1A94A3B8)),
                          SwitchListTile(
                            title: const Text('Sound Feedback', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: const Text('Play immersive notifications for focus shifts', style: TextStyle(fontSize: 12)),
                            value: appState.soundsEnabled,
                            activeThumbColor: AppTheme.accent,
                            onChanged: (val) => appState.setSoundsEnabled(val),
                            contentPadding: EdgeInsets.zero,
                          ),
                          const Divider(color: Color(0x1A94A3B8)),
                          SwitchListTile(
                            title: const Text('Focus Reminders', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: const Text('Enable alerts when a focus mission milestones trigger', style: TextStyle(fontSize: 12)),
                            value: appState.notificationsEnabled,
                            activeThumbColor: AppTheme.accent,
                            onChanged: (val) => appState.setNotificationsEnabled(val),
                            contentPadding: EdgeInsets.zero,
                          ),
                          const Divider(color: Color(0x1A94A3B8)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Default Session Limit', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text('Initial estimation prefilled for new missions', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                  ],
                                ),
                              ),
                              DropdownButton<int>(
                                value: appState.defaultEstimatedDurationMinutes,
                                dropdownColor: AppTheme.surface,
                                underline: const SizedBox(),
                                style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold),
                                items: [15, 30, 45, 60, 90, 120].map((int val) {
                                  return DropdownMenuItem<int>(
                                    value: val,
                                    child: Text('$val mins'),
                                  );
                                }).toList(),
                                onChanged: (int? newVal) {
                                  if (newVal != null) {
                                    appState.setDefaultEstimatedDurationMinutes(newVal);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // About & App Version card
                    _buildSettingsCard(
                      title: "About App",
                      icon: Icons.info_outline,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('App Name', style: TextStyle(fontWeight: FontWeight.w600)),
                              Text('Problem Target Checklist', style: TextStyle(color: AppTheme.textMuted)),
                            ],
                          ),
                          const Divider(color: Color(0x1A94A3B8)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('App Version', style: TextStyle(fontWeight: FontWeight.w600)),
                              Text('1.0.0 (Flutter Desktop & Mobile)', style: TextStyle(color: AppTheme.textMuted)),
                            ],
                          ),
                          const Divider(color: Color(0x1A94A3B8)),
                          const SizedBox(height: 8),
                          const Center(
                            child: Text(
                              'Designed with Premium dark theme UI and smooth animations.',
                              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.2)),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 40, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.accent, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context, AppState appState) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Import Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paste the JSON backup string below:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: '{"targets":[...],"checklist_items":[...]}',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final val = controller.text.trim();
              if (val.isEmpty) return;
              final success = await appState.importBackup(val);
              if (!context.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Backup imported successfully!' : 'Invalid backup code.'),
                  backgroundColor: success ? AppTheme.success : AppTheme.danger,
                ),
              );
            },

            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, CategoryItem? category) {
    final nameController = TextEditingController(text: category?.name ?? '');
    
    // Curated Material Colors for Category selection
    final List<int> colorOptions = [
      0xFF3B82F6, // Blue
      0xFF0284C7, // Cyan
      0xFF10B981, // Emerald Green
      0xFFEF4444, // Red
      0xFFF59E0B, // Amber Orange
      0xFFEC4899, // Pink
      0xFF8B5CF6, // Purple
      0xFF6366F1, // Indigo Blue
      0xFF06B6D4, // Teal Cyan
      0xFF84CC16, // Lime
      0xFF14B8A6, // Teal
      0xFF64748B, // Slate Grey
    ];
    
    int selectedColor = category?.colorValue ?? colorOptions.first;
    final appState = Provider.of<AppState>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          title: Text(category == null ? 'Add Category' : 'Edit Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Category Name',
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Select Category Color', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 10),
                SizedBox(
                  width: 300,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: colorOptions.map((colorVal) {
                      final isSelected = selectedColor == colorVal;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = colorVal),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Color(colorVal),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: Color(colorVal).withValues(alpha: 0.5),
                                  blurRadius: 10,
                                )
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                if (category == null) {
                  await appState.addCategory(name, selectedColor);
                } else {
                  await appState.updateCategory(category.id, name, selectedColor);
                }
                if (!context.mounted) return;
                Navigator.pop(ctx);
              },

              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
