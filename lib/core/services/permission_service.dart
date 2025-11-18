import 'dart:io';

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
}

