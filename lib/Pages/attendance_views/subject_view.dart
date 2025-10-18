// subject_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/theme_model.dart';
import 'subject_attendance_detail.dart';

class SubjectView extends StatelessWidget {
  final Map<String, Map<String, dynamic>> subjectAttendance;
  final List<dynamic> initialSubjectAttendance;
  final List<dynamic> initialHourWiseAttendance;
  final List<dynamic> timetable;
  final List<dynamic> courseMap;

  const SubjectView({Key? key, required this.subjectAttendance , required this.timetable , required this.initialSubjectAttendance , required this.courseMap , required this.initialHourWiseAttendance}) : super(key: key);

  static const Color primaryBlue = Color(0xFF1e3a8a);

  Color _getTextColor(BuildContext context) => Provider.of<ThemeProvider>(context).isDarkMode ? Colors.white : Colors.black;
  Color _getCardColor(BuildContext context) => Provider.of<ThemeProvider>(context).isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  // Helper for secondary text (like 'Total', 'Present', etc.)
  Color _getSecondaryTextColor(BuildContext context) =>
      Provider.of<ThemeProvider>(context).isDarkMode
          ? Colors.white70
          : Colors.grey[600]!;

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
    if (percentage >= 80) return Colors.green;
    if (percentage >= 75) return Colors.orange;
    return Colors.red;
  }

  // ============= MODIFIED HELPER =============
  Widget _buildAttendanceDetail(BuildContext context, String label, dynamic value, Color color, double scale) {
    return Column(
      children: [
        Text(value.toString(), style: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.bold, color: color)),
        Text(
            label,
            style: TextStyle(
                fontSize: 10 * scale,
                color: _getSecondaryTextColor(context) // Fixed for dark mode
            )
        ),
      ],
    );
  }

  // ============= MODIFIED HELPER =============
  Widget _buildInsightItem(BuildContext context, String title, String value, IconData icon, Color color, double scale) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20 * scale),
        SizedBox(width: 8 * scale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  title,
                  style: TextStyle(
                      fontSize: 12 * scale,
                      color: _getSecondaryTextColor(context) // Fixed for dark mode
                  )
              ),
              Text(
                  value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14 * scale, // Added responsive font
                      color: _getTextColor(context) // Added text color
                  )
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    // ============= RESPONSIVE SCALING =============
    final scale = MediaQuery.of(context).textScaler.scale(1.0);
    final screenWidth = MediaQuery.of(context).size.width;
    final double rPadding = screenWidth * 0.04; // ~16px
    // ==============================================

    // ============= DYNAMIC BUNK COLOR (THE FIX) =============
    final Color bunkTextIconColor = isDark ? Colors.purpleAccent[100]! : Colors.purple; // Light purple for dark mode
    final Color bunkBgColor = isDark ? Colors.purpleAccent[100]!.withOpacity(0.2) : Colors.purple.withOpacity(0.1);
    // Use a lighter blue for 'Total' in dark mode
    final Color totalColor = isDark ? Colors.blue[300]! : primaryBlue;
    // ========================================================

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(rPadding), // Responsive padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subject-wise Attendance',
            style: TextStyle(fontSize: 20 * scale, fontWeight: FontWeight.bold, color: _getTextColor(context)), // Responsive
          ),
          SizedBox(height: 16 * scale), // Responsive
          if (subjectAttendance.isEmpty)
            Center(
                child: Text(
                    "No subject attendance data available.",
                    style: TextStyle(
                        color: _getTextColor(context),
                        fontSize: 14 * scale
                    ) // Responsive
                )
            )
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
                        attendancePercentage: subjectData['percentage'], initialHourWiseAttendance: initialHourWiseAttendance, courseMap: courseMap, initialSubjectAttendance: initialSubjectAttendance, timetable: timetable,
                      ),
                    ),
                  );
                },
                child: Card(
                  margin: EdgeInsets.only(bottom: 12 * scale), // Responsive
                  elevation: 3,
                  color: _getCardColor(context),
                  shadowColor: isDark ? Colors.black54 : Colors.grey.withOpacity(0.2),
                  child: Padding(
                    padding: EdgeInsets.all(rPadding), // Responsive
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _getSubjectColor(entry.key),
                              radius: 20 * scale, // Responsive
                              child: Text(
                                  entry.key.substring(0, 1),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 16 * scale) // Responsive
                              ),
                            ),
                            SizedBox(width: 16 * scale), // Responsive
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.bold, color: _getTextColor(context)), // Responsive
                                    maxLines: 2, // Allow wrapping
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4 * scale), // Responsive
                                  LinearProgressIndicator(
                                    value: (subjectData['percentage'] as double) / 100,
                                    backgroundColor: isDark ? Colors.grey[700] : Colors.grey.withOpacity(0.3),
                                    valueColor: AlwaysStoppedAnimation<Color>(_getAttendanceColor(subjectData['percentage'] as double)),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16 * scale), // Responsive
                            Text(
                              '${(subjectData['percentage'] as double).toInt()}%',
                              style: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.bold, color: _getAttendanceColor(subjectData['percentage'] as double)), // Responsive
                            ),
                          ],
                        ),
                        SizedBox(height: 12 * scale), // Responsive
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildAttendanceDetail(context, 'Total', subjectData['totalClasses'], totalColor, scale),
                            _buildAttendanceDetail(context, 'Present', subjectData['present'], Colors.green, scale),
                            _buildAttendanceDetail(context, 'Absent', subjectData['absent'], Colors.red, scale),
                            _buildAttendanceDetail(context, 'OD', subjectData['od'], Colors.orange, scale),
                          ],
                        ),
                        SizedBox(height: 8 * scale), // Responsive
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale), // Responsive
                          decoration: BoxDecoration(
                            color: bunkBgColor, // Use dynamic bg color
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline, color: bunkTextIconColor, size: 16 * scale), // Use dynamic icon color & responsive
                              SizedBox(width: 4 * scale), // Responsive
                              Text(
                                'You can bunk $bunkableClasses more classes',
                                style: TextStyle(fontSize: 12 * scale, color: bunkTextIconColor, fontWeight: FontWeight.w500), // Use dynamic text color & responsive
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
          SizedBox(height: 20 * scale), // Responsive
          Text(
            'Subject-wise Insights',
            style: TextStyle(
              fontSize: 18 * scale, // Responsive
              fontWeight: FontWeight.bold,
              color: _getTextColor(context),
            ),
          ),
          SizedBox(height: 12 * scale), // Responsive
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(rPadding), // Responsive
            decoration: BoxDecoration(
              color: isDark ? primaryBlue.withOpacity(0.2) : primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInsightItem(
                  context, // Pass context
                  'Best Performance',
                  'Data Structures, Computer Networks, Operating System',
                  Icons.star,
                  Colors.amber,
                  scale, // Pass scale
                ),
                SizedBox(height: 12 * scale), // Responsive
                _buildInsightItem(
                  context, // Pass context
                  'Needs Improvement',
                  'Natural Language Processing',
                  Icons.trending_down,
                  Colors.red,
                  scale, // Pass scale
                ),
                SizedBox(height: 12 * scale), // Responsive
                _buildInsightItem(
                  context, // Pass context
                  'Recommendation',
                  'Focus on Natural Language Processing and Soft Skill',
                  Icons.lightbulb,
                  Colors.orange,
                  scale, // Pass scale
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}