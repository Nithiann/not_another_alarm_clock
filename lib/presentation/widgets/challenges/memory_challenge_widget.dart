import 'dart:async';
import 'package:flutter/material.dart';
import '../../../features/challenges/memory_challenge.dart';

class MemoryChallengeWidget extends StatefulWidget {
  const MemoryChallengeWidget({
    super.key,
    required this.challenge,
    required this.onSolved,
    this.onSnooze,
    this.canSnooze = true,
  });

  final MemoryChallenge challenge;
  final ValueChanged<bool> onSolved;
  final VoidCallback? onSnooze;
  final bool canSnooze;

  @override
  State<MemoryChallengeWidget> createState() => _MemoryChallengeWidgetState();
}

class _MemoryChallengeWidgetState extends State<MemoryChallengeWidget> {
  List<int> _selectedCells = [];
  bool _isComplete = false;
  bool _isShowingPattern = true;
  int _currentShowingIndex = 0;
  List<int> _patternBeingShown = []; // Store the pattern we're currently showing
  Timer? _patternTimer;

  @override
  void initState() {
    super.initState();
    _startShowingPattern();
  }

  @override
  void dispose() {
    _patternTimer?.cancel();
    super.dispose();
  }

  void _startShowingPattern() {
    // Cancel any existing timer first
    _patternTimer?.cancel();
    
    // Get the current pattern once at the start and store it
    // This ensures we show the complete pattern even if the challenge state changes
    final patternToShow = List<int>.from(widget.challenge.currentPattern);
    if (patternToShow.isEmpty) {
      return;
    }

    // Reset state and store the pattern we're about to show
    setState(() {
      _isShowingPattern = true;
      _currentShowingIndex = 0;
      _selectedCells.clear();
      _isComplete = false;
      _patternBeingShown = patternToShow; // Store the pattern
    });

    // Show pattern automatically - each cell lights up for 800ms
    // Start immediately with index 0 (already set above), then advance every 800ms
    int tickCount = 0;
    _patternTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        tickCount++;
        // Advance to next cell in the pattern
        if (tickCount < _patternBeingShown.length) {
          _currentShowingIndex = tickCount;
        } else {
          // Pattern showing complete, wait a bit then switch to input mode
          timer.cancel();
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _isShowingPattern = false;
                _currentShowingIndex = 0;
                _patternBeingShown = []; // Clear when done showing
              });
            }
          });
        }
      });
    });
  }

  void _onCellTap(int cellValue) {
    if (_isShowingPattern || _isComplete) return;

    setState(() {
      // Check if cell is already selected - allow deselecting
      if (_selectedCells.contains(cellValue)) {
        // Only allow removing the last selected cell
        if (_selectedCells.isNotEmpty && 
            _selectedCells.last == cellValue) {
          _selectedCells.removeLast();
        }
      } else {
        _selectedCells.add(cellValue);

        // Check if pattern is complete
        if (_selectedCells.length == widget.challenge.currentPatternLength) {
          final isValid = widget.challenge.validatePattern(_selectedCells);
          
          if (isValid && widget.challenge.isComplete) {
            // All patterns completed!
            _isComplete = true;
            widget.onSolved(true);
          } else if (isValid) {
            // Correct pattern, but more to go - challenge already moved to next pattern
            widget.onSolved(false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Correct! Level ${widget.challenge.currentLevel - 1} of ${widget.challenge.totalLevels} complete. Next pattern...'),
                duration: const Duration(seconds: 2),
              ),
            );
            // Clear the input quickly, then show next pattern after delay
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                setState(() {
                  _selectedCells.clear();
                });
                Future.delayed(const Duration(milliseconds: 2500), () {
                  if (mounted) {
                    _startShowingPattern();
                  }
                });
              }
            });
          } else {
            // Wrong pattern - show same pattern again (challenge already reset to show same pattern)
            widget.onSolved(false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Wrong pattern. Try again - watch carefully!'),
                duration: Duration(seconds: 2),
              ),
            );
            // Clear input quickly, then show same pattern again
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                setState(() {
                  _selectedCells.clear();
                });
                Future.delayed(const Duration(milliseconds: 1500), () {
                  if (mounted) {
                    _startShowingPattern();
                  }
                });
              }
            });
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
        Text(
          'Level ${widget.challenge.currentLevel} of ${widget.challenge.totalLevels}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        // 3x3 Grid (cells numbered 1-9, left to right, top to bottom)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: 9,
          itemBuilder: (context, index) {
            // Cell values are 1-9 (index 0-8 maps to value 1-9)
            final cellValue = index + 1;
            
            // For showing pattern: highlight if it's the current cell being shown
            // Use the stored pattern being shown to ensure consistency
            final patternToCheck = _isShowingPattern ? _patternBeingShown : widget.challenge.currentPattern;
            final isCurrentlyHighlighted = _isShowingPattern &&
                _currentShowingIndex < patternToCheck.length &&
                patternToCheck[_currentShowingIndex] == cellValue;
            
            // For input mode: check if selected
            final isSelected = !_isShowingPattern && _selectedCells.contains(cellValue);
            final currentPatternForInput = widget.challenge.currentPattern;
            final selectionOrder = !_isShowingPattern && isSelected
                ? _selectedCells.indexOf(cellValue)
                : -1;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onCellTap(cellValue),
                borderRadius: BorderRadius.circular(12),
                splashColor: colorScheme.primary.withValues(alpha: 0.3),
                highlightColor: colorScheme.primary.withValues(alpha: 0.1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: isCurrentlyHighlighted
                        ? colorScheme.primary
                        : isSelected
                            ? (selectionOrder >= 0 && 
                                selectionOrder < currentPatternForInput.length &&
                                currentPatternForInput[selectionOrder] == cellValue
                                ? colorScheme.primary
                                : colorScheme.error)
                            : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrentlyHighlighted
                          ? colorScheme.primary
                          : isSelected
                              ? colorScheme.primary
                              : colorScheme.outline.withValues(alpha: 0.3),
                      width: isCurrentlyHighlighted || isSelected ? 2 : 1,
                    ),
                    boxShadow: isCurrentlyHighlighted
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.5),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$cellValue',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: isCurrentlyHighlighted || isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        if (_isShowingPattern) ...[
          Text(
            'Watch the sequence: ${_currentShowingIndex + 1}/${widget.challenge.currentPattern.length}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ] else ...[
          Text(
            'Tap the cells in order: ${_selectedCells.length}/${widget.challenge.currentPattern.length}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _selectedCells.length == widget.challenge.currentPattern.length
                  ? colorScheme.primary
                  : colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (_isComplete && widget.challenge.isComplete) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.challenge.successMessage,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
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

