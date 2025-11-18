import 'dart:math';

import 'base_challenge.dart';

class MemoryChallenge extends AlarmChallenge {
  MemoryChallenge({this.difficulty = 1}) {
    _generateSequence();
  }

  final int difficulty;
  late String _sequence;

  @override
  String get question => 'Repeat this code: $_sequence';

  @override
  String? get hint => 'Memorize the digits shown above.';

  @override
  String get successMessage => 'Nicely done! Memory unlocked.';

  void _generateSequence() {
    final rng = Random();
    final length = switch (difficulty) {
      1 => 4,
      2 => 6,
      _ => 8,
    };

    _sequence = List.generate(length, (_) => rng.nextInt(10)).join();
  }

  @override
  bool validateAnswer(String answer) {
    return answer.trim() == _sequence;
  }
}

