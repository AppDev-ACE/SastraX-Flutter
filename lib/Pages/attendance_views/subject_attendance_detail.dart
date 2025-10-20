import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
// Adjust path if needed based on your project structure
import '../../models/theme_model.dart';
import 'dart:math';

class SubjectAttendanceDetail extends StatefulWidget {
  final String subjectName;
  final double attendancePercentage;
  final List<dynamic> initialSubjectAttendance; // Kept but not directly used in record fetching
  final List<dynamic> initialHourWiseAttendance;
  // *** This MUST be the NORMALIZED timetable passed from the parent ***
  final List<dynamic> timetable;
  final List<dynamic> courseMap;
  // Raw timetable is no longer needed with this logic

  const SubjectAttendanceDetail({
    Key? key,
    required this.subjectName,
    required this.attendancePercentage,
    required this.initialHourWiseAttendance,
    required this.courseMap,
    required this.initialSubjectAttendance,
    required this.timetable, // Normalized
  }) : super(key: key);

  static const Color primaryBlue = Color(0xFF1e3a8a);
  static const Color lightBlue = Color(0xFF4A90E2);

  @override
  State<SubjectAttendanceDetail> createState() => _SubjectAttendanceDetailState();
}

class _SubjectAttendanceDetailState extends State<SubjectAttendanceDetail> {

  List<Map<String, String>> _recentSubjectRecords = [];
  String _targetCode = ''; // Store the code from courseMap
  bool _isLoading = true;
  String _errorMessage = '';

  // Map hour keys (used in normalized timetable and attendance)
  static const List<String> _hourKeys = [
    "hour1", "hour2", "hour3", "hour4",
    "hour5", "hour6", "hour7", "hour8",
  ];

  // Helper to safely call setState only if mounted, after the current frame
  void safeSetState(VoidCallback fn) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(fn);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  // --- Orchestration Logic ---
  void _initializeData() {
    // No need for setState here initially
    _isLoading = true;
    _errorMessage = '';

    // Step 1: Find the code from courseMap
    _targetCode = _findCodeInCourseMap();

    if (_targetCode.isNotEmpty) {
      // Step 2 & 3: Find last 10 scheduled occurrences and get their status
      _recentSubjectRecords = _getLast10Records(_targetCode);
    } else {
      _recentSubjectRecords = [];
      _errorMessage = "Could not find code for '${widget.subjectName}' in course map.";
      print("[Initializer] $_errorMessage");
    }

    // Update the UI after processing is complete
    if (mounted) { // Check mount status before final setState
      setState(() => _isLoading = false);
    }
  }

  // --- Step 1: Find the code expected based on courseMap ---
  String _findCodeInCourseMap() {
    final String targetSubjectNameLower = widget.subjectName.trim().toLowerCase();
    for (var course in widget.courseMap) {
      if (course is Map) {
        final courseName = course['courseName']?.toString().trim().toLowerCase();
        if (courseName == targetSubjectNameLower) {
          final code = course['courseCode']?.toString().trim().toUpperCase() ?? '';
          print("[Code Finder] Found code '$code' for subject '${widget.subjectName}' in courseMap.");
          return code;
        }
      }
    }
    print("[Code Finder] ERROR: Could not find subject '${widget.subjectName}' in courseMap.");
    return ''; // Return empty if not found
  }


