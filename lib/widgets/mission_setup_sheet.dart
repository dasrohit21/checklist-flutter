import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/target_item.dart';
import '../models/mission.dart';
import '../providers/app_state.dart';

class MissionSetupSheet extends StatefulWidget {
  final TargetItem target;

  const MissionSetupSheet({super.key, required this.target});

  @override
  State<MissionSetupSheet> createState() => _MissionSetupSheetState();
}

class _MissionSetupSheetState extends State<MissionSetupSheet> {
  late final TextEditingController _nameController;
  int _estimatedDurationMinutes = 60;
  MissionType _selectedType = MissionType.normal;

  final List<int> _durations = [15, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Mission: ${widget.target.title}');
    final appState = Provider.of<AppState>(context, listen: false);
    _estimatedDurationMinutes = appState.defaultEstimatedDurationMinutes;
  }


  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return Container(

      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header
            Row(
              children: [
                Icon(Icons.rocket_launch, color: AppTheme.accent, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Launch Mission',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Name input
            Text(
              'Mission Name',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Enter mission name...',
                prefixIcon: Icon(Icons.title_rounded, size: 20),
              ),
              style: TextStyle(color: AppTheme.text),
            ),
            const SizedBox(height: 18),

            // Target Count Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Target Goal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceStrong.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    '${widget.target.targetCount} problems',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Duration selector
            Text(
              'Estimated Duration',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _durations.map((d) {
                final isSelected = _estimatedDurationMinutes == d;
                return ChoiceChip(
                  label: Text('$d mins'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _estimatedDurationMinutes = d);
                    }
                  },
                  backgroundColor: AppTheme.surfaceStrong.withValues(alpha: 0.3),
                  selectedColor: AppTheme.accent.withValues(alpha: 0.2),
                  side: BorderSide(
                    color: isSelected ? AppTheme.accent : AppTheme.border.withValues(alpha: 0.15),
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.accent : AppTheme.text,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Mission Type selector
            Text(
              'Mission Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            _buildTypeCard(
              type: MissionType.normal,
              title: 'Normal Mode',
              description: 'Solve target problems at your own pace without ticking limits.',
              icon: Icons.shield_outlined,
              activeColor: AppTheme.success,
            ),
            const SizedBox(height: 10),
            _buildTypeCard(
              type: MissionType.strict,
              title: 'Strict Mode',
              description: 'Focus challenge. Stays active behind the scenes if the app closes.',
              icon: Icons.lock_outline,
              activeColor: AppTheme.warning,
            ),
            const SizedBox(height: 10),
            _buildTypeCard(
              type: MissionType.ultimate,
              title: 'Ultimate Mode',
              description: 'High intensity timed challenge. Maximize output under focus pressure.',
              icon: Icons.bolt,
              activeColor: AppTheme.danger,
            ),
            const SizedBox(height: 24),

            // Start Button
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
                  await appState.startMission(
                    widget.target.id,
                    _nameController.text,
                    _estimatedDurationMinutes,
                    _selectedType,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },

                child: const Text(
                  'Start Challenge',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard({
    required MissionType type,
    required String title,
    required String description,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.08)
              : AppTheme.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : AppTheme.border.withValues(alpha: 0.15),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withValues(alpha: 0.12) : AppTheme.surfaceStrong,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? activeColor : AppTheme.textMuted, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? activeColor : AppTheme.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
