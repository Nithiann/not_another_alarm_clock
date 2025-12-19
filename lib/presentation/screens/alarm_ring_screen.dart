import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/services/audio_player_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/system_sound_service.dart';
import '../../core/services/volume_service.dart';
import '../../core/services/vibration_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/alarm_model.dart';
import '../../data/models/radio_station.dart';
import '../../features/challenges/base_challenge.dart';
import '../../features/challenges/challenge_factory.dart';
import '../../core/services/alarm_service.dart';
import '../providers/alarm_provider.dart';
import '../providers/radio_station_provider.dart';
import '../widgets/challenge_widget.dart';

class AlarmRingScreen extends StatefulWidget {
  const AlarmRingScreen({super.key, required this.alarmId});

  final String alarmId;

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> {
  AlarmModel? _alarm;
  AlarmChallenge? _challenge;
  bool _challengeSolved = false;
  bool _processing = false;
  RadioStation? _station;
  bool _radioError = false;
  int _snoozeCount = 0;
  static const int _maxSnoozeCount = 3;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    // Stop alarm audio just in case the widget is disposed
    AudioPlayerService().stop();
    SystemSoundService.stopSystemAlarm();
    VolumeService().cancel();
    VibrationService().stop();
    super.dispose();
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _alarm ??= context.read<AlarmProvider>().getAlarmById(widget.alarmId);
    if (_alarm != null && _challenge == null) {
      _challenge = ChallengeFactory.create(
        type: _alarm!.challengeType,
        difficulty: _alarm!.challengeDifficulty,
      );
      // For none challenge, mark as solved immediately
      if (_alarm!.challengeType == -1) {
        _challengeSolved = true;
      }
      // Start alarm sound and vibration
      _startAlarm();
    }
  }

  Future<void> _startAlarm() async {
    if (_alarm == null) return;

    // Start vibration if enabled
    if (_alarm!.vibrate) {
      VibrationService().startContinuousVibration();
    }

    if (_alarm!.usesRadio) {
      await _startRadio();
    } else {
      // Play alarm sound
      await _startAlarmSound();
    }
  }

  Future<void> _startAlarmSound() async {
    try {
      final maxVolume = StorageService.maxAlarmVolume;
      final gradual = StorageService.gradualVolumeEnabled;
      final minutes = StorageService.gradualVolumeMinutes;
      final startVolume = gradual ? (maxVolume * 0.2) : maxVolume;

      if (_alarm!.alarmTone.startsWith('system://')) {
        final systemSound = _alarm!.alarmTone.replaceFirst('system://', '');
        
        debugPrint('Playing system alarm sound: $systemSound');
        
        final success = await SystemSoundService.playSystemAlarm(systemSound);
        
        if (!success) {
          await SystemSoundService.playSystemAlarm('default');
        }
        
        return;
      }

      final soundPath = 'assets/sounds/${_alarm!.alarmTone}.mp3';
      
      await AudioPlayerService().play(soundPath, startVolume);

      if (gradual && minutes > 0 && maxVolume > startVolume) {
        VolumeService().rampVolume(
          start: startVolume,
          end: maxVolume,
          minutes: minutes,
          player: AudioPlayerService().player,
        );
      }
    } catch (e) {
      debugPrint('Error playing alarm sound: $e');
      // Try with default alarm sound
      try {
        await AudioPlayerService().play('assets/sounds/alarm_sound.mp3', StorageService.maxAlarmVolume);
      } catch (_) {
        debugPrint('Error playing default alarm sound');
      }
    }
  }

