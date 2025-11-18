import 'dart:math';

import 'base_challenge.dart';

class MathChallenge extends AlarmChallenge {
  MathChallenge({this.difficulty = 1}) {
    _generateQuestion();
  }

  final int difficulty;
  late int _answer;
  late String _question;

  @override
  String get question => _question;

  @override
  String? get hint => 'Solve the equation correctly to dismiss the alarm';

  @override
  String get successMessage => 'Great! Math challenge solved.';

  void _generateQuestion() {
    final rng = Random();
    final maxNumber = switch (difficulty) {
      1 => 10,
      2 => 25,
      _ => 50,
    };

    final a = rng.nextInt(maxNumber) + 1;
    final b = rng.nextInt(maxNumber) + 1;
    final operations = <String>['+', '-', '×'];
    final operation = operations[rng.nextInt(operations.length)];

    switch (operation) {
      case '+':
        _answer = a + b;
      case '-':
        _answer = a - b;
      case '×':
        _answer = a * b;
    }

    _question = '$a $operation $b = ?';
  }

  @override
  bool validateAnswer(String answer) {
    final parsed = int.tryParse(answer.trim());
    return parsed == _answer;
  }
}

