import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/audio_options.dart';
import '../../core/services/storage_service.dart';
import '../../data/models/alarm_model.dart';
import '../../data/models/radio_station.dart';
import '../providers/alarm_provider.dart';
import '../providers/radio_station_provider.dart';
import 'challenge_selection_bottom_sheet.dart';
import 'sound_selection_bottom_sheet.dart';
import 'radio_station_selection_bottom_sheet.dart';

class AddAlarmBottomSheet extends StatefulWidget {
  const AddAlarmBottomSheet({super.key, this.alarm});

  final AlarmModel? alarm;

  @override
  State<AddAlarmBottomSheet> createState() => _AddAlarmBottomSheetState();
}

class _AddAlarmBottomSheetState extends State<AddAlarmBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _labelController = TextEditingController();
  static const List<String> _dayNames = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  late TimeOfDay _time;
  late List<int> _repeatDays;
  late bool _vibrate;
  late int _challengeType;
  late int _snoozeMinutes;
  late String _audioSource;
  late String _selectedTone;
  String? _selectedRadioStationId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final alarm = widget.alarm;
    _time = alarm != null
        ? TimeOfDay.fromDateTime(alarm.scheduledTime)
        : TimeOfDay.fromDateTime(
            DateTime.now().add(const Duration(minutes: 5)),
          );
    _repeatDays = alarm?.repeatDays ?? <int>[];
    _vibrate = alarm?.vibrate ?? StorageService.defaultVibration;
    _challengeType = alarm?.challengeType ?? StorageService.defaultChallengeType;
    _snoozeMinutes = alarm?.snoozeMinutes ?? StorageService.defaultSnoozeMinutes;
    _audioSource = alarm?.audioSource ?? 'sound';
    _selectedTone = alarm?.alarmTone ?? defaultAlarmToneOptions.first.id;
    _selectedRadioStationId = alarm?.radioStationId;
    _labelController.text = alarm?.label ?? '';
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final newTime = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (newTime != null) {
      setState(() => _time = newTime);
    }
  }

  

  void _toggleDay(int dayIndex) {
    setState(() {
      if (_repeatDays.contains(dayIndex)) {
        _repeatDays.remove(dayIndex);
      } else {
        _repeatDays.add(dayIndex);
      }
    });
  }

  void _selectChallenge() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      clipBehavior: Clip.antiAlias,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      enableDrag: true,
      builder: (context) => ChallengeSelectionBottomSheet(
        selectedChallenge: _challengeType == -1 ? -1 : _challengeType,
        onChallengeSelected: (challengeType) {
          setState(() => _challengeType = challengeType == -1 ? -1 : challengeType);
        },
      ),
    );
  }

  void _selectSound() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      clipBehavior: Clip.antiAlias,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      enableDrag: true,
      builder: (context) => SoundSelectionBottomSheet(
        selectedSoundId: _selectedTone,
        onSoundSelected: (soundId) {
          setState(() => _selectedTone = soundId);
        },
      ),
    );
  }

  void _selectRadioStation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      clipBehavior: Clip.antiAlias,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      enableDrag: true,
      builder: (context) => RadioStationSelectionBottomSheet(
        selectedStationId: _selectedRadioStationId,
        onStationSelected: (stationId) {
          setState(() => _selectedRadioStationId = stationId);
        },
      ),
    );
  }

  Future<void> _saveAlarm() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AlarmProvider>();
    final radioProvider = context.read<RadioStationProvider>();
    RadioStation? station;
    if (_audioSource == 'radio') {
      station = radioProvider.getById(_selectedRadioStationId);
      if (station == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a radio station first.')),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    final now = DateTime.now();
    final scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      _time.hour,
      _time.minute,
    );

    final alarm = AlarmModel(
      id: widget.alarm?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      scheduledTime: scheduledDate,
      label: _labelController.text.trim().isEmpty
          ? null
          : _labelController.text.trim(),
      repeatDays: List<int>.from(_repeatDays),
      challengeType: _challengeType,
      challengeDifficulty: 1, // Default difficulty
      vibrate: _vibrate,
      snoozeMinutes: _snoozeMinutes,
      isEnabled: true,
      alarmTone: _selectedTone.isEmpty ? 'alarm_sound' : _selectedTone,
      audioSource: _audioSource,
      radioStationId: station?.id,
    );

    final success = widget.alarm == null
        ? await provider.addAlarm(alarm)
        : await provider.updateAlarm(alarm);

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.alarm == null ? 'Alarm created' : 'Alarm updated',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save alarm')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEditing = widget.alarm != null;
    final radioStations = context.watch<RadioStationProvider>().stations;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        isEditing ? 'Edit Alarm' : 'New Alarm',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _isSaving ? null : _saveAlarm,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                        // Swipe up hint - draggable area
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16, top: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Swipe up for more options',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_up,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Time - centered
                        Center(
                          child: GestureDetector(
                            onTap: _pickTime,
                            child: Text(
                              '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Label
                      Row(
                        children: [
                          Icon(
                            Icons.label_outline,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _labelController,
                              decoration: const InputDecoration(
                                labelText: 'Alarm name',
                                hintText: 'Wake up',
                                border: UnderlineInputBorder(),
                              ),
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Repeat
                      Text(
                        'Repeat',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(7, (index) {
                          final selected = _repeatDays.contains(index);
                          return GestureDetector(
                            onTap: () => _toggleDay(index),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: selected
                                      ? colorScheme.primary
                                      : colorScheme.outline,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _dayNames[index],
                                  style: TextStyle(
                                    color: selected
                                        ? colorScheme.onPrimary
                                        : colorScheme.onSurface,
                                    fontWeight: selected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                      // Snooze minutes
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Snooze minutes',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            value: _snoozeMinutes.toDouble(),
                            min: 1,
                            max: 20,
                            divisions: 59,
                            label: '$_snoozeMinutes minutes',
                            onChanged: (value) {
                              setState(() => _snoozeMinutes = value.round());
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Sound options
                      Text(
                        'Sound',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _SoundOptionButton(
                              icon: Icons.music_note,
                              label: 'Alarm Sound',
                              isSelected: _audioSource == 'sound',
                              onTap: () => setState(() => _audioSource = 'sound'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SoundOptionButton(
                              icon: Icons.radio,
                              label: 'Radio Station',
                              isSelected: _audioSource == 'radio',
                              onTap: () => setState(() => _audioSource = 'radio'),
                            ),
                          ),
                        ],
                      ),
                      if (_audioSource == 'sound') ...[
                        const SizedBox(height: 16),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _selectSound,
                            borderRadius: BorderRadius.circular(16),
                            splashColor: colorScheme.primary.withValues(alpha: 0.2),
                            highlightColor: colorScheme.primary.withValues(alpha: 0.1),
                            child: Card(
                              color: colorScheme.primaryContainer,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colorScheme.primary.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.music_note,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Alarm Sound',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          defaultAlarmToneOptions
                                              .firstWhere(
                                                (option) => option.id == _selectedTone,
                                                orElse: () => defaultAlarmToneOptions.first,
                                              )
                                              .label,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.chevron_right,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ),
                      ] else ...[
                        const SizedBox(height: 16),
                        // Radio station
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _selectRadioStation,
                            borderRadius: BorderRadius.circular(16),
                            splashColor: colorScheme.primary.withValues(alpha: 0.2),
                            highlightColor: colorScheme.primary.withValues(alpha: 0.1),
                            child: Card(
                              color: colorScheme.primaryContainer,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colorScheme.primary.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.radio,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Radio Station',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _selectedRadioStationId != null
                                              ? (radioStations
                                                  .firstWhere(
                                                    (station) => station.id == _selectedRadioStationId,
                                                    orElse: () => radioStations.first,
                                                  )
                                                  .name)
                                              : 'Select a station',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.chevron_right,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      // Challenge
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _selectChallenge,
                          borderRadius: BorderRadius.circular(16),
                          splashColor: colorScheme.primary.withValues(alpha: 0.2),
                          highlightColor: colorScheme.primary.withValues(alpha: 0.1),
                          child: Card(
                            color: colorScheme.primaryContainer,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colorScheme.primary.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                            child: Row(
                              children: [
                                Icon(
                                  _getChallengeIcon(_challengeType),
                                  color: colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Challenge',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _getChallengeName(_challengeType),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.chevron_right,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ],
                            ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getChallengeName(int type) {
    switch (type) {
      case 0:
        return 'Math';
      case 1:
        return 'Memory';
      case 2:
        return 'Shake';
      case 3:
        return 'Barcode';
      default:
        return 'None';
    }
  }

  IconData _getChallengeIcon(int type) {
    switch (type) {
      case 0:
        return Icons.calculate_outlined;
      case 1:
        return Icons.psychology_outlined;
      case 2:
        return Icons.vibration;
      case 3:
        return Icons.qr_code_scanner_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }
}

class _SoundOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SoundOptionButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

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
            ),
          ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