  Future<void> _startRadio() async {
    final station = context
        .read<RadioStationProvider>()
        .getById(_alarm!.radioStationId);
    if (station == null) return;

    try {
      final maxVolume = StorageService.maxAlarmVolume;
      final gradual = StorageService.gradualVolumeEnabled;
      final minutes = StorageService.gradualVolumeMinutes;
      final startVolume = gradual ? (maxVolume * 0.2) : maxVolume;

      // Play the stream
      await AudioPlayerService().play(station.streamUrl, startVolume);

      // Ramp volume if gradual is enabled
      if (gradual && minutes > 0 && maxVolume > startVolume) {
        VolumeService().rampVolume(
          start: startVolume,
          end: maxVolume,
          minutes: minutes,
          player: AudioPlayerService().player,
        );
      }

      if (!mounted) return;
      setState(() {
        _station = station;
        _radioError = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _station = station;
          _radioError = true;
        });
      }
    }
  }

  Future<void> _dismissAlarm() async {
    if (_alarm == null) return;
    if (!_challengeSolved && _alarm!.challengeType != -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete the challenge to dismiss')),
      );
      return;
    }

    setState(() => _processing = true);
    final provider = context.read<AlarmProvider>();

    if (!_alarm!.isRepeating) {
      await provider.updateAlarm(_alarm!.copyWith(isEnabled: false));
    }

    await AudioPlayerService().stop();
    await SystemSoundService.stopSystemAlarm();
    VolumeService().cancel();
    VibrationService().stop();

    await NotificationService.cancelNotification(_alarm!.id.hashCode);
    
    // Schedule wake-check with 5 minutes
    await _scheduleWakeCheck();

    if (!mounted) return;
    setState(() => _processing = false);
    Navigator.pop(context);
  }

  Future<void> _snoozeAlarm() async {
    if (_alarm == null) return;
    if (_snoozeCount >= _maxSnoozeCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum snooze limit reached')),
      );
      return;
    }

    setState(() {
      _processing = true;
      _snoozeCount++;
    });

    // Use AlarmService to snooze (10 minutes)
    await AlarmService().snoozeAlarm(_alarm!);

    await AudioPlayerService().stop();
    await SystemSoundService.stopSystemAlarm();
    VolumeService().cancel();
    VibrationService().stop();

    await NotificationService.cancelNotification(_alarm!.id.hashCode);

    if (!mounted) return;
    setState(() => _processing = false);
    Navigator.pop(context);
  }

  Future<void> _scheduleWakeCheck() async {
    if (_alarm == null) return;
    
    // Schedule wake-check alarm in 5 minutes
    final wakeCheckTime = DateTime.now().add(const Duration(minutes: 5));
    final wakeCheckAlarm = _alarm!.copyWith(
      scheduledTime: wakeCheckTime,
      label: _alarm!.label != null ? '${_alarm!.label} (Wake Check)' : 'Wake Check',
    );
    
    await AlarmService().scheduleAlarm(wakeCheckAlarm);
    
    // Schedule wake-check notification with dismiss action
    await NotificationService.scheduleWakeCheckNotification(wakeCheckAlarm);
  }

  @override
Widget build(BuildContext context) {
  if (_alarm == null || _challenge == null) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Alarm not found. Return'),
        ),
      ),
    );
  }

  final colorScheme = Theme.of(context).colorScheme;
  final now = DateTime.now();
  final dateFormat = DateFormat('EEEE, MMMM d');
  final timeFormat = DateFormat('HH:mm');

  return Scaffold(
    resizeToAvoidBottomInset: true,
    body: Container(
      decoration: AppTheme.gradientDecoration(colorScheme),
      width: double.infinity,
      height: MediaQuery.of(context).size.height,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.alarm,
                size: 80,
                color: colorScheme.onSurface,
              ),
              const SizedBox(height: 24),
              Text(
                timeFormat.format(now),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                dateFormat.format(now),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 32),
              Text(
                _alarm!.label ?? 'Alarm',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                _alarm!.formattedTime,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
              if (_alarm!.usesRadio && _station != null) ...[
                const SizedBox(height: 4),
                Text(
                  _station!.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                ),
              ],
              const SizedBox(height: 32),
              ChallengeWidget(
                challenge: _challenge!,
                onSolved: (value) {
                  setState(() => _challengeSolved = value);
                  if (value && _alarm!.challengeType != -1) {
                    // Auto-dismiss after challenge completion (except for none challenge)
                    Future.delayed(const Duration(seconds: 1), () {
                      if (mounted) {
                        _dismissAlarm();
                      }
                    });
                  }
                },
                onDismiss: _alarm!.challengeType == -1 ? _dismissAlarm : null,
                onSnooze: _snoozeAlarm,
                canSnooze: _snoozeCount < _maxSnoozeCount,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
}
}

