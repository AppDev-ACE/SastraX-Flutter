import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

// Class name changed from CreativeSgpaCalculatorPage to SgpaCalculator
class SgpaCalculator extends StatefulWidget {
  const SgpaCalculator({super.key});

  @override
  // State class name updated to match
  State<SgpaCalculator> createState() => _SgpaCalculatorState();
}

// State class name changed from _CreativeSgpaCalculatorPageState to _SgpaCalculatorState
class _SgpaCalculatorState extends State<SgpaCalculator> {
  // Same grade points map
  final Map<String, double> _gradePoints = {
    'S': 10.0, 'A+': 9.0, 'A': 8.0, 'B+': 7.0,
    'B': 6.0, 'C': 5.0, 'D': 4.0, 'F': 0.0, 'N': 0.0,
  };

  // State variables
  List<Map<String, dynamic>> _subjects = [];
  double _sgpa = 0.0;

  @override
  void initState() {
    super.initState();
    // Start with 4 subjects by default
    _subjects = List.generate(4, (_) => {'credits': 3.0, 'grade': 'A'});
    _calculateSgpa(); // Calculate initial SGPA
  }

  // --- Core Logic Methods (largely the same) ---

  void _calculateSgpa() {
    double totalGradePoints = 0;
    double totalCredits = 0;

    for (var subject in _subjects) {
      if (subject['credits'] > 0 && subject['grade'] != null) {
        final credit = subject['credits'] as double;
        final grade = subject['grade'] as String;
        final gradePoint = _gradePoints[grade] ?? 0.0;
        totalGradePoints += credit * gradePoint;
        totalCredits += credit;
      }
    }

    setState(() {
      _sgpa = totalCredits > 0 ? totalGradePoints / totalCredits : 0.0;
    });
  }

  void _addSubject() {
    setState(() {
      _subjects.add({'credits': 3.0, 'grade': 'A'});
    });
    _calculateSgpa();
  }

  void _removeSubject(int index) {
    setState(() {
      _subjects.removeAt(index);
    });
    _calculateSgpa();
  }

  void _resetAll() {
    setState(() {
      _subjects = List.generate(4, (_) => {'credits': 3.0, 'grade': 'A'});
    });
    _calculateSgpa();
  }

  void _updateSubject(int index, {double? newCredit, String? newGrade}) {
    setState(() {
      if (newCredit != null) _subjects[index]['credits'] = newCredit;
      if (newGrade != null) _subjects[index]['grade'] = newGrade;
    });
    _calculateSgpa();
  }

  // --- UI Builder Methods ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Updated AppBar title for simplicity
        title: const Text('SGPA Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetAll,
            tooltip: 'Reset All',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSgpaDisplay(),
            const SizedBox(height: 24),
            // Use AnimatedList for smoother add/remove animations in a real app
            ..._subjects.asMap().entries.map((entry) {
              int index = entry.key;
              return _buildSubjectCard(index);
            }).toList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSubject,
        icon: const Icon(Icons.add),
        label: const Text('Add Subject'),
      ),
    );
  }

  /// Builds the main SGPA display gauge.
  Widget _buildSgpaDisplay() {
    final theme = Theme.of(context);
    return CircularPercentIndicator(
      radius: 90.0,
      lineWidth: 12.0,
      percent: _sgpa / 10.0,
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _sgpa.toStringAsFixed(2),
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            'Your SGPA',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
      progressColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
      circularStrokeCap: CircularStrokeCap.round,
      animation: true,
      animationDuration: 800,
    );
  }

  /// Builds a card for a single subject with interactive controls.
  Widget _buildSubjectCard(int index) {
    final theme = Theme.of(context);
    final subject = _subjects[index];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subject ${index + 1}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                  onPressed: () => _removeSubject(index),
                  tooltip: 'Remove Subject',
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Credit Slider
            Row(
              children: [
                const Icon(Icons.school_outlined, size: 20),
                const SizedBox(width: 8),
                Text('Credits: ${subject['credits'].toInt()}', style: theme.textTheme.bodyMedium),
              ],
            ),
            Slider(
              value: subject['credits'],
              min: 1.0,
              max: 6.0,
              divisions: 5,
              label: subject['credits'].round().toString(),
              onChanged: (newCredit) {
                _updateSubject(index, newCredit: newCredit);
              },
            ),
            const SizedBox(height: 8),
            // Grade Dropdown
            DropdownButtonFormField<String>(
              value: subject['grade'],
              decoration: InputDecoration(
                labelText: 'Grade',
                prefixIcon: const Icon(Icons.star_border_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: _gradePoints.keys.map((String grade) {
                return DropdownMenuItem<String>(
                  value: grade,
                  child: Text(grade),
                );
              }).toList(),
              onChanged: (String? newGrade) {
                if (newGrade != null) {
                  _updateSubject(index, newGrade: newGrade);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}