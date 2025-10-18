// monthly_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../../models/theme_model.dart'; // Ensure this path is correct
import 'day_attendance_detail.dart';

class MonthlyView extends StatefulWidget {
  final Map<DateTime, Map<String, String>> attendanceData; // Expects {'hour1': 'present'}
  final int currentStreak;
  final String regNo ;
  final List<dynamic> timetable; // Normalized timetable
  final List<dynamic> courseMap;

  const MonthlyView({
    Key? key,
    required this.regNo,
    required this.attendanceData,
    required this.currentStreak,
    required this.timetable,
    required this.courseMap,
  }) : super(key: key);

  @override
  State<MonthlyView> createState() => _MonthlyViewState();
}

class _MonthlyViewState extends State<MonthlyView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  static const Color primaryBlue = Color(0xFF1e3a8a);
  static const Color lightBlue = Color(0xFF4A90E2);
  static const Color cyanColor = Color(0xFF00BCD4);

  // ✅ Fixed _calculateMonthStats
  Map<String, int> _calculateMonthStats() {
    int presentCount = 0;
    int absentCount = 0;
    int odCount = 0; // Start at 0

    widget.attendanceData.forEach((date, hourMap) {
      // Check if it's the correct month/year
      if (date.month == _focusedDay.month && date.year == _focusedDay.year) {
        // Count statuses for that day
        int dailyPresent = 0;
        int dailyAbsent = 0;
        int dailyOd = 0;

        hourMap.forEach((hourKey, status) {
          // Ensure status is not null before converting to lowercase
          if (status != null) {
            switch (status.toLowerCase()) { // Convert to lowercase
              case 'present':
                dailyPresent++;
                break;
              case 'absent':
                dailyAbsent++;
                break;
              case 'od': // Match lowercase 'od'
                dailyOd++;
                break;
            }
          }
        });
        // Add daily counts to monthly total
        presentCount += dailyPresent;
        absentCount += dailyAbsent;
        odCount += dailyOd;
      }
    });
    // Always return the counts
    return {'present': presentCount, 'absent': absentCount, 'od': odCount};
  }


  // --- Theming Helpers ---
  Color _getTextColor(BuildContext context) =>
      Provider.of<ThemeProvider>(context).isDarkMode ? Colors.white : Colors.black;
  Color _getSecondaryTextColor(BuildContext context) =>
      Provider.of<ThemeProvider>(context).isDarkMode
          ? Colors.white70
          : Colors.grey[600]!;
  Color _getCardColor(BuildContext context) =>
      Provider.of<ThemeProvider>(context).isDarkMode
          ? const Color(0xFF1E1E1E)
          : Colors.white;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    // ============= RESPONSIVE SCALING =============
    final scale = MediaQuery.of(context).textScaler.scale(1.0);
    final screenWidth = MediaQuery.of(context).size.width;
    // Use 4% of screen width as responsive padding, ~16px on a 400px wide screen
    final double rPadding = screenWidth * 0.04;
    // ==============================================

    final stats = _calculateMonthStats(); // Calculate stats
    // Null safety for calculations
    final present = stats['present'] ?? 0;
    final absent = stats['absent'] ?? 0;
    final od = stats['od'] ?? 0;
    final totalClasses = present + absent + od;
    final percentage = totalClasses > 0
        ? ((present + od) / totalClasses * 100).round()
        : 0;

    // ============== COLOR FIX ==============
    // Use lightBlue in dark mode, primaryBlue in light mode
    final Color percentageColor = isDark ? lightBlue : primaryBlue;
    // =======================================

    return Column(
      children: [
        // --- Monthly Stats Header ---
        Container(
          padding: EdgeInsets.all(rPadding), // Responsive padding
          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(_focusedDay),
                    style: TextStyle(
                        fontSize: 18 * scale, // Responsive font
                        fontWeight: FontWeight.bold,
                        color: _getTextColor(context)),
                  ),
                  Row(
                    children: [
                      _buildLegend('Present', Colors.green, scale), // Pass scale
                      SizedBox(width: rPadding), // Responsive spacing
                      _buildLegend('Absent', Colors.red, scale), // Pass scale
                      SizedBox(width: rPadding), // Responsive spacing
                      _buildLegend('OD', Colors.orange, scale), // Pass scale
                    ],
                  ),
                ],
              ),
              SizedBox(height: rPadding), // Responsive spacing
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMonthStat('Present', present.toString(), Colors.green, scale),
                  _buildMonthStat('Absent', absent.toString(), Colors.red, scale),
                  _buildMonthStat('OD', od.toString(), Colors.orange, scale),
                  // Use the new dynamic color
                  _buildMonthStat('Percentage', '$percentage%', percentageColor, scale),
                ],
              ),
            ],
          ),
        ),
        // --- Calendar ---
        Expanded(
          child: Container(
            color: isDark ? const Color(0xFF121212) : primaryBlue.withOpacity(0.1),
            child: Padding(
              padding: EdgeInsets.all(rPadding), // Responsive padding
              child: Container(
                decoration: BoxDecoration(
                  color: _getCardColor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? cyanColor : primaryBlue, width: 3),
                ),
                child: TableCalendar<String>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: (day) {
                    final dayKey = DateTime(day.year, day.month, day.day);
                    return widget.attendanceData.containsKey(dayKey)
                        ? ['has data'] // Needs a non-empty list for marker
                        : [];
                  },
                  // ============= RESPONSIVE CALENDAR STYLES =============
                  calendarStyle: CalendarStyle(
                    markersMaxCount: 1,
                    markerDecoration:
                    const BoxDecoration(color: Colors.transparent), // Hide default marker
                    todayDecoration: BoxDecoration(
                        color: lightBlue.withOpacity(0.3),
                        shape: BoxShape.circle),
                    selectedDecoration: BoxDecoration(
                        color: primaryBlue, shape: BoxShape.circle),
                    defaultTextStyle: TextStyle(
                        color: _getTextColor(context), fontSize: 14 * scale),
                    selectedTextStyle:
                    TextStyle(color: Colors.white, fontSize: 14 * scale),
                    todayTextStyle: TextStyle(
                        color: _getTextColor(context), fontSize: 14 * scale),
                    weekendTextStyle: TextStyle(
                        color: _getTextColor(context), fontSize: 14 * scale),
                    outsideTextStyle:
                    TextStyle(color: _getSecondaryTextColor(context), fontSize: 12 * scale),
                    outsideDaysVisible: false,
                  ),
                  headerStyle: HeaderStyle(
                    titleTextStyle:
                    TextStyle(color: _getTextColor(context), fontSize: 16 * scale),
                    formatButtonTextStyle:
                    TextStyle(color: _getTextColor(context), fontSize: 14 * scale),
                    leftChevronIcon: Icon(Icons.chevron_left,
                        color: _getTextColor(context)),
                    rightChevronIcon: Icon(Icons.chevron_right,
                        color: _getTextColor(context)),
                    formatButtonDecoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2C)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                        color: _getTextColor(context), fontSize: 12 * scale),
                    weekendStyle: TextStyle(
                        color: _getTextColor(context), fontSize: 12 * scale),
                  ),
                  // ======================================================
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      // Custom marker logic based on attendance
                      if (events.isNotEmpty) {
                        return Positioned(
                            right: 1,
                            bottom: 1,
                            child: _buildAttendanceMarker(day, scale)); // Pass scale
                      }
                      return null;
                    },
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    final dayKey = DateTime(
                        selectedDay.year, selectedDay.month, selectedDay.day);
                    // Only navigate if there's actual data for the day
                    if (widget.attendanceData.containsKey(dayKey)) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay; // Keep focused day in sync
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DayAttendanceDetail(
                            selectedDate: selectedDay,
                            // Pass the hour map for the selected day
                            attendanceData: widget.attendanceData[dayKey] ?? {},
                            timetable: widget.timetable, // Pass normalized timetable
                            courseMap: widget.courseMap,
                            regNo: widget.regNo,
                          ),
                        ),
                      );
                    } else {
                      setState(() {
                        _selectedDay = selectedDay; // Still select the day visually
                        _focusedDay = focusedDay;
                      });
                    }
                  },
                  onPageChanged: (focusedDay) {
                    // Update stats when month changes
                    setState(() => _focusedDay = focusedDay);
                  },
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() => _calendarFormat = format);
                    }
                  },
                ),
              ),
            ),
          ),
        ),
        // --- Achievements Footer ---
        Container(
          padding: EdgeInsets.all(rPadding), // Responsive padding
          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attendance Achievements',
                style: TextStyle(
                    fontSize: 16 * scale, // Responsive font
                    fontWeight: FontWeight.bold,
                    color: _getTextColor(context)),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAchievement('Current Streak',
                      '${widget.currentStreak}', Icons.local_fire_department, Colors.orange, scale),
                  // Replace placeholders with actual logic later
                  _buildAchievement(
                      'Best Month', 'Sept', Icons.emoji_events, Colors.amber, scale),
                  _buildAchievement(
                      'Improvement', '+5%', Icons.trending_up, Colors.green, scale),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Helper Widgets (Now with responsive scale) ---

  Widget _buildLegend(String label, Color color, double scale) {
    return Row(
      children: [
        Container(
            width: 12 * scale, // Responsive size
            height: 12 * scale, // Responsive size
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: _getTextColor(context), fontSize: 12 * scale)), // Responsive font
      ],
    );
  }

  Widget _buildMonthStat(String label, String? value, Color color, double scale) {
    return Column(
      children: [
        Text(
            value ?? '0', // Display '0' if value is null
            style: TextStyle(fontSize: 20 * scale, fontWeight: FontWeight.bold, color: color)), // Responsive font
        Text(label, style: TextStyle(fontSize: 12 * scale, color: Colors.grey)), // Responsive font
      ],
    );
  }

  Widget _buildAttendanceMarker(DateTime day, double scale) {
    final dayKey = DateTime(day.year, day.month, day.day);
    if (!widget.attendanceData.containsKey(dayKey)) return const SizedBox();

    final dayAttendanceMap = widget.attendanceData[dayKey]!; // {'hour1': 'present', ...}

    // Determine color based on the values in the map
    bool hasAbsent = dayAttendanceMap.values.any((s) => s == 'absent');
    bool hasOd = dayAttendanceMap.values.any((s) => s.toLowerCase() == 'od');

    Color color;
    if (hasAbsent) {
      color = Colors.red;
    } else if (hasOd) {
      color = Colors.orange;
    } else {
      color = Colors.green; // All present or only present/unknown
    }
    return Container(
        width: 8 * scale, // Responsive size
        height: 8 * scale, // Responsive size
        decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }

  Widget _buildAchievement(
      String title, String value, IconData icon, Color color, double scale) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8 * scale), // Responsive padding
          decoration:
          BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24 * scale), // Responsive icon
        ),
        const SizedBox(height: 4),
        Text(value ?? '', // Handle potential null value
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getTextColor(context),
                fontSize: 14 * scale)), // Responsive font
        Text(title, style: TextStyle(fontSize: 10 * scale, color: Colors.grey)), // Responsive font
      ],
    );
  }
}