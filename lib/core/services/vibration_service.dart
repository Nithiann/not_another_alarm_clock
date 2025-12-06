import 'dart:async';
import 'package:vibration/vibration.dart';

class VibrationService {
  static final VibrationService _instance = VibrationService._internal();
  factory VibrationService() => _instance;
  VibrationService._internal();

  Timer? _vibrationTimer;
  bool _isVibrating = false;

  Future<void> startContinuousVibration() async {
    if (_isVibrating) return;
    
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == null || !hasVibrator) return;

    _isVibrating = true;
    
    // Start with a vibration
    await Vibration.vibrate(duration: 500);
    
    // Continue vibrating every second
    _vibrationTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == null || !hasVibrator) {
        stop();
        return;
      }
      await Vibration.vibrate(duration: 500);
    });
  }

  void stop() {
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    _isVibrating = false;
    Vibration.cancel();
  }
}

