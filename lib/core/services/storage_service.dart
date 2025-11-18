import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static bool get isReady => _prefs != null;

  static const _themeKey = 'theme_mode';
  static const _vibrationKey = 'default_vibration';
  static const _challengeTypeKey = 'default_challenge_type';
  static const _challengeDifficultyKey = 'default_challenge_difficulty';
  static const _snoozeKey = 'default_snooze_minutes';
  static const _lastBackupKey = 'last_backup_timestamp';
  static const _lastBackupFileKey = 'last_backup_file_id';
  static const _onboardingKey = 'onboarding_complete';
  static const _gradualVolumeEnabledKey = 'gradual_volume_enabled';
  static const _gradualVolumeMinutesKey = 'gradual_volume_minutes';
  static const _maxVolumeKey = 'max_alarm_volume';
  static const _pendingAlarmPayloadKey = 'pending_alarm_payload';

  static ThemeMode getThemeMode() {
    final value = _prefs?.getString(_themeKey);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs?.setString(_themeKey, mode.name);
  }

  static bool get defaultVibration =>
      _prefs?.getBool(_vibrationKey) ?? true;

  static Future<void> setDefaultVibration(bool value) async {
    await _prefs?.setBool(_vibrationKey, value);
  }

  static int get defaultChallengeType =>
      _prefs?.getInt(_challengeTypeKey) ?? 0;

  static Future<void> setDefaultChallengeType(int type) async {
    await _prefs?.setInt(_challengeTypeKey, type);
  }

  static int get defaultChallengeDifficulty =>
      _prefs?.getInt(_challengeDifficultyKey) ?? 1;

  static Future<void> setDefaultChallengeDifficulty(int difficulty) async {
    await _prefs?.setInt(_challengeDifficultyKey, difficulty.clamp(1, 3));
  }

  static int get defaultSnoozeMinutes =>
      _prefs?.getInt(_snoozeKey) ?? 5;

  static Future<void> setDefaultSnoozeMinutes(int minutes) async {
    await _prefs?.setInt(_snoozeKey, minutes.clamp(3, 15));
  }

  static DateTime? get lastBackupTime {
    final value = _prefs?.getString(_lastBackupKey);
    return value != null ? DateTime.tryParse(value) : null;
  }

  static Future<void> setLastBackupTime(DateTime time) async {
    await _prefs?.setString(_lastBackupKey, time.toIso8601String());
  }

  static String? get lastBackupFileId =>
      _prefs?.getString(_lastBackupFileKey);

  static Future<void> setLastBackupFileId(String fileId) async {
    await _prefs?.setString(_lastBackupFileKey, fileId);
  }

  static bool get hasCompletedOnboarding =>
      _prefs?.getBool(_onboardingKey) ?? false;

  static Future<void> setOnboardingComplete() async {
    await _prefs?.setBool(_onboardingKey, true);
  }

  static bool get gradualVolumeEnabled =>
      _prefs?.getBool(_gradualVolumeEnabledKey) ?? false;

  static Future<void> setGradualVolumeEnabled(bool value) async {
    await _prefs?.setBool(_gradualVolumeEnabledKey, value);
  }

  static int get gradualVolumeMinutes =>
      _prefs?.getInt(_gradualVolumeMinutesKey) ?? 2;

  static Future<void> setGradualVolumeMinutes(int value) async {
    await _prefs?.setInt(_gradualVolumeMinutesKey, value.clamp(1, 10));
  }

  static double get maxAlarmVolume =>
      _prefs?.getDouble(_maxVolumeKey) ?? 1.0;

  static Future<void> setMaxAlarmVolume(double value) async {
    await _prefs?.setDouble(_maxVolumeKey, value.clamp(0.2, 1.0));
  }

  static Future<void> setPendingAlarmPayload(String? payload) async {
    if (payload == null) {
      await _prefs?.remove(_pendingAlarmPayloadKey);
    } else {
      await _prefs?.setString(_pendingAlarmPayloadKey, payload);
    }
  }

  static String? consumePendingAlarmPayload() {
    final payload = _prefs?.getString(_pendingAlarmPayloadKey);
    if (payload != null) {
      _prefs?.remove(_pendingAlarmPayloadKey);
    }
    return payload;
  }
}

