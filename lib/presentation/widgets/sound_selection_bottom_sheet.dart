import 'package:flutter/material.dart';
import '../../core/constants/audio_options.dart';

class SoundSelectionBottomSheet extends StatelessWidget {
  const SoundSelectionBottomSheet({
    super.key,
    required this.selectedSoundId,
    required this.onSoundSelected,
  });

  final String selectedSoundId;
  final ValueChanged<String> onSoundSelected;

  IconData _getSoundIcon(String? icon) {
    switch (icon) {
      case 'phone_android':
        return Icons.phone_android;
      case 'alarm':
        return Icons.alarm;
      case 'sunrise':
        return Icons.wb_sunny_outlined;
      case 'nature':
        return Icons.nature_outlined;
      case 'water':
        return Icons.water_drop_outlined;
      case 'bell':
        return Icons.notifications_outlined;
      case 'bolt':
        return Icons.bolt_outlined;
      case 'spa':
        return Icons.spa_outlined;
      case 'music_note':
        return Icons.music_note;
      default:
        return Icons.volume_up_outlined;
    }
  }

  bool _isSystemSound(String id) {
    return id.startsWith('system://');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Select Alarm Sound',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Sound options grid
          Flexible(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // System Sounds Section
                Text(
                  'System Sounds',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: defaultAlarmToneOptions.where((o) => _isSystemSound(o.id)).length,
                  itemBuilder: (context, index) {
                    final systemOptions = defaultAlarmToneOptions.where((o) => _isSystemSound(o.id)).toList();
                    final option = systemOptions[index];
                    final isSelected = selectedSoundId == option.id;

                    return _SoundOption(
                      option: option,
                      isSelected: isSelected,
                      icon: _getSoundIcon(option.icon),
                      onTap: () {
                        onSoundSelected(option.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Custom Sounds Section
                Text(
                  'Custom Sounds',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: defaultAlarmToneOptions.where((o) => !_isSystemSound(o.id)).length,
                  itemBuilder: (context, index) {
                    final customOptions = defaultAlarmToneOptions.where((o) => !_isSystemSound(o.id)).toList();
                    final option = customOptions[index];
                    final isSelected = selectedSoundId == option.id;

                    return _SoundOption(
                      option: option,
                      isSelected: isSelected,
                      icon: _getSoundIcon(option.icon),
                      onTap: () {
                        onSoundSelected(option.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SoundOption extends StatelessWidget {
  const _SoundOption({
    required this.option,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  final AlarmToneOption option;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: colorScheme.primary.withValues(alpha: 0.2),
        highlightColor: colorScheme.primary.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
            ),
            const SizedBox(height: 8),
            Text(
              option.label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Icon(
                Icons.check_circle,
                size: 16,
                color: colorScheme.primary,
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }
}

