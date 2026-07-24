import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/mission_chain.dart';
import '../providers/app_state.dart';

class ChainCompletionScreen extends StatefulWidget {
  final MissionChain chain;

  const ChainCompletionScreen({
    super.key,
    required this.chain,
  });

  @override
  State<ChainCompletionScreen> createState() => _ChainCompletionScreenState();
}

class _ChainCompletionScreenState extends State<ChainCompletionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Generate 50 confetti particles
    for (int i = 0; i < 50; i++) {
      _particles.add(
        _ConfettiParticle(
          x: _random.nextDouble(),
          y: _random.nextDouble() * -1, // Start above screen
          size: _random.nextDouble() * 8 + 4,
          speed: _random.nextDouble() * 0.4 + 0.2,
          angle: _random.nextDouble() * pi * 2,
          color: [
            const Color(0xFF10B981),
            const Color(0xFF6366F1),
            const Color(0xFFF59E0B),
            const Color(0xFFEF4444),
            const Color(0xFFEC4899),
          ][_random.nextInt(5)],
        ),
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final mins = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final totalDuration = widget.chain.endTime != null && widget.chain.startTime != null
        ? widget.chain.endTime!.difference(widget.chain.startTime!).inSeconds
        : widget.chain.estimatedTotalDurationMinutes * 60;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          // Confetti Particle Painter
          AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ConfettiPainter(
                  particles: _particles,
                  progress: _animController.value,
                ),
              );
            },
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  // Celebration Icon Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accent.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 4,
                          )
                        ],
                      ),
                      child: Icon(Icons.workspace_premium_rounded, color: AppTheme.accent, size: 64),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Center(
                    child: Text(
                      '🎉 PERFECT DAY!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Mission Chain Completed Successfully',
                      style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      widget.chain.name,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accent),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Bonus Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.accent.withValues(alpha: 0.2), AppTheme.surface],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.stars_rounded, color: AppTheme.accent, size: 36),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CHAIN BONUS AWARDED!',
                                style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '+300 Bonus XP • +10 Discipline',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Summary Grid
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        _buildRow('Total Execution Time', _formatDuration(totalDuration), Icons.timer_outlined),
                        const Divider(color: Color(0x1A94A3B8), height: 20),
                        _buildRow('Completed Missions', '${widget.chain.totalMissions} / ${widget.chain.totalMissions}', Icons.done_all_rounded),
                        const Divider(color: Color(0x1A94A3B8), height: 20),
                        _buildRow('Total XP Earned', '+${widget.chain.xpReward} XP', Icons.stars_outlined),
                        const Divider(color: Color(0x1A94A3B8), height: 20),
                        _buildRow('Current Chain Streak', '${widget.chain.currentStreak} Days 🔥', Icons.local_fire_department_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Continue Button
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: const Color(0xFF030712),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      onPressed: () {
                        appState.clearCelebratingChain();
                      },
                      child: const Text(
                        'Claim Rewards & Return',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String val, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accent, size: 20),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
        const Spacer(),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}

class _ConfettiParticle {
  double x;
  double y;
  double size;
  double speed;
  double angle;
  Color color;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.angle,
    required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final posY = (p.y + progress * p.speed * 2) % 1.2 * size.height;
      final posX = p.x * size.width + sin(progress * pi * 4 + p.angle) * 20;

      final paint = Paint()
        ..color = p.color.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(posX, posY), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
