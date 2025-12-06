import 'package:flutter/material.dart';

import '../../features/challenges/base_challenge.dart';
import '../../features/challenges/math_challenge.dart';

class ChallengeWidget extends StatefulWidget {
  const ChallengeWidget({
    super.key,
    required this.challenge,
    required this.onSolved,
  });

  final AlarmChallenge challenge;
  final ValueChanged<bool> onSolved;

  @override
  State<ChallengeWidget> createState() => _ChallengeWidgetState();
}

class _ChallengeWidgetState extends State<ChallengeWidget> {
  final TextEditingController _answerController = TextEditingController();
  String? _error;
  bool _completed = false;
  bool _showIntermediateSuccess = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _validateAnswer() {
    // For math challenges, we need to check the answer differently
    if (widget.challenge is MathChallenge) {
      final mathChallenge = widget.challenge as MathChallenge;
      final isValid = mathChallenge.validateAnswer(_answerController.text);
      final wasCorrect = mathChallenge.lastAnswerWasCorrect;
      final isCompleteNow = mathChallenge.isComplete;
      
      if (!wasCorrect) {
        // Wrong answer
        setState(() {
          _error = 'Try again!';
          _completed = false;
          _showIntermediateSuccess = false;
        });
        widget.onSolved(false);
        return;
      }
      
      // Correct answer - check if more questions remain
      if (isCompleteNow) {
        // All questions completed
        setState(() {
          _error = null;
          _completed = true;
          _showIntermediateSuccess = false;
        });
        widget.onSolved(true);
      } else {
        // More questions remain - answer was correct but need to solve more
        setState(() {
          _error = null;
          _completed = false;
          _showIntermediateSuccess = true;
          _answerController.clear();
        });
        widget.onSolved(false);
        // Clear intermediate success after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showIntermediateSuccess = false;
            });
          }
        });
      }
      return;
    }
    
    // For other challenges, use standard validation
    final isValid = widget.challenge.validateAnswer(
      _answerController.text,
    );
    if (!isValid) {
      setState(() {
        _error = 'Try again!';
        _completed = false;
        _showIntermediateSuccess = false;
      });
      widget.onSolved(false);
      return;
    }

    setState(() {
      _error = null;
      _completed = true;
      _showIntermediateSuccess = false;
    });
    widget.onSolved(true);
  }

  @override
  Widget build(BuildContext context) {
    final customInput = widget.challenge.buildCustomInput(
      onCompleted: (value) {
        setState(() {
          _completed = value;
          _error = value ? null : _error;
        });
        widget.onSolved(value);
      },
    );

    if (customInput != null) {
      return customInput;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.challenge.question,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (widget.challenge.hint != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.challenge.hint!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 16),
        // Show question number for math challenges
        if (widget.challenge is MathChallenge) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${(widget.challenge as MathChallenge).currentQuestionNumber} of ${(widget.challenge as MathChallenge).totalQuestions}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextButton.icon(
                onPressed: () {
                  (widget.challenge as MathChallenge).generateNewQuestion();
                  setState(() {
                    _answerController.clear();
                    _error = null;
                    _completed = false;
                    _showIntermediateSuccess = false;
                  });
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('New question'),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: _answerController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Your answer',
            errorText: _error,
            suffixIcon: IconButton(
              icon: Icon(
                _completed ? Icons.check_circle : Icons.send_outlined,
              ),
              onPressed: _validateAnswer,
            ),
          ),
          onSubmitted: (_) => _validateAnswer(),
        ),
        if (_completed) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(widget.challenge.successMessage),
            ],
          ),
        ] else if (_showIntermediateSuccess) ...[
          // Show success message for intermediate questions
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(widget.challenge.successMessage),
            ],
          ),
        ],
      ],
    );
  }
}

