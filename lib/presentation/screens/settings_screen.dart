import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/google_drive_service.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/storage_service.dart';
import '../providers/alarm_provider.dart';
import '../providers/theme_provider.dart';
import 'radio_stations_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isBackingUp = false;
  bool _isRestoring = false;
  bool _overlayGranted = false;
  bool _batteryGranted = false;
  bool _gradualVolumeEnabled = false;
  int _gradualMinutes = 2;
  double _maxVolume = 1.0;

  @override
  void initState() {
    super.initState();
    _gradualVolumeEnabled = StorageService.gradualVolumeEnabled;
    _gradualMinutes = StorageService.gradualVolumeMinutes;
    _maxVolume = StorageService.maxAlarmVolume;
    _refreshPermissions();
  }

  Future<void> _refreshPermissions() async {
    final results = await Future.wait([
      PermissionService.hasOverlayPermission(),
      PermissionService.hasBatteryOptimizationException(),
    ]);
    if (!mounted) return;
    setState(() {
      _overlayGranted = results[0];
      _batteryGranted = results[1];
    });
  }

  Future<void> _backupToDrive() async {
    final alarms = context.read<AlarmProvider>().exportAlarms();
    setState(() => _isBackingUp = true);

    try {
      final fileId =
          await GoogleDriveService.instance.backupAlarms(alarms);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fileId.isEmpty
                ? 'Backup created'
                : 'Backup uploaded (file id: $fileId)',
          ),
        ),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isBackingUp = false);
      }
    }
  }

  Future<void> _restoreFromDrive() async {
    final alarmProvider = context.read<AlarmProvider>();
    setState(() => _isRestoring = true);
    try {
      final alarms =
          await GoogleDriveService.instance.restoreLatestBackup();
      await alarmProvider.importAlarms(alarms);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup restored')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  Future<void> _requestOverlayPermission() async {
    await PermissionService.requestOverlayPermission();
    await _refreshPermissions();
  }

  Future<void> _requestBatteryPermission() async {
    await PermissionService.requestBatteryOptimizationException();
    await _refreshPermissions();
  }

  void _openRadioStations() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RadioStationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final themeMode = themeProvider.themeMode;
    final lastBackup = StorageService.lastBackupTime;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance section
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.smartphone),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.wb_sunny_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.nightlight_round),
                      ),
                    ],
                    selected: <ThemeMode>{themeMode},
                    onSelectionChanged: (selection) {
                      final mode =
                          selection.isEmpty ? ThemeMode.system : selection.first;
                      themeProvider.setThemeMode(mode);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Radio stations
          Text(
            'Audio',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Radio stations'),
              subtitle: const Text('Manage internet streams used for radio alarms'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _openRadioStations,
            ),
          ),
          const SizedBox(height: 12),
          _buildAudioTile(),
          const SizedBox(height: 24),
          // Permissions
          Text(
            'Permissions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildPermissionsTile(),
          const SizedBox(height: 24),
          // Backups
          Text(
            'Backup & Restore',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildBackupsTile(lastBackup),
          const SizedBox(height: 24),
          // About
          Text(
            'About',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildAboutTile(),
        ],
      ),
    );
  }

  Widget _buildBackupsTile(DateTime? lastBackup) {
    return Card(
      child: ExpansionTile(
        title: const Text('Backups'),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Google Drive backup'),
            subtitle: Text(
              lastBackup == null
                  ? 'No backup yet'
                  : 'Last backup ${lastBackup.toLocal()}',
            ),
            trailing: _isBackingUp
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.cloud_upload_outlined),
                    onPressed: _backupToDrive,
                  ),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Restore latest backup'),
            subtitle: Text(
              StorageService.lastBackupFileId == null
                  ? 'Restores most recent Drive file'
                  : 'Preferred file: ${StorageService.lastBackupFileId}',
            ),
            trailing: _isRestoring
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.restore_outlined),
                    onPressed: _restoreFromDrive,
                  ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPermissionsTile() {
    return Card(
      child: ExpansionTile(
        title: const Text('Permissions'),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          SwitchListTile(
            value: _overlayGranted,
            onChanged: (_) => _requestOverlayPermission(),
            title: const Text('Draw over other apps'),
            subtitle: const Text('Needed to display alarms on top.'),
          ),
          SwitchListTile(
            value: _batteryGranted,
            onChanged: (_) => _requestBatteryPermission(),
            title: const Text('Ignore battery optimizations'),
            subtitle: const Text('Prevents OEMs from delaying alarms.'),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioTile() {
    return Card(
      child: ExpansionTile(
        title: const Text('Audio'),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _gradualVolumeEnabled,
            title: const Text('Gradually increase volume'),
            subtitle: const Text('Start softly and ramp up'),
            onChanged: (value) async {
              setState(() => _gradualVolumeEnabled = value);
              await StorageService.setGradualVolumeEnabled(value);
            },
          ),
          if (_gradualVolumeEnabled)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Increase over $_gradualMinutes minute(s)'),
                Slider(
                  value: _gradualMinutes.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '$_gradualMinutes min',
                  onChanged: (value) {
                    setState(() => _gradualMinutes = value.round());
                  },
                  onChangeEnd: (value) =>
                      StorageService.setGradualVolumeMinutes(value.round()),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Text('Maximum volume ${(_maxVolume * 100).round()}%'),
          Slider(
            value: _maxVolume,
            min: 0.2,
            max: 1.0,
            divisions: 8,
            label: '${(_maxVolume * 100).round()}%',
            onChanged: (value) {
              setState(() => _maxVolume = value);
            },
            onChangeEnd: (value) => StorageService.setMaxAlarmVolume(value),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTile() {
    return Card(
      child: ExpansionTile(
        title: const Text('About'),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Version'),
            subtitle: const Text('0.0.1'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Developer'),
            subtitle: const Text('Nithiann'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Privacy policy'),
            subtitle: const Text('https://www.google.com'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Terms of service'),
            subtitle: const Text('https://www.google.com'),
          ),
        ],
      )
    );
  }
}

