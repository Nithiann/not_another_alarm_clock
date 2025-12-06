import 'package:flutter/material.dart';

import '../../core/services/permission_service.dart';
import '../../core/services/storage_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _pageIndex = 0;
  bool _notificationGranted = false;
  bool _exactAlarmGranted = false;
  bool _overlayGranted = false;
  bool _batteryGranted = false;

  @override
  void initState() {
    super.initState();
    _refreshStatuses();
  }

  Future<void> _refreshStatuses() async {
    final results = await Future.wait([
      PermissionService.hasNotificationPermission(),
      PermissionService.hasExactAlarmPermission(),
      PermissionService.hasOverlayPermission(),
      PermissionService.hasBatteryOptimizationException(),
    ]);
    if (!mounted) return;
    setState(() {
      _notificationGranted = results[0];
      _exactAlarmGranted = results[1];
      _overlayGranted = results[2];
      _batteryGranted = results[3];
    });
  }

  Future<void> _completeOnboarding() async {
    await StorageService.setOnboardingComplete();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _handlePermissionRequest(Future<bool> Function() request) async {
    await request();
    await _refreshStatuses();
  }

  bool get _allCriticalGranted =>
      _notificationGranted &&
      _exactAlarmGranted &&
      _batteryGranted &&
      _overlayGranted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (index) {
                    setState(() => _pageIndex = index);
                  },
                  children: [
                    _OnboardingPage(
                      title: 'Oowh nooo! Not Another Alarm Clock',
                      description:
                          'Yes, you are seeing that right! its a alarm clock but with a twist.'
                          'You can set up alarms and challenges to wake you up.'
                          ' and future mini-games to ensure you wake up on time.',
                      icon: Icons.alarm,
                      color: colorScheme.primaryContainer,
                    ),
                    _OnboardingPage(
                      title: 'Smart wake-up tools',
                      description:
                          '• Math & memory challenges\n (coming soon)\n'
                          '• Radio alarm streams\n'
                          '• Google Drive backups\n (coming soon)\n'
                          '• Vibration & snooze controls',
                      icon: Icons.tips_and_updates_outlined,
                      color: colorScheme.secondaryContainer,
                    ),
                    _buildPermissionPage(colorScheme),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: index == _pageIndex ? 32 : 8,
                    decoration: BoxDecoration(
                      color: index == _pageIndex
                          ? colorScheme.primary
                          : colorScheme.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _pageIndex < 2
                    ? () {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOut,
                        );
                      }
                    : (_allCriticalGranted ? _completeOnboarding : null),
                child: Text(_pageIndex < 2 ? 'Next' : 'Finish'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionPage(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grant essential permissions',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        _PermissionTile(
          title: 'Notifications',
          description: 'Show alarms even when the app is closed.',
          granted: _notificationGranted,
          color: colorScheme.primaryContainer,
          onPressed: () => _handlePermissionRequest(
            PermissionService.requestNotificationPermission,
          ),
        ),
        _PermissionTile(
          title: 'Exact alarms',
          description: 'Allow scheduling precise wake-up times.',
          granted: _exactAlarmGranted,
          color: colorScheme.secondaryContainer,
          onPressed: () => _handlePermissionRequest(
            PermissionService.requestExactAlarmPermission,
          ),
        ),
        _PermissionTile(
          title: 'Draw over other apps',
          description: 'Ensure the alarm UI appears above any screen.',
          granted: _overlayGranted,
          color: colorScheme.tertiaryContainer,
          onPressed: () => _handlePermissionRequest(
            PermissionService.requestOverlayPermission,
          ),
        ),
        _PermissionTile(
          title: 'Battery optimization',
          description: 'Prevent OEM optimizations from delaying alarms.',
          granted: _batteryGranted,
          color: colorScheme.errorContainer,
          onPressed: () => _handlePermissionRequest(
            PermissionService.requestBatteryOptimizationException,
          ),
        ),
        const Spacer(),
        Text(
          'You can revisit these later in Settings > Permissions.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: color,
          child: Icon(icon, size: 48),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.title,
    required this.description,
    required this.granted,
    required this.color,
    required this.onPressed,
  });

  final String title;
  final String description;
  final bool granted;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(description),
                ],
              ),
            ),
            granted
                ? const Icon(Icons.check_circle, color: Colors.green)
                : IconButton(
                    icon: const Icon(Icons.lock_open),
                    onPressed: onPressed,
                  ),
          ],
        ),
      ),
    );
  }
}

