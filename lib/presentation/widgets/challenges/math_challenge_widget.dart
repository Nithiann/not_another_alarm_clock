import 'package:flutter/material.dart';
import '../../../features/challenges/math_challenge.dart';

class MathChallengeWidget extends StatefulWidget {
  const MathChallengeWidget({
    super.key,
    required this.challenge,
    required this.onSolved,
    this.onSnooze,
    this.canSnooze = true,
  });

  final MathChallenge challenge;
  final ValueChanged<bool> onSolved;
  final VoidCallback? onSnooze;
  final bool canSnooze;

  @override
  State<MathChallengeWidget> createState() => _MathChallengeWidgetState();
}

class _MathChallengeWidgetState extends State<MathChallengeWidget> {
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
    widget.challenge.validateAnswer(_answerController.text);
    final wasCorrect = widget.challenge.lastAnswerWasCorrect;
    final isCompleteNow = widget.challenge.isComplete;

    if (!wasCorrect) {
      setState(() {
        _error = 'Try again!';
        _completed = false;
        _showIntermediateSuccess = false;
      });
      widget.onSolved(false);
      return;
    }

    if (isCompleteNow) {
      setState(() {
        _error = null;
        _completed = true;
        _showIntermediateSuccess = false;
      });
      widget.onSolved(true);
    } else {
      setState(() {
        _error = null;
        _completed = false;
        _showIntermediateSuccess = true;
        _answerController.clear();
      });
      widget.onSolved(false);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showIntermediateSuccess = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${widget.challenge.currentQuestionNumber} of ${widget.challenge.totalQuestions}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            TextButton.icon(
              onPressed: () {
                widget.challenge.generateNewQuestion();
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
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(widget.challenge.successMessage),
            ],
          ),
        ],
        if (widget.onSnooze != null) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.canSnooze ? widget.onSnooze : null,
              icon: const Icon(Icons.snooze),
              label: const Text('Snooze'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

