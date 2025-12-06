import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../features/challenges/none_challenge.dart';

class NoneChallengeWidget extends StatefulWidget {
  const NoneChallengeWidget({
    super.key,
    required this.challenge,
    required this.onSolved,
    required this.onDismiss,
    required this.onSnooze,
    this.canSnooze = true,
  });

  final NoneChallenge challenge;
  final ValueChanged<bool> onSolved;
  final VoidCallback onDismiss;
  final VoidCallback onSnooze;
  final bool canSnooze;

  @override
  State<NoneChallengeWidget> createState() => _NoneChallengeWidgetState();
}

class _NoneChallengeWidgetState extends State<NoneChallengeWidget> {
  Timer? _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Update time every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('EEEE, MMMM d');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Current time display
        Text(
          timeFormat.format(_currentTime),
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          dateFormat.format(_currentTime),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
        ),
        const SizedBox(height: 48),
        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Snooze button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.canSnooze ? widget.onSnooze : null,
                icon: const Icon(Icons.snooze),
                label: const Text('Snooze'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: widget.canSnooze 
                        ? colorScheme.primary 
                        : colorScheme.outline.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Dismiss button
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  widget.onSolved(true);
                  widget.onDismiss();
                },
                icon: const Icon(Icons.check),
                label: const Text('Dismiss'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

