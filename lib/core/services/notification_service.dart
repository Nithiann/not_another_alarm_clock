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
  static bool _isNavigatingToAlarm = false; // Guard to prevent multiple navigations

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
    // Prevent multiple navigations from multiple calls
    if (_isNavigatingToAlarm) return;
    
    final payload = StorageService.consumePendingAlarmPayload();
    if (payload != null) {
      _isNavigatingToAlarm = true;
      try {
        await NavigationService.navigateToAlarm(payload);
      } finally {
        // Reset after a delay to allow navigation to complete
        Future.delayed(const Duration(seconds: 2), () {
          _isNavigatingToAlarm = false;
        });
      }
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

    // Handle regular alarm tap
    // For full-screen intent notifications, the app is automatically launched by Android
    // We only need to store the payload - flushPendingPayload will handle navigation
    // Don't navigate here to avoid double opening
    // The full-screen intent will launch the app, and flushPendingPayload will navigate
    final alarmId = payload;
    StorageService.setPendingAlarmPayload(alarmId);
    
    // Don't navigate here - let flushPendingPayload handle it
    // This prevents double opening when:
    // 1. Full-screen intent launches the app (Android system)
    // 2. flushPendingPayload navigates to alarm screen (our code)
    // If we also navigate here, we get double opening
  }

  // Show alarm notification with full screen intent
  // This will wake the device and show the alarm screen even when locked
  static Future<void> showAlarmNotification(AlarmModel alarm) async {
    final details = _buildNotificationDetails(alarm);
    
    // Store the alarm payload so the app can open it when launched
    await StorageService.setPendingAlarmPayload(alarm.id);
    
    // Show the notification - the full-screen intent will automatically
    // launch the app and show the alarm screen when the phone is locked
    // The full-screen intent will also work when the phone is unlocked
    // No need for manual navigation as it causes double opening
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
      fullScreenIntent: true, // This will launch the app when phone is locked
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

    // Create alarm channel with full-screen intent support
    // This is critical for alarms to work when phone is locked
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      const alarmChannel = AndroidNotificationChannel(
        'alarm_channel',
        'Alarms',
        description: 'Channel for alarm notifications',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: false,
      );
      
      await androidImplementation.createNotificationChannel(alarmChannel);
      
      // Note: USE_FULL_SCREEN_INTENT permission on Android 12+ may need to be
      // granted manually through system settings (Settings > Apps > [App] > Special app access > Display over other apps)
      // The full-screen intent will work automatically once this permission is granted
    }

    if (requestPermissions) {
      await _requestPermissions();
    }

    _initialized = true;
  }
}
