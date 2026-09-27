import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sleep_enforcement_provider.dart';
import '../theme/colors.dart';
import '../utils/time_formatter.dart';

class SleepCurtainOverlay extends ConsumerWidget {
  const SleepCurtainOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sleepEnforcementProvider);
    if (!state.shouldBlockApp) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cutoffDisplay = TimeFormatter.formatTime(state.activeCutoff ?? '00:45');
    final wakeDisplay = TimeFormatter.formatTime(state.targetWake ?? '07:30');

    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.2,
              colors: [
                Color(0xFF131A33),
                Color(0xFF090D1A),
                Color(0xFF04060C),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Status Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_moon_rounded, size: 14, color: AppColors.warning),
                            SizedBox(width: 6),
                            Text(
                              'CIRCADIAN SLEEP ENFORCEMENT',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (state.isPreviewing)
                        IconButton(
                          tooltip: 'Close Preview',
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          onPressed: () => ref.read(sleepEnforcementProvider.notifier).closePreview(),
                        ),
                    ],
                  ),

                  // Center Hero Card & Icon
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pulsing Moon Container
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.15),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 36,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.bedtime_rounded,
                          size: 54,
                          color: AppColors.momWarm,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Time to Sleep.',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Put your phone down. Your circadian ceiling has been reached.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Cutoff Window Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141A2D).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.4), width: 1.2),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'LATEST PERMISSIBLE SLEEP CUTOFF',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cutoffDisplay,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.wb_sunny_rounded, size: 14, color: AppColors.momWarm),
                                const SizedBox(width: 6),
                                Text(
                                  'Target Wake: $wakeDisplay (8.0h restorative sleep)',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Science Callout
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🧠', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Staying awake past your cutoff prevents your core temperature from dipping, suppressing slow-wave Deep Sleep and creating acute sleep debt.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Bottom Action Buttons (Dismissable & Noticeable)
                  Column(
                    children: [
                      // Primary Button: Go to sleep
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 4,
                          ),
                          onPressed: () {
                            ref.read(sleepEnforcementProvider.notifier).dismissForNight();
                          },
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                          label: const Text(
                            'I\'m Going to Sleep Now (Lock Screen)',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Secondary Button: Snooze 15 minutes
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            ref.read(sleepEnforcementProvider.notifier).snooze15Minutes();
                          },
                          icon: const Icon(Icons.snooze_rounded, size: 18),
                          label: const Text(
                            'Snooze 15 Minutes (Emergency)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
