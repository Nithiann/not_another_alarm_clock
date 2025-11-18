import 'package:hive/hive.dart';

part 'alarm_model.g.dart';

@HiveType(typeId: 0)
class AlarmModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime scheduledTime;

  @HiveField(2)
  String? label;

  @HiveField(3)
  bool isEnabled;

  @HiveField(4)
  List<int> repeatDays; // 0=Monday, 6=Sunday

  @HiveField(5)
  String alarmTone;

  @HiveField(6)
  int challengeType; // 0=Math, 1=Memory, 2=Game (future)

  @HiveField(7)
  int challengeDifficulty; // 1=Easy, 2=Medium, 3=Hard

  @HiveField(8)
  bool vibrate;

  @HiveField(9)
  int snoozeMinutes;

  @HiveField(10)
  DateTime? createdAt;

  @HiveField(11)
  String audioSource;

  @HiveField(12)
  String? radioStationId;

  AlarmModel({
    required this.id,
    required this.scheduledTime,
    this.label,
    this.isEnabled = true,
    this.repeatDays = const [],
    this.alarmTone = 'alarm_sound',
    this.challengeType = 0,
    this.challengeDifficulty = 1,
    this.vibrate = true,
    this.snoozeMinutes = 5,
    this.audioSource = 'sound',
    this.radioStationId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Helper method to get next alarm time
  DateTime getNextAlarmTime() {
    final now = DateTime.now();
    DateTime nextAlarm = DateTime(
      now.year,
      now.month,
      now.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    // If the alarm time has passed today
    if (nextAlarm.isBefore(now)) {
      nextAlarm = nextAlarm.add(const Duration(days: 1));
    }

    // Handle repeat days
    if (repeatDays.isNotEmpty) {
      while (!repeatDays.contains(nextAlarm.weekday - 1)) {
        nextAlarm = nextAlarm.add(const Duration(days: 1));
      }
    }

    return nextAlarm;
  }

  // Check if alarm repeats
  bool get isRepeating => repeatDays.isNotEmpty;

  bool get usesRadio => audioSource == 'radio' && radioStationId != null;

  // Get formatted time string
  String get formattedTime {
    final hour = scheduledTime.hour;
    final minute = scheduledTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  // Get repeat days string
  String get repeatDaysString {
    if (repeatDays.isEmpty) return 'One time';
    if (repeatDays.length == 7) return 'Every day';

    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sortedDays = List<int>.from(repeatDays)..sort();
    return sortedDays.map((day) => dayNames[day]).join(', ');
  }

  // Create a copy with modified fields
  AlarmModel copyWith({
    String? id,
    DateTime? scheduledTime,
    String? label,
    bool? isEnabled,
    List<int>? repeatDays,
    String? alarmTone,
    int? challengeType,
    int? challengeDifficulty,
    bool? vibrate,
    int? snoozeMinutes,
    String? audioSource,
    String? radioStationId,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      label: label ?? this.label,
      isEnabled: isEnabled ?? this.isEnabled,
      repeatDays: repeatDays ?? this.repeatDays,
      alarmTone: alarmTone ?? this.alarmTone,
      challengeType: challengeType ?? this.challengeType,
      challengeDifficulty: challengeDifficulty ?? this.challengeDifficulty,
      vibrate: vibrate ?? this.vibrate,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      audioSource: audioSource ?? this.audioSource,
      radioStationId: radioStationId ?? this.radioStationId,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scheduledTime': scheduledTime.toIso8601String(),
      'label': label,
      'isEnabled': isEnabled,
      'repeatDays': repeatDays,
      'alarmTone': alarmTone,
      'challengeType': challengeType,
      'challengeDifficulty': challengeDifficulty,
      'vibrate': vibrate,
      'snoozeMinutes': snoozeMinutes,
      'createdAt': createdAt?.toIso8601String(),
      'audioSource': audioSource,
      'radioStationId': radioStationId,
    };
  }

  factory AlarmModel.fromJson(Map<String, dynamic> json) {
    return AlarmModel(
      id: json['id'],
      scheduledTime: DateTime.parse(json['scheduledTime']),
      label: json['label'],
      isEnabled: json['isEnabled'],
      repeatDays: List<int>.from(json['repeatDays']),
      alarmTone: json['alarmTone'],
      challengeType: json['challengeType'],
      challengeDifficulty: json['challengeDifficulty'],
      vibrate: json['vibrate'],
      snoozeMinutes: json['snoozeMinutes'],
      audioSource: json['audioSource'] ?? 'sound',
      radioStationId: json['radioStationId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }
}
