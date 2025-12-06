import 'package:flutter/material.dart';
import '../../features/challenges/base_challenge.dart';
import '../../features/challenges/math_challenge.dart';
import '../../features/challenges/memory_challenge.dart';
import '../../features/challenges/none_challenge.dart';
import 'challenges/math_challenge_widget.dart';
import 'challenges/memory_challenge_widget.dart';
import 'challenges/none_challenge_widget.dart';

class ChallengeWidget extends StatelessWidget {
  const ChallengeWidget({
    super.key,
    required this.challenge,
    required this.onSolved,
    this.onDismiss,
    this.onSnooze,
    this.canSnooze = true,
  });

  final AlarmChallenge challenge;
  final ValueChanged<bool> onSolved;
  final VoidCallback? onDismiss;
  final VoidCallback? onSnooze;
  final bool canSnooze;

  @override
  Widget build(BuildContext context) {
    if (challenge is NoneChallenge) {
      if (onDismiss == null || onSnooze == null) {
        throw ArgumentError('onDismiss and onSnooze must be provided for NoneChallenge');
      }
      return NoneChallengeWidget(
        challenge: challenge as NoneChallenge,
        onSolved: onSolved,
        onDismiss: onDismiss!,
        onSnooze: onSnooze!,
        canSnooze: canSnooze,
      );
    }

    if (challenge is MathChallenge) {
      return MathChallengeWidget(
        challenge: challenge as MathChallenge,
        onSolved: onSolved,
        onSnooze: onSnooze,
        canSnooze: canSnooze,
      );
    }

    if (challenge is MemoryChallenge) {
      return MemoryChallengeWidget(
        challenge: challenge as MemoryChallenge,
        onSolved: onSolved,
      );
    }

    return _DefaultChallengeWidget(
      challenge: challenge,
      onSolved: onSolved,
    );
  }
}

/// Default widget for challenges that don't have a custom widget implementation
class _DefaultChallengeWidget extends StatefulWidget {
  const _DefaultChallengeWidget({
    required this.challenge,
    required this.onSolved,
  });

  final AlarmChallenge challenge;
  final ValueChanged<bool> onSolved;

  @override
  State<_DefaultChallengeWidget> createState() => _DefaultChallengeWidgetState();
}

class _DefaultChallengeWidgetState extends State<_DefaultChallengeWidget> {
  final TextEditingController _answerController = TextEditingController();
  String? _error;
  bool _completed = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _validateAnswer() {
    final isValid = widget.challenge.validateAnswer(_answerController.text);
    
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

