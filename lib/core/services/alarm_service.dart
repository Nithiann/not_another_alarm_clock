import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/widgets.dart';

import '../../data/models/alarm_model.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

// Top-level callback function for alarm trigger
// This must be a top-level function for release builds to work properly
@pragma('vm:entry-point')
Future<void> alarmCallback(int id, Map<String, dynamic> params) async {
  debugPrint('Alarm triggered with ID: $id');

  try {
    WidgetsFlutterBinding.ensureInitialized();
    await NotificationService.ensureBackgroundInitialized();

    // Recreate alarm model from params
    final alarm = AlarmModel.fromJson(params);

    // Store the alarm ID so the app can open it when it starts
    await StorageService.setPendingAlarmPayload(alarm.id);

    // Cancel any scheduled notification backup to prevent double opening
    // (This is a safety measure in case a backup was scheduled before this fix)
    await NotificationService.cancelNotification(id);

    // Show full screen notification - this should automatically launch the app
    // The full-screen intent will wake the device and show the alarm screen
    // Don't manually launch the app here - it causes double opening
    // The full-screen intent notification handles launching the app automatically
    await NotificationService.showAlarmNotification(alarm);

    // If it's a repeating alarm, reschedule it
    if (alarm.isRepeating) {
      final alarmService = AlarmService();
      await alarmService.scheduleAlarm(alarm);
    }
  } catch (e) {
    debugPrint('Error in alarm callback: $e');
  }
}

// Helper function to launch app from background
// This uses a platform channel which may not be available in background isolates
Future<void> _launchAppFromBackground() async {
  // Note: Platform channels don't work in background isolates
  // The notification's full-screen intent should handle launching the app
  // This is just a placeholder for potential future implementation
}

@pragma('vm:entry-point')
class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  // Schedule an alarm
  Future<bool> scheduleAlarm(AlarmModel alarm) async {
    try {
      final nextAlarmTime = alarm.getNextAlarmTime();
      final alarmId = alarm.id.hashCode;

      // Cancel any existing alarm with this ID
      await cancelAlarm(alarm.id);

      // Schedule the alarm using AndroidAlarmManager
      // Use the top-level function for better release build compatibility
      final success = await AndroidAlarmManager.oneShotAt(
        nextAlarmTime,
        alarmId,
        alarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        allowWhileIdle: true,
        alarmClock: true,
        params: alarm.toJson(),
      );

      // Don't schedule a backup notification - the alarm manager with alarmClock: true
      // should be reliable, and having both causes double opening issues
      // The alarmCallback will show the notification with full-screen intent

      return success;
    } catch (e) {
      debugPrint('Error scheduling alarm: $e');
      return false;
    }
  }

  // Cancel an alarm
  Future<void> cancelAlarm(String alarmId) async {
    try {
      final id = alarmId.hashCode;
      await AndroidAlarmManager.cancel(id);
      await NotificationService.cancelNotification(id);
    } catch (e) {
      debugPrint('Error canceling alarm: $e');
    }
  }

  // Reschedule repeating alarm
  Future<void> rescheduleRepeatingAlarm(AlarmModel alarm) async {
    if (alarm.isRepeating && alarm.isEnabled) {
      await scheduleAlarm(alarm);
    }
  }

  // Snooze alarm (always 10 minutes)
  Future<void> snoozeAlarm(AlarmModel alarm) async {
    try {
      final snoozeTime = DateTime.now().add(const Duration(minutes: 10));

      final snoozeAlarm = alarm.copyWith(scheduledTime: snoozeTime);

      await scheduleAlarm(snoozeAlarm);
    } catch (e) {
      debugPrint('Error snoozing alarm: $e');
    }
  }

  // Check if exact alarm permission is granted (Android 12+)
  Future<bool> checkExactAlarmPermission() async {
    // This would need platform-specific implementation
    // For now, assume permission is granted
    return true;
  }

  // Request exact alarm permission
  Future<void> requestExactAlarmPermission() async {
    // Platform-specific implementation needed
    // Use permission_handler or MethodChannel
  }
}
