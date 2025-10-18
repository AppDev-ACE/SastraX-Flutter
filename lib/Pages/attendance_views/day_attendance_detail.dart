// day_attendance_detail.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/theme_model.dart';
import '../../components/theme_toggle_button.dart';

class DayAttendanceDetail extends StatefulWidget {
  final DateTime selectedDate;
  // This data is now {'hour1': 'present', 'hour2': 'absent', ...}
  final Map<String, String> attendanceData;
  final List<dynamic> timetable; // Normalized timetable
  final List<dynamic> courseMap;
  final String regNo;

  const DayAttendanceDetail({
    Key? key,
    required this.selectedDate,
    required this.attendanceData,
    required this.timetable,
    required this.courseMap,
    required this.regNo,
  }) : super(key: key);

  @override
  State<DayAttendanceDetail> createState() => _DayAttendanceDetailState();
}

class _DayAttendanceDetailState extends State<DayAttendanceDetail> {
  final Map<String, bool> _checkboxStates = {};
  static const Color primaryBlue = Color(0xFF1e3a8a);

  // ✅ **THIS MAP IS NOW CORRECT**
  // Maps hour keys to display times, matching the parent.
  static const Map<String, String> _hourKeyToTime = {
    'hour1': '08:45 AM - 09:45 AM',
    'hour2': '09:45 AM - 10:45 AM',
    'hour3': '11:00 AM - 12:00 PM',
    'hour4': '12:00 PM - 01:00 PM',
    'hour5': '01:00 PM - 02:00 PM', // Matches the parent's assumption
    'hour6': '02:00 PM - 03:00 PM', // Matches the parent's assumption
    'hour7': '03:15 PM - 04:15 PM', // Matches the parent's assumption
    'hour8': '04:15 PM - 05:15 PM', // Matches the parent's assumption
    // Adjust if necessary based on real data
  };

  late final List<Map<String, String>> _scheduledClasses;
  late final Map<String, String> _codeToNameMap;

  @override
  void initState() {
    super.initState();

    try {
      // Build course code → name map
      _codeToNameMap = {
        for (var course in widget.courseMap)
          if (course is Map && course['courseCode'] != null && course['courseName'] != null)
            course['courseCode'].toString().trim().toUpperCase():
            course['courseName'].toString().trim(),
      };

      _scheduledClasses = _getScheduledClassesForDay();

      // Pre-fill checkbox states
      for (var classData in _scheduledClasses) {
        if (classData['status'] == 'absent') {
          // Use a unique key for the checkbox map (subject + time)
          _checkboxStates[classData['subject']! + classData['time']!] = false;
        }
      }

    } catch (e) {
      print("Error in DayAttendanceDetail initState: $e");
      _scheduledClasses = [];
      _codeToNameMap = {};
    }
  }

  // ✅ This logic now loops over the corrected map keys
  List<Map<String, String>> _getScheduledClassesForDay() {
    final List<Map<String, String>> classes = [];
    final dayOfWeek = DateFormat('EEEE').format(widget.selectedDate).toLowerCase();

    // Find the timetable entry for this day
    final dayTimetable = widget.timetable.firstWhere(
          (d) => d is Map && d['day']?.toString().toLowerCase() == dayOfWeek,
      orElse: () => <String, dynamic>{},
    );

    if (dayTimetable.isEmpty) return [];

    // Loop over the _hourKeyToTime map's keys
    for (final hourKey in _hourKeyToTime.keys) {

      // Get the scheduled course codes for this hour (e.g., "ICT302")
      final rawSlotData = dayTimetable[hourKey]?.toString().trim();

      // Get the attendance status for this hour (e.g., "A")
      final status = widget.attendanceData[hourKey] ?? 'not updated';

      // Only show if there's a scheduled class
      if (rawSlotData != null && rawSlotData.isNotEmpty) {

        final timeString = _hourKeyToTime[hourKey] ?? 'All Day';

        final individualRawCodes = rawSlotData.split(',');
        for (final rawCode in individualRawCodes) {

          final cleanedCode = rawCode.trim().toUpperCase();
          if (cleanedCode.isEmpty) continue;

          final subjectName = _codeToNameMap[cleanedCode] ?? cleanedCode;

          classes.add({
            'code': cleanedCode,
            'subject': subjectName,
            'time': timeString,
            'status': status,
          });
        }
      }
    }

    // Sort the classes by their time
    classes.sort((a, b) {
      try {
        final timeA = DateFormat('h:mm a').parse(a['time']!.split(' - ')[0]);
        final timeB = DateFormat('h:mm a').parse(b['time']!.split(' - ')[0]);
        return timeA.compareTo(timeB);
      } catch (e) {
        return 0; // Should not happen with consistent time formats
      }
    });

    return classes;
  }


  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present': return Colors.green;
      case 'absent': return Colors.red;
      case 'od': return Colors.orange;
      default: return Colors.grey;
    }
  }

  Color _getSubjectColor(String subject) {
    final hash = subject.hashCode;
    return Color((hash & 0xFFFFFF) | 0xFF000000).withOpacity(1.0);
  }

  String _getInsightMessage() {
    if (!mounted || _scheduledClasses.isEmpty) {
      return 'No classes scheduled for today!';
    }

    int absentCount = _scheduledClasses.where((c) => c['status'] == 'absent').length;
    int odCount = _scheduledClasses.where((c) => c['status'] == 'od').length;
    bool pending = _scheduledClasses.any((c) => c['status'] == 'not updated');

    if (absentCount > 0) return 'You missed $absentCount class(es) today.';
    if (odCount > 0) return 'You were on OD for $odCount class(es) today.';
    if (pending) return 'Some classes are still pending update.';

    return 'You attended all your classes today!';
  }

  bool _isDarkMode(BuildContext context) =>
      Provider.of<ThemeProvider>(context).isDarkMode;

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode(context);
    final scale = MediaQuery.of(context).textScaler.scale(1.0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: Text(
          DateFormat('dd MMMM, yyyy').format(widget.selectedDate),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: isDark ? Colors.black12 : primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ThemeToggleButton(
              isDarkMode: isDark,
              onToggle: Provider.of<ThemeProvider>(context, listen: false).toggleTheme,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _scheduledClasses.length,
              itemBuilder: (context, index) {
                final classData = _scheduledClasses[index];
                final subject = classData['subject']!;
                final status = classData['status']!;
                final time = classData['time']!;
                // final code = classData['code']!; // We have this if needed

                final checkboxKey = subject + time;
                final isChecked = _checkboxStates[checkboxKey] ?? false;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 2,
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getSubjectColor(subject),
                      child: Text(
                        subject.substring(0, 1),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16 * scale,
                        ),
                      ),
                    ),
                    title: Text(
                      subject,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                        time, // Only show the time
                        style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey[600])),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12 * scale,
                            ),
                          ),
                        ),
                        if (status == 'absent')
                          Checkbox(
                            value: isChecked,
                            onChanged: (bool? newValue) {
                              setState(() {
                                _checkboxStates[checkboxKey] = newValue ?? false;
                              });
                            },
                            activeColor:
                            isDark ? Colors.cyanAccent : primaryBlue,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? primaryBlue.withOpacity(0.2)
                  : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getInsightMessage(),
              style: TextStyle(
                fontSize: 14 * scale,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}