import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/services/notification_service.dart';
import '../../core/services/storage_service.dart';
import '../../data/models/alarm_model.dart';
import '../../data/models/radio_station.dart';
import '../../features/challenges/base_challenge.dart';
import '../../features/challenges/challenge_factory.dart';
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
  AudioPlayer? _radioPlayer;
  RadioStation? _station;
  bool _radioError = false;
  Timer? _volumeTimer;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    _radioPlayer?.dispose();
    _volumeTimer?.cancel();
    WakelockPlus.disable();
    super.dispose();
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
    }
    if (_alarm != null && _alarm!.usesRadio && _radioPlayer == null) {
      _startRadio();
    }
  }

  Future<void> _startRadio() async {
    final station = context
        .read<RadioStationProvider>()
        .getById(_alarm!.radioStationId);
    if (station == null) return;

    final player = AudioPlayer();
    try {
      final session = await AudioSession.instance;
      await session.configure(
        const AudioSessionConfiguration(
          androidAudioAttributes: AndroidAudioAttributes(
            usage: AndroidAudioUsage.alarm,
            contentType: AndroidAudioContentType.music,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.defaultToSpeaker,
        ),
      );
      await player.setUrl(station.streamUrl);
      final maxVolume = StorageService.maxAlarmVolume;
      final gradual = StorageService.gradualVolumeEnabled;
      final minutes = StorageService.gradualVolumeMinutes;
      final startVolume = gradual ? (maxVolume * 0.2) : maxVolume;
      await player.setVolume(startVolume);
      await player.play();
      if (gradual && minutes > 0 && maxVolume > startVolume) {
        _volumeTimer?.cancel();
        final totalSteps = minutes * 12; // every 5 seconds
        final stepIncrease = (maxVolume - startVolume) / totalSteps;
        int step = 0;
        _volumeTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
          step++;
          final nextVolume = (startVolume + step * stepIncrease)
              .clamp(0.0, maxVolume);
          player.setVolume(nextVolume);
          if (nextVolume >= maxVolume || step >= totalSteps) {
            timer.cancel();
          }
        });
      }
      if (!mounted) {
        await player.dispose();
        return;
      }
      setState(() {
        _radioPlayer = player;
        _station = station;
        _radioError = false;
      });
    } catch (_) {
      await player.dispose();
      if (mounted) {
        setState(() {
          _radioPlayer = null;
          _station = station;
          _radioError = true;
        });
      }
    }
  }

  Future<void> _dismissAlarm() async {
    if (_alarm == null) return;
    if (!_challengeSolved) {
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

    await _radioPlayer?.stop();
    await NotificationService.cancelNotification(_alarm!.id.hashCode);

    if (!mounted) return;
    setState(() => _processing = false);
    Navigator.pop(context);
  }

  Future<void> _snoozeAlarm() async {
    if (_alarm == null) return;
    setState(() => _processing = true);
    await context.read<AlarmProvider>().snoozeAlarm(_alarm!);
    await _radioPlayer?.stop();
    await NotificationService.cancelNotification(_alarm!.id.hashCode);
    if (!mounted) return;
    setState(() => _processing = false);
    Navigator.pop(context);
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

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Text(
                _alarm!.formattedTime,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _alarm!.label ?? 'Alarm Challenge',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 32),
              if (_alarm!.usesRadio)
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Streaming ${_station?.name ?? 'radio'}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        if (_radioError)
                          Text(
                            'Unable to start stream. Check your internet connection.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.redAccent),
                          )
                        else
                          Text(
                            _station?.streamUrl ?? '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (_radioError)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _startRadio,
                              child: const Text('Retry'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ChallengeWidget(
                challenge: _challenge!,
                onSolved: (value) {
                  setState(() => _challengeSolved = value);
                },
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _processing ? null : _snoozeAlarm,
                      icon: const Icon(Icons.snooze),
                      label: const Text('Snooze'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _processing ? null : _dismissAlarm,
                      icon: const Icon(Icons.check),
                      label: Text(
                        _challengeSolved ? 'Dismiss' : 'Solve to dismiss',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

