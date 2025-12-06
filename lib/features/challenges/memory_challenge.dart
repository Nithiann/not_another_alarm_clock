import 'dart:math';
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
    // Generate a pattern of unique cell values (1-9 for a 3x3 grid)
    // Grid is numbered 1-9 from left to right, top to bottom
    final cells = List.generate(9, (index) => index + 1); // Values 1-9
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
  
  final isCorrect = _areSequencesEqual(selectedCells, correctPattern);
  
  if (isCorrect) {
    _completedPatterns[_currentPatternIndex] = true;
    // Move to next pattern if available
    if (_currentPatternIndex < _patterns.length - 1) {
      _currentPatternIndex++;
      _showingPattern = true;
      _showingIndex = 0;
    }
    // Return true to indicate the answer was correct
    return true;
  } else {
    // Pattern was wrong - just reset to show same pattern again (don't regenerate)
    _showingPattern = true;
    _showingIndex = 0;
    return false;
  }
}


  bool _areSequencesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool get isComplete => _completedPatterns.every((completed) => completed == true);

  // Note: buildCustomInput is no longer used as we now use the factory pattern
  // in ChallengeWidget to select the appropriate widget
}

