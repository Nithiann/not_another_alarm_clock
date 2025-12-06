import 'base_challenge.dart';
import 'math_challenge.dart';
import 'memory_challenge.dart';
import 'none_challenge.dart';

class ChallengeFactory {
  static AlarmChallenge create({
    required int type,
    required int difficulty,
  }) {
    switch (type) {
      case -1:
        return NoneChallenge();
      case 0:
        return MathChallenge(difficulty: difficulty);
      case 1:
        return MemoryChallenge(difficulty: difficulty);
      default:
        return MathChallenge(difficulty: difficulty);
    }
  }
}

