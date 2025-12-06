import 'dart:math';
import 'package:flutter/material.dart';

import 'base_challenge.dart';

class MemoryChallenge extends AlarmChallenge {
  MemoryChallenge({this.difficulty = 1}) {
    _generatePatterns();
  }

  final int difficulty;
  final List<List<int>> _patterns = [];
  int _currentPatternIndex = 0;
  final List<bool> _completedPatterns = [];
  bool _showingPattern = true;
  int _showingIndex = 0;

  @override
  String get question {
    if (_patterns.isEmpty) return '';
    if (_showingPattern) {
      return 'Remember the pattern';
    }
    return 'Repeat the pattern';
  }

  @override
  String? get hint {
    if (_patterns.isEmpty) return '';
    if (_showingPattern) {
      return 'Remember ${_patterns[_currentPatternIndex].length} cells in order';
    }
    return 'Tap the cells in the order they appeared';
  }

  @override
  String get successMessage {
    if (_currentPatternIndex < _patterns.length - 1) {
      return 'Correct! Next pattern...';
    }
    return 'Nicely done! All memory challenges completed.';
  }

  void _generatePatterns() {
    _patterns.clear();
    _completedPatterns.clear();
    _currentPatternIndex = 0;
    _showingPattern = true;
    _showingIndex = 0;

    final rng = Random();
    
    // Generate 2 patterns: one with 4 cells, one with 5 cells
    _patterns.add(_generatePattern(rng, 4));
    _patterns.add(_generatePattern(rng, 5));
    
    _completedPatterns.addAll([false, false]);
  }

  List<int> _generatePattern(Random rng, int length) {
    // Generate a pattern of unique cell indices (0-8 for a 3x3 grid)
    final cells = List.generate(9, (index) => index);
    cells.shuffle(rng);
    return cells.take(length).toList();
  }

  List<int> get currentPattern {
    if (_patterns.isEmpty || _currentPatternIndex >= _patterns.length) {
      return [];
    }
    return _patterns[_currentPatternIndex];
  }

  int get currentPatternLength => currentPattern.length;
  int get currentLevel => _currentPatternIndex + 1;
  int get totalLevels => _patterns.length;

  bool get isShowingPattern => _showingPattern;
  int get showingIndex => _showingIndex;

  void advanceShowingIndex() {
    if (_showingIndex < currentPattern.length - 1) {
      _showingIndex++;
    } else {
      _showingPattern = false;
    }
  }

  void startInput() {
    _showingPattern = false;
    _showingIndex = 0;
  }

  @override
  bool validateAnswer(String answer) {
    // This will be handled by the custom input widget
    return false;
  }

  bool validatePattern(List<int> selectedCells) {
    if (_patterns.isEmpty || _currentPatternIndex >= _patterns.length) {
      return false;
    }

    final correctPattern = _patterns[_currentPatternIndex];
    if (selectedCells.length != correctPattern.length) {
      return false;
    }

    final isCorrect = selectedCells.every((cell) => correctPattern.contains(cell)) &&
        selectedCells.length == correctPattern.length &&
        _areSequencesEqual(selectedCells, correctPattern);

    if (isCorrect) {
      _completedPatterns[_currentPatternIndex] = true;
      // Move to next pattern if available
      if (_currentPatternIndex < _patterns.length - 1) {
        _currentPatternIndex++;
        _showingPattern = true;
        _showingIndex = 0;
        return false; // Return false to indicate more patterns remain
      } else {
        // All patterns completed
        return true;
      }
    }

    return false;
  }

  bool _areSequencesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool get isComplete => _completedPatterns.every((completed) => completed == true);

  @override
  Widget? buildCustomInput({required ValueChanged<bool> onCompleted}) {
    return _MemoryChallengeWidget(
      challenge: this,
      onCompleted: onCompleted,
    );
  }
}

class _MemoryChallengeWidget extends StatefulWidget {
  final MemoryChallenge challenge;
  final ValueChanged<bool> onCompleted;

  const _MemoryChallengeWidget({
    required this.challenge,
    required this.onCompleted,
  });

  @override
  State<_MemoryChallengeWidget> createState() => _MemoryChallengeWidgetState();
}

class _MemoryChallengeWidgetState extends State<_MemoryChallengeWidget> {
  List<int> _selectedCells = [];
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    // Auto-advance to input after showing pattern for 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && widget.challenge.isShowingPattern) {
        widget.challenge.startInput();
        setState(() {});
      }
    });
  }

  void _onCellTap(int cellIndex) {
    if (widget.challenge.isShowingPattern || _isComplete) return;

    setState(() {
      if (_selectedCells.contains(cellIndex)) {
        // Remove if already selected (undo)
        _selectedCells.remove(cellIndex);
      } else {
        _selectedCells.add(cellIndex);
        
        // Check if pattern is complete
        if (_selectedCells.length == widget.challenge.currentPatternLength) {
          final isValid = widget.challenge.validatePattern(_selectedCells);
          if (isValid) {
            _isComplete = true;
            widget.onCompleted(true);
          } else {
            // Wrong pattern, reset
            _selectedCells.clear();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Wrong pattern. Try again.')),
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pattern = widget.challenge.currentPattern;
    final showingPattern = widget.challenge.isShowingPattern;
    final showingIndex = widget.challenge.showingIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Level ${widget.challenge.currentLevel} of ${widget.challenge.totalLevels}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        if (showingPattern) ...[
          // Show pattern cells one by one
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              final shouldHighlight = pattern.length > showingIndex &&
                  pattern[showingIndex] == index;
              
              return GestureDetector(
                onTap: () => widget.challenge.advanceShowingIndex(),
                child: Container(
                  decoration: BoxDecoration(
                    color: shouldHighlight
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Progress: ${showingIndex + 1}/${pattern.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ] else ...[
          // Input mode
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              final isSelected = _selectedCells.contains(index);
              final isInPattern = pattern.contains(index);
              
              return GestureDetector(
                onTap: () => _onCellTap(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isInPattern && _selectedCells.indexOf(index) == pattern.indexOf(index)
                            ? colorScheme.primary
                            : colorScheme.error)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Text(
                            '${_selectedCells.indexOf(index) + 1}',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Progress: ${_selectedCells.length}/${pattern.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

