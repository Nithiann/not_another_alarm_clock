import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/alarm_model.dart';
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

  @pragma('vm:entry-point')
  static void _onNotificationTapped(NotificationResponse response) {
    final alarmId = response.payload;
    if (alarmId == null) return;
    if (NavigationService.canNavigate) {
      NavigationService.navigateToAlarm(alarmId);
    } else {
      StorageService.setPendingAlarmPayload(alarmId);
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
          ? RawResourceAndroidNotificationSound(alarm.alarmTone)
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
