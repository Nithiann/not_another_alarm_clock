import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../data/models/alarm_model.dart';
import '../../core/services/alarm_service.dart';

class AlarmProvider extends ChangeNotifier {
  final Box<AlarmModel> _alarmBox = Hive.box<AlarmModel>('alarms');
  final AlarmService _alarmService = AlarmService();

  List<AlarmModel> _alarms = [];
  bool _isLoading = false;

  AlarmProvider() {
    loadAlarms();
  }

  List<AlarmModel> get alarms => _alarms;
  bool get isLoading => _isLoading;

  // Load all alarms from storage
  Future<void> loadAlarms() async {
    _isLoading = true;
    notifyListeners();

    try {
      _alarms = _alarmBox.values.toList();
      _alarms.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    } catch (e) {
      debugPrint('Error loading alarms: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add new alarm
  Future<bool> addAlarm(AlarmModel alarm) async {
    try {
      await _alarmBox.put(alarm.id, alarm);

      if (alarm.isEnabled) {
        await _alarmService.scheduleAlarm(alarm);
      }

      await loadAlarms();
      return true;
    } catch (e) {
      debugPrint('Error adding alarm: $e');
      return false;
    }
  }

  // Update existing alarm
  Future<bool> updateAlarm(AlarmModel alarm) async {
    try {
      await _alarmBox.put(alarm.id, alarm);

      // Cancel old alarm
      await _alarmService.cancelAlarm(alarm.id);

      // Schedule new alarm if enabled
      if (alarm.isEnabled) {
        await _alarmService.scheduleAlarm(alarm);
      }

      await loadAlarms();
      return true;
    } catch (e) {
      debugPrint('Error updating alarm: $e');
      return false;
    }
  }

  // Delete alarm
  Future<bool> deleteAlarm(String alarmId) async {
    try {
      await _alarmService.cancelAlarm(alarmId);
      await _alarmBox.delete(alarmId);
      await loadAlarms();
      return true;
    } catch (e) {
      debugPrint('Error deleting alarm: $e');
      return false;
    }
  }

  // Toggle alarm on/off
  Future<bool> toggleAlarm(String alarmId, bool isEnabled) async {
    try {
      final alarm = _alarmBox.get(alarmId);
      if (alarm == null) return false;

      final updatedAlarm = alarm.copyWith(isEnabled: isEnabled);

      if (isEnabled) {
        await _alarmService.scheduleAlarm(updatedAlarm);
      } else {
        await _alarmService.cancelAlarm(alarmId);
      }

      await _alarmBox.put(alarmId, updatedAlarm);
      await loadAlarms();
      return true;
    } catch (e) {
      debugPrint('Error toggling alarm: $e');
      return false;
    }
  }

  // Snooze alarm
  Future<bool> snoozeAlarm(AlarmModel alarm) async {
    try {
      await _alarmService.snoozeAlarm(alarm);
      return true;
    } catch (e) {
      debugPrint('Error snoozing alarm: $e');
      return false;
    }
  }

  // Get alarm by ID
  AlarmModel? getAlarmById(String id) {
    return _alarmBox.get(id);
  }

  // Get upcoming alarms
  List<AlarmModel> getUpcomingAlarms() {
    final now = DateTime.now();
    return _alarms
        .where(
          (alarm) => alarm.isEnabled && alarm.getNextAlarmTime().isAfter(now),
        )
        .toList();
  }

  // Export alarms to JSON
  List<Map<String, dynamic>> exportAlarms() {
    return _alarms.map((alarm) => alarm.toJson()).toList();
  }

  // Import alarms from JSON
  Future<bool> importAlarms(List<Map<String, dynamic>> alarmsJson) async {
    try {
      for (final json in alarmsJson) {
        final alarm = AlarmModel.fromJson(json);
        await addAlarm(alarm);
      }
      return true;
    } catch (e) {
      debugPrint('Error importing alarms: $e');
      return false;
    }
  }

  // Delete all alarms
  Future<void> deleteAllAlarms() async {
    try {
      for (final alarm in _alarms) {
        await _alarmService.cancelAlarm(alarm.id);
      }
      await _alarmBox.clear();
      await loadAlarms();
    } catch (e) {
      debugPrint('Error deleting all alarms: $e');
    }
  }
}
