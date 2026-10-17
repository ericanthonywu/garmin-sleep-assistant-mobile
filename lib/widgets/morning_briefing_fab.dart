import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/dashboard_data.dart';
import '../providers/dashboard_provider.dart';
import '../providers/health_sync_provider.dart';
import '../theme/colors.dart';
import '../utils/time_formatter.dart';
import 'shimmer_loading.dart';

/// Custom FloatingActionButtonLocation that positions the FAB above the
/// bottom navigation bar, and dynamically adjusts when on the Assistant (chat)
/// screen to hover cleanly above the message text input bar.
class MorningBriefingFabLocation extends FloatingActionButtonLocation {
  final int currentTabIndex;

  const MorningBriefingFabLocation(this.currentTabIndex);

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabWidth = scaffoldGeometry.floatingActionButtonSize.width;
    final double fabHeight = scaffoldGeometry.floatingActionButtonSize.height;
    final double screenWidth = scaffoldGeometry.scaffoldSize.width;

    // 16px margin from the right edge
    final double fabX = screenWidth - fabWidth - 16.0;

    // When on Assistant tab (tab index 2), offset higher to stay above the chat input bar
    final double bottomMargin = (currentTabIndex == 2) ? 76.0 : 16.0;
    final double fabY = scaffoldGeometry.contentBottom - fabHeight - bottomMargin;

    return Offset(fabX, fabY);
  }
}

/// Floating Action Button for the Morning Briefing that stays accessible
/// everywhere across all main app tabs.
class MorningBriefingFab extends ConsumerWidget {
  final int currentTabIndex;

  const MorningBriefingFab({
    super.key,
    required this.currentTabIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hide FAB when soft keyboard is up (e.g. typing in chat)
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    if (isKeyboardOpen) {
      return const SizedBox.shrink();
    }

    final dashboardAsync = ref.watch(dashboardProvider);
    final data = dashboardAsync.asData?.value;

    final emojis = {
      'good': '☀️',
      'okay': '🌤️',
      'bad': '😤',
      'terrible': '🚨',
    };
    final emoji = emojis[data?.morningVerdict] ?? '☀️';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.momWarm.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        heroTag: 'morning_briefing_fab',
        elevation: 3,
        highlightElevation: 5,
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: AppColors.momBorder, width: 1.4),
        ),
        onPressed: () => showMorningBriefingSheet(context, ref),
        icon: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.momCard,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.momBorder, width: 1),
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Morning Briefing',
              style: TextStyle(
                color: AppColors.momWarm,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
            if (data?.morningVerdict != null) ...[
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.verdictColor(data?.morningVerdict),
                ),
              ),
            ],
          ],
        ),
        tooltip: 'Morning Briefing',
      ),
    );
  }
}

/// Displays the Morning Briefing in a rich modal bottom sheet.
void showMorningBriefingSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _MorningBriefingSheetContent(),
  );
}

class _MorningBriefingSheetContent extends ConsumerWidget {
  const _MorningBriefingSheetContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final theme = Theme.of(context);
    final selectedDate = ref.watch(selectedDateProvider);

    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(selectedDate);
    } catch (_) {
      parsedDate = DateTime.now();
    }
    final formattedDate = DateFormat('EEEE, MMMM d').format(parsedDate);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.momBorder, width: 1.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle pill
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 6),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Top Header: Title, Date, Verdict badge & Close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.momCard,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.momBorder, width: 1.2),
                    ),
                    alignment: Alignment.center,
                    child: dashboardAsync.maybeWhen(
                      data: (data) {
                        final emojis = {
                          'good': '☀️',
                          'okay': '🌤️',
                          'bad': '😤',
                          'terrible': '🚨',
                        };
                        return Text(
                          emojis[data.morningVerdict] ?? '☀️',
                          style: const TextStyle(fontSize: 20),
                        );
                      },
                      orElse: () => const Icon(
                        Icons.wb_sunny_rounded,
                        color: AppColors.momWarm,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Morning Briefing',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.momWarm,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(width: 8),
                            dashboardAsync.maybeWhen(
                              data: (data) => data.morningVerdict != null
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.verdictColor(
                                                data.morningVerdict)
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.verdictColor(
                                                  data.morningVerdict)
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Text(
                                        data.morningVerdict!.toUpperCase(),
                                        style: TextStyle(
                                          color: AppColors.verdictColor(
                                              data.morningVerdict),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                              orElse: () => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                        Text(
                          formattedDate,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(color: AppColors.border, height: 1),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: dashboardAsync.when(
                  loading: () => const Column(
                    children: [
                      ShimmerLoading(width: double.infinity, height: 60),
                      SizedBox(height: 16),
                      ShimmerLoading(width: double.infinity, height: 120),
                    ],
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.danger, size: 36),
                        const SizedBox(height: 8),
                        Text('Unable to load briefing',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          err.toString(),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => ref.invalidate(dashboardProvider),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (data) => _buildDataView(context, ref, data, theme),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataView(
    BuildContext context,
    WidgetRef ref,
    DashboardData data,
    ThemeData theme,
  ) {
    final note = data.morningNote;
    final sleepSecs =
        data.sleepSecs ?? (data.sleepHours != null ? data.sleepHours! * 3600 : null);
    final sleepDurationStr =
        sleepSecs != null ? TimeFormatter.formatDurationSecs(sleepSecs) : '--';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Quick Morning Metrics Bar
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                icon: Icons.bedtime_rounded,
                label: 'SLEEP',
                value: sleepDurationStr,
                color: AppColors.sleepLight,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.stars_rounded,
                label: 'SCORE',
                value: data.sleepScore != null ? '${data.sleepScore}' : '--',
                color: AppColors.sleepScoreColor(data.sleepScore),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.favorite_rounded,
                label: 'RESTING HR',
                value: data.restingHR != null ? '${data.restingHR} bpm' : '--',
                color: AppColors.danger,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.medication_rounded,
                label: 'MAGNESIUM',
                value: data.magnesium?.taken == true ? 'Taken ✓' : 'None',
                color: data.magnesium?.taken == true ? AppColors.success : AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // AI Morning Note Container
        if (note != null && note.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.momCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.momBorder, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        size: 16, color: AppColors.momWarm),
                    const SizedBox(width: 6),
                    Text(
                      'AI Sleep & Recovery Analysis',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.momWarm,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  note,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.5,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Button: Ask Assistant
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.momCard,
              foregroundColor: AppColors.momWarm,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.momBorder, width: 1.2),
              ),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/chat');
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: const Text(
              'Discuss with Assistant',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ] else ...[
          // Empty State
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              children: [
                const Icon(Icons.wb_twilight_rounded,
                    size: 40, color: AppColors.textTertiary),
                const SizedBox(height: 12),
                Text(
                  'No Morning Briefing Yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your daily analysis generates once last night\'s Garmin sleep data is synchronized.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, _) {
                    final syncState = ref.watch(healthSyncProvider);
                    return OutlinedButton.icon(
                      onPressed: syncState.isLoading
                          ? null
                          : () async {
                              await ref
                                  .read(healthSyncProvider.notifier)
                                  .syncNow();
                              ref.invalidate(dashboardProvider);
                            },
                      icon: syncState.isLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(Icons.sync_rounded, size: 16),
                      label: Text(
                        syncState.isLoading ? 'Syncing...' : 'Sync HealthKit Now',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
