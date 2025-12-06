import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/alarm_model.dart';
import 'alarm_service.dart';
import 'navigation_service.dart';
import 'storage_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    await _ensureInitialized(
      requestPermissions: true,
      configureCallbacks: true,
    );

    final launchDetails =
        await _notifications.getNotificationAppLaunchDetails();
    final payload = launchDetails?.notificationResponse?.payload;
    if (launchDetails?.didNotificationLaunchApp == true && payload != null) {
      await StorageService.setPendingAlarmPayload(payload);
    }
  }

  static Future<void> ensureBackgroundInitialized() async {
    await _ensureInitialized(
      requestPermissions: false,
      configureCallbacks: false,
    );
  }

  static Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> flushPendingPayload() async {
    final payload = StorageService.consumePendingAlarmPayload();
    if (payload != null) {
      NavigationService.navigateToAlarm(payload);
    }
  }

  // Top-level function for notification tap handler
  // This must be a top-level function for release builds to work properly
  @pragma('vm:entry-point')
  static void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    // Handle wake-check dismiss action
    if (response.actionId == 'dismiss_wake_check' || payload.startsWith('wake_check:')) {
      final alarmId = payload.replaceFirst('wake_check:', '');
      // Cancel the wake-check alarm
      final alarmService = AlarmService();
      alarmService.cancelAlarm(alarmId);
      return;
    }

    // Handle regular alarm tap - always store payload so app can open it
    final alarmId = payload;
    // Store the payload so the app can open it when it starts or resumes
    StorageService.setPendingAlarmPayload(alarmId);
    
    // If app is already running, try to navigate immediately
    if (NavigationService.canNavigate) {
      // Use a small delay to ensure the app is ready
      Future.delayed(const Duration(milliseconds: 100), () {
        if (NavigationService.canNavigate) {
          NavigationService.navigateToAlarm(alarmId);
        }
      });
    }
  }

  // Show alarm notification with full screen intent
  static Future<void> showAlarmNotification(AlarmModel alarm) async {
    final details = _buildNotificationDetails(alarm);
    await _notifications.show(
      alarm.id.hashCode,
      alarm.label ?? 'Alarm',
      'Time to wake up! Complete the challenge to dismiss.',
      details,
      payload: alarm.id,
    );
  }

  // Schedule alarm notification
  static Future<void> scheduleAlarmNotification(AlarmModel alarm) async {
    final scheduledDate = alarm.getNextAlarmTime();

    final details = _buildNotificationDetails(alarm);
    await _notifications.zonedSchedule(
      alarm.id.hashCode,
      alarm.label ?? 'Alarm',
      'Time to wake up!',
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: alarm.id,
    );
  }

  static AndroidNotificationSound? _getAndroidNotificationSound(String alarmTone) {
    // Check if it's a system sound
    if (alarmTone.startsWith('system://')) {
      // Extract the system sound identifier
      final systemSound = alarmTone.replaceFirst('system://', '');
      
      // Use RingtoneManager URIs for system alarm sounds
      // For default: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
      // This typically returns: content://settings/system/alarm_alert
      if (systemSound == 'default') {
        // Use default system alarm - this is the user's selected default alarm
        return const UriAndroidNotificationSound(
          'content://settings/system/alarm_alert',
        );
      } else {
        // For specific alarms, try different URI patterns
        // Some devices use: content://media/internal/audio/media/XX
        // Others use: content://settings/system/alarm_alert_XX
        // We'll try the settings path first, which is more common
        final alarmNumber = systemSound.replaceFirst('alarm_', '');
        
        // Try the standard Android alarm URI pattern
        // Note: These URIs may vary by device manufacturer
        // If this doesn't work, we fall back to default
        try {
          return UriAndroidNotificationSound(
            'content://settings/system/alarm_alert_$alarmNumber',
          );
        } catch (e) {
          // Fall back to default if specific alarm not found
          return const UriAndroidNotificationSound(
            'content://settings/system/alarm_alert',
          );
        }
      }
    } else {
      // Custom app sound - use raw resource
      return RawResourceAndroidNotificationSound(alarmTone);
    }
  }

  static NotificationDetails _buildNotificationDetails(AlarmModel alarm) {
    final playSound = alarm.audioSource == 'sound';
    final androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarms',
      channelDescription: 'Channel for alarm notifications',
      importance: Importance.max,
      priority: Priority.max,
      playSound: playSound,
      enableVibration: alarm.vibrate,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      autoCancel: false,
      ongoing: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      sound: playSound
          ? _getAndroidNotificationSound(alarm.alarmTone)
          : null,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: playSound,
      sound: playSound ? '${alarm.alarmTone}.aiff' : null,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  // Cancel notification
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Schedule wake-check notification with dismiss action
  static Future<void> scheduleWakeCheckNotification(AlarmModel alarm) async {
    final scheduledDate = alarm.getNextAlarmTime();

    final androidDetails = AndroidNotificationDetails(
      'wake_check_channel',
      'Wake Check',
      channelDescription: 'Wake check notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      autoCancel: false,
      ongoing: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      sound: const UriAndroidNotificationSound(
        'content://settings/system/alarm_alert',
      ),
      actions: [
        const AndroidNotificationAction(
          'dismiss_wake_check',
          'Dismiss',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      alarm.id.hashCode,
      alarm.label ?? 'Wake Check',
      'Slide to dismiss or the alarm will repeat',
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'wake_check:${alarm.id}',
    );
  }

  // Show simple notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'general_channel',
      'General',
      channelDescription: 'General notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  static Future<void> _ensureInitialized({
    required bool requestPermissions,
    required bool configureCallbacks,
  }) async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse:
          configureCallbacks ? _onNotificationTapped : null,
      onDidReceiveBackgroundNotificationResponse:
          configureCallbacks ? _onNotificationTapped : null,
    );

    if (requestPermissions) {
      await _requestPermissions();
    }

    _initialized = true;
  }
}
