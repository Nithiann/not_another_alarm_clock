import 'package:flutter/material.dart';
import '../../data/models/alarm_model.dart';

class AlarmCard extends StatelessWidget {
  final AlarmModel alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: alarm.isEnabled ? 2 : 0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(12),
          splashColor: colorScheme.primary.withValues(alpha: 0.2),
          highlightColor: colorScheme.primary.withValues(alpha: 0.1),
          child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alarm.formattedTime,
                          style: textTheme.displaySmall?.copyWith(
                            color: alarm.isEnabled
                                ? colorScheme.onSurface
                                : colorScheme.onSurface.withValues(alpha: 0.4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (alarm.label != null && alarm.label!.isNotEmpty)
                          Text(
                            alarm.label!,
                            style: textTheme.titleMedium?.copyWith(
                              color: alarm.isEnabled
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          alarm.repeatDaysString,
                          style: textTheme.bodySmall?.copyWith(
                            color: alarm.isEnabled
                                ? colorScheme.onSurface.withValues(alpha: 0.7)
                                : colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(value: alarm.isEnabled, onChanged: onToggle),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: _getChallengeIcon(alarm.challengeType),
                    label: _getChallengeName(alarm.challengeType),
                    isEnabled: alarm.isEnabled,
                  ),
                  _InfoChip(
                    icon: alarm.usesRadio
                        ? Icons.radio_outlined
                        : Icons.music_note_outlined,
                    label: alarm.usesRadio 
                        ? (_stationName(alarm) ?? 'Radio')
                        : _getSoundName(alarm),
                    isEnabled: alarm.isEnabled,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Next: ${_getNextAlarmText(alarm)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: alarm.isEnabled
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                    color: colorScheme.error,
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  String? _stationName(AlarmModel alarm) {
    // This would need to be passed from the parent or looked up
    return null;
  }

  String _getSoundName(AlarmModel alarm) {
    // Return a friendly name for the sound
    if (alarm.alarmTone.contains('gentle')) {
      return 'Gentle Wake';
    } else if (alarm.alarmTone.contains('morning')) {
      return 'Morning Breeze';
    } else if (alarm.alarmTone.contains('peaceful')) {
      return 'Peaceful Rise';
    }
    return 'Alarm Sound';
  }

  IconData _getChallengeIcon(int type) {
    switch (type) {
      case 0:
        return Icons.calculate_outlined;
      case 1:
        return Icons.psychology_outlined;
      case 2:
        return Icons.games_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _getChallengeName(int type) {
    switch (type) {
      case 0:
        return 'Math';
      case 1:
        return 'Memory';
      case 2:
        return 'Game';
      default:
        return 'Challenge';
    }
  }

  String _getNextAlarmText(AlarmModel alarm) {
    if (!alarm.isEnabled) return 'Disabled';

    final nextAlarm = alarm.getNextAlarmTime();
    final now = DateTime.now();
    final difference = nextAlarm.difference(now);

    if (difference.inMinutes < 60) {
      return 'in ${difference.inMinutes} minutes';
    } else if (difference.inHours < 24) {
      return 'in ${difference.inHours} hours';
    } else {
      final days = difference.inDays;
      return 'in $days day${days > 1 ? 's' : ''}';
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isEnabled;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isEnabled
            ? colorScheme.secondaryContainer
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isEnabled
                ? colorScheme.onSecondaryContainer
                : colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isEnabled
                  ? colorScheme.onSecondaryContainer
                  : colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
