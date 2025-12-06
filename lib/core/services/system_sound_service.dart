import 'package:flutter/services.dart';

class SystemSoundService {
  static const MethodChannel _channel = MethodChannel(
    'com.nithiann.not_another_alarm_clock/system_sounds',
  );

  /// Get the Android system alarm URI for the given alarm type
  /// 
  /// [alarmType] should be "default" or "alarm_1", "alarm_2", etc.
  /// Returns the content:// URI string for the system alarm sound
  static Future<String?> getSystemAlarmUri(String alarmType) async {
    try {
      final uri = await _channel.invokeMethod<String>(
        'getSystemAlarmUri',
        {'type': alarmType},
      );
      return uri;
    } catch (e) {
      // If platform channel fails, return null
      return null;
    }
  }

  /// Play a system alarm sound using Android's Ringtone class
  /// 
  /// [alarmType] should be "default" or "alarm_1", "alarm_2", etc.
  /// Returns true if successful, false otherwise
  static Future<bool> playSystemAlarm(String alarmType) async {
    try {
      final success = await _channel.invokeMethod<bool>(
        'playSystemAlarm',
        {'type': alarmType},
      );
      return success ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Stop the currently playing system alarm
  static Future<bool> stopSystemAlarm() async {
    try {
      final success = await _channel.invokeMethod<bool>(
        'stopSystemAlarm',
      );
      return success ?? false;
    } catch (e) {
      return false;
    }
  }
}

