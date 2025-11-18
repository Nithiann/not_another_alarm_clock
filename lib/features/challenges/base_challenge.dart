import 'package:flutter/material.dart';

abstract class AlarmChallenge {
  String get question;
  String? get hint;
  String get successMessage;

  /// Validates the provided answer.
  bool validateAnswer(String answer);

  /// Optional widget for more complex challenges (e.g., memory games).
  Widget? buildCustomInput({
    required ValueChanged<bool> onCompleted,
  }) =>
      null;
}

