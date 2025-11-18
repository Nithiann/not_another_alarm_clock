import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/audio_options.dart';
import '../../core/services/storage_service.dart';
import '../../data/models/alarm_model.dart';
import '../../data/models/radio_station.dart';
import '../providers/alarm_provider.dart';
import '../providers/radio_station_provider.dart';
import '../widgets/time_picker_widget.dart';
import 'radio_stations_screen.dart';

class AddAlarmScreen extends StatefulWidget {
  const AddAlarmScreen({super.key, this.alarm});

  final AlarmModel? alarm;

  @override
  State<AddAlarmScreen> createState() => _AddAlarmScreenState();
}

class _AddAlarmScreenState extends State<AddAlarmScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _customToneController = TextEditingController();
  static const List<String> _dayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  late TimeOfDay _time;
  late List<int> _repeatDays;
  late bool _vibrate;
  late int _challengeType;
  late int _challengeDifficulty;
  late int _snoozeMinutes;
  late String _audioSource;
  late String _selectedTone;
  String? _selectedRadioStationId;
  bool _useCustomTone = false;
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
    _challengeDifficulty =
        alarm?.challengeDifficulty ?? StorageService.defaultChallengeDifficulty;
    _snoozeMinutes = alarm?.snoozeMinutes ?? StorageService.defaultSnoozeMinutes;
    _audioSource = alarm?.audioSource ?? 'sound';
    _selectedTone = alarm?.alarmTone ?? defaultAlarmToneOptions.first.id;
    _selectedRadioStationId = alarm?.radioStationId;
    final knownTones =
        defaultAlarmToneOptions.map((option) => option.id).toSet();
    if (_audioSource == 'sound' && !knownTones.contains(_selectedTone)) {
      _useCustomTone = true;
      _customToneController.text = _selectedTone;
    }
    _labelController.text = alarm?.label ?? '';
  }

  @override
  void dispose() {
    _labelController.dispose();
    _customToneController.dispose();
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

    final toneName = _audioSource == 'sound'
        ? (_useCustomTone
            ? _customToneController.text.trim()
            : _selectedTone)
        : _selectedTone;

    final alarm = AlarmModel(
      id: widget.alarm?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      scheduledTime: scheduledDate,
      label: _labelController.text.trim().isEmpty
          ? null
          : _labelController.text.trim(),
      repeatDays: List<int>.from(_repeatDays),
      challengeType: _challengeType,
      challengeDifficulty: _challengeDifficulty,
      vibrate: _vibrate,
      snoozeMinutes: _snoozeMinutes,
      isEnabled: true,
      alarmTone: toneName.isEmpty ? 'alarm_sound' : toneName,
      audioSource: _audioSource,
      radioStationId: station?.id,
    );

    final success = widget.alarm == null
        ? await provider.addAlarm(alarm)
        : await provider.updateAlarm(alarm);

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.alarm == null ? 'Alarm created' : 'Alarm updated',
          ),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save alarm')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.alarm != null;
    final radioStations = context.watch<RadioStationProvider>().stations;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Alarm' : 'Add Alarm'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TimePickerField(
              timeOfDay: _time,
              onTap: _pickTime,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'Morning workout, Work, etc.',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            Text(
              'Repeat on',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (index) {
                final selected = _repeatDays.contains(index);
                return FilterChip(
                  label: Text(_dayNames[index]),
                  selected: selected,
                  onSelected: (_) => _toggleDay(index),
                );
              }),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: DropdownMenu<int>(
                initialSelection: _challengeType,
                label: const Text('Wake-up challenge'),
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: 0, label: 'Math challenge'),
                  DropdownMenuEntry(value: 1, label: 'Memory code'),
                  DropdownMenuEntry(
                    value: 2,
                    label: 'Mini game (coming soon)',
                  ),
                ],
                onSelected: (value) {
                  if (value == null) return;
                  setState(() => _challengeType = value);
                  StorageService.setDefaultChallengeType(value);
                },
              ),
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Challenge difficulty',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Slider(
                  value: _challengeDifficulty.toDouble(),
                  divisions: 2,
                  min: 1,
                  max: 3,
                  label: ['Easy', 'Medium', 'Hard'][_challengeDifficulty - 1],
                  onChanged: (value) {
                    setState(() => _challengeDifficulty = value.round());
                    StorageService.setDefaultChallengeDifficulty(
                      value.round(),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Alarm audio',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'sound',
                  label: Text('Sound'),
                  icon: Icon(Icons.music_note_outlined),
                ),
                ButtonSegment(
                  value: 'radio',
                  label: Text('Radio'),
                  icon: Icon(Icons.radio_outlined),
                ),
              ],
              selected: {_audioSource},
              onSelectionChanged: (selection) {
                setState(() => _audioSource = selection.first);
              },
            ),
            const SizedBox(height: 16),
            if (_audioSource == 'sound') ...[
              DropdownMenu<String>(
                initialSelection: _useCustomTone ? '__custom__' : _selectedTone,
                label: const Text('Built-in tone'),
                dropdownMenuEntries: [
                  for (final option in defaultAlarmToneOptions)
                    DropdownMenuEntry(
                      value: option.id,
                      label: option.label,
                    ),
                  const DropdownMenuEntry(
                    value: '__custom__',
                    label: 'Custom resource…',
                  ),
                ],
                onSelected: (value) {
                  if (value == null) return;
                  setState(() {
                    if (value == '__custom__') {
                      _useCustomTone = true;
                    } else {
                      _useCustomTone = false;
                      _selectedTone = value;
                    }
                  });
                },
              ),
              if (_useCustomTone) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _customToneController,
                  decoration: const InputDecoration(
                    labelText: 'Android raw resource name',
                    hintText: 'alarm_sound',
                  ),
                  validator: (value) {
                    if (_audioSource == 'sound' &&
                        _useCustomTone &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Provide the resource name';
                    }
                    return null;
                  },
                ),
              ],
            ] else ...[
              DropdownMenu<String>(
                initialSelection: _selectedRadioStationId,
                label: const Text('Radio station'),
                dropdownMenuEntries: radioStations
                    .map(
                      (station) => DropdownMenuEntry(
                        value: station.id,
                        label: station.name,
                      ),
                    )
                    .toList(),
                onSelected: (value) {
                  setState(() => _selectedRadioStationId = value);
                },
              ),
              if (radioStations.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Add stations to enable radio alarms.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RadioStationsScreen(),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Manage stations'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SwitchListTile(
              value: _vibrate,
              onChanged: (value) {
                setState(() => _vibrate = value);
                StorageService.setDefaultVibration(value);
              },
              title: const Text('Vibrate'),
              subtitle: const Text('Recommended for heavy sleepers'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Snooze (minutes)'),
              subtitle: Slider(
                value: _snoozeMinutes.toDouble(),
                min: 3,
                max: 15,
                divisions: 12,
                label: '$_snoozeMinutes min',
                onChanged: (value) {
                  setState(() => _snoozeMinutes = value.round());
                  StorageService.setDefaultSnoozeMinutes(_snoozeMinutes);
                },
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveAlarm,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.alarm),
              label: Text(isEditing ? 'Update alarm' : 'Create alarm'),
            ),
          ],
        ),
      ),
    );
  }
}

