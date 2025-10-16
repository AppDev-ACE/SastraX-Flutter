import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/theme_model.dart';
import 'subject_attendance_detail.dart';

class SubjectView extends StatelessWidget {
  final Map<String, Map<String, dynamic>> subjectAttendance;

  const SubjectView({Key? key, required this.subjectAttendance}) : super(key: key);

  static const Color primaryBlue = Color(0xFF1e3a8a);

  Color _getTextColor(BuildContext context) => Provider.of<ThemeProvider>(context).isDarkMode ? Colors.white : Colors.black;
  Color _getCardColor(BuildContext context) => Provider.of<ThemeProvider>(context).isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

  int _calculateBunkableClasses(Map<String, dynamic> subjectData) {
    final totalClasses = subjectData['totalClasses'] as int? ?? 0;
    final present = subjectData['present'] as int? ?? 0;
    final absent = subjectData['absent'] as int? ?? 0;
    final od = subjectData['od'] as int? ?? 0;
    if (totalClasses == 0) return 0;
    final effectiveAttended = present + od;
    const minRequiredPercentage = 75.0;
    final maxTotalClasses = (effectiveAttended / (minRequiredPercentage / 100)).floor();
    final maxAllowedAbsences = maxTotalClasses - effectiveAttended;
    final bunkableClasses = maxAllowedAbsences - absent;
    return bunkableClasses.clamp(0, totalClasses);
  }

  Color _getSubjectColor(String subject) {
    final hash = subject.hashCode;
    return Color((hash & 0xFFFFFF) | 0xFF000000).withOpacity(1.0);
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 85) return Colors.green;
    if (percentage >= 75) return Colors.orange;
    return Colors.red;
  }

  Widget _buildAttendanceDetail(String label, dynamic value, Color color) {
    return Column(
      children: [
        Text(value.toString(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildInsightItem(String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subject-wise Attendance',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _getTextColor(context)),
          ),
          const SizedBox(height: 16),
          if (subjectAttendance.isEmpty)
            const Center(child: Text("No subject attendance data available."))
          else
            ...subjectAttendance.entries.map((entry) {
              final subjectData = entry.value;
              final bunkableClasses = _calculateBunkableClasses(subjectData);
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubjectAttendanceDetail(
                        subjectName: entry.key,
                        attendancePercentage: subjectData['percentage'],
                      ),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 3,
                  color: _getCardColor(context),
                  shadowColor: isDark ? Colors.black54 : Colors.grey.withOpacity(0.2),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _getSubjectColor(entry.key),
                              child: Text(entry.key.substring(0, 1), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _getTextColor(context)),
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: (subjectData['percentage'] as double) / 100,
                                    backgroundColor: isDark ? Colors.grey[700] : Colors.grey.withOpacity(0.3),
                                    valueColor: AlwaysStoppedAnimation<Color>(_getAttendanceColor(subjectData['percentage'] as double)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${(subjectData['percentage'] as double).toInt()}%',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _getAttendanceColor(subjectData['percentage'] as double)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildAttendanceDetail('Total', subjectData['totalClasses'], primaryBlue),
                            _buildAttendanceDetail('Present', subjectData['present'], Colors.green),
                            _buildAttendanceDetail('Absent', subjectData['absent'], Colors.red),
                            _buildAttendanceDetail('OD', subjectData['od'], Colors.orange),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.purple.withOpacity(0.2) : Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.info_outline, color: Colors.purple, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'You can bunk $bunkableClasses more classes',
                                style: const TextStyle(fontSize: 12, color: Colors.purple, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          const SizedBox(height: 20),
          Text(
            'Subject-wise Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _getTextColor(context),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? primaryBlue.withOpacity(0.2) : primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInsightItem(
                  'Best Performance',
                  'Data Structures, Computer Networks, Operating System',
                  Icons.star,
                  Colors.amber,
                ),
                const SizedBox(height: 12),
                _buildInsightItem(
                  'Needs Improvement',
                  'Natural Language Processing',
                  Icons.trending_down,
                  Colors.red,
                ),
                const SizedBox(height: 12),
                _buildInsightItem(
                  'Recommendation',
                  'Focus on Natural Language Processing and Soft Skill',
                  Icons.lightbulb,
                  Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}