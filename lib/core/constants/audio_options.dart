class AlarmToneOption {
  const AlarmToneOption({
    required this.id,
    required this.label,
    this.icon,
  });

  final String id;
  final String label;
  final String? icon; // Optional icon identifier
}

const defaultAlarmToneOptions = [
  // Android System Sounds
  AlarmToneOption(
    id: 'system://default',
    label: 'System Default',
    icon: 'phone_android',
  ),
  AlarmToneOption(
    id: 'system://alarm_1',
    label: 'System Alarm 1',
    icon: 'phone_android',
  ),
  AlarmToneOption(
    id: 'system://alarm_2',
    label: 'System Alarm 2',
    icon: 'phone_android',
  ),
  AlarmToneOption(
    id: 'system://alarm_3',
    label: 'System Alarm 3',
    icon: 'phone_android',
  ),
  AlarmToneOption(
    id: 'system://alarm_4',
    label: 'System Alarm 4',
    icon: 'phone_android',
  ),
  AlarmToneOption(
    id: 'system://alarm_5',
    label: 'System Alarm 5',
    icon: 'phone_android',
  ),
  AlarmToneOption(
    id: 'system://alarm_6',
    label: 'System Alarm 6',
    icon: 'phone_android',
  ),
  AlarmToneOption(
    id: 'system://alarm_7',
    label: 'System Alarm 7',
    icon: 'phone_android',
  ),
  AlarmToneOption(
    id: 'system://alarm_8',
    label: 'System Alarm 8',
    icon: 'phone_android',
  ),
  AlarmToneOption(
    id: 'system://alarm_9',
    label: 'System Alarm 9',
    icon: 'phone_android',
  ),
  AlarmToneOption(
    id: 'system://alarm_10',
    label: 'System Alarm 10',
    icon: 'phone_android',
  ),
  // Custom App Sounds
  AlarmToneOption(
    id: 'alarm_sound',
    label: 'Classic Alarm',
    icon: 'alarm',
  ),
  AlarmToneOption(
    id: 'gentle_wake',
    label: 'Gentle Wake',
    icon: 'sunrise',
  ),
  AlarmToneOption(
    id: 'morning_birds',
    label: 'Morning Birds',
    icon: 'nature',
  ),
  AlarmToneOption(
    id: 'ocean_waves',
    label: 'Ocean Waves',
    icon: 'water',
  ),
  AlarmToneOption(
    id: 'soft_chime',
    label: 'Soft Chime',
    icon: 'bell',
  ),
  AlarmToneOption(
    id: 'energetic',
    label: 'Energetic',
    icon: 'bolt',
  ),
  AlarmToneOption(
    id: 'peaceful',
    label: 'Peaceful',
    icon: 'spa',
  ),
  AlarmToneOption(
    id: 'upbeat',
    label: 'Upbeat',
    icon: 'music_note',
  ),
];