  // --- Step 2 & 3 Combined: Find Last 10 Occurrences and Get Status ---
  List<Map<String, String>> _getLast10Records(String targetCode) {
    print("[Record Fetcher] Finding last 10 scheduled occurrences for code: '$targetCode'");
    final List<Map<String, String>> records = [];
    // Stores {'date': DateTime, 'hourKey': String, 'dayName': String}
    final List<Map<String, dynamic>> foundOccurrences = [];

    // Create a lookup map for faster attendance checking
    final Map<DateTime, Map<String, dynamic>> attendanceLookup = {};
    for (var dayData in widget.initialHourWiseAttendance) {
      if (dayData is! Map || dayData['dateDay'] == null) continue;
      try {
        final dateString = (dayData['dateDay'] as String).split(' ')[0];
        final date = DateFormat('dd-MMM-yyyy').parse(dateString);
        final dayKey = DateTime(date.year, date.month, date.day); // Use date only as key
        attendanceLookup[dayKey] = Map<String, dynamic>.from(dayData); // Explicit cast
      } catch(e) {
        print("[Record Fetcher] Error parsing date for attendance lookup: ${dayData['dateDay']} - $e");
      }
    }
    print("[Record Fetcher] Created attendance lookup map with ${attendanceLookup.length} entries.");


    // Iterate backwards from today to find scheduled classes
    DateTime checkDate = DateTime.now();
    int daysChecked = 0;
    const int maxDaysToCheck = 90; // Limit search depth

    while (foundOccurrences.length < 10 && daysChecked < maxDaysToCheck) {
      final dayNameLower = DateFormat('EEEE').format(checkDate).toLowerCase(); // e.g., "monday"
      final dateOnly = DateTime(checkDate.year, checkDate.month, checkDate.day);

      // Find the timetable entry for this day of the week in the NORMALIZED timetable
      dynamic dayTimetableEntry = null;
      try {
        dayTimetableEntry = widget.timetable.firstWhere(
              (d) => d is Map && d['day']?.toString().toLowerCase() == dayNameLower,
        );
      } catch (e) { /* Day not found in timetable (expected for weekends/holidays) */ }

      if (dayTimetableEntry != null) {
        final dayTimetable = dayTimetableEntry as Map<String, dynamic>;
        // Check hours in NORMAL order for this day to get chronological occurrences
        for (final hourKey in _hourKeys) {
          final scheduledCodes = dayTimetable[hourKey]?.toString() ?? '';
          if (scheduledCodes.isNotEmpty) {
            final codesInSlot = scheduledCodes.split(',').map((c) => c.trim()).toList();
            if (codesInSlot.contains(targetCode)) {
              // Found a scheduled occurrence for the target code
              foundOccurrences.add({
                'date': dateOnly,
                'hourKey': hourKey,
                'dayName': DateFormat('EEEE').format(checkDate), // Full day name
              });
            }
          }
        }
      }

      // Move to the previous day
      checkDate = checkDate.subtract(const Duration(days: 1));
      daysChecked++;
    }

    // Sort occurrences newest first
    foundOccurrences.sort((a,b) {
      int dateComp = (b['date'] as DateTime).compareTo(a['date'] as DateTime);
      if (dateComp != 0) return dateComp;
      return _hourKeys.indexOf(b['hourKey']).compareTo(_hourKeys.indexOf(a['hourKey']));
    });

    print("[Record Fetcher] Found ${foundOccurrences.length} scheduled occurrences within the last $daysChecked days.");

    // Now, get the status for the latest 10 found occurrences
    int recordsAdded = 0;
    for (var occurrence in foundOccurrences) {
      if (recordsAdded >= 10) break; // Ensure we only take the top 10

      final DateTime occDate = occurrence['date'];
      final String occHourKey = occurrence['hourKey'];
      final String occDayName = occurrence['dayName'];

      // Look up the attendance record for this specific day
      final attendanceRecord = attendanceLookup[occDate];
      String finalStatus = 'not updated'; // Default

      if (attendanceRecord != null) {
        final status = attendanceRecord[occHourKey]?.toString().toUpperCase() ?? '';
        switch (status) {
          case 'P': finalStatus = 'present'; break;
          case 'A': finalStatus = 'absent'; break;
          case 'OD': finalStatus = 'OD'; break;
        }
      }

      records.add({
        'date': DateFormat('dd/MM').format(occDate),
        'dayName': occDayName,
        'status': finalStatus,
      });
      recordsAdded++;
    }

    if (records.isEmpty && _targetCode.isNotEmpty) {
      if (foundOccurrences.isEmpty) {
        _errorMessage = "Subject '$targetCode' was not found scheduled in the timetable within the last $maxDaysToCheck days.";
        print("[Record Fetcher] $_errorMessage");
      } else {
        _errorMessage = "Found scheduled classes, but couldn't retrieve attendance status for any recent ones.";
        print("[Record Fetcher] $_errorMessage");
      }
    } else {
      print("[Record Fetcher] Successfully compiled ${records.length} final records.");
    }

    return records;
  }


