import 'dart:math';

import 'base_challenge.dart';

class MathChallenge extends AlarmChallenge {
  MathChallenge({this.difficulty = 1}) {
    _generateQuestions();
  }

  final int difficulty;
  final List<_MathQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  final List<bool> _answers = [];
  bool _lastAnswerWasCorrect = false;

  @override
  String get question {
    if (_questions.isEmpty) return '';
    return _questions[_currentQuestionIndex].question;
  }

  @override
  String? get hint => 'Solve ${_questions.length} problems to dismiss the alarm';

  @override
  String get successMessage {
    if (_currentQuestionIndex < _questions.length - 1) {
      return 'Correct! Next question...';
    }
    return 'Great! All math challenges solved.';
  }

  void _generateQuestions() {
    _questions.clear();
    _answers.clear();
    _currentQuestionIndex = 0;

    final rng = Random();
    final maxNumber = switch (difficulty) {
      1 => 10,
      2 => 25,
      _ => 50,
    };

    // Generate 2 questions
    for (int i = 0; i < 2; i++) {
      final a = rng.nextInt(maxNumber) + 1;
      final b = rng.nextInt(maxNumber) + 1;
      final operations = <String>['+', '-', '×'];
      final operation = operations[rng.nextInt(operations.length)];

      final answer = switch (operation) {
        '+' => a + b,
        '-' => a - b,
        '×' => a * b,
        _ => a + b,
      };

      _questions.add(_MathQuestion(
        question: '$a $operation $b = ?',
        answer: answer,
      ));
      _answers.add(false);
    }
  }

  @override
  bool validateAnswer(String answer) {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) {
      _lastAnswerWasCorrect = false;
      return false;
    }

    final parsed = int.tryParse(answer.trim());
    final isCorrect = parsed == _questions[_currentQuestionIndex].answer;
    _lastAnswerWasCorrect = isCorrect;

    if (isCorrect) {
      _answers[_currentQuestionIndex] = true;
      // Move to next question if available
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
        // Return false to indicate more questions remain (not complete yet)
        return false;
      } else {
        // All questions answered correctly
        return true;
      }
    }

    return false;
  }

  bool get lastAnswerWasCorrect => _lastAnswerWasCorrect;

  void generateNewQuestion() {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) {
      return;
    }

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

    final answer = switch (operation) {
      '+' => a + b,
      '-' => a - b,
      '×' => a * b,
      _ => a + b,
    };

    // Replace the current question with a new one
    _questions[_currentQuestionIndex] = _MathQuestion(
      question: '$a $operation $b = ?',
      answer: answer,
    );
    // Don't mark as answered - user still needs to solve this question
  }

  bool get isComplete => _answers.every((answer) => answer == true);
  int get currentQuestionNumber => _currentQuestionIndex + 1;
  int get totalQuestions => _questions.length;
  int get currentQuestionAnswer {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) {
      return 0;
    }
    return _questions[_currentQuestionIndex].answer;
  }
}

class _MathQuestion {
  final String question;
  final int answer;

  _MathQuestion({required this.question, required this.answer});
}

