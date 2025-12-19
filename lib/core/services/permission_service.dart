import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;

    var status = await Permission.scheduleExactAlarm.status;
    if (status.isGranted) {
      return true;
    }

    status = await Permission.scheduleExactAlarm.request();
    return status.isGranted;
  }

  static Future<bool> requestOverlayPermission() async {
    if (!Platform.isAndroid) return true;
    var status = await Permission.systemAlertWindow.status;
    if (status.isGranted) return true;
    status = await Permission.systemAlertWindow.request();
    return status.isGranted;
  }

  static Future<bool> requestBatteryOptimizationException() async {
    if (!Platform.isAndroid) return true;
    var status = await Permission.ignoreBatteryOptimizations.status;
    if (status.isGranted) return true;
    status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  static Future<bool> hasNotificationPermission() =>
      Permission.notification.status.then((value) => value.isGranted);

  static Future<bool> hasExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    return Permission.scheduleExactAlarm.status.then((value) => value.isGranted);
  }

  static Future<bool> hasOverlayPermission() async {
    if (!Platform.isAndroid) return true;
    return Permission.systemAlertWindow.status.then((value) => value.isGranted);
  }

  static Future<bool> hasBatteryOptimizationException() async {
    if (!Platform.isAndroid) return true;
    return Permission.ignoreBatteryOptimizations.status
        .then((value) => value.isGranted);
  }

  static const MethodChannel _permissionChannel = MethodChannel(
    'com.nithiann.not_another_alarm_clock/permissions',
  );

  static Future<bool> hasFullScreenIntentPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final result = await _permissionChannel.invokeMethod<bool>(
        'hasFullScreenIntentPermission',
      );
      return result ?? false;
    } catch (e) {
      // If method channel fails, assume permission is granted (Android 11 and below)
      return true;
    }
  }

  static Future<bool> requestFullScreenIntentPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      await _permissionChannel.invokeMethod('requestFullScreenIntentPermission');
      // Wait a bit for user to return from settings, then check status
      await Future.delayed(const Duration(milliseconds: 500));
      return await hasFullScreenIntentPermission();
    } catch (e) {
      return false;
    }
  }
}

