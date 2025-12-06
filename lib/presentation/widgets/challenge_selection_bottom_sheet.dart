import 'package:flutter/material.dart';

class ChallengeSelectionBottomSheet extends StatelessWidget {
  const ChallengeSelectionBottomSheet({
    super.key,
    required this.selectedChallenge,
    required this.onChallengeSelected,
  });

  final int selectedChallenge;
  final ValueChanged<int> onChallengeSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    'Choose Challenge',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Challenge options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _ChallengeOption(
                  icon: Icons.check_circle_outline,
                  label: 'None',
                  description: 'Dismiss easily',
                  isSelected: selectedChallenge == -1,
                  onTap: () {
                    onChallengeSelected(-1);
                    Navigator.pop(context);
                  },
                ),
                _ChallengeOption(
                  icon: Icons.calculate_outlined,
                  label: 'Math',
                  description: 'Solve simple math problems',
                  isSelected: selectedChallenge == 0,
                  onTap: () {
                    onChallengeSelected(0);
                    Navigator.pop(context);
                  },
                ),
                _ChallengeOption(
                  icon: Icons.psychology_outlined,
                  label: 'Memory',
                  description: 'Remember pattern sequence',
                  isSelected: selectedChallenge == 1,
                  onTap: () {
                    onChallengeSelected(1);
                    Navigator.pop(context);
                  },
                ),
                _ChallengeOption(
                  icon: Icons.vibration,
                  label: 'Shake',
                  description: 'Shake phone to dismiss',
                  isSelected: selectedChallenge == 2,
                  onTap: () {
                    onChallengeSelected(2);
                    Navigator.pop(context);
                  },
                ),
                _ChallengeOption(
                  icon: Icons.qr_code_scanner_outlined,
                  label: 'Barcode',
                  description: 'Scan specific barcode',
                  isSelected: selectedChallenge == 3,
                  onTap: () {
                    onChallengeSelected(3);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChallengeOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                    : colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

