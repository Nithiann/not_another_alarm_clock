import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  AudioPlayer? _player;

  AudioPlayer get player {
    _player ??= AudioPlayer();
    return _player!;
  }

  Future<void> play(String url, double volume) async {
    _player ??= AudioPlayer();

    // Configure audio session
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

    // Check if it's a local asset, system URI, or URL
    if (url.startsWith('assets/') || (!url.contains('://') && !url.startsWith('content://'))) {
      // Local asset file - remove 'assets/' prefix if present
      final assetPath = url.startsWith('assets/') 
          ? url.substring(7) // Remove 'assets/' prefix
          : url;
      await _player!.setAsset(assetPath);
    } else if (url.startsWith('content://')) {
      // System content URI (for Android system sounds)
      await _player!.setUrl(url);
    } else {
      // URL (radio stream or http/https)
      await _player!.setUrl(url);
    }
    
    await _player!.setVolume(volume);
    await _player!.setLoopMode(LoopMode.one); // Loop the alarm sound
    await _player!.play();
  }

  Future<void> stop() async {
    await _player?.stop();
    await _player?.dispose();
    _player = null;
  }

  Future<void> setVolume(double volume) async {
    if (_player != null) {
      await _player!.setVolume(volume);
    }
  }
}
