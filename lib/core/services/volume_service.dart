import 'dart:async';
import 'package:just_audio/just_audio.dart';

class VolumeService {
  static final VolumeService _instance = VolumeService._internal();
  factory VolumeService() => _instance;
  VolumeService._internal();

  Timer? _timer;

  void rampVolume({
    required double start,
    required double end,
    required int minutes,
    required AudioPlayer player,
  }) {
    _timer?.cancel();
    if (minutes <= 0 || start >= end) {
      player.setVolume(end);
      return;
    }

    final totalSteps = minutes * 12; // every 5 seconds
    final stepIncrease = (end - start) / totalSteps;
    int step = 0;

    player.setVolume(start);

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      step++;
      final nextVolume = (start + step * stepIncrease).clamp(0.0, end);
      player.setVolume(nextVolume);
      if (nextVolume >= end || step >= totalSteps) {
        timer.cancel();
      }
    });
  }

  void cancel() {
    _timer?.cancel();
  }
}
