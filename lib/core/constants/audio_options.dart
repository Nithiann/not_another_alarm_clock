class AlarmToneOption {
  const AlarmToneOption({required this.id, required this.label});

  final String id;
  final String label;
}

const defaultAlarmToneOptions = [
  AlarmToneOption(id: 'alarm_sound', label: 'Classic (alarm_sound)'),
  AlarmToneOption(id: 'gentle_alarm', label: 'Gentle (add to res/raw)'),
];

