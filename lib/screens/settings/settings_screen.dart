import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/constants.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/health_sync_provider.dart';
import '../../theme/colors.dart';
import '../../widgets/glass_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _urlController;
  late final TextEditingController _topicController;
  bool _isTesting = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: AppConstants.apiBaseUrl);
    _topicController = TextEditingController(text: AppConstants.ntfyTopic);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      api.updateBaseUrl(_urlController.text.trim());
      await api.getDashboard();

      setState(() {
        _testResult = 'Connection successful! ✅';
      });
    } catch (e) {
      setState(() {
        _testResult = 'Connection failed: $e';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _triggerIntervalsSync() async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.triggerIntervalsSync();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Intervals.icu sync triggered!')),
      );
      ref.invalidate(dashboardProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final syncState = ref.watch(healthSyncProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings & Connections',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        children: [
          Text('BACKEND SERVER', style: theme.textTheme.labelSmall),
          const SizedBox(height: 8),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'API Base URL',
                    hintText: 'http://srv1743851.hstgr.cloud:3002/api',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isTesting ? null : _testConnection,
                      icon: _isTesting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.network_check_rounded, size: 16),
                      label: const Text('Test Connection'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceElevated,
                        foregroundColor: AppColors.textPrimary,
                      ),
                      onPressed: _triggerIntervalsSync,
                      icon: const Icon(Icons.cloud_download_rounded, size: 16),
                      label: const Text('Sync Intervals.icu'),
                    ),
                  ],
                ),
                if (_testResult != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _testResult!,
                    style: TextStyle(
                      fontSize: 12,
                      color: _testResult!.contains('successful')
                          ? AppColors.success
                          : AppColors.danger,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('PUSH NOTIFICATIONS (ntfy.sh)', style: theme.textTheme.labelSmall),
          const SizedBox(height: 8),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _topicController,
                  decoration: const InputDecoration(
                    labelText: 'ntfy.sh Topic',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Install the free "ntfy" app from App Store on your iPhone 13, and subscribe to this exact topic to receive Mama\'s 7:30 AM morning sleep review.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('HEALTHKIT SYNC STATUS', style: theme.textTheme.labelSmall),
          const SizedBox(height: 8),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Apple HealthKit Access', style: TextStyle(fontWeight: FontWeight.w600)),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: syncState.isLoading
                          ? null
                          : () => ref.read(healthSyncProvider.notifier).syncNow(),
                      child: Text(syncState.isLoading ? 'Syncing...' : 'Sync Now'),
                    ),
                  ],
                ),
                if (syncState.value != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    syncState.value!,
                    style: const TextStyle(fontSize: 12, color: AppColors.success),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('CIRCADIAN TARGETS', style: theme.textTheme.labelSmall),
          const SizedBox(height: 8),
          const GlassCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Target Bedtime'),
                    Text('12:00 AM (Midnight)', style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                Divider(color: AppColors.border, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Target Sleep Duration'),
                    Text('8.0 Hours', style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                Divider(color: AppColors.border, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Phase Shift Limit'),
                    Text('15 - 30 min / day', style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
