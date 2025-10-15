import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../models/theme_model.dart';

class SgpaCalculatorWidget extends StatefulWidget {
  const SgpaCalculatorWidget({super.key});

  @override
  State<SgpaCalculatorWidget> createState() => _SgpaCalculatorWidgetState();
}

class _SgpaCalculatorWidgetState extends State<SgpaCalculatorWidget> {
  final Map<String, double> _gradePoints = {
    'S': 10.0, 'A+': 9.0, 'A': 8.0, 'B+': 7.0,
    'B': 6.0, 'C': 5.0, 'D': 4.0, 'F': 0.0, 'N': 0.0,
  };

  List<Map<String, dynamic>> _subjects = [];
  double _sgpa = 0.0;

  @override
  void initState() {
    super.initState();
    _subjects = List.generate(5, (_) => {'credits': 3.0, 'grade': 'A'});
    _calculateSgpa();
  }

  void _calculateSgpa() {
    double totalGradePoints = 0;
    double totalCredits = 0;

    for (var subject in _subjects) {
      final credit = subject['credits'] as double;
      final grade = subject['grade'] as String;
      final gradePoint = _gradePoints[grade] ?? 0.0;
      totalGradePoints += credit * gradePoint;
      totalCredits += credit;
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
    if (_subjects.length > 1) { // Prevent removing the last subject
      setState(() {
        _subjects.removeAt(index);
      });
      _calculateSgpa();
    }
  }

  void _resetAll() {
    setState(() {
      _subjects = List.generate(5, (_) => {'credits': 3.0, 'grade': 'A'});
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: themeProvider.cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: themeProvider.isDarkMode
            ? Border.all(color: AppTheme.primaryPurple.withOpacity(0.3))
            : null,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: _buildSgpaDisplay(theme),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._subjects.asMap().entries.map((entry) {
                  return _buildSubjectCard(entry.key, theme);
                }).toList(),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: _resetAll,
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text('Reset'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _addSubject,
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Add Subject'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSgpaDisplay(ThemeData theme) {
    return CircularPercentIndicator(
      radius: 70.0,
      lineWidth: 10.0,
      percent: _sgpa / 10.0,
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _sgpa.toStringAsFixed(2),
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            'Expected SGPA',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
      progressColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
      circularStrokeCap: CircularStrokeCap.round,
      animation: true,
    );
  }

  Widget _buildSubjectCard(int index, ThemeData theme) {
    final subject = _subjects[index];
    return Card(
      elevation: 0,
      color: Theme.of(context).scaffoldBackgroundColor,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.withOpacity(0.2))
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subject ${index + 1}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: theme.colorScheme.error, size: 20),
                  onPressed: () => _removeSubject(index),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.school_outlined, size: 20),
                const SizedBox(width: 8),
                Text('Credits: ${subject['credits'].toInt()}'),
                Expanded(
                  child: Slider(
                    value: subject['credits'],
                    min: 1.0,
                    max: 6.0,
                    divisions: 5,
                    label: subject['credits'].round().toString(),
                    onChanged: (newCredit) => _updateSubject(index, newCredit: newCredit),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: subject['grade'],
              decoration: InputDecoration(
                labelText: 'Grade',
                prefixIcon: const Icon(Icons.star_border_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: _gradePoints.keys.map((String grade) {
                return DropdownMenuItem<String>(value: grade, child: Text(grade));
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