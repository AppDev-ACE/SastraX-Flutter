import 'package:flutter/material.dart';
import 'more_options_page.dart'; // Make sure this import is correct

class InternalsPage extends StatelessWidget {
  final String token ;
  InternalsPage({super.key , required this.token});

  // Hardcoded data for student's internal marks
  final List<Map<String, dynamic>> subjects = [
    {'name': 'CA', 'internal1': 18, 'internal2': 22, 'internal3': 20, 'total': 60, 'maxMarks': 75},
    {'name': 'CO', 'internal1': 20, 'internal2': 19, 'internal3': 23, 'total': 62, 'maxMarks': 75},
    {'name': 'CN', 'internal1': 17, 'internal2': 21, 'internal3': 19, 'total': 57, 'maxMarks': 75},
    {'name': 'Computer Science', 'internal1': 24, 'internal2': 23, 'internal3': 22, 'total': 69, 'maxMarks': 75},
    {'name': 'DAA', 'internal1': 19, 'internal2': 20, 'internal3': 21, 'total': 60, 'maxMarks': 75},
    {'name': 'CODING', 'internal1': 16, 'internal2': 18, 'internal3': 20, 'total': 54, 'maxMarks': 75},
    {'name': 'PYTHON', 'internal1': 22, 'internal2': 20, 'internal3': 18, 'total': 60, 'maxMarks': 75},
  ];

  // Helper function to determine the color based on percentage
  Color _getGradeColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 70) return Colors.blue;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate overall average percentage
    final double totalMarks = subjects.fold(0, (sum, item) => sum + (item['total'] as int));
    final double maxTotalMarks = subjects.fold(0, (sum, item) => sum + (item['maxMarks'] as int));
    final double averagePercentage = (maxTotalMarks > 0) ? (totalMarks / maxTotalMarks) * 100 : 0;

    return Scaffold(
      // The AppBar has been updated as you requested
      appBar: AppBar(
        title: Text('Internal Marks', style: theme.textTheme.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overall Performance', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 5),
            Text(
              'A summary of your internal assessment marks across all subjects.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 20),

            // List of subjects, each in its own card
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                return _buildSubjectCard(context, subject);
              },
            ),
          ],
        ),
      ),
    );
  }

  // A new widget to display each subject's data in a card, similar to the SGPA calculator
  Widget _buildSubjectCard(BuildContext context, Map<String, dynamic> subject) {
    final theme = Theme.of(context);
    final double percentage = (subject['total'] / subject['maxMarks']) * 100;
    final Color gradeColor = _getGradeColor(percentage);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Subject Name and Percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subject['name'],
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: gradeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Middle row: Individual internal marks
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInternalMark(theme, 'CIA 1', subject['internal1']),
              _buildInternalMark(theme, 'CIA 2', subject['internal2']),
              _buildInternalMark(theme, 'CIA 3', subject['internal3']),
            ],
          ),
          const SizedBox(height: 16),

          // Bottom part: Total and Progress Bar
          Text(
            'Total: ${subject['total']} / ${subject['maxMarks']}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
            borderRadius: BorderRadius.circular(5),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  // Helper widget to display a single internal assessment mark
  Widget _buildInternalMark(ThemeData theme, String label, int mark) {
    return Column(
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 4),
        Text(
          mark.toString(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}