  // --- Helper methods ---
  bool _isDarkMode(BuildContext context) => Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
  Color _getBackgroundColor(BuildContext context) => _isDarkMode(context) ? const Color(0xFF121212) : Colors.white;
  Color _getCardColor(BuildContext context) => _isDarkMode(context) ? const Color(0xFF1E1E1E) : Colors.white;
  Color _getTextColor(BuildContext context) => _isDarkMode(context) ? Colors.white : Colors.black;
  Color _getSecondaryTextColor(BuildContext context) => _isDarkMode(context) ? Colors.white70 : Colors.grey[600]!;
  Color _getAppBarColor(BuildContext context) => _isDarkMode(context) ? Colors.black12 : SubjectAttendanceDetail.primaryBlue;
  Color _getGridColor(BuildContext context) => _isDarkMode(context) ? const Color(0xFF2C2C2C) : Colors.grey.withOpacity(0.3);
  Color _getAttendanceColor(double percentage) { if (percentage >= 80) return Colors.green; if (percentage >= 75) return Colors.orange; return Colors.red; }
  Color _getSubjectColor(String subject) { final hash = subject.hashCode; return Color((hash & 0xFFFFFF) | 0xFF000000).withOpacity(1.0); }
  Color _getStatusColor(String status) { switch (status.toLowerCase()) { case 'present': return Colors.green; case 'absent': return Colors.red; case 'od': return Colors.orange; default: return Colors.grey; } }

