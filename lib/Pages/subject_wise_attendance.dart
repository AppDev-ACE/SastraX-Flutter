// subject_wise_attendance_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Import your models/components
import '../models/theme_model.dart';
import '../components/theme_toggle_button.dart';
import 'attendance_views/monthly_view.dart';
import 'attendance_views/subject_view.dart';
import 'attendance_views/analytics_view.dart';

class SubjectWiseAttendancePage extends StatefulWidget {
  final String regNo;
  final String token;
  final String url;
  final List<dynamic> initialSubjectAttendance;
  final List<dynamic> initialHourWiseAttendance;
  final List<dynamic> timetable;
  final List<dynamic> courseMap;

  const SubjectWiseAttendancePage({
    Key? key,
    required this.regNo,
    required this.token,
    required this.url,
    required this.initialSubjectAttendance,
    required this.initialHourWiseAttendance,
    required this.timetable,
    required this.courseMap,
  }) : super(key: key);

  @override
  State<SubjectWiseAttendancePage> createState() =>
      _SubjectWiseAttendancePageState();
}

class _SubjectWiseAttendancePageState
    extends State<SubjectWiseAttendancePage> with TickerProviderStateMixin {
  late TabController _tabController;

  Map<DateTime, Map<String, String>> _attendanceData = {};
  Map<String, Map<String, dynamic>> _subjectAttendance = {};
  List<Map<String, dynamic>> _normalizedTimetable = [];
  int _currentStreak = 0;

  static const Color primaryBlue = Color(0xFF1e3a8a);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));

    _processData(
      subjectData: widget.initialSubjectAttendance,
      hourData: widget.initialHourWiseAttendance,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// ✅ **FINAL, CORRECT DATA PROCESSING LOGIC**
  void _processData({required List<dynamic> subjectData, required List<dynamic> hourData}) {
    // Step 1: Normalize the timetable
    final List<Map<String, dynamic>> normalized = [];
    final Map<String, String> dayAbbreviationMap = {
      "Mon": "Monday", "Tue": "Tuesday", "Wed": "Wednesday",
      "Thu": "Thursday", "Fri": "Friday", "Sat": "Saturday",
    };

    // Correct Mapping
    final Map<String, String> slotToHourKeyMap = {
      "08:45 - 09:45": "hour1",
      "09:45 - 10:45": "hour2",
      "11:00 - 12:00": "hour3",
      "12:00 - 01:00": "hour4",
      "01:00 - 02:00": "hour5", // Assuming 1-2 PM maps to hour5
      "02:00 - 03:00": "hour6", // Assuming 2-3 PM maps to hour6
      "03:15 - 04:15": "hour7", // Assuming 3:15-4:15 PM maps to hour7
      "04:15 - 05:15": "hour8", // Assuming 4:15-5:15 PM maps to hour8
      // Adjust if necessary
    };

    for (var dayEntry in widget.timetable) {
      if (dayEntry is! Map) continue;
      final String dayAbbr = dayEntry['day']?.toString() ?? '';
      final Map<String, dynamic> newDay = {'day': dayAbbreviationMap[dayAbbr] ?? dayAbbr};

      for (final entry in slotToHourKeyMap.entries) {
        final timeSlotKey = entry.key;
        final hourKey = entry.value;
        final rawSlotData = dayEntry[timeSlotKey]?.toString();

        if (rawSlotData != null &&
            rawSlotData.isNotEmpty &&
            rawSlotData.trim() != 'N/A' &&
            rawSlotData.trim().toLowerCase() != 'break') {
          final individualRawCodes = rawSlotData.split(',');
          List<String> cleanedCodes = [];
          for (final rawCode in individualRawCodes) {
            final cleanedCode = rawCode
                .trim()
                .replaceAll(RegExp(r'\((.*?)\)'), '')
                .replaceAll(RegExp(r'-[A-Z0-9]+$'), '')
                .trim()
                .toUpperCase();
            if (cleanedCode.isNotEmpty) {
              cleanedCodes.add(cleanedCode);
            }
          }
          newDay[hourKey] = cleanedCodes.join(',');
        }
      }
      normalized.add(newDay);
    }
    setState(() => _normalizedTimetable = normalized);

    // Step 2: Process hour-wise data
    final newAttendanceData = <DateTime, Map<String, String>>{};
    for (var dayData in hourData) {
      if (dayData is! Map || dayData['dateDay'] == null) continue;
      try {
        final dateString = (dayData['dateDay'] as String).split(' ')[0];
        final date = DateFormat('dd-MMM-yyyy').parse(dateString);
        final dayKey = DateTime(date.year, date.month, date.day);
        final Map<String, String> hourMap = {};
        for (final hourKey in slotToHourKeyMap.values) {
          final status = dayData[hourKey]?.toString() ?? '';
          if (status.isNotEmpty) {
            switch (status.toUpperCase()) {
              case 'P': hourMap[hourKey] = 'present'; break;
              case 'A': hourMap[hourKey] = 'absent'; break;
              case 'OD': hourMap[hourKey] = 'OD'; break;
            }
          }
        }
        if (hourMap.isNotEmpty) {
          newAttendanceData[dayKey] = hourMap;
        }
      } catch (e) {
        debugPrint("Error parsing hour data for ${dayData['dateDay']}: $e");
      }
    }
    setState(() => _attendanceData = newAttendanceData);

    // Step 3: Process subject summary (✅ OD count is now included)
    final newSubjectAttendance = <String, Map<String, dynamic>>{};
    for (var item in subjectData) {
      if (item is! Map) continue;
      final subjectName = item['subject'] as String? ?? 'Unknown';

      // Safely parse counts, defaulting to 0
      final totalClasses = int.tryParse(item['totalHrs']?.toString() ?? '0') ?? 0;
      final present = int.tryParse(item['presentHrs']?.toString() ?? '0') ?? 0;
      final absent = int.tryParse(item['absentHrs']?.toString() ?? '0') ?? 0;

      // Calculate OD count
      final odCount = (totalClasses - present - absent).clamp(0, totalClasses);

      newSubjectAttendance[subjectName] = {
        'percentage': double.tryParse(item['percentage']?.toString() ?? '0.0') ?? 0.0,
        'totalClasses': totalClasses,
        'present': present,
        'absent': absent,
        'od': odCount, // Add the calculated OD count here
      };
    }
    setState(() => _subjectAttendance = newSubjectAttendance);

    // Step 4: Calculate streak
    _calculateCurrentStreak();
  }

  bool _isDayPresentOrOd(DateTime day) {
    final dayKey = DateTime(day.year, day.month, day.day);
    if (!_attendanceData.containsKey(dayKey)) return false;
    return !_attendanceData[dayKey]!.values.any((status) => status == 'absent');
  }

  void _calculateCurrentStreak() {
    final sortedDates = _attendanceData.keys.toList()..sort((a, b) => b.compareTo(a));
    if (sortedDates.isEmpty) {
      setState(() => _currentStreak = 0); // Use setState here
      return;
    }

    int streak = 0;
    DateTime? previousDate;
    for (final date in sortedDates) {
      if (_isDayPresentOrOd(date)) {
        if (previousDate == null) {
          streak = 1;
        } else {
          final difference = previousDate.difference(date).inDays;
          if (difference == 1 ||
              (previousDate.weekday == DateTime.monday &&
                  date.weekday == DateTime.friday && difference <= 3)) {
            streak++;
          } else {
            break;
          }
        }
        previousDate = date;
      } else {
        break; // Stop streak if a day is absent or missing
      }
    }
    setState(() => _currentStreak = streak);
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final double scaleFactor = screenWidth / 390.0;

    final double selectedFontSize = (15 * scaleFactor).clamp(12.0, 16.0);
    final double unselectedFontSize = (13 * scaleFactor).clamp(11.0, 14.0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text('Attendance', style: TextStyle(color: Colors.white)),
        backgroundColor: isDark ? Colors.black12 : primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ThemeToggleButton(isDarkMode: isDark, onToggle: themeProvider.toggleTheme),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false, // Make tabs fill width
          tabAlignment: TabAlignment.fill, // Ensure they fill equally
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: ['Monthly View', 'Subject View', 'Analytics']
              .asMap()
              .entries
              .map((entry) => Tab(
            child: Text(
              entry.value,
              textAlign: TextAlign.center, // Center text within the tab
              style: TextStyle(
                fontSize: _tabController.index == entry.key
                    ? selectedFontSize
                    : unselectedFontSize,
                fontWeight: _tabController.index == entry.key
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          MonthlyView(
            attendanceData: _attendanceData,
            currentStreak: _currentStreak,
            timetable: _normalizedTimetable,
            courseMap: widget.courseMap,
            regNo: widget.regNo,
          ),
          SubjectView(
            // Pass the updated map which includes 'od'
            subjectAttendance: _subjectAttendance,
          ),
          AnalyticsView(
            // Pass the updated map which includes 'od'
            subjectAttendance: _subjectAttendance,
          ),
        ],
      ),
    );
  }
}