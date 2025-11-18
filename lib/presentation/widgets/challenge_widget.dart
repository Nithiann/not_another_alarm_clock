import 'package:flutter/material.dart';

import '../../features/challenges/base_challenge.dart';

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

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _validateAnswer() {
    final isValid = widget.challenge.validateAnswer(
      _answerController.text,
    );
    if (!isValid) {
      setState(() {
        _error = 'Try again!';
        _completed = false;
      });
      widget.onSolved(false);
      return;
    }

    setState(() {
      _error = null;
      _completed = true;
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
        ],
      ],
    );
  }
}

