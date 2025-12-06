import 'base_challenge.dart';

/// Challenge type for alarms with no challenge - just dismiss/snooze buttons
class NoneChallenge extends AlarmChallenge {
  NoneChallenge();

  @override
  String get question => '';

  @override
  String? get hint => null;

  @override
  String get successMessage => 'Alarm dismissed';

  @override
  bool validateAnswer(String answer) {
    // No validation needed for none challenge
    return true;
  }
}