  // --- Recommendation Helper ---
  Widget _buildRecommendationItem(BuildContext context, String title, String value, IconData icon, Color color, double scale) { return Row( children: [ Icon(icon, color: color, size: 20 * scale), SizedBox(width: 8 * scale), Expanded( child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Text( title, style: TextStyle( fontSize: 12 * scale, color: _getSecondaryTextColor(context) ) ), Text( value?.toString() ?? '', style: TextStyle( fontWeight: FontWeight.bold, color: _getTextColor(context), fontSize: 14 * scale ), ), ], ), ), ], ); }


  // ============= BUILD METHOD WITH APPBAR FIX APPLIED =============
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).textScaler.scale(1.0);
    final screenWidth = MediaQuery.of(context).size.width;
    final double rPadding = screenWidth * 0.04;
    final bool isDark = _isDarkMode(context);
    final Color goalIconColor = isDark ? SubjectAttendanceDetail.lightBlue : SubjectAttendanceDetail.primaryBlue;

    return Scaffold(
      backgroundColor: _getBackgroundColor(context),
      appBar: AppBar(
        // Use a Column in the title slot for wrapping
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          crossAxisAlignment: CrossAxisAlignment.start, // Align text start
          children: [
            Text(
              widget.subjectName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18 * scale, // Slightly smaller base size
              ),
              textAlign: TextAlign.start, // Align text start
              softWrap: true, // Allow wrapping
              // Text will wrap automatically within the Column
            ),
          ],
        ),
        backgroundColor: _getAppBarColor(context),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: false, // Set to false to allow Column alignment to work
        // Optional: Increase height slightly if titles frequently wrap
        // toolbarHeight: kToolbarHeight + (widget.subjectName.length > 25 ? (20 * scale) : 0),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: isDark ? SubjectAttendanceDetail.lightBlue : SubjectAttendanceDetail.primaryBlue))
          : SingleChildScrollView(
        padding: EdgeInsets.all(rPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Attendance Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(rPadding),
              decoration: BoxDecoration(
                color: _getAttendanceColor(widget.attendancePercentage).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text('Current Attendance',
                      style: TextStyle(
                          fontSize: 16 * scale,
                          color: _getSecondaryTextColor(context))),
                  SizedBox(height: 8 * scale),
                  Text(
                    '${widget.attendancePercentage.toInt()}%',
                    style: TextStyle(
                        fontSize: 36 * scale,
                        fontWeight: FontWeight.bold,
                        color: _getAttendanceColor(widget.attendancePercentage)),
                  ),
                  SizedBox(height: 8 * scale),
                  LinearProgressIndicator(
                    value: widget.attendancePercentage / 100,
                    backgroundColor: _getGridColor(context),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _getAttendanceColor(widget.attendancePercentage)),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20 * scale),

            // ❌ GRAPH REMOVED

            // RECENT ATTENDANCE LIST (Using user's provided structure)
            Text('Recent Attendance Records',
                style: TextStyle(
                    fontSize: 18 * scale,
                    fontWeight: FontWeight.bold,
                    color: _getTextColor(context))),
            SizedBox(height: 16 * scale),
            ListView.builder( // Directly use ListView.builder
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              // Show 1 item for message, or actual record count
              itemCount: (_errorMessage.isNotEmpty || _recentSubjectRecords.isEmpty) ? 1 : _recentSubjectRecords.length,
              itemBuilder: (context, index) {
                // Handle Error Message
                if (_errorMessage.isNotEmpty) {
                  return Container(
                    width: double.infinity, padding: EdgeInsets.all(rPadding),
                    margin: EdgeInsets.only(bottom: 8 * scale), // Add margin like Card
                    decoration: BoxDecoration( color: _getCardColor(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.redAccent.withOpacity(0.7)) ),
                    child: Center( child: Text( _errorMessage, style: TextStyle(color: _isDarkMode(context) ? Colors.redAccent[100] : Colors.red[700], fontSize: 14 * scale), textAlign: TextAlign.center, ), ),
                  );
                }
                // Handle No Records Found
                else if (_recentSubjectRecords.isEmpty) {
                  return Container(
                    width: double.infinity, padding: EdgeInsets.all(rPadding),
                    margin: EdgeInsets.only(bottom: 8 * scale), // Add margin like Card
                    decoration: BoxDecoration( color: _getCardColor(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: _getGridColor(context)) ),
                    child: Center( child: Text( 'No recent attendance records found.', style: TextStyle(color: _getSecondaryTextColor(context), fontSize: 14 * scale), textAlign: TextAlign.center, ), ),
                  );
                }
                // Build Actual Record Item
                else {
                  // Ensure index is within bounds (should be, due to itemCount logic)
                  if (index >= _recentSubjectRecords.length) return const SizedBox.shrink(); // Safety net

                  final record = _recentSubjectRecords[index];
                  final dateStr = record['date']!;
                  final dayName = record['dayName']!;
                  final status = record['status']!;
                  return Card(
                    margin: EdgeInsets.only(bottom: 8 * scale),
                    color: _getCardColor(context),
                    shadowColor: _isDarkMode(context)
                        ? Colors.black54
                        : Colors.grey.withOpacity(0.2),
                    child: ListTile(
                      leading: Text(dateStr, style: TextStyle( fontWeight: FontWeight.bold, fontSize: 14 * scale, color: _getTextColor(context))),
                      title: Text(dayName, style: TextStyle( color: _getTextColor(context), fontSize: 16 * scale)),
                      trailing: Container(
                        padding: EdgeInsets.symmetric( horizontal: 8 * scale, vertical: 4 * scale),
                        decoration: BoxDecoration( color: _getStatusColor(status).withOpacity(0.2), borderRadius: BorderRadius.circular(20), ),
                        child: Text( status.toUpperCase(), style: TextStyle( color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 12 * scale), ),
                      ),
                    ),
                  );
                }
              },
            ),
            SizedBox(height: 20 * scale),

            // Recommendations Card
            Text('Recommendations',
                style: TextStyle(
                    fontSize: 18 * scale,
                    fontWeight: FontWeight.bold,
                    color: _getTextColor(context))),
            SizedBox(height: 16 * scale),
            Container(
              width: double.infinity, padding: EdgeInsets.all(rPadding),
              decoration: BoxDecoration( color: _isDarkMode(context) ? SubjectAttendanceDetail.primaryBlue.withOpacity(0.2) : Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12), ),
              child: Column( children: [
                _buildRecommendationItem(context, 'Attendance Goal', 'Try to maintain at least 85% attendance', Icons.flag, goalIconColor, scale),
                SizedBox(height: 12 * scale),
                _buildRecommendationItem(context, 'Study Time', 'Allocate extra time for ${widget.subjectName.toLowerCase()}', Icons.schedule, Colors.green, scale),
                SizedBox(height: 12 * scale),
                _buildRecommendationItem( context, 'Performance', widget.attendancePercentage < 75 ? 'Your attendance is below average. Focus on improving.' : 'Good attendance! Keep it up.', widget.attendancePercentage < 75 ? Icons.warning : Icons.thumb_up, widget.attendancePercentage < 75 ? Colors.orange : Colors.green, scale ),
              ], ),
            ),
          ],
        ),
      ),
    );
  }
}